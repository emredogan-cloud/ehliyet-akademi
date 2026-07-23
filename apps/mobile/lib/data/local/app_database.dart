import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Anahtar-değer içerik belgesi deposu (Mobile Phase 3). Tüm içerik anlık görüntüsü tek satırda
/// (`key='content-snapshot'`) sürümüyle saklanır → atomik yaz/oku, çevrimdışı-öncelik.
///
/// drift (SQLite) mimari kararı gereği yerel DB'dir (rule #10). Phase 4'te SRS/deneme/oturum
/// için ilişkisel tablolar bu veritabanına eklenecek.
class ContentDocuments extends Table {
  TextColumn get key => text()();
  TextColumn get version => text()();
  TextColumn get body => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [ContentDocuments])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'ehliyet_akademi'));

  @override
  int get schemaVersion => 1;

  Future<ContentDocument?> getDocument(String key) =>
      (select(contentDocuments)..where((t) => t.key.equals(key))).getSingleOrNull();

  Future<void> putDocument({
    required String key,
    required String version,
    required String body,
  }) => into(contentDocuments).insertOnConflictUpdate(
    ContentDocumentsCompanion.insert(
      key: key,
      version: version,
      body: body,
      updatedAt: DateTime.now(),
    ),
  );
}
