import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Faz 4 + 5 — ödeme ekranından ÇIKIŞ hatırlatması ve erişim KAYBI sonrası geri kazanım.
///
/// İkisi de aynı ilkeye tabidir: **bir kez, gecikmeli, kapatılabilir.** Uygulama kullanıcıyı
/// takip edip her fırsatta satış yapmaz; bir kez hatırlatır ve susar.

// ─────────────────────────────────────────────────────────────────────────────────────────────
// Faz 4 — ödeme ekranını satın almadan terk eden kullanıcı
// ─────────────────────────────────────────────────────────────────────────────────────────────

/// Terk ile hatırlatma arasındaki EN AZ süre.
///
/// Neden 24 saat: kullanıcı ödeme ekranını yeni kapattıysa kararını zaten o an vermiştir; beş
/// dakika sonra aynı şeyi sormak ısrardır. Ayrıca mevcut bağlamsal teşvikin soğuma süresi de
/// 24 saat (`premium_prompt.dart`); aynı değeri kullanmak iki sistemin **aynı gün içinde üst üste
/// binmesini** yapısal olarak engeller.
const int kPaywallReminderDelayMs = 24 * 60 * 60 * 1000;

class PaywallReminderState {
  const PaywallReminderState({this.leftAtMs = 0, this.reminded = false});

  /// Ödeme ekranının satın alma OLMADAN kapatıldığı an (0 = hiç olmadı).
  final int leftAtMs;

  /// Hatırlatma gösterildi mi? **Ömür boyu bir kez.**
  final bool reminded;

  Map<String, dynamic> toJson() => {'leftMs': leftAtMs, 'reminded': reminded};

  static PaywallReminderState fromJson(Map<String, dynamic> j) => PaywallReminderState(
    leftAtMs: (j['leftMs'] as num?)?.toInt() ?? 0,
    reminded: j['reminded'] == true,
  );
}

/// Saf karar: şimdi tek hatırlatma gösterilmeli mi?
bool shouldRemindAfterPaywall({
  required PaywallReminderState state,
  required bool premium,
  required int nowMs,
}) {
  if (premium) return false; // satın aldıysa hatırlatılacak bir şey yok
  if (state.reminded) return false; // TEK hatırlatma — ikincisi taciz olur
  if (state.leftAtMs <= 0) return false; // ödeme ekranı hiç terk edilmedi
  // "Hemen değil": terk anından itibaren en az bekleme süresi geçmeli.
  return nowMs - state.leftAtMs >= kPaywallReminderDelayMs;
}

// ─────────────────────────────────────────────────────────────────────────────────────────────
// Faz 5 — erişim kaybı sonrası geri kazanım
// ─────────────────────────────────────────────────────────────────────────────────────────────

class WinBackState {
  const WinBackState({this.everOwned = false, this.lostAtMs = 0, this.offered = false});

  /// Bu cihazda hiç premium erişim görüldü mü? Görülmediyse "geri kazanılacak" bir şey yoktur.
  final bool everOwned;

  /// Erişimin kaybedildiği an (süre doldu / iade / iptal sonrası dönem bitti).
  final int lostAtMs;

  /// Geri kazanım teklifi sunuldu mu? **Ömür boyu bir kez.**
  final bool offered;

  Map<String, dynamic> toJson() => {
    'everOwned': everOwned,
    'lostMs': lostAtMs,
    'offered': offered,
  };

  static WinBackState fromJson(Map<String, dynamic> j) => WinBackState(
    everOwned: j['everOwned'] == true,
    lostAtMs: (j['lostMs'] as num?)?.toInt() ?? 0,
    offered: j['offered'] == true,
  );
}

/// Erişim kaybından sonra teklif için beklenen en az süre.
///
/// Sıfır DEĞİL: sahiplik durumu açılışta sunucudan tazeleniyor ve geçici bir ağ/senkron
/// dalgalanması "kaybettin" gibi görünebilir. Bir saat, gerçek kaybı geçici gürültüden ayırır.
const int kWinBackDelayMs = 60 * 60 * 1000;

/// Saf karar: geri kazanım teklifi sunulmalı mı?
bool shouldOfferWinBack({
  required WinBackState state,
  required bool premium,
  required int nowMs,
}) {
  if (premium) return false; // erişim sürüyor
  if (!state.everOwned) return false; // hiç sahip olmadı → geri kazanım değil, ilk satış
  if (state.offered) return false; // bir kez
  if (state.lostAtMs <= 0) return false;
  return nowMs - state.lostAtMs >= kWinBackDelayMs;
}

// ─────────────────────────────────────────────────────────────────────────────────────────────
// Kalıcılık
// ─────────────────────────────────────────────────────────────────────────────────────────────

const _kPaywallReminder = 'ea:paywallReminder:v1';
const _kWinBack = 'ea:winBack:v1';

class PaywallReminderController extends Notifier<PaywallReminderState> {
  @override
  PaywallReminderState build() {
    Future.microtask(_load);
    return const PaywallReminderState();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kPaywallReminder);
      if (raw != null) {
        state = PaywallReminderState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (_) {}
  }

  /// Ödeme ekranı satın alma olmadan kapatıldı.
  ///
  /// İLK terk anı korunur: kullanıcı ekranı beş kez açıp kapatırsa bekleme süresi her seferinde
  /// baştan başlamamalı, yoksa hatırlatma sürekli ötelenir.
  Future<void> recordLeftWithoutPurchase(int nowMs) async {
    if (state.reminded || state.leftAtMs > 0) return;
    state = PaywallReminderState(leftAtMs: nowMs, reminded: false);
    await _persist();
  }

  Future<void> recordReminded() async {
    state = PaywallReminderState(leftAtMs: state.leftAtMs, reminded: true);
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPaywallReminder, jsonEncode(state.toJson()));
    } catch (_) {}
  }
}

class WinBackController extends Notifier<WinBackState> {
  @override
  WinBackState build() {
    Future.microtask(_load);
    return const WinBackState();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kWinBack);
      if (raw != null) {
        state = WinBackState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (_) {}
  }

  /// Sahiplik durumunu bildir. Geçişleri BU metot yakalar:
  /// · yok → var  : `everOwned` işaretlenir, kayıp anı sıfırlanır (yeniden satın aldı)
  /// · var → yok  : kayıp anı damgalanır
  Future<void> observePremium({required bool premium, required int nowMs}) async {
    if (premium) {
      if (state.everOwned && state.lostAtMs == 0) return; // değişiklik yok
      state = WinBackState(everOwned: true, lostAtMs: 0, offered: false);
      await _persist();
      return;
    }
    // Premium değil. Daha önce sahip olunmadıysa kaydedilecek bir kayıp yok.
    if (!state.everOwned) return;
    if (state.lostAtMs > 0) return; // kayıp zaten damgalı
    state = WinBackState(everOwned: true, lostAtMs: nowMs, offered: state.offered);
    await _persist();
  }

  Future<void> recordOffered() async {
    state = WinBackState(everOwned: state.everOwned, lostAtMs: state.lostAtMs, offered: true);
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kWinBack, jsonEncode(state.toJson()));
    } catch (_) {}
  }
}

final paywallReminderProvider =
    NotifierProvider<PaywallReminderController, PaywallReminderState>(
      PaywallReminderController.new,
    );

final winBackProvider = NotifierProvider<WinBackController, WinBackState>(WinBackController.new);
