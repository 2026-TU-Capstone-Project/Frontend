import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/fitting/clothes/repository/clothes_repository.dart';

enum _UploadStep {
  queued,
  processingAi,
  saving,
  completed,
  failed,
}

extension _UploadStepX on _UploadStep {
  static _UploadStep? fromStringOrNull(String raw) {
    switch (raw.trim().toUpperCase()) {
      case 'QUEUED':
        return _UploadStep.queued;
      case 'PROCESSING':       // 서버 실제 값
      case 'PROCESSING_AI':   // 스펙 예비 값
        return _UploadStep.processingAi;
      case 'SAVING':
        return _UploadStep.saving;
      case 'COMPLETED':
        return _UploadStep.completed;
      case 'FAILED':
        return _UploadStep.failed;
      default:
        return null;
    }
  }

  String get label {
    switch (this) {
      case _UploadStep.queued:
        return 'AI 분석 대기 중...';
      case _UploadStep.processingAi:
        return 'AI 사진 누끼 작업 중...';
      case _UploadStep.saving:
        return '옷 정보 저장 중...';
      case _UploadStep.completed:
        return '등록 완료!';
      case _UploadStep.failed:
        return '서버에서 등록에 실패했습니다.';
    }
  }

  double get progress {
    switch (this) {
      case _UploadStep.queued:
        return 0.2;
      case _UploadStep.processingAi:
        return 0.5;
      case _UploadStep.saving:
        return 0.8;
      case _UploadStep.completed:
        return 1.0;
      case _UploadStep.failed:
        return 0.0;
    }
  }
}

/// 옷 업로드 진행 상황을 SSE로 실시간 수신하는 프로그레스 다이얼로그.
///
/// - SSE가 정상 동작 시: COMPLETED → pop(true), FAILED → pop(false)
/// - SSE 연결 자체 실패 시: POST는 이미 성공했으므로 일정 시간 후 pop(true)로 폴백
class ClothingUploadProgressDialog extends StatefulWidget {
  const ClothingUploadProgressDialog({super.key, required this.taskId});

  final int taskId;

  @override
  State<ClothingUploadProgressDialog> createState() =>
      _ClothingUploadProgressDialogState();
}

class _ClothingUploadProgressDialogState
    extends State<ClothingUploadProgressDialog> {
  _UploadStep _step = _UploadStep.queued;
  bool _isDone = false;

  // SSE 연결이 아닌 서버가 명시적으로 FAILED를 보낸 경우 true
  bool _serverFailed = false;

  // SSE 연결 실패 후 폴백 타이머가 돌고 있을 때 true
  bool _fallbackMode = false;

  HttpClient? _httpClient;
  StreamSubscription<String>? _subscription;

  @override
  void initState() {
    super.initState();
    _connectSse();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _httpClient?.close(force: true);
    super.dispose();
  }

  Future<void> _connectSse() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'ACCESS_TOKEN');
      if (!mounted) return;

      final uri = Uri.parse(
        '$baseUrl/api/v1/clothes/upload/${widget.taskId}/stream',
      );
      debugPrint('[SSE] 연결 시도: $uri');

      _httpClient = HttpClient();
      final request = await _httpClient!.getUrl(uri);

      if (token != null && token.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      request.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
      request.headers.set('cache-control', 'no-cache');

      final response = await request.close();
      debugPrint('[SSE] 응답 상태: ${response.statusCode}');

      if (!mounted) return;

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('[SSE] 비정상 응답 → 폴백 처리');
        _onSseConnectionLost();
        return;
      }

      final buffer = StringBuffer();

      _subscription = response.transform(utf8.decoder).listen(
        (text) {
          if (_isDone) return;
          debugPrint('[SSE] 수신 청크: ${text.replaceAll('\n', '↵')}');
          buffer.write(text);

          while (buffer.toString().contains('\n\n')) {
            final full = buffer.toString();
            final splitIdx = full.indexOf('\n\n');
            final eventBlock = full.substring(0, splitIdx);
            buffer.clear();
            buffer.write(full.substring(splitIdx + 2));
            _handleEventBlock(eventBlock);
            if (_isDone) return;
          }
        },
        onError: (Object e) {
          debugPrint('[SSE] 스트림 오류: $e');
          if (!_isDone) _onSseConnectionLost();
        },
        onDone: () {
          debugPrint('[SSE] 스트림 종료. 버퍼 잔여: "${buffer.toString().trim()}"');
          final remaining = buffer.toString().trim();
          if (remaining.isNotEmpty && !_isDone) {
            _handleEventBlock(remaining);
          }
          // COMPLETED/FAILED 없이 스트림 종료 → 폴백
          if (!_isDone) _onSseConnectionLost();
        },
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('[SSE] 연결 예외: $e');
      if (!_isDone) _onSseConnectionLost();
    }
  }

  void _handleEventBlock(String block) {
    debugPrint('[SSE] 이벤트 블록:\n$block');
    String? rawData;

    for (final line in block.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('data:')) {
        rawData = trimmed.substring(5).trim();
      }
    }

    if (rawData == null) return;

    // 서버가 JSON 객체로 보내는 경우: {"taskId":15,"status":"COMPLETED",...}
    // plain text 로 보내는 경우: COMPLETED
    String? statusStr;
    try {
      final json = jsonDecode(rawData) as Map<String, dynamic>;
      statusStr = json['status'] as String?;
    } catch (_) {
      // JSON이 아니면 data 값 자체가 status 문자열
      statusStr = rawData;
    }

    if (statusStr == null) return;

    final step = _UploadStepX.fromStringOrNull(statusStr);
    if (step != null) {
      debugPrint('[SSE] 상태 수신: $statusStr');
      _applyStatus(step);
    } else {
      debugPrint('[SSE] 알 수 없는 status (무시): $statusStr');
    }
  }

  void _applyStatus(_UploadStep step) {
    if (!mounted) return;

    setState(() => _step = step);

    if (step == _UploadStep.completed) {
      _isDone = true;
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) Navigator.of(context).pop(true);
      });
    } else if (step == _UploadStep.failed) {
      _onServerFailed();
    }
  }

  /// 서버가 FAILED 상태를 명시적으로 보낸 경우 — 실제 실패 처리
  void _onServerFailed() {
    if (!mounted || _isDone) return;
    _isDone = true;
    _serverFailed = true;
    setState(() => _step = _UploadStep.failed);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) Navigator.of(context).pop(false);
    });
  }

  /// SSE 연결 자체가 실패 — POST는 이미 성공했으므로 폴백으로 처리
  ///
  /// 서버가 AI 처리를 완료하면 옷은 등록되므로, 일정 시간 후 성공으로 닫는다.
  void _onSseConnectionLost() {
    if (!mounted || _isDone) return;
    _isDone = true;
    debugPrint('[SSE] 연결 유실 — 20초 대기 후 목록 갱신으로 폴백');
    setState(() => _fallbackMode = true);
    Future.delayed(const Duration(seconds: 20), () {
      if (mounted) Navigator.of(context).pop(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.white,
      elevation: 8,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(),
            const SizedBox(height: 20),
            _buildTitle(),
            const SizedBox(height: 8),
            _buildStatusMessage(),
            const SizedBox(height: 24),
            _buildProgressBar(),
            const SizedBox(height: 8),
            _buildStepLabels(),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (_step == _UploadStep.completed) {
      return Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(
          color: AppColors.SUCCESS_COLOR,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, color: AppColors.white, size: 36),
      );
    }
    if (_serverFailed) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.ERROR_COLOR.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.error_outline_rounded,
          color: AppColors.ERROR_COLOR,
          size: 36,
        ),
      );
    }
    return const SizedBox(
      width: 48,
      height: 48,
      child: CircularProgressIndicator(
        color: AppColors.ACCENT_BLUE,
        strokeWidth: 3.5,
      ),
    );
  }

  Widget _buildTitle() {
    if (_step == _UploadStep.completed) {
      return const Text(
        '등록 완료!',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.SUCCESS_COLOR,
        ),
      );
    }
    if (_serverFailed) {
      return const Text(
        '등록 실패',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.ERROR_COLOR,
        ),
      );
    }
    return const Text(
      '옷 등록 중',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.BLACK,
      ),
    );
  }

  Widget _buildStatusMessage() {
    // SSE 연결 실패 폴백 모드
    if (_fallbackMode && !_serverFailed && _step != _UploadStep.completed) {
      return const Text(
        '등록 처리 중입니다.\n완료되면 자동으로 닫힙니다.',
        style: TextStyle(
          fontSize: 14,
          color: AppColors.BODY_COLOR,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      );
    }
    return Text(
      _step.label,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.BODY_COLOR,
        height: 1.4,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildProgressBar() {
    if (_serverFailed) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        // 폴백 모드에서는 indeterminate(null) 진행바 표시
        value: _fallbackMode ? null : _step.progress,
        minHeight: 6,
        backgroundColor: AppColors.BORDER_COLOR,
        valueColor: AlwaysStoppedAnimation<Color>(
          _step == _UploadStep.completed
              ? AppColors.SUCCESS_COLOR
              : AppColors.ACCENT_BLUE,
        ),
      ),
    );
  }

  Widget _buildStepLabels() {
    if (_serverFailed || _fallbackMode) return const SizedBox.shrink();
    const steps = ['대기', 'AI 처리', '저장', '완료'];
    final activeIdx = _step == _UploadStep.queued
        ? 0
        : _step == _UploadStep.processingAi
            ? 1
            : _step == _UploadStep.saving
                ? 2
                : 3;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(steps.length, (i) {
        final isActive = i <= activeIdx;
        return Text(
          steps[i],
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            color: isActive ? AppColors.ACCENT_BLUE : AppColors.MEDIUM_GREY,
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 옷 삭제 진행 다이얼로그
// ─────────────────────────────────────────────────────────────────────────────

enum _DeleteStep { deleting, completed, failed }

/// 옷 삭제 진행 상황을 표시하는 프로그레스 다이얼로그.
/// - 성공 시 pop(true), 실패 시 pop(false)
class ClothingDeleteProgressDialog extends StatefulWidget {
  const ClothingDeleteProgressDialog({
    super.key,
    required this.clothId,
    required this.repository,
  });

  final int clothId;
  final ClothesRepository repository;

  @override
  State<ClothingDeleteProgressDialog> createState() =>
      _ClothingDeleteProgressDialogState();
}

class _ClothingDeleteProgressDialogState
    extends State<ClothingDeleteProgressDialog> {
  _DeleteStep _step = _DeleteStep.deleting;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _runDelete();
  }

  Future<void> _runDelete() async {
    try {
      final resp = await widget.repository.deleteCloth(id: widget.clothId);
      if (!mounted) return;
      if (resp.success) {
        setState(() => _step = _DeleteStep.completed);
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.of(context).pop(true);
      } else {
        setState(() {
          _step = _DeleteStep.failed;
          _errorMessage = resp.message;
        });
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.of(context).pop(false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _step = _DeleteStep.failed;
        _errorMessage = e.toString();
      });
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.white,
      elevation: 8,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(),
            const SizedBox(height: 20),
            _buildTitle(),
            const SizedBox(height: 8),
            _buildStatusMessage(),
            const SizedBox(height: 24),
            _buildProgressBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (_step == _DeleteStep.completed) {
      return Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(
          color: AppColors.SUCCESS_COLOR,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, color: AppColors.white, size: 36),
      );
    }
    if (_step == _DeleteStep.failed) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.ERROR_COLOR.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.error_outline_rounded,
          color: AppColors.ERROR_COLOR,
          size: 36,
        ),
      );
    }
    return const SizedBox(
      width: 48,
      height: 48,
      child: CircularProgressIndicator(
        color: AppColors.ACCENT_BLUE,
        strokeWidth: 3.5,
      ),
    );
  }

  Widget _buildTitle() {
    switch (_step) {
      case _DeleteStep.completed:
        return const Text(
          '삭제 완료!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.SUCCESS_COLOR,
          ),
        );
      case _DeleteStep.failed:
        return const Text(
          '삭제 실패',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.ERROR_COLOR,
          ),
        );
      case _DeleteStep.deleting:
        return const Text(
          '옷 삭제 중',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.BLACK,
          ),
        );
    }
  }

  Widget _buildStatusMessage() {
    switch (_step) {
      case _DeleteStep.completed:
        return const Text(
          '옷이 삭제되었습니다.',
          style: TextStyle(fontSize: 14, color: AppColors.BODY_COLOR, height: 1.4),
          textAlign: TextAlign.center,
        );
      case _DeleteStep.failed:
        return Text(
          _errorMessage ?? '삭제에 실패했습니다. 다시 시도해주세요.',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.ERROR_COLOR,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        );
      case _DeleteStep.deleting:
        return const Text(
          '잠시만 기다려주세요...',
          style: TextStyle(fontSize: 14, color: AppColors.BODY_COLOR, height: 1.4),
          textAlign: TextAlign.center,
        );
    }
  }

  Widget _buildProgressBar() {
    if (_step == _DeleteStep.failed) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: _step == _DeleteStep.deleting ? null : 1.0,
        minHeight: 6,
        backgroundColor: AppColors.BORDER_COLOR,
        valueColor: AlwaysStoppedAnimation<Color>(
          _step == _DeleteStep.completed
              ? AppColors.SUCCESS_COLOR
              : AppColors.ACCENT_BLUE,
        ),
      ),
    );
  }
}
