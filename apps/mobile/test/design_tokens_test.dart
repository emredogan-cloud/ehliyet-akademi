import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Evolution Faz E13 — tasarım sistemi disiplinini KAYNAK düzeyinde koruyan test.
///
/// NEDEN KAYNAK TARAMASI: sabit bir renk widget testinde "çalışır" görünür — yalnız YANLIŞ temada
/// yanlış görünür. E13 denetiminde premium altını dört ayrı dosyada sabit değer olarak bulundu ve
/// **koyu temanın** tonu donmuştu; açık temada yanlış altın çiziliyordu. Test bunun geri gelmesini
/// engeller.
void main() {
  final libDir = Directory('lib');

  /// Sabit renge izin verilen yerler ve GEREKÇESİ.
  /// Buraya ekleme yapmak bilinçli bir karar olmalı — gerekçesiz ekleme yapılmaz.
  const allowed = <String, String>{
    'lib/design/app_card.dart': 'Gölge rengi; ternary’nin diğer dalı temaya göre seçiliyor.',
    'lib/design/brand.dart': 'Gölge rengi; p.brightness ile dallanıyor.',
    'lib/features/coach/coach_screen.dart': 'Balon zemini; p.brightness ile dallanıyor.',
    'lib/core/theme/app_theme.dart': 'Buton ön plan rengi; p.brightness ile dallanıyor.',
    'lib/features/auth/auth_screen.dart':
        'Google markasının dört rengi — marka kılavuzu değiştirilmesini yasaklıyor, temayla değişemez.',
    'lib/features/learn/widgets/traffic_sign_view.dart':
        'Trafik levhasının MEVZUATTAKİ kırmızısı — temaya göre değişemez.',
    'lib/design/coach_marks.dart':
        'Turun karartması. Karartma bir YÜZEY değil, ışığın dışında kalan her şeydir: her iki '
        'temada da aynı derinlikte olmalı. Açık temada paletin açık zeminine bağlansaydı karartma '
        'griye döner, ışık halkası ayırt edilemezdi (E13 kuralının bilinçli istisnası).',
  };

  test('tema token’ları dışında sabit renk kullanılmıyor', () {
    final offenders = <String>[];

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      // Üretilmiş dosyalar bizim yazdığımız kod değil.
      if (entity.path.endsWith('.g.dart') || entity.path.endsWith('.freezed.dart')) continue;
      // Palet tanımının kendisi elbette sabit renk içerir.
      if (entity.path.endsWith('core/theme/tokens.dart')) continue;

      final normalized = entity.path.replaceAll(r'\', '/');
      if (allowed.containsKey(normalized)) continue;

      final source = entity.readAsStringSync();
      for (final line in source.split('\n')) {
        if (line.contains('Color(0x')) {
          offenders.add('$normalized → ${line.trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Sabit renk bulundu. Renkler `context.palette` üzerinden gelmeli; gerçekten temadan '
          'bağımsız olması gereken bir renkse bu testteki `allowed` listesine GEREKÇESİYLE ekle.\n'
          '${offenders.join('\n')}',
    );
  });

  test('izin listesindeki her dosya hâlâ var (ölü istisna birikmesin)', () {
    for (final path in allowed.keys) {
      expect(File(path).existsSync(), isTrue, reason: '$path yok — istisnayı kaldır.');
    }
  });
}
