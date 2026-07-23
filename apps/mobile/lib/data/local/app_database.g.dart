// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ContentDocumentsTable extends ContentDocuments
    with TableInfo<$ContentDocumentsTable, ContentDocument> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContentDocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<String> version = GeneratedColumn<String>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, version, body, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'content_documents';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContentDocument> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  ContentDocument map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContentDocument(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ContentDocumentsTable createAlias(String alias) {
    return $ContentDocumentsTable(attachedDatabase, alias);
  }
}

class ContentDocument extends DataClass implements Insertable<ContentDocument> {
  final String key;
  final String version;
  final String body;
  final DateTime updatedAt;
  const ContentDocument({
    required this.key,
    required this.version,
    required this.body,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['version'] = Variable<String>(version);
    map['body'] = Variable<String>(body);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ContentDocumentsCompanion toCompanion(bool nullToAbsent) {
    return ContentDocumentsCompanion(
      key: Value(key),
      version: Value(version),
      body: Value(body),
      updatedAt: Value(updatedAt),
    );
  }

  factory ContentDocument.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContentDocument(
      key: serializer.fromJson<String>(json['key']),
      version: serializer.fromJson<String>(json['version']),
      body: serializer.fromJson<String>(json['body']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'version': serializer.toJson<String>(version),
      'body': serializer.toJson<String>(body),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ContentDocument copyWith({
    String? key,
    String? version,
    String? body,
    DateTime? updatedAt,
  }) => ContentDocument(
    key: key ?? this.key,
    version: version ?? this.version,
    body: body ?? this.body,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ContentDocument copyWithCompanion(ContentDocumentsCompanion data) {
    return ContentDocument(
      key: data.key.present ? data.key.value : this.key,
      version: data.version.present ? data.version.value : this.version,
      body: data.body.present ? data.body.value : this.body,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContentDocument(')
          ..write('key: $key, ')
          ..write('version: $version, ')
          ..write('body: $body, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, version, body, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContentDocument &&
          other.key == this.key &&
          other.version == this.version &&
          other.body == this.body &&
          other.updatedAt == this.updatedAt);
}

class ContentDocumentsCompanion extends UpdateCompanion<ContentDocument> {
  final Value<String> key;
  final Value<String> version;
  final Value<String> body;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ContentDocumentsCompanion({
    this.key = const Value.absent(),
    this.version = const Value.absent(),
    this.body = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContentDocumentsCompanion.insert({
    required String key,
    required String version,
    required String body,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       version = Value(version),
       body = Value(body),
       updatedAt = Value(updatedAt);
  static Insertable<ContentDocument> custom({
    Expression<String>? key,
    Expression<String>? version,
    Expression<String>? body,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (version != null) 'version': version,
      if (body != null) 'body': body,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContentDocumentsCompanion copyWith({
    Value<String>? key,
    Value<String>? version,
    Value<String>? body,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ContentDocumentsCompanion(
      key: key ?? this.key,
      version: version ?? this.version,
      body: body ?? this.body,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (version.present) {
      map['version'] = Variable<String>(version.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContentDocumentsCompanion(')
          ..write('key: $key, ')
          ..write('version: $version, ')
          ..write('body: $body, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ContentDocumentsTable contentDocuments = $ContentDocumentsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [contentDocuments];
}

typedef $$ContentDocumentsTableCreateCompanionBuilder =
    ContentDocumentsCompanion Function({
      required String key,
      required String version,
      required String body,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ContentDocumentsTableUpdateCompanionBuilder =
    ContentDocumentsCompanion Function({
      Value<String> key,
      Value<String> version,
      Value<String> body,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ContentDocumentsTableFilterComposer
    extends Composer<_$AppDatabase, $ContentDocumentsTable> {
  $$ContentDocumentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ContentDocumentsTableOrderingComposer
    extends Composer<_$AppDatabase, $ContentDocumentsTable> {
  $$ContentDocumentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContentDocumentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContentDocumentsTable> {
  $$ContentDocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ContentDocumentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContentDocumentsTable,
          ContentDocument,
          $$ContentDocumentsTableFilterComposer,
          $$ContentDocumentsTableOrderingComposer,
          $$ContentDocumentsTableAnnotationComposer,
          $$ContentDocumentsTableCreateCompanionBuilder,
          $$ContentDocumentsTableUpdateCompanionBuilder,
          (
            ContentDocument,
            BaseReferences<
              _$AppDatabase,
              $ContentDocumentsTable,
              ContentDocument
            >,
          ),
          ContentDocument,
          PrefetchHooks Function()
        > {
  $$ContentDocumentsTableTableManager(
    _$AppDatabase db,
    $ContentDocumentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContentDocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContentDocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContentDocumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> version = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContentDocumentsCompanion(
                key: key,
                version: version,
                body: body,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String version,
                required String body,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ContentDocumentsCompanion.insert(
                key: key,
                version: version,
                body: body,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ContentDocumentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ContentDocumentsTable,
      ContentDocument,
      $$ContentDocumentsTableFilterComposer,
      $$ContentDocumentsTableOrderingComposer,
      $$ContentDocumentsTableAnnotationComposer,
      $$ContentDocumentsTableCreateCompanionBuilder,
      $$ContentDocumentsTableUpdateCompanionBuilder,
      (
        ContentDocument,
        BaseReferences<_$AppDatabase, $ContentDocumentsTable, ContentDocument>,
      ),
      ContentDocument,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ContentDocumentsTableTableManager get contentDocuments =>
      $$ContentDocumentsTableTableManager(_db, _db.contentDocuments);
}
