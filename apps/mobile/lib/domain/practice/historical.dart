import 'exam.dart';
import 'question.dart';

/// Geçmiş (MEB) sınavları — web `qip/archive.ts` + `historical.ts` uyarlaması. 18 sabit gerçek oturum
/// TARİHİ (yalnız olgu; kopyalanan soru YOK). Her tarih için, tarih tohumundan ÖZGÜN, MEB formatında
/// deneme kurulur (deterministik) → çevrimdışı.

const String historicalLabel = 'MEB formatında hazırlanmış özgün deneme sınavı';

const List<String> historicalSessionDates = [
  '2015-01-10',
  '2015-03-22',
  '2015-06-27',
  '2015-08-29',
  '2015-10-10',
  '2015-12-12',
  '2016-02-13',
  '2016-05-14',
  '2016-08-27',
  '2016-10-08',
  '2017-02-11',
  '2017-05-20',
  '2017-07-29',
  '2017-10-07',
  '2017-12-23',
  '2018-02-10',
  '2018-04-21',
  '2018-08-04',
];

const List<String> _monthLabels = [
  'Ocak',
  'Şubat',
  'Mart',
  'Nisan',
  'Mayıs',
  'Haziran',
  'Temmuz',
  'Ağustos',
  'Eylül',
  'Ekim',
  'Kasım',
  'Aralık',
];

class HistoricalSession {
  const HistoricalSession({
    required this.id,
    required this.date,
    required this.year,
    required this.month,
    required this.monthLabel,
    required this.label,
  });
  final String id;
  final String date;
  final int year;
  final int month;
  final String monthLabel;
  final String label;
}

HistoricalSession _sessionFor(String date) {
  final parts = date.split('-');
  final year = int.parse(parts[0]);
  final month = int.parse(parts[1]);
  final monthLabel = _monthLabels[month - 1];
  return HistoricalSession(
    id: date,
    date: date,
    year: year,
    month: month,
    monthLabel: monthLabel,
    label: '$monthLabel $year',
  );
}

/// Tüm oturumlar, en yeni önce.
List<HistoricalSession> historicalSessions() {
  final list = historicalSessionDates.map(_sessionFor).toList();
  list.sort((a, b) => b.date.compareTo(a.date));
  return list;
}

/// Yıla göre gruplanmış (yıl azalan).
Map<int, List<HistoricalSession>> historicalSessionsByYear() {
  final map = <int, List<HistoricalSession>>{};
  for (final s in historicalSessions()) {
    (map[s.year] ??= []).add(s);
  }
  return map;
}

HistoricalSession? historicalSessionById(String id) {
  for (final s in historicalSessions()) {
    if (s.id == id) return s;
  }
  return null;
}

/// Bir oturum tarihi için özgün, tarih-tohumlu 50 soruluk deneme.
BuiltExam historicalExam(List<Question> bank, String date) =>
    buildExam(bank, rng: seededRng(seedFromDate(date)));
