import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/duel/duel_energy.dart';

/// Ürün Evrimi v1.1 · Faz 4 — düello enerjisinin kalıcılığı.
///
/// Yalnız OKUMA/YAZMA yapar; kural [duel_energy.dart] içinde saf fonksiyonlarda durur. Bu ayrım
/// sayesinde "gün değişimi", "bekleme", "günlük sınır" testleri depolama olmadan yazılabiliyor.
///
/// SUNUCU DOĞRULAMASI YOK — ve bu, çevrimiçi sıralama gelene kadar kabul edilebilir. Bugün XP
/// yalnız kullanıcının kendi ekranında görünüyor; kimseyle karşılaştırılmıyor. Sıralama sunucuya
/// taşındığında sayaç da sunucuya taşınmalı, yoksa yerel kaydı düzenleyen herkes tepeye çıkar.
const String kDuelEnergyKey = 'ea:duel:energy:v1';

class DuelEnergyController extends Notifier<DuelEnergy> {
  DuelEnergyController(this._prefs);

  final SharedPreferences? _prefs;

  @override
  DuelEnergy build() {
    final raw = _prefs?.getString(kDuelEnergyKey);
    if (raw == null || raw.isEmpty) return DuelEnergy.empty;
    try {
      return DuelEnergy.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } catch (_) {
      // Bozuk kayıt kullanıcıyı kilitlemez; boş durumdan devam edilir.
      return DuelEnergy.empty;
    }
  }

  Future<void> _persist(DuelEnergy next) async {
    state = next;
    await _prefs?.setString(kDuelEnergyKey, jsonEncode(next.toJson()));
  }

  /// Düello başlarken hak harca.
  Future<void> spend(DateTime now) => _persist(spendForDuel(state, now));

  /// Düello bitince bekleme sayacını başlat.
  Future<void> finish(DateTime now) => _persist(markFinished(state, now));
}

/// Enerji sağlayıcısı.
///
/// `SharedPreferences` ASENKRON açılır ama ekran senkron okumak zorunda. Çözüm: örnek bir kez
/// alınıp saklanıyor; henüz gelmemişse denetleyici belleğe yazıyor ve örnek gelince kalıcılaşıyor.
/// Enerji kaydı yüzünden ekranın yüklenme durumu göstermesi gereksiz bir karmaşa olurdu.
final duelEnergyProvider = NotifierProvider<DuelEnergyController, DuelEnergy>(
  () => DuelEnergyController(_prefs),
);

SharedPreferences? _prefs;

/// Açılışta bir kez çağrılır (`main`).
Future<void> initDuelEnergyStorage() async {
  _prefs ??= await SharedPreferences.getInstance();
}

/// Yalnız test için.
void resetDuelEnergyStorageForTest() => _prefs = null;
