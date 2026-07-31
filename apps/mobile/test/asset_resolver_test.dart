import 'package:ehliyet_akademi/core/asset_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

/// Faz 8 — varlık çözümleyicisinin kapısı.
///
/// Korunan söz: **doğru adla üretilmiş bir görsel klasöre bırakılınca kod değişmeden kullanılır.**
void main() {
  setUp(AssetCatalog.resetForTest);

  test('sözleşmeye uyan dosya bulunur', () {
    final c = AssetCatalog.forTest(['assets/dash/abs.webp']);
    expect(c.byConvention('dash', 'abs'), 'assets/dash/abs.webp');
  });

  test('paketteki olmayan kimlik için null', () {
    final c = AssetCatalog.forTest(['assets/dash/abs.webp']);
    expect(c.byConvention('dash', 'yok'), isNull);
  });

  test('vektör rasterin ÖNÜNDE gelir', () {
    final c = AssetCatalog.forTest([
      'assets/signs/dur.webp',
      'assets/signs/dur.svg',
    ]);
    expect(c.byConvention('signs', 'dur'), 'assets/signs/dur.svg');
  });

  /// İstisna tablosu, dosya adı kimlikten farklı olduğunda hâlâ gerekli (resmî işaret kodları).
  test('sözleşme tutmazsa istisna tablosuna düşülür', () {
    final c = AssetCatalog.forTest(['assets/signs/tt-24.svg']);
    expect(
      c.resolve(
        category: 'signs',
        id: 'agirlik-siniri',
        overrides: const {'agirlik-siniri': 'assets/signs/tt-24.svg'},
      ),
      'assets/signs/tt-24.svg',
    );
  });

  /// ASIL KAZANÇ: yeni dosya, eski istisna satırını geçersiz kılar — varlık yenilemek için
  /// tablo düzenlemek gerekmez.
  test('sözleşmeye uyan YENİ dosya, eski istisna satırını GEÇER', () {
    final c = AssetCatalog.forTest([
      'assets/signs/agirlik-siniri.svg',
      'assets/signs/tt-24.svg',
    ]);
    expect(
      c.resolve(
        category: 'signs',
        id: 'agirlik-siniri',
        overrides: const {'agirlik-siniri': 'assets/signs/tt-24.svg'},
      ),
      'assets/signs/agirlik-siniri.svg',
    );
  });

  test('hiçbiri yoksa null — uydurma yol üretilmez', () {
    final c = AssetCatalog.forTest(const []);
    expect(c.resolve(category: 'mech', id: 'yok'), isNull);
  });

  test('boş katalogda istisna tablosu yine çalışır', () {
    final c = AssetCatalog.forTest(const []);
    expect(
      c.resolve(category: 'dash', id: 'abs', overrides: const {'abs': 'assets/dash/abs.webp'}),
      'assets/dash/abs.webp',
      reason: 'varlık listesi okunamasa bile mevcut davranış korunmalı',
    );
  });
}
