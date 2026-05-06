import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/common/provider/dio_provider.dart';
import 'package:capstone_fe/chat/model/chat_model.dart';
import 'package:capstone_fe/chat/repository/chat_repository.dart';
import 'package:capstone_fe/fitting/util/weather_util.dart';

// ─── Repository Provider ──────────────────────────────────────────────────────

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(authDioProvider), baseUrl: baseUrl);
});

// ─── Weather Cache (5분 TTL) ─────────────────────────────────────────────────

class _WeatherCache {
  WeatherInfo? _data;
  DateTime? _fetchedAt;
  static const _ttl = Duration(minutes: 5);

  bool get isValid =>
      _data != null &&
      _fetchedAt != null &&
      DateTime.now().difference(_fetchedAt!) < _ttl;

  WeatherInfo? get data => isValid ? _data : null;

  void update(WeatherInfo info) {
    _data = info;
    _fetchedAt = DateTime.now();
  }
}

final _weatherCache = _WeatherCache();

/// 마지막으로 캐시된 날씨 정보를 UI에서 읽을 수 있도록 노출
final cachedWeatherProvider = StateProvider<WeatherInfo?>((ref) => null);

// ─── UI-only chat message model ───────────────────────────────────────────────

class ChatMessage {
  final bool isUser;
  final String? text;
  final ChatResponseData? responseData;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? sentAt;

  const ChatMessage({
    required this.isUser,
    this.text,
    this.responseData,
    this.isLoading = false,
    this.errorMessage,
    this.sentAt,
  });
}

// ─── State ────────────────────────────────────────────────────────────────────

class ChatState {
  final List<ChatMessage> messages;
  final bool isSending;

  const ChatState({this.messages = const [], this.isSending = false});

  ChatState copyWith({List<ChatMessage>? messages, bool? isSending}) {
    return ChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatRepository _repository;
  final Ref _ref;

  ChatNotifier(this._repository, this._ref) : super(const ChatState());

  /// 봇 메시지에서 히스토리용 텍스트를 추출한다.
  /// text가 비어 있어도 추천 데이터가 있으면 요약 문자열을 반환한다.
  String? _botHistoryContent(ChatMessage m) {
    final parts = <String>[];
    if (m.text != null && m.text!.isNotEmpty) parts.add(m.text!);

    final data = m.responseData;
    if (data != null) {
      final outfitCount =
          data.recommendations?.recommendations?.whereType<RecommendationItem>().length ?? 0;
      final topCount =
          data.recommendationsTops?.items?.whereType<ClothesScoreItem>().length ?? 0;
      final bottomCount =
          data.recommendationsBottoms?.items?.whereType<ClothesScoreItem>().length ?? 0;

      if (outfitCount > 0 || topCount > 0 || bottomCount > 0) {
        final segments = <String>[];
        if (outfitCount > 0) segments.add('코디 $outfitCount개');
        if (topCount > 0) segments.add('상의 $topCount개');
        if (bottomCount > 0) segments.add('하의 $bottomCount개');
        parts.add('[추천: ${segments.join(', ')}]');
      }
    }
    return parts.isEmpty ? null : parts.join('\n');
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isSending) return;

    // 1. 이전 대화 히스토리 추출 (추천 컨텍스트 포함)
    final historyList = <ChatHistoryItem>[];
    for (final m in state.messages) {
      if (m.isLoading || m.errorMessage != null) continue;
      final content = m.isUser ? m.text : _botHistoryContent(m);
      if (content == null || content.isEmpty) continue;
      historyList.add(ChatHistoryItem(
        role: m.isUser ? 'user' : 'model',
        content: content,
      ));
    }

    // 2. 날씨 조회 (캐시 5분 유효 → GPS 재호출 방지)
    WeatherInfo? weather = _weatherCache.data;
    if (weather == null) {
      try {
        weather = await fetchWeatherFromCurrentPosition();
        _weatherCache.update(weather);
      } catch (_) {}
    }
    // UI에서 날씨 정보를 표시할 수 있도록 캐시 갱신
    if (weather != null) {
      _ref.read(cachedWeatherProvider.notifier).state = weather;
    }

    final isDefault = weather == null;

    // 3. 요청 DTO 구성 (OrDefault 플래그로 폴백 여부 전달)
    final requestDto = ChatRequestDto(
      message: trimmed,
      history: historyList,
      temp: weather?.temp ?? 15.0,
      rain: weather?.rain ?? 0.0,
      snow: weather?.snow ?? 0.0,
      windSpeed: weather?.windSpeed ?? 0.0,
      humidity: weather?.humidity ?? 0,
      tempOrDefault: isDefault ? true : null,
      rainOrDefault: isDefault ? true : null,
      snowOrDefault: isDefault ? true : null,
      windSpeedOrDefault: isDefault ? true : null,
      humidityOrDefault: isDefault ? true : null,
    );

    // 4. 유저 말풍선 + 로딩 말풍선을 즉시 노출
    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessage(isUser: true, text: trimmed, sentAt: DateTime.now()),
        const ChatMessage(isUser: false, isLoading: true),
      ],
      isSending: true,
    );

    try {
      final response = await _repository.sendMessage(
        body: requestDto,
      );

      // 2. 로딩 말풍선을 실제 응답으로 교체
      final updated = [...state.messages]
        ..removeLast()
        ..add(ChatMessage(
          isUser: false,
          text: response.data?.message,
          responseData: response.data,
          sentAt: DateTime.now(),
        ));

      state = state.copyWith(messages: updated, isSending: false);
    } catch (_) {
      // 3. 에러 시 에러 말풍선으로 교체
      final updated = [...state.messages]
        ..removeLast()
        ..add(const ChatMessage(
          isUser: false,
          errorMessage: '메시지를 보내지 못했습니다.\n잠시 후 다시 시도해주세요.',
        ));

      state = state.copyWith(messages: updated, isSending: false);
    }
  }
}

// ─── Provider (keepAlive: buyUrl 등 외부 이동 시 대화 유지) ──────────────────

final chatProvider =
    StateNotifierProvider<ChatNotifier, ChatState>(
  (ref) => ChatNotifier(ref.read(chatRepositoryProvider), ref),
);
