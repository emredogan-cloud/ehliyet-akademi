import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/coach/coach_api.dart';
import '../onboarding/study_profile.dart';

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
  const CoachChatState({
    this.messages = const [],
    this.sending = false,
    this.error,
    this.streaming = false,
  });
  final List<ChatMessage> messages;
  final bool sending;
  final String? error;

  /// Beta Faz 9 — son AI mesajı ŞU AN parça parça yazılıyor mu?
  ///
  /// Yalnız sunucu `streamed: true` dediğinde açılır. Tek parça yanıtta **kapalı kalır**:
  /// arayüz o durumda yazma göstergesi çizmez, çünkü ortada akan bir şey yoktur.
  final bool streaming;

  CoachChatState copyWith({
    List<ChatMessage>? messages,
    bool? sending,
    String? error,
    bool? streaming,
  }) => CoachChatState(
    messages: messages ?? this.messages,
    sending: sending ?? this.sending,
    error: error,
    streaming: streaming ?? this.streaming,
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

  /// Kişiselleştirme profilinden LLM bağlamı — yanıtlar kullanıcının hedefine göre uyarlanır.
  String? _profileContext() {
    final p = ref.read(studyProfileProvider);
    // Ehliyet sınıfı Profil'den de değiştirilebilir (Faz E4) → onboarding tamamlanmamış olsa
    // bile sınıf bilgisi verilir; ayrıntılı profil yalnız tamamlandıysa eklenir.
    final licence = 'Kullanıcı ${p.category.badge} sınıfı (${p.category.title}) ehliyete hazırlanıyor.';
    if (!p.completed) {
      return '$licence Yanıtı bu sınıfa uygun, kısa ve net ver.';
    }
    return '$licence Odak: ${p.focus.title}. Sınava kalan süre: ${p.timeframe.title}. '
        'Deneyim: ${p.experience.title}. Yanıtı kısa, net ve bu profile uygun ver.';
  }

  Future<void> send(String question, {String? context}) async {
    final q = question.trim();
    if (q.length < 3 || state.sending) return;
    final withUser = [...state.messages, ChatMessage(role: 'user', text: q)];
    state = state.copyWith(messages: withUser, sending: true, error: null, streaming: false);
    unawaited(_persist(withUser));
    final ctx = context ?? _profileContext();

    // Beta Faz 9 — ÖNCE akan uç denenir.
    //
    // Sözleşme: `streamed: false` gelirse yanıt tek parçadır ve arayüz onu **olduğu gibi** çizer;
    // yapay bir yazma animasyonu üretilmez. Akış hiç kurulamazsa (eski sunucu, ağ, 404) sessizce
    // tek parça uca düşülür — kullanıcı bir gerileme görmez.
    try {
      var text = '';
      var meta = const CoachMeta(grounded: false, sources: [], model: '', streamed: false);
      var started = false;

      await for (final evt in ref.read(coachApiProvider).askStream(q, context: ctx)) {
        switch (evt) {
          case CoachMeta():
            meta = evt;
          case CoachDelta():
            text += evt.text;
            final msg = ChatMessage(
              role: 'ai',
              text: text,
              grounded: meta.grounded,
              sources: meta.sources,
              model: meta.model,
            );
            state = state.copyWith(
              // İlk parçada mesaj EKLENİR, sonrakilerde YERİNE YAZILIR — her parça için yeni
              // balon eklenirse sohbet tek yanıttan onlarca mesaj üretir.
              messages: started ? [...withUser, msg] : [...state.messages, msg],
              sending: true,
              streaming: meta.streamed,
            );
            started = true;
          case CoachDone():
            break;
        }
      }

      if (!started) throw StateError('ai_stream_no_content');
      final finalMessages = state.messages;
      state = state.copyWith(sending: false, streaming: false);
      unawaited(_persist(finalMessages));
      return;
    } catch (_) {
      // Akış kurulamadı → tek parça uca düş. Yarım kalmış AI balonu varsa geri alınır ki
      // kullanıcı iki kez yanıt görmesin.
      state = state.copyWith(messages: withUser, sending: true, streaming: false);
    }

    try {
      final ans = await ref.read(coachApiProvider).ask(q, context: ctx);
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
      state = state.copyWith(messages: withAi, sending: false, streaming: false);
      unawaited(_persist(withAi));
    } catch (_) {
      state = state.copyWith(
        sending: false,
        streaming: false,
        error: 'Bağlantı hatası. İnternetini kontrol et.',
      );
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
