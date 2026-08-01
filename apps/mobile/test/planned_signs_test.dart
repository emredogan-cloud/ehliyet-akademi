import 'package:ehliyet_akademi/core/asset_resolver.dart';
import 'package:ehliyet_akademi/core/official_signs.dart';
import 'package:ehliyet_akademi/core/planned_signs.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ürün Evrimi v1.1 · Faz 3 — ayrılmış levha dosya adlarının sözleşmesi.
///
/// İSTENEN: "Uygulama dosya adlarını şimdiden referans etsin; görseli koyduğumda kendiliğinden
/// görünsün." Bu test o sözün iki yarısını da doğrular:
/// 1. Dosya YOKKEN hiçbir şey bozulmaz (prosedürel çizim sürer).
/// 2. Dosya konduğu anda kod değişmeden kullanılır.
void main() {
  setUp(AssetCatalog.resetForTest);
  tearDown(AssetCatalog.resetForTest);

  test('ayrılmış 18 ad; hiçbiri üretilmiş levhalarla çakışmaz', () {
    expect(kPlannedSignAsset, hasLength(18));
    for (final id in kPlannedSignAsset.keys) {
      expect(
        kOfficialSignAsset.containsKey(id),
        isFalse,
        reason: '$id zaten üretilmiş levhalarda var — ikinci kez ayrılmamalı',
      );
    }
  });

  test('dosya adları benzersiz', () {
    final paths = kPlannedSignAsset.values.toList();
    expect(paths.toSet(), hasLength(paths.length));
    for (final p in paths) {
      expect(kOfficialSignAsset.values.contains(p), isFalse, reason: '$p zaten kullanılıyor');
    }
  });

  /// "Do NOT generate duplicate prompts" kuralının kod tarafındaki karşılığı: rakam taşıdığı için
  /// görsel ÜRETİLMEYECEK işaretler, üretilecekler listesine giremez.
  test('prosedürel kalacak 17 işaret, üretim listesine GİRMEZ', () {
    expect(kProceduralBySign, hasLength(17));
    for (final id in kProceduralBySign) {
      expect(
        kPlannedSignAsset.containsKey(id),
        isFalse,
        reason: '$id sayı taşıyan bir levha — prosedürel çizim doğru çözüm, görsel üretilmemeli',
      );
    }
  });

  group('signAssetFor', () {
    test('üretilmiş levha her zaman kazanır', () {
      expect(signAssetFor('yol-ver'), 'assets/signs/tt-1.svg');
    });

    test('DOSYA YOKKEN ayrılmış ad kullanılmaz — prosedürel çizime düşülür', () {
      // Katalog boş: dosya pakete girmemiş.
      expect(
        signAssetFor('lokanta', catalog: AssetCatalog.forTest(const [])),
        isNull,
        reason: 'olmayan dosyaya işaret etmek kırık görsel demektir',
      );
      // Katalog hiç yüklenmemişse de aynı davranış.
      expect(signAssetFor('lokanta'), isNull);
    });

    test('DOSYA KONDUĞUNDA kod değişmeden kullanılır', () {
      final catalog = AssetCatalog.forTest(const ['assets/signs/lokanta.svg']);
      expect(signAssetFor('lokanta', catalog: catalog), 'assets/signs/lokanta.svg');
    });

    test('tanınmayan işaret null döner', () {
      expect(signAssetFor('boyle-bir-isaret-yok'), isNull);
    });
  });
}
