// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SavedBriefsTable extends SavedBriefs
    with TableInfo<$SavedBriefsTable, SavedBrief> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedBriefsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _processedAtMeta = const VerificationMeta(
    'processedAt',
  );
  @override
  late final GeneratedColumn<DateTime> processedAt = GeneratedColumn<DateTime>(
    'processed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    payloadJson,
    processedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_briefs';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedBrief> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('processed_at')) {
      context.handle(
        _processedAtMeta,
        processedAt.isAcceptableOrUnknown(
          data['processed_at']!,
          _processedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_processedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavedBrief map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedBrief(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      processedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}processed_at'],
      )!,
    );
  }

  @override
  $SavedBriefsTable createAlias(String alias) {
    return $SavedBriefsTable(attachedDatabase, alias);
  }
}

class SavedBrief extends DataClass implements Insertable<SavedBrief> {
  final String id;
  final String accountId;
  final String payloadJson;
  final DateTime processedAt;
  const SavedBrief({
    required this.id,
    required this.accountId,
    required this.payloadJson,
    required this.processedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    map['payload_json'] = Variable<String>(payloadJson);
    map['processed_at'] = Variable<DateTime>(processedAt);
    return map;
  }

  SavedBriefsCompanion toCompanion(bool nullToAbsent) {
    return SavedBriefsCompanion(
      id: Value(id),
      accountId: Value(accountId),
      payloadJson: Value(payloadJson),
      processedAt: Value(processedAt),
    );
  }

  factory SavedBrief.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedBrief(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      processedAt: serializer.fromJson<DateTime>(json['processedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'processedAt': serializer.toJson<DateTime>(processedAt),
    };
  }

  SavedBrief copyWith({
    String? id,
    String? accountId,
    String? payloadJson,
    DateTime? processedAt,
  }) => SavedBrief(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    payloadJson: payloadJson ?? this.payloadJson,
    processedAt: processedAt ?? this.processedAt,
  );
  SavedBrief copyWithCompanion(SavedBriefsCompanion data) {
    return SavedBrief(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      processedAt: data.processedAt.present
          ? data.processedAt.value
          : this.processedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedBrief(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('processedAt: $processedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, accountId, payloadJson, processedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedBrief &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.payloadJson == this.payloadJson &&
          other.processedAt == this.processedAt);
}

class SavedBriefsCompanion extends UpdateCompanion<SavedBrief> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<String> payloadJson;
  final Value<DateTime> processedAt;
  final Value<int> rowid;
  const SavedBriefsCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.processedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavedBriefsCompanion.insert({
    required String id,
    required String accountId,
    required String payloadJson,
    required DateTime processedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accountId = Value(accountId),
       payloadJson = Value(payloadJson),
       processedAt = Value(processedAt);
  static Insertable<SavedBrief> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<String>? payloadJson,
    Expression<DateTime>? processedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (processedAt != null) 'processed_at': processedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavedBriefsCompanion copyWith({
    Value<String>? id,
    Value<String>? accountId,
    Value<String>? payloadJson,
    Value<DateTime>? processedAt,
    Value<int>? rowid,
  }) {
    return SavedBriefsCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      payloadJson: payloadJson ?? this.payloadJson,
      processedAt: processedAt ?? this.processedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (processedAt.present) {
      map['processed_at'] = Variable<DateTime>(processedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedBriefsCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('processedAt: $processedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SavedBriefsTable savedBriefs = $SavedBriefsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [savedBriefs];
}

typedef $$SavedBriefsTableCreateCompanionBuilder =
    SavedBriefsCompanion Function({
      required String id,
      required String accountId,
      required String payloadJson,
      required DateTime processedAt,
      Value<int> rowid,
    });
typedef $$SavedBriefsTableUpdateCompanionBuilder =
    SavedBriefsCompanion Function({
      Value<String> id,
      Value<String> accountId,
      Value<String> payloadJson,
      Value<DateTime> processedAt,
      Value<int> rowid,
    });

class $$SavedBriefsTableFilterComposer
    extends Composer<_$AppDatabase, $SavedBriefsTable> {
  $$SavedBriefsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get processedAt => $composableBuilder(
    column: $table.processedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SavedBriefsTableOrderingComposer
    extends Composer<_$AppDatabase, $SavedBriefsTable> {
  $$SavedBriefsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get processedAt => $composableBuilder(
    column: $table.processedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SavedBriefsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavedBriefsTable> {
  $$SavedBriefsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get processedAt => $composableBuilder(
    column: $table.processedAt,
    builder: (column) => column,
  );
}

class $$SavedBriefsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavedBriefsTable,
          SavedBrief,
          $$SavedBriefsTableFilterComposer,
          $$SavedBriefsTableOrderingComposer,
          $$SavedBriefsTableAnnotationComposer,
          $$SavedBriefsTableCreateCompanionBuilder,
          $$SavedBriefsTableUpdateCompanionBuilder,
          (
            SavedBrief,
            BaseReferences<_$AppDatabase, $SavedBriefsTable, SavedBrief>,
          ),
          SavedBrief,
          PrefetchHooks Function()
        > {
  $$SavedBriefsTableTableManager(_$AppDatabase db, $SavedBriefsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedBriefsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedBriefsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavedBriefsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<DateTime> processedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavedBriefsCompanion(
                id: id,
                accountId: accountId,
                payloadJson: payloadJson,
                processedAt: processedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String accountId,
                required String payloadJson,
                required DateTime processedAt,
                Value<int> rowid = const Value.absent(),
              }) => SavedBriefsCompanion.insert(
                id: id,
                accountId: accountId,
                payloadJson: payloadJson,
                processedAt: processedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SavedBriefsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavedBriefsTable,
      SavedBrief,
      $$SavedBriefsTableFilterComposer,
      $$SavedBriefsTableOrderingComposer,
      $$SavedBriefsTableAnnotationComposer,
      $$SavedBriefsTableCreateCompanionBuilder,
      $$SavedBriefsTableUpdateCompanionBuilder,
      (
        SavedBrief,
        BaseReferences<_$AppDatabase, $SavedBriefsTable, SavedBrief>,
      ),
      SavedBrief,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SavedBriefsTableTableManager get savedBriefs =>
      $$SavedBriefsTableTableManager(_db, _db.savedBriefs);
}
