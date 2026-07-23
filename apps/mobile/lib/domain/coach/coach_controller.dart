import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/coach/coach_api.dart';

/// Sohbet mesajı (persist: `ea:chat:v1`, son 40 ile web ile aynı).
class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.text,
    this.grounded = false,
    this.sources = const [],
    this.model,
  });
  final String role; // 'user' | 'ai'
  final String text;
  final bool grounded;
  final List<String> sources;
  final String? model;

  Map<String, dynamic> toJson() => {
    'role': role,
    'text': text,
    'grounded': grounded,
    'sources': sources,
    if (model != null) 'model': model,
  };
  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    role: j['role'] as String? ?? 'ai',
    text: j['text'] as String? ?? '',
    grounded: j['grounded'] as bool? ?? false,
    sources: ((j['sources'] as List?) ?? const []).map((e) => e.toString()).toList(),
    model: j['model'] as String?,
  );
}

class CoachChatState {
  const CoachChatState({this.messages = const [], this.sending = false, this.error});
  final List<ChatMessage> messages;
  final bool sending;
  final String? error;

  CoachChatState copyWith({List<ChatMessage>? messages, bool? sending, String? error}) =>
      CoachChatState(
        messages: messages ?? this.messages,
        sending: sending ?? this.sending,
        error: error,
      );
}

const _kChat = 'ea:chat:v1';
const _chatCap = 40;

/// AI Koç sohbeti — mesajları yerelde saklar; `/api/ai/ask`'e grounded soru sorar.
class CoachChatController extends Notifier<CoachChatState> {
  @override
  CoachChatState build() {
    Future.microtask(_load);
    return const CoachChatState();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kChat);
      if (raw == null) return;
      final list = (jsonDecode(raw) as List)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(messages: list);
    } catch (_) {}
  }

  Future<void> _persist(List<ChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final capped = messages.length > _chatCap
          ? messages.sublist(messages.length - _chatCap)
          : messages;
      await prefs.setString(_kChat, jsonEncode(capped.map((m) => m.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> send(String question, {String? context}) async {
    final q = question.trim();
    if (q.length < 3 || state.sending) return;
    final withUser = [...state.messages, ChatMessage(role: 'user', text: q)];
    state = state.copyWith(messages: withUser, sending: true, error: null);
    unawaited(_persist(withUser));
    try {
      final ans = await ref.read(coachApiProvider).ask(q, context: context);
      final withAi = [
        ...withUser,
        ChatMessage(
          role: 'ai',
          text: ans.answer,
          grounded: ans.grounded,
          sources: ans.sources,
          model: ans.model,
        ),
      ];
      state = state.copyWith(messages: withAi, sending: false);
      unawaited(_persist(withAi));
    } catch (_) {
      state = state.copyWith(sending: false, error: 'Bağlantı hatası. İnternetini kontrol et.');
    }
  }

  Future<void> clear() async {
    state = const CoachChatState();
    await _persist(const []);
  }
}

final coachChatProvider = NotifierProvider<CoachChatController, CoachChatState>(
  CoachChatController.new,
);
