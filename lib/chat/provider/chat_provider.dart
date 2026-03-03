import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:capstone_fe/common/const/data.dart';
import 'package:capstone_fe/common/provider/dio_provider.dart';
import 'package:capstone_fe/chat/model/chat_model.dart';
import 'package:capstone_fe/chat/repository/chat_repository.dart';

// ─── Repository Provider ──────────────────────────────────────────────────────

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(authDioProvider), baseUrl: baseUrl);
});

// ─── UI-only chat message model ───────────────────────────────────────────────

class ChatMessage {
  final bool isUser;
  final String? text;
  final ChatResponseData? responseData;
  final bool isLoading;
  final String? errorMessage;

  const ChatMessage({
    required this.isUser,
    this.text,
    this.responseData,
    this.isLoading = false,
    this.errorMessage,
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

  ChatNotifier(this._repository) : super(const ChatState());

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isSending) return;

    // 1. 유저 말풍선 + 로딩 말풍선을 즉시 노출
    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessage(isUser: true, text: trimmed),
        const ChatMessage(isUser: false, isLoading: true),
      ],
      isSending: true,
    );

    try {
      final response = await _repository.sendMessage(
        body: ChatRequestDto(message: trimmed),
      );

      // 2. 로딩 말풍선을 실제 응답으로 교체
      final updated = [...state.messages]
        ..removeLast()
        ..add(ChatMessage(
          isUser: false,
          text: response.data?.message,
          responseData: response.data,
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

// ─── Provider (autoDispose: 화면 이탈 시 대화 초기화) ─────────────────────────

final chatProvider =
    StateNotifierProvider.autoDispose<ChatNotifier, ChatState>(
  (ref) => ChatNotifier(ref.read(chatRepositoryProvider)),
);
