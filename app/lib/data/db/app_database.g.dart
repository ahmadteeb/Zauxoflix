// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SourcesTable extends Sources with TableInfo<$SourcesTable, Source> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SourceType, String> sourceType =
      GeneratedColumn<String>(
        'source_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('xtream'),
      ).withConverter<SourceType>($SourcesTable.$convertersourceType);
  static const VerificationMeta _serverUrlMeta = const VerificationMeta(
    'serverUrl',
  );
  @override
  late final GeneratedColumn<String> serverUrl = GeneratedColumn<String>(
    'server_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _passwordMeta = const VerificationMeta(
    'password',
  );
  @override
  late final GeneratedColumn<String> password = GeneratedColumn<String>(
    'password',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _epgUrlMeta = const VerificationMeta('epgUrl');
  @override
  late final GeneratedColumn<String> epgUrl = GeneratedColumn<String>(
    'epg_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncAtMeta = const VerificationMeta(
    'lastSyncAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAt = GeneratedColumn<DateTime>(
    'last_sync_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    sourceType,
    serverUrl,
    username,
    password,
    epgUrl,
    lastSyncAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sources';
  @override
  VerificationContext validateIntegrity(
    Insertable<Source> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('server_url')) {
      context.handle(
        _serverUrlMeta,
        serverUrl.isAcceptableOrUnknown(data['server_url']!, _serverUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_serverUrlMeta);
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('password')) {
      context.handle(
        _passwordMeta,
        password.isAcceptableOrUnknown(data['password']!, _passwordMeta),
      );
    } else if (isInserting) {
      context.missing(_passwordMeta);
    }
    if (data.containsKey('epg_url')) {
      context.handle(
        _epgUrlMeta,
        epgUrl.isAcceptableOrUnknown(data['epg_url']!, _epgUrlMeta),
      );
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
        _lastSyncAtMeta,
        lastSyncAt.isAcceptableOrUnknown(
          data['last_sync_at']!,
          _lastSyncAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Source map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Source(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sourceType: $SourcesTable.$convertersourceType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source_type'],
        )!,
      ),
      serverUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_url'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      password: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password'],
      )!,
      epgUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}epg_url'],
      ),
      lastSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_at'],
      ),
    );
  }

  @override
  $SourcesTable createAlias(String alias) {
    return $SourcesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SourceType, String, String> $convertersourceType =
      const EnumNameConverter<SourceType>(SourceType.values);
}

class Source extends DataClass implements Insertable<Source> {
  final int id;
  final String name;
  final SourceType sourceType;
  final String serverUrl;
  final String username;
  final String password;

  /// Optional XMLTV URL. Xtream sources fall back to their xmltv.php feed.
  final String? epgUrl;
  final DateTime? lastSyncAt;
  const Source({
    required this.id,
    required this.name,
    required this.sourceType,
    required this.serverUrl,
    required this.username,
    required this.password,
    this.epgUrl,
    this.lastSyncAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    {
      map['source_type'] = Variable<String>(
        $SourcesTable.$convertersourceType.toSql(sourceType),
      );
    }
    map['server_url'] = Variable<String>(serverUrl);
    map['username'] = Variable<String>(username);
    map['password'] = Variable<String>(password);
    if (!nullToAbsent || epgUrl != null) {
      map['epg_url'] = Variable<String>(epgUrl);
    }
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt);
    }
    return map;
  }

  SourcesCompanion toCompanion(bool nullToAbsent) {
    return SourcesCompanion(
      id: Value(id),
      name: Value(name),
      sourceType: Value(sourceType),
      serverUrl: Value(serverUrl),
      username: Value(username),
      password: Value(password),
      epgUrl: epgUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(epgUrl),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
    );
  }

  factory Source.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Source(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sourceType: $SourcesTable.$convertersourceType.fromJson(
        serializer.fromJson<String>(json['sourceType']),
      ),
      serverUrl: serializer.fromJson<String>(json['serverUrl']),
      username: serializer.fromJson<String>(json['username']),
      password: serializer.fromJson<String>(json['password']),
      epgUrl: serializer.fromJson<String?>(json['epgUrl']),
      lastSyncAt: serializer.fromJson<DateTime?>(json['lastSyncAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'sourceType': serializer.toJson<String>(
        $SourcesTable.$convertersourceType.toJson(sourceType),
      ),
      'serverUrl': serializer.toJson<String>(serverUrl),
      'username': serializer.toJson<String>(username),
      'password': serializer.toJson<String>(password),
      'epgUrl': serializer.toJson<String?>(epgUrl),
      'lastSyncAt': serializer.toJson<DateTime?>(lastSyncAt),
    };
  }

  Source copyWith({
    int? id,
    String? name,
    SourceType? sourceType,
    String? serverUrl,
    String? username,
    String? password,
    Value<String?> epgUrl = const Value.absent(),
    Value<DateTime?> lastSyncAt = const Value.absent(),
  }) => Source(
    id: id ?? this.id,
    name: name ?? this.name,
    sourceType: sourceType ?? this.sourceType,
    serverUrl: serverUrl ?? this.serverUrl,
    username: username ?? this.username,
    password: password ?? this.password,
    epgUrl: epgUrl.present ? epgUrl.value : this.epgUrl,
    lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
  );
  Source copyWithCompanion(SourcesCompanion data) {
    return Source(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      serverUrl: data.serverUrl.present ? data.serverUrl.value : this.serverUrl,
      username: data.username.present ? data.username.value : this.username,
      password: data.password.present ? data.password.value : this.password,
      epgUrl: data.epgUrl.present ? data.epgUrl.value : this.epgUrl,
      lastSyncAt: data.lastSyncAt.present
          ? data.lastSyncAt.value
          : this.lastSyncAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Source(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sourceType: $sourceType, ')
          ..write('serverUrl: $serverUrl, ')
          ..write('username: $username, ')
          ..write('password: $password, ')
          ..write('epgUrl: $epgUrl, ')
          ..write('lastSyncAt: $lastSyncAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    sourceType,
    serverUrl,
    username,
    password,
    epgUrl,
    lastSyncAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Source &&
          other.id == this.id &&
          other.name == this.name &&
          other.sourceType == this.sourceType &&
          other.serverUrl == this.serverUrl &&
          other.username == this.username &&
          other.password == this.password &&
          other.epgUrl == this.epgUrl &&
          other.lastSyncAt == this.lastSyncAt);
}

class SourcesCompanion extends UpdateCompanion<Source> {
  final Value<int> id;
  final Value<String> name;
  final Value<SourceType> sourceType;
  final Value<String> serverUrl;
  final Value<String> username;
  final Value<String> password;
  final Value<String?> epgUrl;
  final Value<DateTime?> lastSyncAt;
  const SourcesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.serverUrl = const Value.absent(),
    this.username = const Value.absent(),
    this.password = const Value.absent(),
    this.epgUrl = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
  });
  SourcesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.sourceType = const Value.absent(),
    required String serverUrl,
    required String username,
    required String password,
    this.epgUrl = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
  }) : name = Value(name),
       serverUrl = Value(serverUrl),
       username = Value(username),
       password = Value(password);
  static Insertable<Source> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? sourceType,
    Expression<String>? serverUrl,
    Expression<String>? username,
    Expression<String>? password,
    Expression<String>? epgUrl,
    Expression<DateTime>? lastSyncAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sourceType != null) 'source_type': sourceType,
      if (serverUrl != null) 'server_url': serverUrl,
      if (username != null) 'username': username,
      if (password != null) 'password': password,
      if (epgUrl != null) 'epg_url': epgUrl,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
    });
  }

  SourcesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<SourceType>? sourceType,
    Value<String>? serverUrl,
    Value<String>? username,
    Value<String>? password,
    Value<String?>? epgUrl,
    Value<DateTime?>? lastSyncAt,
  }) {
    return SourcesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sourceType: sourceType ?? this.sourceType,
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      epgUrl: epgUrl ?? this.epgUrl,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(
        $SourcesTable.$convertersourceType.toSql(sourceType.value),
      );
    }
    if (serverUrl.present) {
      map['server_url'] = Variable<String>(serverUrl.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (password.present) {
      map['password'] = Variable<String>(password.value);
    }
    if (epgUrl.present) {
      map['epg_url'] = Variable<String>(epgUrl.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SourcesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sourceType: $sourceType, ')
          ..write('serverUrl: $serverUrl, ')
          ..write('username: $username, ')
          ..write('password: $password, ')
          ..write('epgUrl: $epgUrl, ')
          ..write('lastSyncAt: $lastSyncAt')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<int> sourceId = GeneratedColumn<int>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sources (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<CatalogKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CatalogKind>($CategoriesTable.$converterkind);
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [sourceId, kind, categoryId, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Category> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceId, kind, categoryId};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_id'],
      )!,
      kind: $CategoriesTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CatalogKind, String, String> $converterkind =
      const EnumNameConverter<CatalogKind>(CatalogKind.values);
}

class Category extends DataClass implements Insertable<Category> {
  final int sourceId;
  final CatalogKind kind;
  final String categoryId;
  final String name;
  const Category({
    required this.sourceId,
    required this.kind,
    required this.categoryId,
    required this.name,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_id'] = Variable<int>(sourceId);
    {
      map['kind'] = Variable<String>(
        $CategoriesTable.$converterkind.toSql(kind),
      );
    }
    map['category_id'] = Variable<String>(categoryId);
    map['name'] = Variable<String>(name);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      sourceId: Value(sourceId),
      kind: Value(kind),
      categoryId: Value(categoryId),
      name: Value(name),
    );
  }

  factory Category.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      sourceId: serializer.fromJson<int>(json['sourceId']),
      kind: $CategoriesTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sourceId': serializer.toJson<int>(sourceId),
      'kind': serializer.toJson<String>(
        $CategoriesTable.$converterkind.toJson(kind),
      ),
      'categoryId': serializer.toJson<String>(categoryId),
      'name': serializer.toJson<String>(name),
    };
  }

  Category copyWith({
    int? sourceId,
    CatalogKind? kind,
    String? categoryId,
    String? name,
  }) => Category(
    sourceId: sourceId ?? this.sourceId,
    kind: kind ?? this.kind,
    categoryId: categoryId ?? this.categoryId,
    name: name ?? this.name,
  );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      kind: data.kind.present ? data.kind.value : this.kind,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('sourceId: $sourceId, ')
          ..write('kind: $kind, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sourceId, kind, categoryId, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.sourceId == this.sourceId &&
          other.kind == this.kind &&
          other.categoryId == this.categoryId &&
          other.name == this.name);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<int> sourceId;
  final Value<CatalogKind> kind;
  final Value<String> categoryId;
  final Value<String> name;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.sourceId = const Value.absent(),
    this.kind = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.name = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required int sourceId,
    required CatalogKind kind,
    required String categoryId,
    required String name,
    this.rowid = const Value.absent(),
  }) : sourceId = Value(sourceId),
       kind = Value(kind),
       categoryId = Value(categoryId),
       name = Value(name);
  static Insertable<Category> custom({
    Expression<int>? sourceId,
    Expression<String>? kind,
    Expression<String>? categoryId,
    Expression<String>? name,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceId != null) 'source_id': sourceId,
      if (kind != null) 'kind': kind,
      if (categoryId != null) 'category_id': categoryId,
      if (name != null) 'name': name,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<int>? sourceId,
    Value<CatalogKind>? kind,
    Value<String>? categoryId,
    Value<String>? name,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      sourceId: sourceId ?? this.sourceId,
      kind: kind ?? this.kind,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceId.present) {
      map['source_id'] = Variable<int>(sourceId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $CategoriesTable.$converterkind.toSql(kind.value),
      );
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('sourceId: $sourceId, ')
          ..write('kind: $kind, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LiveChannelsTable extends LiveChannels
    with TableInfo<$LiveChannelsTable, LiveChannel> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LiveChannelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<int> sourceId = GeneratedColumn<int>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sources (id)',
    ),
  );
  static const VerificationMeta _streamIdMeta = const VerificationMeta(
    'streamId',
  );
  @override
  late final GeneratedColumn<int> streamId = GeneratedColumn<int>(
    'stream_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _epgChannelIdMeta = const VerificationMeta(
    'epgChannelId',
  );
  @override
  late final GeneratedColumn<String> epgChannelId = GeneratedColumn<String>(
    'epg_channel_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _channelNumberMeta = const VerificationMeta(
    'channelNumber',
  );
  @override
  late final GeneratedColumn<int> channelNumber = GeneratedColumn<int>(
    'channel_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _streamUrlMeta = const VerificationMeta(
    'streamUrl',
  );
  @override
  late final GeneratedColumn<String> streamUrl = GeneratedColumn<String>(
    'stream_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sourceId,
    streamId,
    name,
    icon,
    categoryId,
    epgChannelId,
    channelNumber,
    streamUrl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'live_channels';
  @override
  VerificationContext validateIntegrity(
    Insertable<LiveChannel> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('stream_id')) {
      context.handle(
        _streamIdMeta,
        streamId.isAcceptableOrUnknown(data['stream_id']!, _streamIdMeta),
      );
    } else if (isInserting) {
      context.missing(_streamIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('epg_channel_id')) {
      context.handle(
        _epgChannelIdMeta,
        epgChannelId.isAcceptableOrUnknown(
          data['epg_channel_id']!,
          _epgChannelIdMeta,
        ),
      );
    }
    if (data.containsKey('channel_number')) {
      context.handle(
        _channelNumberMeta,
        channelNumber.isAcceptableOrUnknown(
          data['channel_number']!,
          _channelNumberMeta,
        ),
      );
    }
    if (data.containsKey('stream_url')) {
      context.handle(
        _streamUrlMeta,
        streamUrl.isAcceptableOrUnknown(data['stream_url']!, _streamUrlMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceId, streamId};
  @override
  LiveChannel map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LiveChannel(
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_id'],
      )!,
      streamId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stream_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      epgChannelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}epg_channel_id'],
      ),
      channelNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}channel_number'],
      ),
      streamUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stream_url'],
      ),
    );
  }

  @override
  $LiveChannelsTable createAlias(String alias) {
    return $LiveChannelsTable(attachedDatabase, alias);
  }
}

class LiveChannel extends DataClass implements Insertable<LiveChannel> {
  final int sourceId;
  final int streamId;
  final String name;
  final String? icon;
  final String? categoryId;
  final String? epgChannelId;
  final int? channelNumber;

  /// M3U entries carry their own URL; Xtream channels build it from creds.
  final String? streamUrl;
  const LiveChannel({
    required this.sourceId,
    required this.streamId,
    required this.name,
    this.icon,
    this.categoryId,
    this.epgChannelId,
    this.channelNumber,
    this.streamUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_id'] = Variable<int>(sourceId);
    map['stream_id'] = Variable<int>(streamId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || epgChannelId != null) {
      map['epg_channel_id'] = Variable<String>(epgChannelId);
    }
    if (!nullToAbsent || channelNumber != null) {
      map['channel_number'] = Variable<int>(channelNumber);
    }
    if (!nullToAbsent || streamUrl != null) {
      map['stream_url'] = Variable<String>(streamUrl);
    }
    return map;
  }

  LiveChannelsCompanion toCompanion(bool nullToAbsent) {
    return LiveChannelsCompanion(
      sourceId: Value(sourceId),
      streamId: Value(streamId),
      name: Value(name),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      epgChannelId: epgChannelId == null && nullToAbsent
          ? const Value.absent()
          : Value(epgChannelId),
      channelNumber: channelNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(channelNumber),
      streamUrl: streamUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(streamUrl),
    );
  }

  factory LiveChannel.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LiveChannel(
      sourceId: serializer.fromJson<int>(json['sourceId']),
      streamId: serializer.fromJson<int>(json['streamId']),
      name: serializer.fromJson<String>(json['name']),
      icon: serializer.fromJson<String?>(json['icon']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      epgChannelId: serializer.fromJson<String?>(json['epgChannelId']),
      channelNumber: serializer.fromJson<int?>(json['channelNumber']),
      streamUrl: serializer.fromJson<String?>(json['streamUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sourceId': serializer.toJson<int>(sourceId),
      'streamId': serializer.toJson<int>(streamId),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<String?>(icon),
      'categoryId': serializer.toJson<String?>(categoryId),
      'epgChannelId': serializer.toJson<String?>(epgChannelId),
      'channelNumber': serializer.toJson<int?>(channelNumber),
      'streamUrl': serializer.toJson<String?>(streamUrl),
    };
  }

  LiveChannel copyWith({
    int? sourceId,
    int? streamId,
    String? name,
    Value<String?> icon = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    Value<String?> epgChannelId = const Value.absent(),
    Value<int?> channelNumber = const Value.absent(),
    Value<String?> streamUrl = const Value.absent(),
  }) => LiveChannel(
    sourceId: sourceId ?? this.sourceId,
    streamId: streamId ?? this.streamId,
    name: name ?? this.name,
    icon: icon.present ? icon.value : this.icon,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    epgChannelId: epgChannelId.present ? epgChannelId.value : this.epgChannelId,
    channelNumber: channelNumber.present
        ? channelNumber.value
        : this.channelNumber,
    streamUrl: streamUrl.present ? streamUrl.value : this.streamUrl,
  );
  LiveChannel copyWithCompanion(LiveChannelsCompanion data) {
    return LiveChannel(
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      streamId: data.streamId.present ? data.streamId.value : this.streamId,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      epgChannelId: data.epgChannelId.present
          ? data.epgChannelId.value
          : this.epgChannelId,
      channelNumber: data.channelNumber.present
          ? data.channelNumber.value
          : this.channelNumber,
      streamUrl: data.streamUrl.present ? data.streamUrl.value : this.streamUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LiveChannel(')
          ..write('sourceId: $sourceId, ')
          ..write('streamId: $streamId, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('categoryId: $categoryId, ')
          ..write('epgChannelId: $epgChannelId, ')
          ..write('channelNumber: $channelNumber, ')
          ..write('streamUrl: $streamUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sourceId,
    streamId,
    name,
    icon,
    categoryId,
    epgChannelId,
    channelNumber,
    streamUrl,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LiveChannel &&
          other.sourceId == this.sourceId &&
          other.streamId == this.streamId &&
          other.name == this.name &&
          other.icon == this.icon &&
          other.categoryId == this.categoryId &&
          other.epgChannelId == this.epgChannelId &&
          other.channelNumber == this.channelNumber &&
          other.streamUrl == this.streamUrl);
}

class LiveChannelsCompanion extends UpdateCompanion<LiveChannel> {
  final Value<int> sourceId;
  final Value<int> streamId;
  final Value<String> name;
  final Value<String?> icon;
  final Value<String?> categoryId;
  final Value<String?> epgChannelId;
  final Value<int?> channelNumber;
  final Value<String?> streamUrl;
  final Value<int> rowid;
  const LiveChannelsCompanion({
    this.sourceId = const Value.absent(),
    this.streamId = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.epgChannelId = const Value.absent(),
    this.channelNumber = const Value.absent(),
    this.streamUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LiveChannelsCompanion.insert({
    required int sourceId,
    required int streamId,
    required String name,
    this.icon = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.epgChannelId = const Value.absent(),
    this.channelNumber = const Value.absent(),
    this.streamUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sourceId = Value(sourceId),
       streamId = Value(streamId),
       name = Value(name);
  static Insertable<LiveChannel> custom({
    Expression<int>? sourceId,
    Expression<int>? streamId,
    Expression<String>? name,
    Expression<String>? icon,
    Expression<String>? categoryId,
    Expression<String>? epgChannelId,
    Expression<int>? channelNumber,
    Expression<String>? streamUrl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceId != null) 'source_id': sourceId,
      if (streamId != null) 'stream_id': streamId,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (categoryId != null) 'category_id': categoryId,
      if (epgChannelId != null) 'epg_channel_id': epgChannelId,
      if (channelNumber != null) 'channel_number': channelNumber,
      if (streamUrl != null) 'stream_url': streamUrl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LiveChannelsCompanion copyWith({
    Value<int>? sourceId,
    Value<int>? streamId,
    Value<String>? name,
    Value<String?>? icon,
    Value<String?>? categoryId,
    Value<String?>? epgChannelId,
    Value<int?>? channelNumber,
    Value<String?>? streamUrl,
    Value<int>? rowid,
  }) {
    return LiveChannelsCompanion(
      sourceId: sourceId ?? this.sourceId,
      streamId: streamId ?? this.streamId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      categoryId: categoryId ?? this.categoryId,
      epgChannelId: epgChannelId ?? this.epgChannelId,
      channelNumber: channelNumber ?? this.channelNumber,
      streamUrl: streamUrl ?? this.streamUrl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceId.present) {
      map['source_id'] = Variable<int>(sourceId.value);
    }
    if (streamId.present) {
      map['stream_id'] = Variable<int>(streamId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (epgChannelId.present) {
      map['epg_channel_id'] = Variable<String>(epgChannelId.value);
    }
    if (channelNumber.present) {
      map['channel_number'] = Variable<int>(channelNumber.value);
    }
    if (streamUrl.present) {
      map['stream_url'] = Variable<String>(streamUrl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LiveChannelsCompanion(')
          ..write('sourceId: $sourceId, ')
          ..write('streamId: $streamId, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('categoryId: $categoryId, ')
          ..write('epgChannelId: $epgChannelId, ')
          ..write('channelNumber: $channelNumber, ')
          ..write('streamUrl: $streamUrl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MoviesTable extends Movies with TableInfo<$MoviesTable, Movie> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MoviesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<int> sourceId = GeneratedColumn<int>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sources (id)',
    ),
  );
  static const VerificationMeta _streamIdMeta = const VerificationMeta(
    'streamId',
  );
  @override
  late final GeneratedColumn<int> streamId = GeneratedColumn<int>(
    'stream_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _containerExtensionMeta =
      const VerificationMeta('containerExtension');
  @override
  late final GeneratedColumn<String> containerExtension =
      GeneratedColumn<String>(
        'container_extension',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
    'rating',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _streamUrlMeta = const VerificationMeta(
    'streamUrl',
  );
  @override
  late final GeneratedColumn<String> streamUrl = GeneratedColumn<String>(
    'stream_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sourceId,
    streamId,
    name,
    icon,
    categoryId,
    containerExtension,
    rating,
    addedAt,
    streamUrl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'movies';
  @override
  VerificationContext validateIntegrity(
    Insertable<Movie> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('stream_id')) {
      context.handle(
        _streamIdMeta,
        streamId.isAcceptableOrUnknown(data['stream_id']!, _streamIdMeta),
      );
    } else if (isInserting) {
      context.missing(_streamIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('container_extension')) {
      context.handle(
        _containerExtensionMeta,
        containerExtension.isAcceptableOrUnknown(
          data['container_extension']!,
          _containerExtensionMeta,
        ),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    }
    if (data.containsKey('stream_url')) {
      context.handle(
        _streamUrlMeta,
        streamUrl.isAcceptableOrUnknown(data['stream_url']!, _streamUrlMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceId, streamId};
  @override
  Movie map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Movie(
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_id'],
      )!,
      streamId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stream_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      containerExtension: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}container_extension'],
      ),
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rating'],
      ),
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      ),
      streamUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stream_url'],
      ),
    );
  }

  @override
  $MoviesTable createAlias(String alias) {
    return $MoviesTable(attachedDatabase, alias);
  }
}

class Movie extends DataClass implements Insertable<Movie> {
  final int sourceId;
  final int streamId;
  final String name;
  final String? icon;
  final String? categoryId;
  final String? containerExtension;
  final double? rating;
  final DateTime? addedAt;
  final String? streamUrl;
  const Movie({
    required this.sourceId,
    required this.streamId,
    required this.name,
    this.icon,
    this.categoryId,
    this.containerExtension,
    this.rating,
    this.addedAt,
    this.streamUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_id'] = Variable<int>(sourceId);
    map['stream_id'] = Variable<int>(streamId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || containerExtension != null) {
      map['container_extension'] = Variable<String>(containerExtension);
    }
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<double>(rating);
    }
    if (!nullToAbsent || addedAt != null) {
      map['added_at'] = Variable<DateTime>(addedAt);
    }
    if (!nullToAbsent || streamUrl != null) {
      map['stream_url'] = Variable<String>(streamUrl);
    }
    return map;
  }

  MoviesCompanion toCompanion(bool nullToAbsent) {
    return MoviesCompanion(
      sourceId: Value(sourceId),
      streamId: Value(streamId),
      name: Value(name),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      containerExtension: containerExtension == null && nullToAbsent
          ? const Value.absent()
          : Value(containerExtension),
      rating: rating == null && nullToAbsent
          ? const Value.absent()
          : Value(rating),
      addedAt: addedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(addedAt),
      streamUrl: streamUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(streamUrl),
    );
  }

  factory Movie.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Movie(
      sourceId: serializer.fromJson<int>(json['sourceId']),
      streamId: serializer.fromJson<int>(json['streamId']),
      name: serializer.fromJson<String>(json['name']),
      icon: serializer.fromJson<String?>(json['icon']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      containerExtension: serializer.fromJson<String?>(
        json['containerExtension'],
      ),
      rating: serializer.fromJson<double?>(json['rating']),
      addedAt: serializer.fromJson<DateTime?>(json['addedAt']),
      streamUrl: serializer.fromJson<String?>(json['streamUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sourceId': serializer.toJson<int>(sourceId),
      'streamId': serializer.toJson<int>(streamId),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<String?>(icon),
      'categoryId': serializer.toJson<String?>(categoryId),
      'containerExtension': serializer.toJson<String?>(containerExtension),
      'rating': serializer.toJson<double?>(rating),
      'addedAt': serializer.toJson<DateTime?>(addedAt),
      'streamUrl': serializer.toJson<String?>(streamUrl),
    };
  }

  Movie copyWith({
    int? sourceId,
    int? streamId,
    String? name,
    Value<String?> icon = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    Value<String?> containerExtension = const Value.absent(),
    Value<double?> rating = const Value.absent(),
    Value<DateTime?> addedAt = const Value.absent(),
    Value<String?> streamUrl = const Value.absent(),
  }) => Movie(
    sourceId: sourceId ?? this.sourceId,
    streamId: streamId ?? this.streamId,
    name: name ?? this.name,
    icon: icon.present ? icon.value : this.icon,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    containerExtension: containerExtension.present
        ? containerExtension.value
        : this.containerExtension,
    rating: rating.present ? rating.value : this.rating,
    addedAt: addedAt.present ? addedAt.value : this.addedAt,
    streamUrl: streamUrl.present ? streamUrl.value : this.streamUrl,
  );
  Movie copyWithCompanion(MoviesCompanion data) {
    return Movie(
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      streamId: data.streamId.present ? data.streamId.value : this.streamId,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      containerExtension: data.containerExtension.present
          ? data.containerExtension.value
          : this.containerExtension,
      rating: data.rating.present ? data.rating.value : this.rating,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      streamUrl: data.streamUrl.present ? data.streamUrl.value : this.streamUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Movie(')
          ..write('sourceId: $sourceId, ')
          ..write('streamId: $streamId, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('categoryId: $categoryId, ')
          ..write('containerExtension: $containerExtension, ')
          ..write('rating: $rating, ')
          ..write('addedAt: $addedAt, ')
          ..write('streamUrl: $streamUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sourceId,
    streamId,
    name,
    icon,
    categoryId,
    containerExtension,
    rating,
    addedAt,
    streamUrl,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Movie &&
          other.sourceId == this.sourceId &&
          other.streamId == this.streamId &&
          other.name == this.name &&
          other.icon == this.icon &&
          other.categoryId == this.categoryId &&
          other.containerExtension == this.containerExtension &&
          other.rating == this.rating &&
          other.addedAt == this.addedAt &&
          other.streamUrl == this.streamUrl);
}

class MoviesCompanion extends UpdateCompanion<Movie> {
  final Value<int> sourceId;
  final Value<int> streamId;
  final Value<String> name;
  final Value<String?> icon;
  final Value<String?> categoryId;
  final Value<String?> containerExtension;
  final Value<double?> rating;
  final Value<DateTime?> addedAt;
  final Value<String?> streamUrl;
  final Value<int> rowid;
  const MoviesCompanion({
    this.sourceId = const Value.absent(),
    this.streamId = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.containerExtension = const Value.absent(),
    this.rating = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.streamUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MoviesCompanion.insert({
    required int sourceId,
    required int streamId,
    required String name,
    this.icon = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.containerExtension = const Value.absent(),
    this.rating = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.streamUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sourceId = Value(sourceId),
       streamId = Value(streamId),
       name = Value(name);
  static Insertable<Movie> custom({
    Expression<int>? sourceId,
    Expression<int>? streamId,
    Expression<String>? name,
    Expression<String>? icon,
    Expression<String>? categoryId,
    Expression<String>? containerExtension,
    Expression<double>? rating,
    Expression<DateTime>? addedAt,
    Expression<String>? streamUrl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceId != null) 'source_id': sourceId,
      if (streamId != null) 'stream_id': streamId,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (categoryId != null) 'category_id': categoryId,
      if (containerExtension != null) 'container_extension': containerExtension,
      if (rating != null) 'rating': rating,
      if (addedAt != null) 'added_at': addedAt,
      if (streamUrl != null) 'stream_url': streamUrl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MoviesCompanion copyWith({
    Value<int>? sourceId,
    Value<int>? streamId,
    Value<String>? name,
    Value<String?>? icon,
    Value<String?>? categoryId,
    Value<String?>? containerExtension,
    Value<double?>? rating,
    Value<DateTime?>? addedAt,
    Value<String?>? streamUrl,
    Value<int>? rowid,
  }) {
    return MoviesCompanion(
      sourceId: sourceId ?? this.sourceId,
      streamId: streamId ?? this.streamId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      categoryId: categoryId ?? this.categoryId,
      containerExtension: containerExtension ?? this.containerExtension,
      rating: rating ?? this.rating,
      addedAt: addedAt ?? this.addedAt,
      streamUrl: streamUrl ?? this.streamUrl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceId.present) {
      map['source_id'] = Variable<int>(sourceId.value);
    }
    if (streamId.present) {
      map['stream_id'] = Variable<int>(streamId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (containerExtension.present) {
      map['container_extension'] = Variable<String>(containerExtension.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (streamUrl.present) {
      map['stream_url'] = Variable<String>(streamUrl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MoviesCompanion(')
          ..write('sourceId: $sourceId, ')
          ..write('streamId: $streamId, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('categoryId: $categoryId, ')
          ..write('containerExtension: $containerExtension, ')
          ..write('rating: $rating, ')
          ..write('addedAt: $addedAt, ')
          ..write('streamUrl: $streamUrl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SeriesItemsTable extends SeriesItems
    with TableInfo<$SeriesItemsTable, SeriesItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeriesItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<int> sourceId = GeneratedColumn<int>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sources (id)',
    ),
  );
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<int> seriesId = GeneratedColumn<int>(
    'series_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coverMeta = const VerificationMeta('cover');
  @override
  late final GeneratedColumn<String> cover = GeneratedColumn<String>(
    'cover',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _plotMeta = const VerificationMeta('plot');
  @override
  late final GeneratedColumn<String> plot = GeneratedColumn<String>(
    'plot',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
    'rating',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastModifiedAtMeta = const VerificationMeta(
    'lastModifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastModifiedAt =
      GeneratedColumn<DateTime>(
        'last_modified_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    sourceId,
    seriesId,
    name,
    cover,
    categoryId,
    plot,
    rating,
    lastModifiedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'series_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<SeriesItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    } else if (isInserting) {
      context.missing(_seriesIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('cover')) {
      context.handle(
        _coverMeta,
        cover.isAcceptableOrUnknown(data['cover']!, _coverMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('plot')) {
      context.handle(
        _plotMeta,
        plot.isAcceptableOrUnknown(data['plot']!, _plotMeta),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('last_modified_at')) {
      context.handle(
        _lastModifiedAtMeta,
        lastModifiedAt.isAcceptableOrUnknown(
          data['last_modified_at']!,
          _lastModifiedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceId, seriesId};
  @override
  SeriesItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SeriesItem(
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_id'],
      )!,
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}series_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      cover: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      plot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plot'],
      ),
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rating'],
      ),
      lastModifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified_at'],
      ),
    );
  }

  @override
  $SeriesItemsTable createAlias(String alias) {
    return $SeriesItemsTable(attachedDatabase, alias);
  }
}

class SeriesItem extends DataClass implements Insertable<SeriesItem> {
  final int sourceId;
  final int seriesId;
  final String name;
  final String? cover;
  final String? categoryId;
  final String? plot;
  final double? rating;
  final DateTime? lastModifiedAt;
  const SeriesItem({
    required this.sourceId,
    required this.seriesId,
    required this.name,
    this.cover,
    this.categoryId,
    this.plot,
    this.rating,
    this.lastModifiedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_id'] = Variable<int>(sourceId);
    map['series_id'] = Variable<int>(seriesId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || cover != null) {
      map['cover'] = Variable<String>(cover);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || plot != null) {
      map['plot'] = Variable<String>(plot);
    }
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<double>(rating);
    }
    if (!nullToAbsent || lastModifiedAt != null) {
      map['last_modified_at'] = Variable<DateTime>(lastModifiedAt);
    }
    return map;
  }

  SeriesItemsCompanion toCompanion(bool nullToAbsent) {
    return SeriesItemsCompanion(
      sourceId: Value(sourceId),
      seriesId: Value(seriesId),
      name: Value(name),
      cover: cover == null && nullToAbsent
          ? const Value.absent()
          : Value(cover),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      plot: plot == null && nullToAbsent ? const Value.absent() : Value(plot),
      rating: rating == null && nullToAbsent
          ? const Value.absent()
          : Value(rating),
      lastModifiedAt: lastModifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModifiedAt),
    );
  }

  factory SeriesItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SeriesItem(
      sourceId: serializer.fromJson<int>(json['sourceId']),
      seriesId: serializer.fromJson<int>(json['seriesId']),
      name: serializer.fromJson<String>(json['name']),
      cover: serializer.fromJson<String?>(json['cover']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      plot: serializer.fromJson<String?>(json['plot']),
      rating: serializer.fromJson<double?>(json['rating']),
      lastModifiedAt: serializer.fromJson<DateTime?>(json['lastModifiedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sourceId': serializer.toJson<int>(sourceId),
      'seriesId': serializer.toJson<int>(seriesId),
      'name': serializer.toJson<String>(name),
      'cover': serializer.toJson<String?>(cover),
      'categoryId': serializer.toJson<String?>(categoryId),
      'plot': serializer.toJson<String?>(plot),
      'rating': serializer.toJson<double?>(rating),
      'lastModifiedAt': serializer.toJson<DateTime?>(lastModifiedAt),
    };
  }

  SeriesItem copyWith({
    int? sourceId,
    int? seriesId,
    String? name,
    Value<String?> cover = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    Value<String?> plot = const Value.absent(),
    Value<double?> rating = const Value.absent(),
    Value<DateTime?> lastModifiedAt = const Value.absent(),
  }) => SeriesItem(
    sourceId: sourceId ?? this.sourceId,
    seriesId: seriesId ?? this.seriesId,
    name: name ?? this.name,
    cover: cover.present ? cover.value : this.cover,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    plot: plot.present ? plot.value : this.plot,
    rating: rating.present ? rating.value : this.rating,
    lastModifiedAt: lastModifiedAt.present
        ? lastModifiedAt.value
        : this.lastModifiedAt,
  );
  SeriesItem copyWithCompanion(SeriesItemsCompanion data) {
    return SeriesItem(
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      name: data.name.present ? data.name.value : this.name,
      cover: data.cover.present ? data.cover.value : this.cover,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      plot: data.plot.present ? data.plot.value : this.plot,
      rating: data.rating.present ? data.rating.value : this.rating,
      lastModifiedAt: data.lastModifiedAt.present
          ? data.lastModifiedAt.value
          : this.lastModifiedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SeriesItem(')
          ..write('sourceId: $sourceId, ')
          ..write('seriesId: $seriesId, ')
          ..write('name: $name, ')
          ..write('cover: $cover, ')
          ..write('categoryId: $categoryId, ')
          ..write('plot: $plot, ')
          ..write('rating: $rating, ')
          ..write('lastModifiedAt: $lastModifiedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sourceId,
    seriesId,
    name,
    cover,
    categoryId,
    plot,
    rating,
    lastModifiedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SeriesItem &&
          other.sourceId == this.sourceId &&
          other.seriesId == this.seriesId &&
          other.name == this.name &&
          other.cover == this.cover &&
          other.categoryId == this.categoryId &&
          other.plot == this.plot &&
          other.rating == this.rating &&
          other.lastModifiedAt == this.lastModifiedAt);
}

class SeriesItemsCompanion extends UpdateCompanion<SeriesItem> {
  final Value<int> sourceId;
  final Value<int> seriesId;
  final Value<String> name;
  final Value<String?> cover;
  final Value<String?> categoryId;
  final Value<String?> plot;
  final Value<double?> rating;
  final Value<DateTime?> lastModifiedAt;
  final Value<int> rowid;
  const SeriesItemsCompanion({
    this.sourceId = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.name = const Value.absent(),
    this.cover = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.plot = const Value.absent(),
    this.rating = const Value.absent(),
    this.lastModifiedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SeriesItemsCompanion.insert({
    required int sourceId,
    required int seriesId,
    required String name,
    this.cover = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.plot = const Value.absent(),
    this.rating = const Value.absent(),
    this.lastModifiedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sourceId = Value(sourceId),
       seriesId = Value(seriesId),
       name = Value(name);
  static Insertable<SeriesItem> custom({
    Expression<int>? sourceId,
    Expression<int>? seriesId,
    Expression<String>? name,
    Expression<String>? cover,
    Expression<String>? categoryId,
    Expression<String>? plot,
    Expression<double>? rating,
    Expression<DateTime>? lastModifiedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceId != null) 'source_id': sourceId,
      if (seriesId != null) 'series_id': seriesId,
      if (name != null) 'name': name,
      if (cover != null) 'cover': cover,
      if (categoryId != null) 'category_id': categoryId,
      if (plot != null) 'plot': plot,
      if (rating != null) 'rating': rating,
      if (lastModifiedAt != null) 'last_modified_at': lastModifiedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SeriesItemsCompanion copyWith({
    Value<int>? sourceId,
    Value<int>? seriesId,
    Value<String>? name,
    Value<String?>? cover,
    Value<String?>? categoryId,
    Value<String?>? plot,
    Value<double?>? rating,
    Value<DateTime?>? lastModifiedAt,
    Value<int>? rowid,
  }) {
    return SeriesItemsCompanion(
      sourceId: sourceId ?? this.sourceId,
      seriesId: seriesId ?? this.seriesId,
      name: name ?? this.name,
      cover: cover ?? this.cover,
      categoryId: categoryId ?? this.categoryId,
      plot: plot ?? this.plot,
      rating: rating ?? this.rating,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceId.present) {
      map['source_id'] = Variable<int>(sourceId.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<int>(seriesId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (cover.present) {
      map['cover'] = Variable<String>(cover.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (plot.present) {
      map['plot'] = Variable<String>(plot.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (lastModifiedAt.present) {
      map['last_modified_at'] = Variable<DateTime>(lastModifiedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeriesItemsCompanion(')
          ..write('sourceId: $sourceId, ')
          ..write('seriesId: $seriesId, ')
          ..write('name: $name, ')
          ..write('cover: $cover, ')
          ..write('categoryId: $categoryId, ')
          ..write('plot: $plot, ')
          ..write('rating: $rating, ')
          ..write('lastModifiedAt: $lastModifiedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EpgProgrammesTable extends EpgProgrammes
    with TableInfo<$EpgProgrammesTable, EpgProgramme> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EpgProgrammesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<int> sourceId = GeneratedColumn<int>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sources (id)',
    ),
  );
  static const VerificationMeta _channelIdMeta = const VerificationMeta(
    'channelId',
  );
  @override
  late final GeneratedColumn<String> channelId = GeneratedColumn<String>(
    'channel_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startAtMeta = const VerificationMeta(
    'startAt',
  );
  @override
  late final GeneratedColumn<DateTime> startAt = GeneratedColumn<DateTime>(
    'start_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endAtMeta = const VerificationMeta('endAt');
  @override
  late final GeneratedColumn<DateTime> endAt = GeneratedColumn<DateTime>(
    'end_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sourceId,
    channelId,
    startAt,
    endAt,
    title,
    description,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'epg_programmes';
  @override
  VerificationContext validateIntegrity(
    Insertable<EpgProgramme> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('channel_id')) {
      context.handle(
        _channelIdMeta,
        channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_channelIdMeta);
    }
    if (data.containsKey('start_at')) {
      context.handle(
        _startAtMeta,
        startAt.isAcceptableOrUnknown(data['start_at']!, _startAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startAtMeta);
    }
    if (data.containsKey('end_at')) {
      context.handle(
        _endAtMeta,
        endAt.isAcceptableOrUnknown(data['end_at']!, _endAtMeta),
      );
    } else if (isInserting) {
      context.missing(_endAtMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  EpgProgramme map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EpgProgramme(
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_id'],
      )!,
      channelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel_id'],
      )!,
      startAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_at'],
      )!,
      endAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_at'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
    );
  }

  @override
  $EpgProgrammesTable createAlias(String alias) {
    return $EpgProgrammesTable(attachedDatabase, alias);
  }
}

class EpgProgramme extends DataClass implements Insertable<EpgProgramme> {
  final int sourceId;
  final String channelId;
  final DateTime startAt;
  final DateTime endAt;
  final String title;
  final String? description;
  const EpgProgramme({
    required this.sourceId,
    required this.channelId,
    required this.startAt,
    required this.endAt,
    required this.title,
    this.description,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_id'] = Variable<int>(sourceId);
    map['channel_id'] = Variable<String>(channelId);
    map['start_at'] = Variable<DateTime>(startAt);
    map['end_at'] = Variable<DateTime>(endAt);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    return map;
  }

  EpgProgrammesCompanion toCompanion(bool nullToAbsent) {
    return EpgProgrammesCompanion(
      sourceId: Value(sourceId),
      channelId: Value(channelId),
      startAt: Value(startAt),
      endAt: Value(endAt),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
    );
  }

  factory EpgProgramme.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EpgProgramme(
      sourceId: serializer.fromJson<int>(json['sourceId']),
      channelId: serializer.fromJson<String>(json['channelId']),
      startAt: serializer.fromJson<DateTime>(json['startAt']),
      endAt: serializer.fromJson<DateTime>(json['endAt']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sourceId': serializer.toJson<int>(sourceId),
      'channelId': serializer.toJson<String>(channelId),
      'startAt': serializer.toJson<DateTime>(startAt),
      'endAt': serializer.toJson<DateTime>(endAt),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
    };
  }

  EpgProgramme copyWith({
    int? sourceId,
    String? channelId,
    DateTime? startAt,
    DateTime? endAt,
    String? title,
    Value<String?> description = const Value.absent(),
  }) => EpgProgramme(
    sourceId: sourceId ?? this.sourceId,
    channelId: channelId ?? this.channelId,
    startAt: startAt ?? this.startAt,
    endAt: endAt ?? this.endAt,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
  );
  EpgProgramme copyWithCompanion(EpgProgrammesCompanion data) {
    return EpgProgramme(
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      startAt: data.startAt.present ? data.startAt.value : this.startAt,
      endAt: data.endAt.present ? data.endAt.value : this.endAt,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EpgProgramme(')
          ..write('sourceId: $sourceId, ')
          ..write('channelId: $channelId, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('title: $title, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(sourceId, channelId, startAt, endAt, title, description);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EpgProgramme &&
          other.sourceId == this.sourceId &&
          other.channelId == this.channelId &&
          other.startAt == this.startAt &&
          other.endAt == this.endAt &&
          other.title == this.title &&
          other.description == this.description);
}

class EpgProgrammesCompanion extends UpdateCompanion<EpgProgramme> {
  final Value<int> sourceId;
  final Value<String> channelId;
  final Value<DateTime> startAt;
  final Value<DateTime> endAt;
  final Value<String> title;
  final Value<String?> description;
  final Value<int> rowid;
  const EpgProgrammesCompanion({
    this.sourceId = const Value.absent(),
    this.channelId = const Value.absent(),
    this.startAt = const Value.absent(),
    this.endAt = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EpgProgrammesCompanion.insert({
    required int sourceId,
    required String channelId,
    required DateTime startAt,
    required DateTime endAt,
    required String title,
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sourceId = Value(sourceId),
       channelId = Value(channelId),
       startAt = Value(startAt),
       endAt = Value(endAt),
       title = Value(title);
  static Insertable<EpgProgramme> custom({
    Expression<int>? sourceId,
    Expression<String>? channelId,
    Expression<DateTime>? startAt,
    Expression<DateTime>? endAt,
    Expression<String>? title,
    Expression<String>? description,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceId != null) 'source_id': sourceId,
      if (channelId != null) 'channel_id': channelId,
      if (startAt != null) 'start_at': startAt,
      if (endAt != null) 'end_at': endAt,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EpgProgrammesCompanion copyWith({
    Value<int>? sourceId,
    Value<String>? channelId,
    Value<DateTime>? startAt,
    Value<DateTime>? endAt,
    Value<String>? title,
    Value<String?>? description,
    Value<int>? rowid,
  }) {
    return EpgProgrammesCompanion(
      sourceId: sourceId ?? this.sourceId,
      channelId: channelId ?? this.channelId,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      title: title ?? this.title,
      description: description ?? this.description,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceId.present) {
      map['source_id'] = Variable<int>(sourceId.value);
    }
    if (channelId.present) {
      map['channel_id'] = Variable<String>(channelId.value);
    }
    if (startAt.present) {
      map['start_at'] = Variable<DateTime>(startAt.value);
    }
    if (endAt.present) {
      map['end_at'] = Variable<DateTime>(endAt.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EpgProgrammesCompanion(')
          ..write('sourceId: $sourceId, ')
          ..write('channelId: $channelId, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FavoritesTable extends Favorites
    with TableInfo<$FavoritesTable, Favorite> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<int> sourceId = GeneratedColumn<int>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sources (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<CatalogKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CatalogKind>($FavoritesTable.$converterkind);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sourceId,
    kind,
    itemId,
    name,
    imageUrl,
    addedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorites';
  @override
  VerificationContext validateIntegrity(
    Insertable<Favorite> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceId, kind, itemId};
  @override
  Favorite map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Favorite(
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_id'],
      )!,
      kind: $FavoritesTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $FavoritesTable createAlias(String alias) {
    return $FavoritesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CatalogKind, String, String> $converterkind =
      const EnumNameConverter<CatalogKind>(CatalogKind.values);
}

class Favorite extends DataClass implements Insertable<Favorite> {
  final int sourceId;
  final CatalogKind kind;
  final int itemId;
  final String name;
  final String? imageUrl;
  final DateTime addedAt;
  const Favorite({
    required this.sourceId,
    required this.kind,
    required this.itemId,
    required this.name,
    this.imageUrl,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_id'] = Variable<int>(sourceId);
    {
      map['kind'] = Variable<String>(
        $FavoritesTable.$converterkind.toSql(kind),
      );
    }
    map['item_id'] = Variable<int>(itemId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  FavoritesCompanion toCompanion(bool nullToAbsent) {
    return FavoritesCompanion(
      sourceId: Value(sourceId),
      kind: Value(kind),
      itemId: Value(itemId),
      name: Value(name),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      addedAt: Value(addedAt),
    );
  }

  factory Favorite.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Favorite(
      sourceId: serializer.fromJson<int>(json['sourceId']),
      kind: $FavoritesTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      itemId: serializer.fromJson<int>(json['itemId']),
      name: serializer.fromJson<String>(json['name']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sourceId': serializer.toJson<int>(sourceId),
      'kind': serializer.toJson<String>(
        $FavoritesTable.$converterkind.toJson(kind),
      ),
      'itemId': serializer.toJson<int>(itemId),
      'name': serializer.toJson<String>(name),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  Favorite copyWith({
    int? sourceId,
    CatalogKind? kind,
    int? itemId,
    String? name,
    Value<String?> imageUrl = const Value.absent(),
    DateTime? addedAt,
  }) => Favorite(
    sourceId: sourceId ?? this.sourceId,
    kind: kind ?? this.kind,
    itemId: itemId ?? this.itemId,
    name: name ?? this.name,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    addedAt: addedAt ?? this.addedAt,
  );
  Favorite copyWithCompanion(FavoritesCompanion data) {
    return Favorite(
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      kind: data.kind.present ? data.kind.value : this.kind,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      name: data.name.present ? data.name.value : this.name,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Favorite(')
          ..write('sourceId: $sourceId, ')
          ..write('kind: $kind, ')
          ..write('itemId: $itemId, ')
          ..write('name: $name, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(sourceId, kind, itemId, name, imageUrl, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Favorite &&
          other.sourceId == this.sourceId &&
          other.kind == this.kind &&
          other.itemId == this.itemId &&
          other.name == this.name &&
          other.imageUrl == this.imageUrl &&
          other.addedAt == this.addedAt);
}

class FavoritesCompanion extends UpdateCompanion<Favorite> {
  final Value<int> sourceId;
  final Value<CatalogKind> kind;
  final Value<int> itemId;
  final Value<String> name;
  final Value<String?> imageUrl;
  final Value<DateTime> addedAt;
  final Value<int> rowid;
  const FavoritesCompanion({
    this.sourceId = const Value.absent(),
    this.kind = const Value.absent(),
    this.itemId = const Value.absent(),
    this.name = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FavoritesCompanion.insert({
    required int sourceId,
    required CatalogKind kind,
    required int itemId,
    required String name,
    this.imageUrl = const Value.absent(),
    required DateTime addedAt,
    this.rowid = const Value.absent(),
  }) : sourceId = Value(sourceId),
       kind = Value(kind),
       itemId = Value(itemId),
       name = Value(name),
       addedAt = Value(addedAt);
  static Insertable<Favorite> custom({
    Expression<int>? sourceId,
    Expression<String>? kind,
    Expression<int>? itemId,
    Expression<String>? name,
    Expression<String>? imageUrl,
    Expression<DateTime>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceId != null) 'source_id': sourceId,
      if (kind != null) 'kind': kind,
      if (itemId != null) 'item_id': itemId,
      if (name != null) 'name': name,
      if (imageUrl != null) 'image_url': imageUrl,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FavoritesCompanion copyWith({
    Value<int>? sourceId,
    Value<CatalogKind>? kind,
    Value<int>? itemId,
    Value<String>? name,
    Value<String?>? imageUrl,
    Value<DateTime>? addedAt,
    Value<int>? rowid,
  }) {
    return FavoritesCompanion(
      sourceId: sourceId ?? this.sourceId,
      kind: kind ?? this.kind,
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceId.present) {
      map['source_id'] = Variable<int>(sourceId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $FavoritesTable.$converterkind.toSql(kind.value),
      );
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoritesCompanion(')
          ..write('sourceId: $sourceId, ')
          ..write('kind: $kind, ')
          ..write('itemId: $itemId, ')
          ..write('name: $name, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaybackPositionsTable extends PlaybackPositions
    with TableInfo<$PlaybackPositionsTable, PlaybackPosition> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaybackPositionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<int> sourceId = GeneratedColumn<int>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sources (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<WatchKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<WatchKind>($PlaybackPositionsTable.$converterkind);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<int> seriesId = GeneratedColumn<int>(
    'series_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subtitleMeta = const VerificationMeta(
    'subtitle',
  );
  @override
  late final GeneratedColumn<String> subtitle = GeneratedColumn<String>(
    'subtitle',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _containerExtensionMeta =
      const VerificationMeta('containerExtension');
  @override
  late final GeneratedColumn<String> containerExtension =
      GeneratedColumn<String>(
        'container_extension',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _positionSecsMeta = const VerificationMeta(
    'positionSecs',
  );
  @override
  late final GeneratedColumn<int> positionSecs = GeneratedColumn<int>(
    'position_secs',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationSecsMeta = const VerificationMeta(
    'durationSecs',
  );
  @override
  late final GeneratedColumn<int> durationSecs = GeneratedColumn<int>(
    'duration_secs',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  List<GeneratedColumn> get $columns => [
    sourceId,
    kind,
    itemId,
    seriesId,
    title,
    subtitle,
    imageUrl,
    containerExtension,
    positionSecs,
    durationSecs,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playback_positions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaybackPosition> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('subtitle')) {
      context.handle(
        _subtitleMeta,
        subtitle.isAcceptableOrUnknown(data['subtitle']!, _subtitleMeta),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('container_extension')) {
      context.handle(
        _containerExtensionMeta,
        containerExtension.isAcceptableOrUnknown(
          data['container_extension']!,
          _containerExtensionMeta,
        ),
      );
    }
    if (data.containsKey('position_secs')) {
      context.handle(
        _positionSecsMeta,
        positionSecs.isAcceptableOrUnknown(
          data['position_secs']!,
          _positionSecsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_positionSecsMeta);
    }
    if (data.containsKey('duration_secs')) {
      context.handle(
        _durationSecsMeta,
        durationSecs.isAcceptableOrUnknown(
          data['duration_secs']!,
          _durationSecsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationSecsMeta);
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
  Set<GeneratedColumn> get $primaryKey => {sourceId, kind, itemId};
  @override
  PlaybackPosition map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaybackPosition(
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_id'],
      )!,
      kind: $PlaybackPositionsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_id'],
      )!,
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}series_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      subtitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtitle'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      containerExtension: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}container_extension'],
      ),
      positionSecs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position_secs'],
      )!,
      durationSecs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_secs'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PlaybackPositionsTable createAlias(String alias) {
    return $PlaybackPositionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<WatchKind, String, String> $converterkind =
      const EnumNameConverter<WatchKind>(WatchKind.values);
}

class PlaybackPosition extends DataClass
    implements Insertable<PlaybackPosition> {
  final int sourceId;
  final WatchKind kind;
  final int itemId;
  final int? seriesId;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String? containerExtension;
  final int positionSecs;
  final int durationSecs;
  final DateTime updatedAt;
  const PlaybackPosition({
    required this.sourceId,
    required this.kind,
    required this.itemId,
    this.seriesId,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.containerExtension,
    required this.positionSecs,
    required this.durationSecs,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_id'] = Variable<int>(sourceId);
    {
      map['kind'] = Variable<String>(
        $PlaybackPositionsTable.$converterkind.toSql(kind),
      );
    }
    map['item_id'] = Variable<int>(itemId);
    if (!nullToAbsent || seriesId != null) {
      map['series_id'] = Variable<int>(seriesId);
    }
    map['title'] = Variable<String>(title);
    map['subtitle'] = Variable<String>(subtitle);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || containerExtension != null) {
      map['container_extension'] = Variable<String>(containerExtension);
    }
    map['position_secs'] = Variable<int>(positionSecs);
    map['duration_secs'] = Variable<int>(durationSecs);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PlaybackPositionsCompanion toCompanion(bool nullToAbsent) {
    return PlaybackPositionsCompanion(
      sourceId: Value(sourceId),
      kind: Value(kind),
      itemId: Value(itemId),
      seriesId: seriesId == null && nullToAbsent
          ? const Value.absent()
          : Value(seriesId),
      title: Value(title),
      subtitle: Value(subtitle),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      containerExtension: containerExtension == null && nullToAbsent
          ? const Value.absent()
          : Value(containerExtension),
      positionSecs: Value(positionSecs),
      durationSecs: Value(durationSecs),
      updatedAt: Value(updatedAt),
    );
  }

  factory PlaybackPosition.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaybackPosition(
      sourceId: serializer.fromJson<int>(json['sourceId']),
      kind: $PlaybackPositionsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      itemId: serializer.fromJson<int>(json['itemId']),
      seriesId: serializer.fromJson<int?>(json['seriesId']),
      title: serializer.fromJson<String>(json['title']),
      subtitle: serializer.fromJson<String>(json['subtitle']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      containerExtension: serializer.fromJson<String?>(
        json['containerExtension'],
      ),
      positionSecs: serializer.fromJson<int>(json['positionSecs']),
      durationSecs: serializer.fromJson<int>(json['durationSecs']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sourceId': serializer.toJson<int>(sourceId),
      'kind': serializer.toJson<String>(
        $PlaybackPositionsTable.$converterkind.toJson(kind),
      ),
      'itemId': serializer.toJson<int>(itemId),
      'seriesId': serializer.toJson<int?>(seriesId),
      'title': serializer.toJson<String>(title),
      'subtitle': serializer.toJson<String>(subtitle),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'containerExtension': serializer.toJson<String?>(containerExtension),
      'positionSecs': serializer.toJson<int>(positionSecs),
      'durationSecs': serializer.toJson<int>(durationSecs),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PlaybackPosition copyWith({
    int? sourceId,
    WatchKind? kind,
    int? itemId,
    Value<int?> seriesId = const Value.absent(),
    String? title,
    String? subtitle,
    Value<String?> imageUrl = const Value.absent(),
    Value<String?> containerExtension = const Value.absent(),
    int? positionSecs,
    int? durationSecs,
    DateTime? updatedAt,
  }) => PlaybackPosition(
    sourceId: sourceId ?? this.sourceId,
    kind: kind ?? this.kind,
    itemId: itemId ?? this.itemId,
    seriesId: seriesId.present ? seriesId.value : this.seriesId,
    title: title ?? this.title,
    subtitle: subtitle ?? this.subtitle,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    containerExtension: containerExtension.present
        ? containerExtension.value
        : this.containerExtension,
    positionSecs: positionSecs ?? this.positionSecs,
    durationSecs: durationSecs ?? this.durationSecs,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PlaybackPosition copyWithCompanion(PlaybackPositionsCompanion data) {
    return PlaybackPosition(
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      kind: data.kind.present ? data.kind.value : this.kind,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      title: data.title.present ? data.title.value : this.title,
      subtitle: data.subtitle.present ? data.subtitle.value : this.subtitle,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      containerExtension: data.containerExtension.present
          ? data.containerExtension.value
          : this.containerExtension,
      positionSecs: data.positionSecs.present
          ? data.positionSecs.value
          : this.positionSecs,
      durationSecs: data.durationSecs.present
          ? data.durationSecs.value
          : this.durationSecs,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackPosition(')
          ..write('sourceId: $sourceId, ')
          ..write('kind: $kind, ')
          ..write('itemId: $itemId, ')
          ..write('seriesId: $seriesId, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('containerExtension: $containerExtension, ')
          ..write('positionSecs: $positionSecs, ')
          ..write('durationSecs: $durationSecs, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sourceId,
    kind,
    itemId,
    seriesId,
    title,
    subtitle,
    imageUrl,
    containerExtension,
    positionSecs,
    durationSecs,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaybackPosition &&
          other.sourceId == this.sourceId &&
          other.kind == this.kind &&
          other.itemId == this.itemId &&
          other.seriesId == this.seriesId &&
          other.title == this.title &&
          other.subtitle == this.subtitle &&
          other.imageUrl == this.imageUrl &&
          other.containerExtension == this.containerExtension &&
          other.positionSecs == this.positionSecs &&
          other.durationSecs == this.durationSecs &&
          other.updatedAt == this.updatedAt);
}

class PlaybackPositionsCompanion extends UpdateCompanion<PlaybackPosition> {
  final Value<int> sourceId;
  final Value<WatchKind> kind;
  final Value<int> itemId;
  final Value<int?> seriesId;
  final Value<String> title;
  final Value<String> subtitle;
  final Value<String?> imageUrl;
  final Value<String?> containerExtension;
  final Value<int> positionSecs;
  final Value<int> durationSecs;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PlaybackPositionsCompanion({
    this.sourceId = const Value.absent(),
    this.kind = const Value.absent(),
    this.itemId = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.title = const Value.absent(),
    this.subtitle = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.containerExtension = const Value.absent(),
    this.positionSecs = const Value.absent(),
    this.durationSecs = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaybackPositionsCompanion.insert({
    required int sourceId,
    required WatchKind kind,
    required int itemId,
    this.seriesId = const Value.absent(),
    required String title,
    this.subtitle = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.containerExtension = const Value.absent(),
    required int positionSecs,
    required int durationSecs,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : sourceId = Value(sourceId),
       kind = Value(kind),
       itemId = Value(itemId),
       title = Value(title),
       positionSecs = Value(positionSecs),
       durationSecs = Value(durationSecs),
       updatedAt = Value(updatedAt);
  static Insertable<PlaybackPosition> custom({
    Expression<int>? sourceId,
    Expression<String>? kind,
    Expression<int>? itemId,
    Expression<int>? seriesId,
    Expression<String>? title,
    Expression<String>? subtitle,
    Expression<String>? imageUrl,
    Expression<String>? containerExtension,
    Expression<int>? positionSecs,
    Expression<int>? durationSecs,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceId != null) 'source_id': sourceId,
      if (kind != null) 'kind': kind,
      if (itemId != null) 'item_id': itemId,
      if (seriesId != null) 'series_id': seriesId,
      if (title != null) 'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      if (imageUrl != null) 'image_url': imageUrl,
      if (containerExtension != null) 'container_extension': containerExtension,
      if (positionSecs != null) 'position_secs': positionSecs,
      if (durationSecs != null) 'duration_secs': durationSecs,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaybackPositionsCompanion copyWith({
    Value<int>? sourceId,
    Value<WatchKind>? kind,
    Value<int>? itemId,
    Value<int?>? seriesId,
    Value<String>? title,
    Value<String>? subtitle,
    Value<String?>? imageUrl,
    Value<String?>? containerExtension,
    Value<int>? positionSecs,
    Value<int>? durationSecs,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PlaybackPositionsCompanion(
      sourceId: sourceId ?? this.sourceId,
      kind: kind ?? this.kind,
      itemId: itemId ?? this.itemId,
      seriesId: seriesId ?? this.seriesId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      containerExtension: containerExtension ?? this.containerExtension,
      positionSecs: positionSecs ?? this.positionSecs,
      durationSecs: durationSecs ?? this.durationSecs,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceId.present) {
      map['source_id'] = Variable<int>(sourceId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $PlaybackPositionsTable.$converterkind.toSql(kind.value),
      );
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<int>(seriesId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (subtitle.present) {
      map['subtitle'] = Variable<String>(subtitle.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (containerExtension.present) {
      map['container_extension'] = Variable<String>(containerExtension.value);
    }
    if (positionSecs.present) {
      map['position_secs'] = Variable<int>(positionSecs.value);
    }
    if (durationSecs.present) {
      map['duration_secs'] = Variable<int>(durationSecs.value);
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
    return (StringBuffer('PlaybackPositionsCompanion(')
          ..write('sourceId: $sourceId, ')
          ..write('kind: $kind, ')
          ..write('itemId: $itemId, ')
          ..write('seriesId: $seriesId, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('containerExtension: $containerExtension, ')
          ..write('positionSecs: $positionSecs, ')
          ..write('durationSecs: $durationSecs, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncTombstonesTable extends SyncTombstones
    with TableInfo<$SyncTombstonesTable, SyncTombstone> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncTombstonesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<int> sourceId = GeneratedColumn<int>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sources (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<TombstoneScope, String> scope =
      GeneratedColumn<String>(
        'scope',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TombstoneScope>($SyncTombstonesTable.$converterscope);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<int> seriesId = GeneratedColumn<int>(
    'series_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sourceId,
    scope,
    kind,
    itemId,
    seriesId,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_tombstones';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncTombstone> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_deletedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceId, scope, kind, itemId};
  @override
  SyncTombstone map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncTombstone(
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_id'],
      )!,
      scope: $SyncTombstonesTable.$converterscope.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}scope'],
        )!,
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_id'],
      )!,
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}series_id'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      )!,
    );
  }

  @override
  $SyncTombstonesTable createAlias(String alias) {
    return $SyncTombstonesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TombstoneScope, String, String> $converterscope =
      const EnumNameConverter<TombstoneScope>(TombstoneScope.values);
}

class SyncTombstone extends DataClass implements Insertable<SyncTombstone> {
  final int sourceId;
  final TombstoneScope scope;
  final String kind;
  final int itemId;
  final int? seriesId;
  final DateTime deletedAt;
  const SyncTombstone({
    required this.sourceId,
    required this.scope,
    required this.kind,
    required this.itemId,
    this.seriesId,
    required this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_id'] = Variable<int>(sourceId);
    {
      map['scope'] = Variable<String>(
        $SyncTombstonesTable.$converterscope.toSql(scope),
      );
    }
    map['kind'] = Variable<String>(kind);
    map['item_id'] = Variable<int>(itemId);
    if (!nullToAbsent || seriesId != null) {
      map['series_id'] = Variable<int>(seriesId);
    }
    map['deleted_at'] = Variable<DateTime>(deletedAt);
    return map;
  }

  SyncTombstonesCompanion toCompanion(bool nullToAbsent) {
    return SyncTombstonesCompanion(
      sourceId: Value(sourceId),
      scope: Value(scope),
      kind: Value(kind),
      itemId: Value(itemId),
      seriesId: seriesId == null && nullToAbsent
          ? const Value.absent()
          : Value(seriesId),
      deletedAt: Value(deletedAt),
    );
  }

  factory SyncTombstone.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncTombstone(
      sourceId: serializer.fromJson<int>(json['sourceId']),
      scope: $SyncTombstonesTable.$converterscope.fromJson(
        serializer.fromJson<String>(json['scope']),
      ),
      kind: serializer.fromJson<String>(json['kind']),
      itemId: serializer.fromJson<int>(json['itemId']),
      seriesId: serializer.fromJson<int?>(json['seriesId']),
      deletedAt: serializer.fromJson<DateTime>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sourceId': serializer.toJson<int>(sourceId),
      'scope': serializer.toJson<String>(
        $SyncTombstonesTable.$converterscope.toJson(scope),
      ),
      'kind': serializer.toJson<String>(kind),
      'itemId': serializer.toJson<int>(itemId),
      'seriesId': serializer.toJson<int?>(seriesId),
      'deletedAt': serializer.toJson<DateTime>(deletedAt),
    };
  }

  SyncTombstone copyWith({
    int? sourceId,
    TombstoneScope? scope,
    String? kind,
    int? itemId,
    Value<int?> seriesId = const Value.absent(),
    DateTime? deletedAt,
  }) => SyncTombstone(
    sourceId: sourceId ?? this.sourceId,
    scope: scope ?? this.scope,
    kind: kind ?? this.kind,
    itemId: itemId ?? this.itemId,
    seriesId: seriesId.present ? seriesId.value : this.seriesId,
    deletedAt: deletedAt ?? this.deletedAt,
  );
  SyncTombstone copyWithCompanion(SyncTombstonesCompanion data) {
    return SyncTombstone(
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      scope: data.scope.present ? data.scope.value : this.scope,
      kind: data.kind.present ? data.kind.value : this.kind,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncTombstone(')
          ..write('sourceId: $sourceId, ')
          ..write('scope: $scope, ')
          ..write('kind: $kind, ')
          ..write('itemId: $itemId, ')
          ..write('seriesId: $seriesId, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(sourceId, scope, kind, itemId, seriesId, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncTombstone &&
          other.sourceId == this.sourceId &&
          other.scope == this.scope &&
          other.kind == this.kind &&
          other.itemId == this.itemId &&
          other.seriesId == this.seriesId &&
          other.deletedAt == this.deletedAt);
}

class SyncTombstonesCompanion extends UpdateCompanion<SyncTombstone> {
  final Value<int> sourceId;
  final Value<TombstoneScope> scope;
  final Value<String> kind;
  final Value<int> itemId;
  final Value<int?> seriesId;
  final Value<DateTime> deletedAt;
  final Value<int> rowid;
  const SyncTombstonesCompanion({
    this.sourceId = const Value.absent(),
    this.scope = const Value.absent(),
    this.kind = const Value.absent(),
    this.itemId = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncTombstonesCompanion.insert({
    required int sourceId,
    required TombstoneScope scope,
    required String kind,
    required int itemId,
    this.seriesId = const Value.absent(),
    required DateTime deletedAt,
    this.rowid = const Value.absent(),
  }) : sourceId = Value(sourceId),
       scope = Value(scope),
       kind = Value(kind),
       itemId = Value(itemId),
       deletedAt = Value(deletedAt);
  static Insertable<SyncTombstone> custom({
    Expression<int>? sourceId,
    Expression<String>? scope,
    Expression<String>? kind,
    Expression<int>? itemId,
    Expression<int>? seriesId,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceId != null) 'source_id': sourceId,
      if (scope != null) 'scope': scope,
      if (kind != null) 'kind': kind,
      if (itemId != null) 'item_id': itemId,
      if (seriesId != null) 'series_id': seriesId,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncTombstonesCompanion copyWith({
    Value<int>? sourceId,
    Value<TombstoneScope>? scope,
    Value<String>? kind,
    Value<int>? itemId,
    Value<int?>? seriesId,
    Value<DateTime>? deletedAt,
    Value<int>? rowid,
  }) {
    return SyncTombstonesCompanion(
      sourceId: sourceId ?? this.sourceId,
      scope: scope ?? this.scope,
      kind: kind ?? this.kind,
      itemId: itemId ?? this.itemId,
      seriesId: seriesId ?? this.seriesId,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceId.present) {
      map['source_id'] = Variable<int>(sourceId.value);
    }
    if (scope.present) {
      map['scope'] = Variable<String>(
        $SyncTombstonesTable.$converterscope.toSql(scope.value),
      );
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<int>(seriesId.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncTombstonesCompanion(')
          ..write('sourceId: $sourceId, ')
          ..write('scope: $scope, ')
          ..write('kind: $kind, ')
          ..write('itemId: $itemId, ')
          ..write('seriesId: $seriesId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DownloadsTable extends Downloads
    with TableInfo<$DownloadsTable, DownloadItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<int> sourceId = GeneratedColumn<int>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sources (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<WatchKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<WatchKind>($DownloadsTable.$converterkind);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<int> seriesId = GeneratedColumn<int>(
    'series_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subtitleMeta = const VerificationMeta(
    'subtitle',
  );
  @override
  late final GeneratedColumn<String> subtitle = GeneratedColumn<String>(
    'subtitle',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _episodeImageUrlMeta = const VerificationMeta(
    'episodeImageUrl',
  );
  @override
  late final GeneratedColumn<String> episodeImageUrl = GeneratedColumn<String>(
    'episode_image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _containerExtensionMeta =
      const VerificationMeta('containerExtension');
  @override
  late final GeneratedColumn<String> containerExtension =
      GeneratedColumn<String>(
        'container_extension',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalBytesMeta = const VerificationMeta(
    'totalBytes',
  );
  @override
  late final GeneratedColumn<int> totalBytes = GeneratedColumn<int>(
    'total_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DownloadStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DownloadStatus>($DownloadsTable.$converterstatus);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sourceId,
    kind,
    itemId,
    seriesId,
    title,
    subtitle,
    imageUrl,
    episodeImageUrl,
    containerExtension,
    filePath,
    totalBytes,
    status,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'downloads';
  @override
  VerificationContext validateIntegrity(
    Insertable<DownloadItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('subtitle')) {
      context.handle(
        _subtitleMeta,
        subtitle.isAcceptableOrUnknown(data['subtitle']!, _subtitleMeta),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('episode_image_url')) {
      context.handle(
        _episodeImageUrlMeta,
        episodeImageUrl.isAcceptableOrUnknown(
          data['episode_image_url']!,
          _episodeImageUrlMeta,
        ),
      );
    }
    if (data.containsKey('container_extension')) {
      context.handle(
        _containerExtensionMeta,
        containerExtension.isAcceptableOrUnknown(
          data['container_extension']!,
          _containerExtensionMeta,
        ),
      );
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('total_bytes')) {
      context.handle(
        _totalBytesMeta,
        totalBytes.isAcceptableOrUnknown(data['total_bytes']!, _totalBytesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceId, kind, itemId};
  @override
  DownloadItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadItem(
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_id'],
      )!,
      kind: $DownloadsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_id'],
      )!,
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}series_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      subtitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtitle'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      episodeImageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}episode_image_url'],
      ),
      containerExtension: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}container_extension'],
      ),
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      totalBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_bytes'],
      ),
      status: $DownloadsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DownloadsTable createAlias(String alias) {
    return $DownloadsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<WatchKind, String, String> $converterkind =
      const EnumNameConverter<WatchKind>(WatchKind.values);
  static JsonTypeConverter2<DownloadStatus, String, String> $converterstatus =
      const EnumNameConverter<DownloadStatus>(DownloadStatus.values);
}

class DownloadItem extends DataClass implements Insertable<DownloadItem> {
  final int sourceId;
  final WatchKind kind;
  final int itemId;

  /// For episodes: the parent series — keeps resume rows and cast identities
  /// correct when playing from Downloads.
  final int? seriesId;
  final String title;
  final String subtitle;

  /// Group poster: for episodes this is the series cover (shared by the whole
  /// download group); for movies it's the movie art.
  final String? imageUrl;

  /// Per-episode still, so the Downloads list can show each episode's own
  /// thumbnail instead of the series cover. Null for movies.
  final String? episodeImageUrl;
  final String? containerExtension;
  final String filePath;
  final int? totalBytes;
  final DownloadStatus status;
  final DateTime createdAt;
  const DownloadItem({
    required this.sourceId,
    required this.kind,
    required this.itemId,
    this.seriesId,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.episodeImageUrl,
    this.containerExtension,
    required this.filePath,
    this.totalBytes,
    required this.status,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_id'] = Variable<int>(sourceId);
    {
      map['kind'] = Variable<String>(
        $DownloadsTable.$converterkind.toSql(kind),
      );
    }
    map['item_id'] = Variable<int>(itemId);
    if (!nullToAbsent || seriesId != null) {
      map['series_id'] = Variable<int>(seriesId);
    }
    map['title'] = Variable<String>(title);
    map['subtitle'] = Variable<String>(subtitle);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || episodeImageUrl != null) {
      map['episode_image_url'] = Variable<String>(episodeImageUrl);
    }
    if (!nullToAbsent || containerExtension != null) {
      map['container_extension'] = Variable<String>(containerExtension);
    }
    map['file_path'] = Variable<String>(filePath);
    if (!nullToAbsent || totalBytes != null) {
      map['total_bytes'] = Variable<int>(totalBytes);
    }
    {
      map['status'] = Variable<String>(
        $DownloadsTable.$converterstatus.toSql(status),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DownloadsCompanion toCompanion(bool nullToAbsent) {
    return DownloadsCompanion(
      sourceId: Value(sourceId),
      kind: Value(kind),
      itemId: Value(itemId),
      seriesId: seriesId == null && nullToAbsent
          ? const Value.absent()
          : Value(seriesId),
      title: Value(title),
      subtitle: Value(subtitle),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      episodeImageUrl: episodeImageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(episodeImageUrl),
      containerExtension: containerExtension == null && nullToAbsent
          ? const Value.absent()
          : Value(containerExtension),
      filePath: Value(filePath),
      totalBytes: totalBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(totalBytes),
      status: Value(status),
      createdAt: Value(createdAt),
    );
  }

  factory DownloadItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadItem(
      sourceId: serializer.fromJson<int>(json['sourceId']),
      kind: $DownloadsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      itemId: serializer.fromJson<int>(json['itemId']),
      seriesId: serializer.fromJson<int?>(json['seriesId']),
      title: serializer.fromJson<String>(json['title']),
      subtitle: serializer.fromJson<String>(json['subtitle']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      episodeImageUrl: serializer.fromJson<String?>(json['episodeImageUrl']),
      containerExtension: serializer.fromJson<String?>(
        json['containerExtension'],
      ),
      filePath: serializer.fromJson<String>(json['filePath']),
      totalBytes: serializer.fromJson<int?>(json['totalBytes']),
      status: $DownloadsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sourceId': serializer.toJson<int>(sourceId),
      'kind': serializer.toJson<String>(
        $DownloadsTable.$converterkind.toJson(kind),
      ),
      'itemId': serializer.toJson<int>(itemId),
      'seriesId': serializer.toJson<int?>(seriesId),
      'title': serializer.toJson<String>(title),
      'subtitle': serializer.toJson<String>(subtitle),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'episodeImageUrl': serializer.toJson<String?>(episodeImageUrl),
      'containerExtension': serializer.toJson<String?>(containerExtension),
      'filePath': serializer.toJson<String>(filePath),
      'totalBytes': serializer.toJson<int?>(totalBytes),
      'status': serializer.toJson<String>(
        $DownloadsTable.$converterstatus.toJson(status),
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DownloadItem copyWith({
    int? sourceId,
    WatchKind? kind,
    int? itemId,
    Value<int?> seriesId = const Value.absent(),
    String? title,
    String? subtitle,
    Value<String?> imageUrl = const Value.absent(),
    Value<String?> episodeImageUrl = const Value.absent(),
    Value<String?> containerExtension = const Value.absent(),
    String? filePath,
    Value<int?> totalBytes = const Value.absent(),
    DownloadStatus? status,
    DateTime? createdAt,
  }) => DownloadItem(
    sourceId: sourceId ?? this.sourceId,
    kind: kind ?? this.kind,
    itemId: itemId ?? this.itemId,
    seriesId: seriesId.present ? seriesId.value : this.seriesId,
    title: title ?? this.title,
    subtitle: subtitle ?? this.subtitle,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    episodeImageUrl: episodeImageUrl.present
        ? episodeImageUrl.value
        : this.episodeImageUrl,
    containerExtension: containerExtension.present
        ? containerExtension.value
        : this.containerExtension,
    filePath: filePath ?? this.filePath,
    totalBytes: totalBytes.present ? totalBytes.value : this.totalBytes,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
  );
  DownloadItem copyWithCompanion(DownloadsCompanion data) {
    return DownloadItem(
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      kind: data.kind.present ? data.kind.value : this.kind,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      title: data.title.present ? data.title.value : this.title,
      subtitle: data.subtitle.present ? data.subtitle.value : this.subtitle,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      episodeImageUrl: data.episodeImageUrl.present
          ? data.episodeImageUrl.value
          : this.episodeImageUrl,
      containerExtension: data.containerExtension.present
          ? data.containerExtension.value
          : this.containerExtension,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      totalBytes: data.totalBytes.present
          ? data.totalBytes.value
          : this.totalBytes,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadItem(')
          ..write('sourceId: $sourceId, ')
          ..write('kind: $kind, ')
          ..write('itemId: $itemId, ')
          ..write('seriesId: $seriesId, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('episodeImageUrl: $episodeImageUrl, ')
          ..write('containerExtension: $containerExtension, ')
          ..write('filePath: $filePath, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sourceId,
    kind,
    itemId,
    seriesId,
    title,
    subtitle,
    imageUrl,
    episodeImageUrl,
    containerExtension,
    filePath,
    totalBytes,
    status,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadItem &&
          other.sourceId == this.sourceId &&
          other.kind == this.kind &&
          other.itemId == this.itemId &&
          other.seriesId == this.seriesId &&
          other.title == this.title &&
          other.subtitle == this.subtitle &&
          other.imageUrl == this.imageUrl &&
          other.episodeImageUrl == this.episodeImageUrl &&
          other.containerExtension == this.containerExtension &&
          other.filePath == this.filePath &&
          other.totalBytes == this.totalBytes &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class DownloadsCompanion extends UpdateCompanion<DownloadItem> {
  final Value<int> sourceId;
  final Value<WatchKind> kind;
  final Value<int> itemId;
  final Value<int?> seriesId;
  final Value<String> title;
  final Value<String> subtitle;
  final Value<String?> imageUrl;
  final Value<String?> episodeImageUrl;
  final Value<String?> containerExtension;
  final Value<String> filePath;
  final Value<int?> totalBytes;
  final Value<DownloadStatus> status;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const DownloadsCompanion({
    this.sourceId = const Value.absent(),
    this.kind = const Value.absent(),
    this.itemId = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.title = const Value.absent(),
    this.subtitle = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.episodeImageUrl = const Value.absent(),
    this.containerExtension = const Value.absent(),
    this.filePath = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadsCompanion.insert({
    required int sourceId,
    required WatchKind kind,
    required int itemId,
    this.seriesId = const Value.absent(),
    required String title,
    this.subtitle = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.episodeImageUrl = const Value.absent(),
    this.containerExtension = const Value.absent(),
    required String filePath,
    this.totalBytes = const Value.absent(),
    required DownloadStatus status,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : sourceId = Value(sourceId),
       kind = Value(kind),
       itemId = Value(itemId),
       title = Value(title),
       filePath = Value(filePath),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<DownloadItem> custom({
    Expression<int>? sourceId,
    Expression<String>? kind,
    Expression<int>? itemId,
    Expression<int>? seriesId,
    Expression<String>? title,
    Expression<String>? subtitle,
    Expression<String>? imageUrl,
    Expression<String>? episodeImageUrl,
    Expression<String>? containerExtension,
    Expression<String>? filePath,
    Expression<int>? totalBytes,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceId != null) 'source_id': sourceId,
      if (kind != null) 'kind': kind,
      if (itemId != null) 'item_id': itemId,
      if (seriesId != null) 'series_id': seriesId,
      if (title != null) 'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      if (imageUrl != null) 'image_url': imageUrl,
      if (episodeImageUrl != null) 'episode_image_url': episodeImageUrl,
      if (containerExtension != null) 'container_extension': containerExtension,
      if (filePath != null) 'file_path': filePath,
      if (totalBytes != null) 'total_bytes': totalBytes,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadsCompanion copyWith({
    Value<int>? sourceId,
    Value<WatchKind>? kind,
    Value<int>? itemId,
    Value<int?>? seriesId,
    Value<String>? title,
    Value<String>? subtitle,
    Value<String?>? imageUrl,
    Value<String?>? episodeImageUrl,
    Value<String?>? containerExtension,
    Value<String>? filePath,
    Value<int?>? totalBytes,
    Value<DownloadStatus>? status,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return DownloadsCompanion(
      sourceId: sourceId ?? this.sourceId,
      kind: kind ?? this.kind,
      itemId: itemId ?? this.itemId,
      seriesId: seriesId ?? this.seriesId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      episodeImageUrl: episodeImageUrl ?? this.episodeImageUrl,
      containerExtension: containerExtension ?? this.containerExtension,
      filePath: filePath ?? this.filePath,
      totalBytes: totalBytes ?? this.totalBytes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceId.present) {
      map['source_id'] = Variable<int>(sourceId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $DownloadsTable.$converterkind.toSql(kind.value),
      );
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<int>(seriesId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (subtitle.present) {
      map['subtitle'] = Variable<String>(subtitle.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (episodeImageUrl.present) {
      map['episode_image_url'] = Variable<String>(episodeImageUrl.value);
    }
    if (containerExtension.present) {
      map['container_extension'] = Variable<String>(containerExtension.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (totalBytes.present) {
      map['total_bytes'] = Variable<int>(totalBytes.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $DownloadsTable.$converterstatus.toSql(status.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadsCompanion(')
          ..write('sourceId: $sourceId, ')
          ..write('kind: $kind, ')
          ..write('itemId: $itemId, ')
          ..write('seriesId: $seriesId, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('episodeImageUrl: $episodeImageUrl, ')
          ..write('containerExtension: $containerExtension, ')
          ..write('filePath: $filePath, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SourcesTable sources = $SourcesTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $LiveChannelsTable liveChannels = $LiveChannelsTable(this);
  late final $MoviesTable movies = $MoviesTable(this);
  late final $SeriesItemsTable seriesItems = $SeriesItemsTable(this);
  late final $EpgProgrammesTable epgProgrammes = $EpgProgrammesTable(this);
  late final $FavoritesTable favorites = $FavoritesTable(this);
  late final $PlaybackPositionsTable playbackPositions =
      $PlaybackPositionsTable(this);
  late final $SyncTombstonesTable syncTombstones = $SyncTombstonesTable(this);
  late final $DownloadsTable downloads = $DownloadsTable(this);
  late final Index epgChannelStart = Index(
    'epg_channel_start',
    'CREATE INDEX epg_channel_start ON epg_programmes (source_id, channel_id, start_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sources,
    categories,
    liveChannels,
    movies,
    seriesItems,
    epgProgrammes,
    favorites,
    playbackPositions,
    syncTombstones,
    downloads,
    epgChannelStart,
  ];
}

typedef $$SourcesTableCreateCompanionBuilder =
    SourcesCompanion Function({
      Value<int> id,
      required String name,
      Value<SourceType> sourceType,
      required String serverUrl,
      required String username,
      required String password,
      Value<String?> epgUrl,
      Value<DateTime?> lastSyncAt,
    });
typedef $$SourcesTableUpdateCompanionBuilder =
    SourcesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<SourceType> sourceType,
      Value<String> serverUrl,
      Value<String> username,
      Value<String> password,
      Value<String?> epgUrl,
      Value<DateTime?> lastSyncAt,
    });

final class $$SourcesTableReferences
    extends BaseReferences<_$AppDatabase, $SourcesTable, Source> {
  $$SourcesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CategoriesTable, List<Category>>
  _categoriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.categories,
    aliasName: $_aliasNameGenerator(db.sources.id, db.categories.sourceId),
  );

  $$CategoriesTableProcessedTableManager get categoriesRefs {
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.sourceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_categoriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LiveChannelsTable, List<LiveChannel>>
  _liveChannelsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.liveChannels,
    aliasName: $_aliasNameGenerator(db.sources.id, db.liveChannels.sourceId),
  );

  $$LiveChannelsTableProcessedTableManager get liveChannelsRefs {
    final manager = $$LiveChannelsTableTableManager(
      $_db,
      $_db.liveChannels,
    ).filter((f) => f.sourceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_liveChannelsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MoviesTable, List<Movie>> _moviesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.movies,
    aliasName: $_aliasNameGenerator(db.sources.id, db.movies.sourceId),
  );

  $$MoviesTableProcessedTableManager get moviesRefs {
    final manager = $$MoviesTableTableManager(
      $_db,
      $_db.movies,
    ).filter((f) => f.sourceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_moviesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SeriesItemsTable, List<SeriesItem>>
  _seriesItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.seriesItems,
    aliasName: $_aliasNameGenerator(db.sources.id, db.seriesItems.sourceId),
  );

  $$SeriesItemsTableProcessedTableManager get seriesItemsRefs {
    final manager = $$SeriesItemsTableTableManager(
      $_db,
      $_db.seriesItems,
    ).filter((f) => f.sourceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_seriesItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EpgProgrammesTable, List<EpgProgramme>>
  _epgProgrammesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.epgProgrammes,
    aliasName: $_aliasNameGenerator(db.sources.id, db.epgProgrammes.sourceId),
  );

  $$EpgProgrammesTableProcessedTableManager get epgProgrammesRefs {
    final manager = $$EpgProgrammesTableTableManager(
      $_db,
      $_db.epgProgrammes,
    ).filter((f) => f.sourceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_epgProgrammesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FavoritesTable, List<Favorite>>
  _favoritesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.favorites,
    aliasName: $_aliasNameGenerator(db.sources.id, db.favorites.sourceId),
  );

  $$FavoritesTableProcessedTableManager get favoritesRefs {
    final manager = $$FavoritesTableTableManager(
      $_db,
      $_db.favorites,
    ).filter((f) => f.sourceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_favoritesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PlaybackPositionsTable, List<PlaybackPosition>>
  _playbackPositionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.playbackPositions,
        aliasName: $_aliasNameGenerator(
          db.sources.id,
          db.playbackPositions.sourceId,
        ),
      );

  $$PlaybackPositionsTableProcessedTableManager get playbackPositionsRefs {
    final manager = $$PlaybackPositionsTableTableManager(
      $_db,
      $_db.playbackPositions,
    ).filter((f) => f.sourceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _playbackPositionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SyncTombstonesTable, List<SyncTombstone>>
  _syncTombstonesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.syncTombstones,
    aliasName: $_aliasNameGenerator(db.sources.id, db.syncTombstones.sourceId),
  );

  $$SyncTombstonesTableProcessedTableManager get syncTombstonesRefs {
    final manager = $$SyncTombstonesTableTableManager(
      $_db,
      $_db.syncTombstones,
    ).filter((f) => f.sourceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_syncTombstonesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DownloadsTable, List<DownloadItem>>
  _downloadsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.downloads,
    aliasName: $_aliasNameGenerator(db.sources.id, db.downloads.sourceId),
  );

  $$DownloadsTableProcessedTableManager get downloadsRefs {
    final manager = $$DownloadsTableTableManager(
      $_db,
      $_db.downloads,
    ).filter((f) => f.sourceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_downloadsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SourcesTableFilterComposer
    extends Composer<_$AppDatabase, $SourcesTable> {
  $$SourcesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SourceType, SourceType, String>
  get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get serverUrl => $composableBuilder(
    column: $table.serverUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get password => $composableBuilder(
    column: $table.password,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get epgUrl => $composableBuilder(
    column: $table.epgUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> categoriesRefs(
    Expression<bool> Function($$CategoriesTableFilterComposer f) f,
  ) {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> liveChannelsRefs(
    Expression<bool> Function($$LiveChannelsTableFilterComposer f) f,
  ) {
    final $$LiveChannelsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.liveChannels,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LiveChannelsTableFilterComposer(
            $db: $db,
            $table: $db.liveChannels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> moviesRefs(
    Expression<bool> Function($$MoviesTableFilterComposer f) f,
  ) {
    final $$MoviesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.movies,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MoviesTableFilterComposer(
            $db: $db,
            $table: $db.movies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> seriesItemsRefs(
    Expression<bool> Function($$SeriesItemsTableFilterComposer f) f,
  ) {
    final $$SeriesItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.seriesItems,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SeriesItemsTableFilterComposer(
            $db: $db,
            $table: $db.seriesItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> epgProgrammesRefs(
    Expression<bool> Function($$EpgProgrammesTableFilterComposer f) f,
  ) {
    final $$EpgProgrammesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.epgProgrammes,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EpgProgrammesTableFilterComposer(
            $db: $db,
            $table: $db.epgProgrammes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> favoritesRefs(
    Expression<bool> Function($$FavoritesTableFilterComposer f) f,
  ) {
    final $$FavoritesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.favorites,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoritesTableFilterComposer(
            $db: $db,
            $table: $db.favorites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> playbackPositionsRefs(
    Expression<bool> Function($$PlaybackPositionsTableFilterComposer f) f,
  ) {
    final $$PlaybackPositionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playbackPositions,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaybackPositionsTableFilterComposer(
            $db: $db,
            $table: $db.playbackPositions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> syncTombstonesRefs(
    Expression<bool> Function($$SyncTombstonesTableFilterComposer f) f,
  ) {
    final $$SyncTombstonesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syncTombstones,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncTombstonesTableFilterComposer(
            $db: $db,
            $table: $db.syncTombstones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> downloadsRefs(
    Expression<bool> Function($$DownloadsTableFilterComposer f) f,
  ) {
    final $$DownloadsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.downloads,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DownloadsTableFilterComposer(
            $db: $db,
            $table: $db.downloads,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SourcesTableOrderingComposer
    extends Composer<_$AppDatabase, $SourcesTable> {
  $$SourcesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverUrl => $composableBuilder(
    column: $table.serverUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get password => $composableBuilder(
    column: $table.password,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get epgUrl => $composableBuilder(
    column: $table.epgUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SourcesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SourcesTable> {
  $$SourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SourceType, String> get sourceType =>
      $composableBuilder(
        column: $table.sourceType,
        builder: (column) => column,
      );

  GeneratedColumn<String> get serverUrl =>
      $composableBuilder(column: $table.serverUrl, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get password =>
      $composableBuilder(column: $table.password, builder: (column) => column);

  GeneratedColumn<String> get epgUrl =>
      $composableBuilder(column: $table.epgUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => column,
  );

  Expression<T> categoriesRefs<T extends Object>(
    Expression<T> Function($$CategoriesTableAnnotationComposer a) f,
  ) {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> liveChannelsRefs<T extends Object>(
    Expression<T> Function($$LiveChannelsTableAnnotationComposer a) f,
  ) {
    final $$LiveChannelsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.liveChannels,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LiveChannelsTableAnnotationComposer(
            $db: $db,
            $table: $db.liveChannels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> moviesRefs<T extends Object>(
    Expression<T> Function($$MoviesTableAnnotationComposer a) f,
  ) {
    final $$MoviesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.movies,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MoviesTableAnnotationComposer(
            $db: $db,
            $table: $db.movies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> seriesItemsRefs<T extends Object>(
    Expression<T> Function($$SeriesItemsTableAnnotationComposer a) f,
  ) {
    final $$SeriesItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.seriesItems,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SeriesItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.seriesItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> epgProgrammesRefs<T extends Object>(
    Expression<T> Function($$EpgProgrammesTableAnnotationComposer a) f,
  ) {
    final $$EpgProgrammesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.epgProgrammes,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EpgProgrammesTableAnnotationComposer(
            $db: $db,
            $table: $db.epgProgrammes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> favoritesRefs<T extends Object>(
    Expression<T> Function($$FavoritesTableAnnotationComposer a) f,
  ) {
    final $$FavoritesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.favorites,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoritesTableAnnotationComposer(
            $db: $db,
            $table: $db.favorites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> playbackPositionsRefs<T extends Object>(
    Expression<T> Function($$PlaybackPositionsTableAnnotationComposer a) f,
  ) {
    final $$PlaybackPositionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.playbackPositions,
          getReferencedColumn: (t) => t.sourceId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PlaybackPositionsTableAnnotationComposer(
                $db: $db,
                $table: $db.playbackPositions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> syncTombstonesRefs<T extends Object>(
    Expression<T> Function($$SyncTombstonesTableAnnotationComposer a) f,
  ) {
    final $$SyncTombstonesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syncTombstones,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncTombstonesTableAnnotationComposer(
            $db: $db,
            $table: $db.syncTombstones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> downloadsRefs<T extends Object>(
    Expression<T> Function($$DownloadsTableAnnotationComposer a) f,
  ) {
    final $$DownloadsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.downloads,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DownloadsTableAnnotationComposer(
            $db: $db,
            $table: $db.downloads,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SourcesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SourcesTable,
          Source,
          $$SourcesTableFilterComposer,
          $$SourcesTableOrderingComposer,
          $$SourcesTableAnnotationComposer,
          $$SourcesTableCreateCompanionBuilder,
          $$SourcesTableUpdateCompanionBuilder,
          (Source, $$SourcesTableReferences),
          Source,
          PrefetchHooks Function({
            bool categoriesRefs,
            bool liveChannelsRefs,
            bool moviesRefs,
            bool seriesItemsRefs,
            bool epgProgrammesRefs,
            bool favoritesRefs,
            bool playbackPositionsRefs,
            bool syncTombstonesRefs,
            bool downloadsRefs,
          })
        > {
  $$SourcesTableTableManager(_$AppDatabase db, $SourcesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SourcesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<SourceType> sourceType = const Value.absent(),
                Value<String> serverUrl = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String> password = const Value.absent(),
                Value<String?> epgUrl = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
              }) => SourcesCompanion(
                id: id,
                name: name,
                sourceType: sourceType,
                serverUrl: serverUrl,
                username: username,
                password: password,
                epgUrl: epgUrl,
                lastSyncAt: lastSyncAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<SourceType> sourceType = const Value.absent(),
                required String serverUrl,
                required String username,
                required String password,
                Value<String?> epgUrl = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
              }) => SourcesCompanion.insert(
                id: id,
                name: name,
                sourceType: sourceType,
                serverUrl: serverUrl,
                username: username,
                password: password,
                epgUrl: epgUrl,
                lastSyncAt: lastSyncAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SourcesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                categoriesRefs = false,
                liveChannelsRefs = false,
                moviesRefs = false,
                seriesItemsRefs = false,
                epgProgrammesRefs = false,
                favoritesRefs = false,
                playbackPositionsRefs = false,
                syncTombstonesRefs = false,
                downloadsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (categoriesRefs) db.categories,
                    if (liveChannelsRefs) db.liveChannels,
                    if (moviesRefs) db.movies,
                    if (seriesItemsRefs) db.seriesItems,
                    if (epgProgrammesRefs) db.epgProgrammes,
                    if (favoritesRefs) db.favorites,
                    if (playbackPositionsRefs) db.playbackPositions,
                    if (syncTombstonesRefs) db.syncTombstones,
                    if (downloadsRefs) db.downloads,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (categoriesRefs)
                        await $_getPrefetchedData<
                          Source,
                          $SourcesTable,
                          Category
                        >(
                          currentTable: table,
                          referencedTable: $$SourcesTableReferences
                              ._categoriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SourcesTableReferences(
                                db,
                                table,
                                p0,
                              ).categoriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sourceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (liveChannelsRefs)
                        await $_getPrefetchedData<
                          Source,
                          $SourcesTable,
                          LiveChannel
                        >(
                          currentTable: table,
                          referencedTable: $$SourcesTableReferences
                              ._liveChannelsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SourcesTableReferences(
                                db,
                                table,
                                p0,
                              ).liveChannelsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sourceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (moviesRefs)
                        await $_getPrefetchedData<Source, $SourcesTable, Movie>(
                          currentTable: table,
                          referencedTable: $$SourcesTableReferences
                              ._moviesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SourcesTableReferences(
                                db,
                                table,
                                p0,
                              ).moviesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sourceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (seriesItemsRefs)
                        await $_getPrefetchedData<
                          Source,
                          $SourcesTable,
                          SeriesItem
                        >(
                          currentTable: table,
                          referencedTable: $$SourcesTableReferences
                              ._seriesItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SourcesTableReferences(
                                db,
                                table,
                                p0,
                              ).seriesItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sourceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (epgProgrammesRefs)
                        await $_getPrefetchedData<
                          Source,
                          $SourcesTable,
                          EpgProgramme
                        >(
                          currentTable: table,
                          referencedTable: $$SourcesTableReferences
                              ._epgProgrammesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SourcesTableReferences(
                                db,
                                table,
                                p0,
                              ).epgProgrammesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sourceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (favoritesRefs)
                        await $_getPrefetchedData<
                          Source,
                          $SourcesTable,
                          Favorite
                        >(
                          currentTable: table,
                          referencedTable: $$SourcesTableReferences
                              ._favoritesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SourcesTableReferences(
                                db,
                                table,
                                p0,
                              ).favoritesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sourceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (playbackPositionsRefs)
                        await $_getPrefetchedData<
                          Source,
                          $SourcesTable,
                          PlaybackPosition
                        >(
                          currentTable: table,
                          referencedTable: $$SourcesTableReferences
                              ._playbackPositionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SourcesTableReferences(
                                db,
                                table,
                                p0,
                              ).playbackPositionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sourceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (syncTombstonesRefs)
                        await $_getPrefetchedData<
                          Source,
                          $SourcesTable,
                          SyncTombstone
                        >(
                          currentTable: table,
                          referencedTable: $$SourcesTableReferences
                              ._syncTombstonesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SourcesTableReferences(
                                db,
                                table,
                                p0,
                              ).syncTombstonesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sourceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (downloadsRefs)
                        await $_getPrefetchedData<
                          Source,
                          $SourcesTable,
                          DownloadItem
                        >(
                          currentTable: table,
                          referencedTable: $$SourcesTableReferences
                              ._downloadsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SourcesTableReferences(
                                db,
                                table,
                                p0,
                              ).downloadsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sourceId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SourcesTable,
      Source,
      $$SourcesTableFilterComposer,
      $$SourcesTableOrderingComposer,
      $$SourcesTableAnnotationComposer,
      $$SourcesTableCreateCompanionBuilder,
      $$SourcesTableUpdateCompanionBuilder,
      (Source, $$SourcesTableReferences),
      Source,
      PrefetchHooks Function({
        bool categoriesRefs,
        bool liveChannelsRefs,
        bool moviesRefs,
        bool seriesItemsRefs,
        bool epgProgrammesRefs,
        bool favoritesRefs,
        bool playbackPositionsRefs,
        bool syncTombstonesRefs,
        bool downloadsRefs,
      })
    >;
typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({
      required int sourceId,
      required CatalogKind kind,
      required String categoryId,
      required String name,
      Value<int> rowid,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<int> sourceId,
      Value<CatalogKind> kind,
      Value<String> categoryId,
      Value<String> name,
      Value<int> rowid,
    });

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, Category> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SourcesTable _sourceIdTable(_$AppDatabase db) => db.sources
      .createAlias($_aliasNameGenerator(db.categories.sourceId, db.sources.id));

  $$SourcesTableProcessedTableManager get sourceId {
    final $_column = $_itemColumn<int>('source_id')!;

    final manager = $$SourcesTableTableManager(
      $_db,
      $_db.sources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<CatalogKind, CatalogKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  $$SourcesTableFilterComposer get sourceId {
    final $$SourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableFilterComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  $$SourcesTableOrderingComposer get sourceId {
    final $$SourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableOrderingComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<CatalogKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  $$SourcesTableAnnotationComposer get sourceId {
    final $$SourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          Category,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (Category, $$CategoriesTableReferences),
          Category,
          PrefetchHooks Function({bool sourceId})
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> sourceId = const Value.absent(),
                Value<CatalogKind> kind = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                sourceId: sourceId,
                kind: kind,
                categoryId: categoryId,
                name: name,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int sourceId,
                required CatalogKind kind,
                required String categoryId,
                required String name,
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                sourceId: sourceId,
                kind: kind,
                categoryId: categoryId,
                name: name,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sourceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sourceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sourceId,
                                referencedTable: $$CategoriesTableReferences
                                    ._sourceIdTable(db),
                                referencedColumn: $$CategoriesTableReferences
                                    ._sourceIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      Category,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (Category, $$CategoriesTableReferences),
      Category,
      PrefetchHooks Function({bool sourceId})
    >;
typedef $$LiveChannelsTableCreateCompanionBuilder =
    LiveChannelsCompanion Function({
      required int sourceId,
      required int streamId,
      required String name,
      Value<String?> icon,
      Value<String?> categoryId,
      Value<String?> epgChannelId,
      Value<int?> channelNumber,
      Value<String?> streamUrl,
      Value<int> rowid,
    });
typedef $$LiveChannelsTableUpdateCompanionBuilder =
    LiveChannelsCompanion Function({
      Value<int> sourceId,
      Value<int> streamId,
      Value<String> name,
      Value<String?> icon,
      Value<String?> categoryId,
      Value<String?> epgChannelId,
      Value<int?> channelNumber,
      Value<String?> streamUrl,
      Value<int> rowid,
    });

final class $$LiveChannelsTableReferences
    extends BaseReferences<_$AppDatabase, $LiveChannelsTable, LiveChannel> {
  $$LiveChannelsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SourcesTable _sourceIdTable(_$AppDatabase db) =>
      db.sources.createAlias(
        $_aliasNameGenerator(db.liveChannels.sourceId, db.sources.id),
      );

  $$SourcesTableProcessedTableManager get sourceId {
    final $_column = $_itemColumn<int>('source_id')!;

    final manager = $$SourcesTableTableManager(
      $_db,
      $_db.sources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LiveChannelsTableFilterComposer
    extends Composer<_$AppDatabase, $LiveChannelsTable> {
  $$LiveChannelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get streamId => $composableBuilder(
    column: $table.streamId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get epgChannelId => $composableBuilder(
    column: $table.epgChannelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get channelNumber => $composableBuilder(
    column: $table.channelNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get streamUrl => $composableBuilder(
    column: $table.streamUrl,
    builder: (column) => ColumnFilters(column),
  );

  $$SourcesTableFilterComposer get sourceId {
    final $$SourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableFilterComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LiveChannelsTableOrderingComposer
    extends Composer<_$AppDatabase, $LiveChannelsTable> {
  $$LiveChannelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get streamId => $composableBuilder(
    column: $table.streamId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get epgChannelId => $composableBuilder(
    column: $table.epgChannelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get channelNumber => $composableBuilder(
    column: $table.channelNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get streamUrl => $composableBuilder(
    column: $table.streamUrl,
    builder: (column) => ColumnOrderings(column),
  );

  $$SourcesTableOrderingComposer get sourceId {
    final $$SourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableOrderingComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LiveChannelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LiveChannelsTable> {
  $$LiveChannelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get streamId =>
      $composableBuilder(column: $table.streamId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get epgChannelId => $composableBuilder(
    column: $table.epgChannelId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get channelNumber => $composableBuilder(
    column: $table.channelNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get streamUrl =>
      $composableBuilder(column: $table.streamUrl, builder: (column) => column);

  $$SourcesTableAnnotationComposer get sourceId {
    final $$SourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LiveChannelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LiveChannelsTable,
          LiveChannel,
          $$LiveChannelsTableFilterComposer,
          $$LiveChannelsTableOrderingComposer,
          $$LiveChannelsTableAnnotationComposer,
          $$LiveChannelsTableCreateCompanionBuilder,
          $$LiveChannelsTableUpdateCompanionBuilder,
          (LiveChannel, $$LiveChannelsTableReferences),
          LiveChannel,
          PrefetchHooks Function({bool sourceId})
        > {
  $$LiveChannelsTableTableManager(_$AppDatabase db, $LiveChannelsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LiveChannelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LiveChannelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LiveChannelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> sourceId = const Value.absent(),
                Value<int> streamId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> epgChannelId = const Value.absent(),
                Value<int?> channelNumber = const Value.absent(),
                Value<String?> streamUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LiveChannelsCompanion(
                sourceId: sourceId,
                streamId: streamId,
                name: name,
                icon: icon,
                categoryId: categoryId,
                epgChannelId: epgChannelId,
                channelNumber: channelNumber,
                streamUrl: streamUrl,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int sourceId,
                required int streamId,
                required String name,
                Value<String?> icon = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> epgChannelId = const Value.absent(),
                Value<int?> channelNumber = const Value.absent(),
                Value<String?> streamUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LiveChannelsCompanion.insert(
                sourceId: sourceId,
                streamId: streamId,
                name: name,
                icon: icon,
                categoryId: categoryId,
                epgChannelId: epgChannelId,
                channelNumber: channelNumber,
                streamUrl: streamUrl,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LiveChannelsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sourceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sourceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sourceId,
                                referencedTable: $$LiveChannelsTableReferences
                                    ._sourceIdTable(db),
                                referencedColumn: $$LiveChannelsTableReferences
                                    ._sourceIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LiveChannelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LiveChannelsTable,
      LiveChannel,
      $$LiveChannelsTableFilterComposer,
      $$LiveChannelsTableOrderingComposer,
      $$LiveChannelsTableAnnotationComposer,
      $$LiveChannelsTableCreateCompanionBuilder,
      $$LiveChannelsTableUpdateCompanionBuilder,
      (LiveChannel, $$LiveChannelsTableReferences),
      LiveChannel,
      PrefetchHooks Function({bool sourceId})
    >;
typedef $$MoviesTableCreateCompanionBuilder =
    MoviesCompanion Function({
      required int sourceId,
      required int streamId,
      required String name,
      Value<String?> icon,
      Value<String?> categoryId,
      Value<String?> containerExtension,
      Value<double?> rating,
      Value<DateTime?> addedAt,
      Value<String?> streamUrl,
      Value<int> rowid,
    });
typedef $$MoviesTableUpdateCompanionBuilder =
    MoviesCompanion Function({
      Value<int> sourceId,
      Value<int> streamId,
      Value<String> name,
      Value<String?> icon,
      Value<String?> categoryId,
      Value<String?> containerExtension,
      Value<double?> rating,
      Value<DateTime?> addedAt,
      Value<String?> streamUrl,
      Value<int> rowid,
    });

final class $$MoviesTableReferences
    extends BaseReferences<_$AppDatabase, $MoviesTable, Movie> {
  $$MoviesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SourcesTable _sourceIdTable(_$AppDatabase db) => db.sources
      .createAlias($_aliasNameGenerator(db.movies.sourceId, db.sources.id));

  $$SourcesTableProcessedTableManager get sourceId {
    final $_column = $_itemColumn<int>('source_id')!;

    final manager = $$SourcesTableTableManager(
      $_db,
      $_db.sources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MoviesTableFilterComposer
    extends Composer<_$AppDatabase, $MoviesTable> {
  $$MoviesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get streamId => $composableBuilder(
    column: $table.streamId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get containerExtension => $composableBuilder(
    column: $table.containerExtension,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get streamUrl => $composableBuilder(
    column: $table.streamUrl,
    builder: (column) => ColumnFilters(column),
  );

  $$SourcesTableFilterComposer get sourceId {
    final $$SourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableFilterComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MoviesTableOrderingComposer
    extends Composer<_$AppDatabase, $MoviesTable> {
  $$MoviesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get streamId => $composableBuilder(
    column: $table.streamId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get containerExtension => $composableBuilder(
    column: $table.containerExtension,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get streamUrl => $composableBuilder(
    column: $table.streamUrl,
    builder: (column) => ColumnOrderings(column),
  );

  $$SourcesTableOrderingComposer get sourceId {
    final $$SourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableOrderingComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MoviesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MoviesTable> {
  $$MoviesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get streamId =>
      $composableBuilder(column: $table.streamId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get containerExtension => $composableBuilder(
    column: $table.containerExtension,
    builder: (column) => column,
  );

  GeneratedColumn<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<String> get streamUrl =>
      $composableBuilder(column: $table.streamUrl, builder: (column) => column);

  $$SourcesTableAnnotationComposer get sourceId {
    final $$SourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MoviesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MoviesTable,
          Movie,
          $$MoviesTableFilterComposer,
          $$MoviesTableOrderingComposer,
          $$MoviesTableAnnotationComposer,
          $$MoviesTableCreateCompanionBuilder,
          $$MoviesTableUpdateCompanionBuilder,
          (Movie, $$MoviesTableReferences),
          Movie,
          PrefetchHooks Function({bool sourceId})
        > {
  $$MoviesTableTableManager(_$AppDatabase db, $MoviesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MoviesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MoviesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MoviesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> sourceId = const Value.absent(),
                Value<int> streamId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> containerExtension = const Value.absent(),
                Value<double?> rating = const Value.absent(),
                Value<DateTime?> addedAt = const Value.absent(),
                Value<String?> streamUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MoviesCompanion(
                sourceId: sourceId,
                streamId: streamId,
                name: name,
                icon: icon,
                categoryId: categoryId,
                containerExtension: containerExtension,
                rating: rating,
                addedAt: addedAt,
                streamUrl: streamUrl,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int sourceId,
                required int streamId,
                required String name,
                Value<String?> icon = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> containerExtension = const Value.absent(),
                Value<double?> rating = const Value.absent(),
                Value<DateTime?> addedAt = const Value.absent(),
                Value<String?> streamUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MoviesCompanion.insert(
                sourceId: sourceId,
                streamId: streamId,
                name: name,
                icon: icon,
                categoryId: categoryId,
                containerExtension: containerExtension,
                rating: rating,
                addedAt: addedAt,
                streamUrl: streamUrl,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$MoviesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({sourceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sourceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sourceId,
                                referencedTable: $$MoviesTableReferences
                                    ._sourceIdTable(db),
                                referencedColumn: $$MoviesTableReferences
                                    ._sourceIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MoviesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MoviesTable,
      Movie,
      $$MoviesTableFilterComposer,
      $$MoviesTableOrderingComposer,
      $$MoviesTableAnnotationComposer,
      $$MoviesTableCreateCompanionBuilder,
      $$MoviesTableUpdateCompanionBuilder,
      (Movie, $$MoviesTableReferences),
      Movie,
      PrefetchHooks Function({bool sourceId})
    >;
typedef $$SeriesItemsTableCreateCompanionBuilder =
    SeriesItemsCompanion Function({
      required int sourceId,
      required int seriesId,
      required String name,
      Value<String?> cover,
      Value<String?> categoryId,
      Value<String?> plot,
      Value<double?> rating,
      Value<DateTime?> lastModifiedAt,
      Value<int> rowid,
    });
typedef $$SeriesItemsTableUpdateCompanionBuilder =
    SeriesItemsCompanion Function({
      Value<int> sourceId,
      Value<int> seriesId,
      Value<String> name,
      Value<String?> cover,
      Value<String?> categoryId,
      Value<String?> plot,
      Value<double?> rating,
      Value<DateTime?> lastModifiedAt,
      Value<int> rowid,
    });

final class $$SeriesItemsTableReferences
    extends BaseReferences<_$AppDatabase, $SeriesItemsTable, SeriesItem> {
  $$SeriesItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SourcesTable _sourceIdTable(_$AppDatabase db) =>
      db.sources.createAlias(
        $_aliasNameGenerator(db.seriesItems.sourceId, db.sources.id),
      );

  $$SourcesTableProcessedTableManager get sourceId {
    final $_column = $_itemColumn<int>('source_id')!;

    final manager = $$SourcesTableTableManager(
      $_db,
      $_db.sources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SeriesItemsTableFilterComposer
    extends Composer<_$AppDatabase, $SeriesItemsTable> {
  $$SeriesItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cover => $composableBuilder(
    column: $table.cover,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plot => $composableBuilder(
    column: $table.plot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModifiedAt => $composableBuilder(
    column: $table.lastModifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SourcesTableFilterComposer get sourceId {
    final $$SourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableFilterComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SeriesItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $SeriesItemsTable> {
  $$SeriesItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cover => $composableBuilder(
    column: $table.cover,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plot => $composableBuilder(
    column: $table.plot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModifiedAt => $composableBuilder(
    column: $table.lastModifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SourcesTableOrderingComposer get sourceId {
    final $$SourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableOrderingComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SeriesItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SeriesItemsTable> {
  $$SeriesItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seriesId =>
      $composableBuilder(column: $table.seriesId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get cover =>
      $composableBuilder(column: $table.cover, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get plot =>
      $composableBuilder(column: $table.plot, builder: (column) => column);

  GeneratedColumn<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModifiedAt => $composableBuilder(
    column: $table.lastModifiedAt,
    builder: (column) => column,
  );

  $$SourcesTableAnnotationComposer get sourceId {
    final $$SourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SeriesItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SeriesItemsTable,
          SeriesItem,
          $$SeriesItemsTableFilterComposer,
          $$SeriesItemsTableOrderingComposer,
          $$SeriesItemsTableAnnotationComposer,
          $$SeriesItemsTableCreateCompanionBuilder,
          $$SeriesItemsTableUpdateCompanionBuilder,
          (SeriesItem, $$SeriesItemsTableReferences),
          SeriesItem,
          PrefetchHooks Function({bool sourceId})
        > {
  $$SeriesItemsTableTableManager(_$AppDatabase db, $SeriesItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SeriesItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SeriesItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SeriesItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> sourceId = const Value.absent(),
                Value<int> seriesId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> cover = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> plot = const Value.absent(),
                Value<double?> rating = const Value.absent(),
                Value<DateTime?> lastModifiedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SeriesItemsCompanion(
                sourceId: sourceId,
                seriesId: seriesId,
                name: name,
                cover: cover,
                categoryId: categoryId,
                plot: plot,
                rating: rating,
                lastModifiedAt: lastModifiedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int sourceId,
                required int seriesId,
                required String name,
                Value<String?> cover = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> plot = const Value.absent(),
                Value<double?> rating = const Value.absent(),
                Value<DateTime?> lastModifiedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SeriesItemsCompanion.insert(
                sourceId: sourceId,
                seriesId: seriesId,
                name: name,
                cover: cover,
                categoryId: categoryId,
                plot: plot,
                rating: rating,
                lastModifiedAt: lastModifiedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SeriesItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sourceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sourceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sourceId,
                                referencedTable: $$SeriesItemsTableReferences
                                    ._sourceIdTable(db),
                                referencedColumn: $$SeriesItemsTableReferences
                                    ._sourceIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SeriesItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SeriesItemsTable,
      SeriesItem,
      $$SeriesItemsTableFilterComposer,
      $$SeriesItemsTableOrderingComposer,
      $$SeriesItemsTableAnnotationComposer,
      $$SeriesItemsTableCreateCompanionBuilder,
      $$SeriesItemsTableUpdateCompanionBuilder,
      (SeriesItem, $$SeriesItemsTableReferences),
      SeriesItem,
      PrefetchHooks Function({bool sourceId})
    >;
typedef $$EpgProgrammesTableCreateCompanionBuilder =
    EpgProgrammesCompanion Function({
      required int sourceId,
      required String channelId,
      required DateTime startAt,
      required DateTime endAt,
      required String title,
      Value<String?> description,
      Value<int> rowid,
    });
typedef $$EpgProgrammesTableUpdateCompanionBuilder =
    EpgProgrammesCompanion Function({
      Value<int> sourceId,
      Value<String> channelId,
      Value<DateTime> startAt,
      Value<DateTime> endAt,
      Value<String> title,
      Value<String?> description,
      Value<int> rowid,
    });

final class $$EpgProgrammesTableReferences
    extends BaseReferences<_$AppDatabase, $EpgProgrammesTable, EpgProgramme> {
  $$EpgProgrammesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SourcesTable _sourceIdTable(_$AppDatabase db) =>
      db.sources.createAlias(
        $_aliasNameGenerator(db.epgProgrammes.sourceId, db.sources.id),
      );

  $$SourcesTableProcessedTableManager get sourceId {
    final $_column = $_itemColumn<int>('source_id')!;

    final manager = $$SourcesTableTableManager(
      $_db,
      $_db.sources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EpgProgrammesTableFilterComposer
    extends Composer<_$AppDatabase, $EpgProgrammesTable> {
  $$EpgProgrammesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endAt => $composableBuilder(
    column: $table.endAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  $$SourcesTableFilterComposer get sourceId {
    final $$SourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableFilterComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EpgProgrammesTableOrderingComposer
    extends Composer<_$AppDatabase, $EpgProgrammesTable> {
  $$EpgProgrammesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endAt => $composableBuilder(
    column: $table.endAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  $$SourcesTableOrderingComposer get sourceId {
    final $$SourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableOrderingComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EpgProgrammesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EpgProgrammesTable> {
  $$EpgProgrammesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get channelId =>
      $composableBuilder(column: $table.channelId, builder: (column) => column);

  GeneratedColumn<DateTime> get startAt =>
      $composableBuilder(column: $table.startAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endAt =>
      $composableBuilder(column: $table.endAt, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  $$SourcesTableAnnotationComposer get sourceId {
    final $$SourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EpgProgrammesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EpgProgrammesTable,
          EpgProgramme,
          $$EpgProgrammesTableFilterComposer,
          $$EpgProgrammesTableOrderingComposer,
          $$EpgProgrammesTableAnnotationComposer,
          $$EpgProgrammesTableCreateCompanionBuilder,
          $$EpgProgrammesTableUpdateCompanionBuilder,
          (EpgProgramme, $$EpgProgrammesTableReferences),
          EpgProgramme,
          PrefetchHooks Function({bool sourceId})
        > {
  $$EpgProgrammesTableTableManager(_$AppDatabase db, $EpgProgrammesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EpgProgrammesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EpgProgrammesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EpgProgrammesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> sourceId = const Value.absent(),
                Value<String> channelId = const Value.absent(),
                Value<DateTime> startAt = const Value.absent(),
                Value<DateTime> endAt = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EpgProgrammesCompanion(
                sourceId: sourceId,
                channelId: channelId,
                startAt: startAt,
                endAt: endAt,
                title: title,
                description: description,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int sourceId,
                required String channelId,
                required DateTime startAt,
                required DateTime endAt,
                required String title,
                Value<String?> description = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EpgProgrammesCompanion.insert(
                sourceId: sourceId,
                channelId: channelId,
                startAt: startAt,
                endAt: endAt,
                title: title,
                description: description,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EpgProgrammesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sourceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sourceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sourceId,
                                referencedTable: $$EpgProgrammesTableReferences
                                    ._sourceIdTable(db),
                                referencedColumn: $$EpgProgrammesTableReferences
                                    ._sourceIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$EpgProgrammesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EpgProgrammesTable,
      EpgProgramme,
      $$EpgProgrammesTableFilterComposer,
      $$EpgProgrammesTableOrderingComposer,
      $$EpgProgrammesTableAnnotationComposer,
      $$EpgProgrammesTableCreateCompanionBuilder,
      $$EpgProgrammesTableUpdateCompanionBuilder,
      (EpgProgramme, $$EpgProgrammesTableReferences),
      EpgProgramme,
      PrefetchHooks Function({bool sourceId})
    >;
typedef $$FavoritesTableCreateCompanionBuilder =
    FavoritesCompanion Function({
      required int sourceId,
      required CatalogKind kind,
      required int itemId,
      required String name,
      Value<String?> imageUrl,
      required DateTime addedAt,
      Value<int> rowid,
    });
typedef $$FavoritesTableUpdateCompanionBuilder =
    FavoritesCompanion Function({
      Value<int> sourceId,
      Value<CatalogKind> kind,
      Value<int> itemId,
      Value<String> name,
      Value<String?> imageUrl,
      Value<DateTime> addedAt,
      Value<int> rowid,
    });

final class $$FavoritesTableReferences
    extends BaseReferences<_$AppDatabase, $FavoritesTable, Favorite> {
  $$FavoritesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SourcesTable _sourceIdTable(_$AppDatabase db) => db.sources
      .createAlias($_aliasNameGenerator(db.favorites.sourceId, db.sources.id));

  $$SourcesTableProcessedTableManager get sourceId {
    final $_column = $_itemColumn<int>('source_id')!;

    final manager = $$SourcesTableTableManager(
      $_db,
      $_db.sources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FavoritesTableFilterComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<CatalogKind, CatalogKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SourcesTableFilterComposer get sourceId {
    final $$SourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableFilterComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoritesTableOrderingComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SourcesTableOrderingComposer get sourceId {
    final $$SourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableOrderingComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoritesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<CatalogKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  $$SourcesTableAnnotationComposer get sourceId {
    final $$SourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoritesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FavoritesTable,
          Favorite,
          $$FavoritesTableFilterComposer,
          $$FavoritesTableOrderingComposer,
          $$FavoritesTableAnnotationComposer,
          $$FavoritesTableCreateCompanionBuilder,
          $$FavoritesTableUpdateCompanionBuilder,
          (Favorite, $$FavoritesTableReferences),
          Favorite,
          PrefetchHooks Function({bool sourceId})
        > {
  $$FavoritesTableTableManager(_$AppDatabase db, $FavoritesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> sourceId = const Value.absent(),
                Value<CatalogKind> kind = const Value.absent(),
                Value<int> itemId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FavoritesCompanion(
                sourceId: sourceId,
                kind: kind,
                itemId: itemId,
                name: name,
                imageUrl: imageUrl,
                addedAt: addedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int sourceId,
                required CatalogKind kind,
                required int itemId,
                required String name,
                Value<String?> imageUrl = const Value.absent(),
                required DateTime addedAt,
                Value<int> rowid = const Value.absent(),
              }) => FavoritesCompanion.insert(
                sourceId: sourceId,
                kind: kind,
                itemId: itemId,
                name: name,
                imageUrl: imageUrl,
                addedAt: addedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FavoritesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sourceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sourceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sourceId,
                                referencedTable: $$FavoritesTableReferences
                                    ._sourceIdTable(db),
                                referencedColumn: $$FavoritesTableReferences
                                    ._sourceIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FavoritesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FavoritesTable,
      Favorite,
      $$FavoritesTableFilterComposer,
      $$FavoritesTableOrderingComposer,
      $$FavoritesTableAnnotationComposer,
      $$FavoritesTableCreateCompanionBuilder,
      $$FavoritesTableUpdateCompanionBuilder,
      (Favorite, $$FavoritesTableReferences),
      Favorite,
      PrefetchHooks Function({bool sourceId})
    >;
typedef $$PlaybackPositionsTableCreateCompanionBuilder =
    PlaybackPositionsCompanion Function({
      required int sourceId,
      required WatchKind kind,
      required int itemId,
      Value<int?> seriesId,
      required String title,
      Value<String> subtitle,
      Value<String?> imageUrl,
      Value<String?> containerExtension,
      required int positionSecs,
      required int durationSecs,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$PlaybackPositionsTableUpdateCompanionBuilder =
    PlaybackPositionsCompanion Function({
      Value<int> sourceId,
      Value<WatchKind> kind,
      Value<int> itemId,
      Value<int?> seriesId,
      Value<String> title,
      Value<String> subtitle,
      Value<String?> imageUrl,
      Value<String?> containerExtension,
      Value<int> positionSecs,
      Value<int> durationSecs,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$PlaybackPositionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PlaybackPositionsTable,
          PlaybackPosition
        > {
  $$PlaybackPositionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SourcesTable _sourceIdTable(_$AppDatabase db) =>
      db.sources.createAlias(
        $_aliasNameGenerator(db.playbackPositions.sourceId, db.sources.id),
      );

  $$SourcesTableProcessedTableManager get sourceId {
    final $_column = $_itemColumn<int>('source_id')!;

    final manager = $$SourcesTableTableManager(
      $_db,
      $_db.sources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlaybackPositionsTableFilterComposer
    extends Composer<_$AppDatabase, $PlaybackPositionsTable> {
  $$PlaybackPositionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<WatchKind, WatchKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get containerExtension => $composableBuilder(
    column: $table.containerExtension,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get positionSecs => $composableBuilder(
    column: $table.positionSecs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSecs => $composableBuilder(
    column: $table.durationSecs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SourcesTableFilterComposer get sourceId {
    final $$SourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableFilterComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaybackPositionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaybackPositionsTable> {
  $$PlaybackPositionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get containerExtension => $composableBuilder(
    column: $table.containerExtension,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get positionSecs => $composableBuilder(
    column: $table.positionSecs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSecs => $composableBuilder(
    column: $table.durationSecs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SourcesTableOrderingComposer get sourceId {
    final $$SourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableOrderingComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaybackPositionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaybackPositionsTable> {
  $$PlaybackPositionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<WatchKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<int> get seriesId =>
      $composableBuilder(column: $table.seriesId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get subtitle =>
      $composableBuilder(column: $table.subtitle, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get containerExtension => $composableBuilder(
    column: $table.containerExtension,
    builder: (column) => column,
  );

  GeneratedColumn<int> get positionSecs => $composableBuilder(
    column: $table.positionSecs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationSecs => $composableBuilder(
    column: $table.durationSecs,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$SourcesTableAnnotationComposer get sourceId {
    final $$SourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaybackPositionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaybackPositionsTable,
          PlaybackPosition,
          $$PlaybackPositionsTableFilterComposer,
          $$PlaybackPositionsTableOrderingComposer,
          $$PlaybackPositionsTableAnnotationComposer,
          $$PlaybackPositionsTableCreateCompanionBuilder,
          $$PlaybackPositionsTableUpdateCompanionBuilder,
          (PlaybackPosition, $$PlaybackPositionsTableReferences),
          PlaybackPosition,
          PrefetchHooks Function({bool sourceId})
        > {
  $$PlaybackPositionsTableTableManager(
    _$AppDatabase db,
    $PlaybackPositionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaybackPositionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaybackPositionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaybackPositionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> sourceId = const Value.absent(),
                Value<WatchKind> kind = const Value.absent(),
                Value<int> itemId = const Value.absent(),
                Value<int?> seriesId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> subtitle = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> containerExtension = const Value.absent(),
                Value<int> positionSecs = const Value.absent(),
                Value<int> durationSecs = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaybackPositionsCompanion(
                sourceId: sourceId,
                kind: kind,
                itemId: itemId,
                seriesId: seriesId,
                title: title,
                subtitle: subtitle,
                imageUrl: imageUrl,
                containerExtension: containerExtension,
                positionSecs: positionSecs,
                durationSecs: durationSecs,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int sourceId,
                required WatchKind kind,
                required int itemId,
                Value<int?> seriesId = const Value.absent(),
                required String title,
                Value<String> subtitle = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> containerExtension = const Value.absent(),
                required int positionSecs,
                required int durationSecs,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PlaybackPositionsCompanion.insert(
                sourceId: sourceId,
                kind: kind,
                itemId: itemId,
                seriesId: seriesId,
                title: title,
                subtitle: subtitle,
                imageUrl: imageUrl,
                containerExtension: containerExtension,
                positionSecs: positionSecs,
                durationSecs: durationSecs,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlaybackPositionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sourceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sourceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sourceId,
                                referencedTable:
                                    $$PlaybackPositionsTableReferences
                                        ._sourceIdTable(db),
                                referencedColumn:
                                    $$PlaybackPositionsTableReferences
                                        ._sourceIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PlaybackPositionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaybackPositionsTable,
      PlaybackPosition,
      $$PlaybackPositionsTableFilterComposer,
      $$PlaybackPositionsTableOrderingComposer,
      $$PlaybackPositionsTableAnnotationComposer,
      $$PlaybackPositionsTableCreateCompanionBuilder,
      $$PlaybackPositionsTableUpdateCompanionBuilder,
      (PlaybackPosition, $$PlaybackPositionsTableReferences),
      PlaybackPosition,
      PrefetchHooks Function({bool sourceId})
    >;
typedef $$SyncTombstonesTableCreateCompanionBuilder =
    SyncTombstonesCompanion Function({
      required int sourceId,
      required TombstoneScope scope,
      required String kind,
      required int itemId,
      Value<int?> seriesId,
      required DateTime deletedAt,
      Value<int> rowid,
    });
typedef $$SyncTombstonesTableUpdateCompanionBuilder =
    SyncTombstonesCompanion Function({
      Value<int> sourceId,
      Value<TombstoneScope> scope,
      Value<String> kind,
      Value<int> itemId,
      Value<int?> seriesId,
      Value<DateTime> deletedAt,
      Value<int> rowid,
    });

final class $$SyncTombstonesTableReferences
    extends BaseReferences<_$AppDatabase, $SyncTombstonesTable, SyncTombstone> {
  $$SyncTombstonesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SourcesTable _sourceIdTable(_$AppDatabase db) =>
      db.sources.createAlias(
        $_aliasNameGenerator(db.syncTombstones.sourceId, db.sources.id),
      );

  $$SourcesTableProcessedTableManager get sourceId {
    final $_column = $_itemColumn<int>('source_id')!;

    final manager = $$SourcesTableTableManager(
      $_db,
      $_db.sources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SyncTombstonesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncTombstonesTable> {
  $$SyncTombstonesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<TombstoneScope, TombstoneScope, String>
  get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SourcesTableFilterComposer get sourceId {
    final $$SourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableFilterComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncTombstonesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncTombstonesTable> {
  $$SyncTombstonesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SourcesTableOrderingComposer get sourceId {
    final $$SourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableOrderingComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncTombstonesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncTombstonesTable> {
  $$SyncTombstonesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<TombstoneScope, String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<int> get seriesId =>
      $composableBuilder(column: $table.seriesId, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$SourcesTableAnnotationComposer get sourceId {
    final $$SourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncTombstonesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncTombstonesTable,
          SyncTombstone,
          $$SyncTombstonesTableFilterComposer,
          $$SyncTombstonesTableOrderingComposer,
          $$SyncTombstonesTableAnnotationComposer,
          $$SyncTombstonesTableCreateCompanionBuilder,
          $$SyncTombstonesTableUpdateCompanionBuilder,
          (SyncTombstone, $$SyncTombstonesTableReferences),
          SyncTombstone,
          PrefetchHooks Function({bool sourceId})
        > {
  $$SyncTombstonesTableTableManager(
    _$AppDatabase db,
    $SyncTombstonesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncTombstonesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncTombstonesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncTombstonesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> sourceId = const Value.absent(),
                Value<TombstoneScope> scope = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> itemId = const Value.absent(),
                Value<int?> seriesId = const Value.absent(),
                Value<DateTime> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncTombstonesCompanion(
                sourceId: sourceId,
                scope: scope,
                kind: kind,
                itemId: itemId,
                seriesId: seriesId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int sourceId,
                required TombstoneScope scope,
                required String kind,
                required int itemId,
                Value<int?> seriesId = const Value.absent(),
                required DateTime deletedAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncTombstonesCompanion.insert(
                sourceId: sourceId,
                scope: scope,
                kind: kind,
                itemId: itemId,
                seriesId: seriesId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SyncTombstonesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sourceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sourceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sourceId,
                                referencedTable: $$SyncTombstonesTableReferences
                                    ._sourceIdTable(db),
                                referencedColumn:
                                    $$SyncTombstonesTableReferences
                                        ._sourceIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SyncTombstonesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncTombstonesTable,
      SyncTombstone,
      $$SyncTombstonesTableFilterComposer,
      $$SyncTombstonesTableOrderingComposer,
      $$SyncTombstonesTableAnnotationComposer,
      $$SyncTombstonesTableCreateCompanionBuilder,
      $$SyncTombstonesTableUpdateCompanionBuilder,
      (SyncTombstone, $$SyncTombstonesTableReferences),
      SyncTombstone,
      PrefetchHooks Function({bool sourceId})
    >;
typedef $$DownloadsTableCreateCompanionBuilder =
    DownloadsCompanion Function({
      required int sourceId,
      required WatchKind kind,
      required int itemId,
      Value<int?> seriesId,
      required String title,
      Value<String> subtitle,
      Value<String?> imageUrl,
      Value<String?> episodeImageUrl,
      Value<String?> containerExtension,
      required String filePath,
      Value<int?> totalBytes,
      required DownloadStatus status,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$DownloadsTableUpdateCompanionBuilder =
    DownloadsCompanion Function({
      Value<int> sourceId,
      Value<WatchKind> kind,
      Value<int> itemId,
      Value<int?> seriesId,
      Value<String> title,
      Value<String> subtitle,
      Value<String?> imageUrl,
      Value<String?> episodeImageUrl,
      Value<String?> containerExtension,
      Value<String> filePath,
      Value<int?> totalBytes,
      Value<DownloadStatus> status,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$DownloadsTableReferences
    extends BaseReferences<_$AppDatabase, $DownloadsTable, DownloadItem> {
  $$DownloadsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SourcesTable _sourceIdTable(_$AppDatabase db) => db.sources
      .createAlias($_aliasNameGenerator(db.downloads.sourceId, db.sources.id));

  $$SourcesTableProcessedTableManager get sourceId {
    final $_column = $_itemColumn<int>('source_id')!;

    final manager = $$SourcesTableTableManager(
      $_db,
      $_db.sources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DownloadsTableFilterComposer
    extends Composer<_$AppDatabase, $DownloadsTable> {
  $$DownloadsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<WatchKind, WatchKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get episodeImageUrl => $composableBuilder(
    column: $table.episodeImageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get containerExtension => $composableBuilder(
    column: $table.containerExtension,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DownloadStatus, DownloadStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SourcesTableFilterComposer get sourceId {
    final $$SourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableFilterComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DownloadsTableOrderingComposer
    extends Composer<_$AppDatabase, $DownloadsTable> {
  $$DownloadsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get episodeImageUrl => $composableBuilder(
    column: $table.episodeImageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get containerExtension => $composableBuilder(
    column: $table.containerExtension,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SourcesTableOrderingComposer get sourceId {
    final $$SourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableOrderingComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DownloadsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DownloadsTable> {
  $$DownloadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<WatchKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<int> get seriesId =>
      $composableBuilder(column: $table.seriesId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get subtitle =>
      $composableBuilder(column: $table.subtitle, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get episodeImageUrl => $composableBuilder(
    column: $table.episodeImageUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get containerExtension => $composableBuilder(
    column: $table.containerExtension,
    builder: (column) => column,
  );

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DownloadStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$SourcesTableAnnotationComposer get sourceId {
    final $$SourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DownloadsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DownloadsTable,
          DownloadItem,
          $$DownloadsTableFilterComposer,
          $$DownloadsTableOrderingComposer,
          $$DownloadsTableAnnotationComposer,
          $$DownloadsTableCreateCompanionBuilder,
          $$DownloadsTableUpdateCompanionBuilder,
          (DownloadItem, $$DownloadsTableReferences),
          DownloadItem,
          PrefetchHooks Function({bool sourceId})
        > {
  $$DownloadsTableTableManager(_$AppDatabase db, $DownloadsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> sourceId = const Value.absent(),
                Value<WatchKind> kind = const Value.absent(),
                Value<int> itemId = const Value.absent(),
                Value<int?> seriesId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> subtitle = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> episodeImageUrl = const Value.absent(),
                Value<String?> containerExtension = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<int?> totalBytes = const Value.absent(),
                Value<DownloadStatus> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadsCompanion(
                sourceId: sourceId,
                kind: kind,
                itemId: itemId,
                seriesId: seriesId,
                title: title,
                subtitle: subtitle,
                imageUrl: imageUrl,
                episodeImageUrl: episodeImageUrl,
                containerExtension: containerExtension,
                filePath: filePath,
                totalBytes: totalBytes,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int sourceId,
                required WatchKind kind,
                required int itemId,
                Value<int?> seriesId = const Value.absent(),
                required String title,
                Value<String> subtitle = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> episodeImageUrl = const Value.absent(),
                Value<String?> containerExtension = const Value.absent(),
                required String filePath,
                Value<int?> totalBytes = const Value.absent(),
                required DownloadStatus status,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => DownloadsCompanion.insert(
                sourceId: sourceId,
                kind: kind,
                itemId: itemId,
                seriesId: seriesId,
                title: title,
                subtitle: subtitle,
                imageUrl: imageUrl,
                episodeImageUrl: episodeImageUrl,
                containerExtension: containerExtension,
                filePath: filePath,
                totalBytes: totalBytes,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DownloadsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sourceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sourceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sourceId,
                                referencedTable: $$DownloadsTableReferences
                                    ._sourceIdTable(db),
                                referencedColumn: $$DownloadsTableReferences
                                    ._sourceIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DownloadsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DownloadsTable,
      DownloadItem,
      $$DownloadsTableFilterComposer,
      $$DownloadsTableOrderingComposer,
      $$DownloadsTableAnnotationComposer,
      $$DownloadsTableCreateCompanionBuilder,
      $$DownloadsTableUpdateCompanionBuilder,
      (DownloadItem, $$DownloadsTableReferences),
      DownloadItem,
      PrefetchHooks Function({bool sourceId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SourcesTableTableManager get sources =>
      $$SourcesTableTableManager(_db, _db.sources);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$LiveChannelsTableTableManager get liveChannels =>
      $$LiveChannelsTableTableManager(_db, _db.liveChannels);
  $$MoviesTableTableManager get movies =>
      $$MoviesTableTableManager(_db, _db.movies);
  $$SeriesItemsTableTableManager get seriesItems =>
      $$SeriesItemsTableTableManager(_db, _db.seriesItems);
  $$EpgProgrammesTableTableManager get epgProgrammes =>
      $$EpgProgrammesTableTableManager(_db, _db.epgProgrammes);
  $$FavoritesTableTableManager get favorites =>
      $$FavoritesTableTableManager(_db, _db.favorites);
  $$PlaybackPositionsTableTableManager get playbackPositions =>
      $$PlaybackPositionsTableTableManager(_db, _db.playbackPositions);
  $$SyncTombstonesTableTableManager get syncTombstones =>
      $$SyncTombstonesTableTableManager(_db, _db.syncTombstones);
  $$DownloadsTableTableManager get downloads =>
      $$DownloadsTableTableManager(_db, _db.downloads);
}
