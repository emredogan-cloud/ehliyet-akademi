import 'dart:convert';

import 'package:ehliyet_akademi/data/coach/coach_api.dart';
import 'package:ehliyet_akademi/domain/coach/coach_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Beta Faz 9 — akan (streaming) AI.
///
/// Bu dosyanın ASIL konusu "akış çalışıyor mu" değil, **dürüstlük**: tek parça gelen bir yanıt
/// akıyormuş gibi gösterilmemeli. Yol haritası şartı birebir buydu.
void main() {
  group('SSE çözümleyici', () {
    Stream<List<int>> bytesOf(List<String> chunks) =>
        Stream.fromIterable(chunks.map(utf8.encode));

    test('olayları sırayla çözer', () async {
      final evts = await parseCoachSse(
        bytesOf([
          'data: {"type":"meta","grounded":true,"sources":["trafik"],"model":"anthropic","streamed":true}\n\n',
          'data: {"type":"delta","text":"Kırmızı "}\n\n',
          'data: {"type":"delta","text":"ışıkta durulur."}\n\n',
          'data: {"type":"done"}\n\n',
        ]),
      ).toList();

      expect(evts, hasLength(4));
      expect((evts[0] as CoachMeta).streamed, isTrue);
      expect((evts[0] as CoachMeta).sources, ['trafik']);
      expect((evts[1] as CoachDelta).text, 'Kırmızı ');
      expect(evts[3], isA<CoachDone>());
    });

    test('OLAY ORTASINDAN bölünmüş ağ parçalarını birleştirir', () async {
      // Ağ, satır sınırına saygı göstermez. Tampon tutulmazsa JSON çözümlemesi sessizce patlar
      // ve akış ortada kesilir — bu, gerçek cihazda en sık görülen akış hatasıdır.
      const full = 'data: {"type":"delta","text":"bölünmüş parça"}\n\n';
      final evts = await parseCoachSse(
        bytesOf([full.substring(0, 17), full.substring(17, 30), full.substring(30)]),
      ).toList();

      expect(evts, hasLength(1));
      expect((evts.single as CoachDelta).text, 'bölünmüş parça');
    });

    test('bozuk tek olay akışı ÖLDÜRMEZ', () async {
      final evts = await parseCoachSse(
        bytesOf([
          'data: {bozuk json\n\n',
          'data: {"type":"delta","text":"devam"}\n\n',
        ]),
      ).toList();
      expect(evts, hasLength(1));
      expect((evts.single as CoachDelta).text, 'devam');
    });
  });

  group('sohbet denetleyicisi', () {
    ProviderContainer containerWith(FakeCoachApi api) {
      final c = ProviderContainer(overrides: [coachApiProvider.overrideWithValue(api)]);
      addTearDown(c.dispose);
      return c;
    }

    test('akan yanıt PARÇA PARÇA yazılır — tek balonda birikir', () async {
      final api = FakeCoachApi(chunks: const ['Kırmızı ', 'ışıkta ', 'durulur.']);
      final c = containerWith(api);
      final ctrl = c.read(coachChatProvider.notifier);

      final metinler = <String>[];
      c.listen(coachChatProvider, (_, next) {
        final ai = next.messages.where((m) => m.role == 'ai');
        if (ai.isNotEmpty) metinler.add(ai.last.text);
      });

      await ctrl.send('Kırmızı ışık ne demek?');

      // Sahte akış OLMADIĞININ ölçüsü: ara durumlar gerçekten görülmüş olmalı.
      expect(metinler, contains('Kırmızı '));
      expect(metinler, contains('Kırmızı ışıkta '));
      expect(metinler.last, 'Kırmızı ışıkta durulur.');

      final st = c.read(coachChatProvider);
      expect(st.messages.where((m) => m.role == 'ai'), hasLength(1), reason: 'TEK balon olmalı');
      expect(st.streaming, isFalse, reason: 'bittiğinde göstergesi kapanır');
      expect(st.sending, isFalse);
      expect(api.streamCalls, 1);
      expect(api.calls, 0, reason: 'akış çalıştıysa tek parça uç çağrılmaz');
    });

    test('AKMAYAN yanıt tek seferde yazılır — sahte animasyon YOK', () async {
      final api = FakeCoachApi(); // chunks yok → streamed:false
      final c = containerWith(api);

      final metinler = <String>[];
      c.listen(coachChatProvider, (_, next) {
        final ai = next.messages.where((m) => m.role == 'ai');
        if (ai.isNotEmpty) metinler.add(ai.last.text);
      });

      await c.read(coachChatProvider.notifier).send('Kırmızı ışık ne demek?');

      // Ölçü, bildirim SAYISI değil, görülen FARKLI metinlerdir: `sending` kapanışı da bir
      // bildirim üretir ama metni değiştirmez. Sahte akış olsaydı burada birden çok farklı
      // (giderek uzayan) metin görülürdü.
      expect(metinler.toSet(), {'Kırmızı ışıkta durulur.'}, reason: 'ara metin OLMAMALI');
      expect(c.read(coachChatProvider).streaming, isFalse);
    });

    test('akış kurulamazsa TEK PARÇA uca düşülür ve kullanıcı yine yanıt alır', () async {
      final api = FakeCoachApi(streamThrows: true);
      final c = containerWith(api);

      await c.read(coachChatProvider.notifier).send('Kırmızı ışık ne demek?');

      final st = c.read(coachChatProvider);
      expect(api.streamCalls, 1);
      expect(api.calls, 1, reason: 'tek parça uca düşülmeli');
      expect(st.messages.where((m) => m.role == 'ai'), hasLength(1), reason: 'ÇİFT yanıt olmaz');
      expect(st.messages.last.text, 'Kırmızı ışıkta durulur.');
      expect(st.error, isNull);
    });

    test('akış yarım kalırsa yarım balon bırakılmaz', () async {
      // Akış meta yayar ama hiç parça vermezse: kullanıcı boş bir AI balonuyla kalmamalı.
      final api = FakeCoachApi(chunks: const []);
      final c = containerWith(api);

      await c.read(coachChatProvider.notifier).send('Kırmızı ışık ne demek?');

      final st = c.read(coachChatProvider);
      expect(st.messages.where((m) => m.role == 'ai'), hasLength(1));
      expect(st.messages.last.text, isNotEmpty, reason: 'boş balon kalmamalı');
      expect(api.calls, 1, reason: 'içerik gelmediyse tek parça uca düşülür');
    });
  });
}
