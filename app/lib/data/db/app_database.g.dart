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
  static const VerificationMeta _discoveredEpgUrlMeta = const VerificationMeta(
    'discoveredEpgUrl',
  );
  @override
  late final GeneratedColumn<String> discoveredEpgUrl = GeneratedColumn<String>(
    'discovered_epg_url',
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
    discoveredEpgUrl,
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
    if (data.containsKey('discovered_epg_url')) {
      context.handle(
        _discoveredEpgUrlMeta,
        discoveredEpgUrl.isAcceptableOrUnknown(
          data['discovered_epg_url']!,
          _discoveredEpgUrlMeta,
        ),
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
      discoveredEpgUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}discovered_epg_url'],
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
  final String? discoveredEpgUrl;
  final DateTime? lastSyncAt;
  const Source({
    required this.id,
    required this.name,
    required this.sourceType,
    required this.serverUrl,
    required this.username,
    required this.password,
    this.epgUrl,
    this.discoveredEpgUrl,
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
    if (!nullToAbsent || discoveredEpgUrl != null) {
      map['discovered_epg_url'] = Variable<String>(discoveredEpgUrl);
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
      discoveredEpgUrl: discoveredEpgUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(discoveredEpgUrl),
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
      discoveredEpgUrl: serializer.fromJson<String?>(json['discoveredEpgUrl']),
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
      'discoveredEpgUrl': serializer.toJson<String?>(discoveredEpgUrl),
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
    Value<String?> discoveredEpgUrl = const Value.absent(),
    Value<DateTime?> lastSyncAt = const Value.absent(),
  }) => Source(
    id: id ?? this.id,
    name: name ?? this.name,
    sourceType: sourceType ?? this.sourceType,
    serverUrl: serverUrl ?? this.serverUrl,
    username: username ?? this.username,
    password: password ?? this.password,
    epgUrl: epgUrl.present ? epgUrl.value : this.epgUrl,
    discoveredEpgUrl: discoveredEpgUrl.present
        ? discoveredEpgUrl.value
        : this.discoveredEpgUrl,
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
      discoveredEpgUrl: data.discoveredEpgUrl.present
          ? data.discoveredEpgUrl.value
          : this.discoveredEpgUrl,
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
          ..write('discoveredEpgUrl: $discoveredEpgUrl, ')
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
    discoveredEpgUrl,
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
          other.discoveredEpgUrl == this.discoveredEpgUrl &&
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
  final Value<String?> discoveredEpgUrl;
  final Value<DateTime?> lastSyncAt;
  const SourcesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.serverUrl = const Value.absent(),
    this.username = const Value.absent(),
    this.password = const Value.absent(),
    this.epgUrl = const Value.absent(),
    this.discoveredEpgUrl = const Value.absent(),
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
    this.discoveredEpgUrl = const Value.absent(),
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
    Expression<String>? discoveredEpgUrl,
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
      if (discoveredEpgUrl != null) 'discovered_epg_url': discoveredEpgUrl,
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
    Value<String?>? discoveredEpgUrl,
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
      discoveredEpgUrl: discoveredEpgUrl ?? this.discoveredEpgUrl,
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
    if (discoveredEpgUrl.present) {
      map['discovered_epg_url'] = Variable<String>(discoveredEpgUrl.value);
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
          ..write('discoveredEpgUrl: $discoveredEpgUrl, ')
          ..write('lastSyncAt: $lastSyncAt')
          ..write(')'))
        .toString();
  }
}

class $CatalogValidatorsTable extends CatalogValidators
    with TableInfo<$CatalogValidatorsTable, CatalogValidator> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CatalogValidatorsTable(this.attachedDatabase, [this._alias]);
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
  late final GeneratedColumnWithTypeConverter<CatalogFeed, String> feed =
      GeneratedColumn<String>(
        'feed',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CatalogFeed>($CatalogValidatorsTable.$converterfeed);
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
    'etag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastModifiedMeta = const VerificationMeta(
    'lastModified',
  );
  @override
  late final GeneratedColumn<String> lastModified = GeneratedColumn<String>(
    'last_modified',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [sourceId, feed, etag, lastModified];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'catalog_validators';
  @override
  VerificationContext validateIntegrity(
    Insertable<CatalogValidator> instance, {
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
    if (data.containsKey('etag')) {
      context.handle(
        _etagMeta,
        etag.isAcceptableOrUnknown(data['etag']!, _etagMeta),
      );
    }
    if (data.containsKey('last_modified')) {
      context.handle(
        _lastModifiedMeta,
        lastModified.isAcceptableOrUnknown(
          data['last_modified']!,
          _lastModifiedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceId, feed};
  @override
  CatalogValidator map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CatalogValidator(
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_id'],
      )!,
      feed: $CatalogValidatorsTable.$converterfeed.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}feed'],
        )!,
      ),
      etag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etag'],
      ),
      lastModified: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_modified'],
      ),
    );
  }

  @override
  $CatalogValidatorsTable createAlias(String alias) {
    return $CatalogValidatorsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CatalogFeed, String, String> $converterfeed =
      const EnumNameConverter<CatalogFeed>(CatalogFeed.values);
}

class CatalogValidator extends DataClass
    implements Insertable<CatalogValidator> {
  final int sourceId;
  final CatalogFeed feed;
  final String? etag;
  final String? lastModified;
  const CatalogValidator({
    required this.sourceId,
    required this.feed,
    this.etag,
    this.lastModified,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_id'] = Variable<int>(sourceId);
    {
      map['feed'] = Variable<String>(
        $CatalogValidatorsTable.$converterfeed.toSql(feed),
      );
    }
    if (!nullToAbsent || etag != null) {
      map['etag'] = Variable<String>(etag);
    }
    if (!nullToAbsent || lastModified != null) {
      map['last_modified'] = Variable<String>(lastModified);
    }
    return map;
  }

  CatalogValidatorsCompanion toCompanion(bool nullToAbsent) {
    return CatalogValidatorsCompanion(
      sourceId: Value(sourceId),
      feed: Value(feed),
      etag: etag == null && nullToAbsent ? const Value.absent() : Value(etag),
      lastModified: lastModified == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModified),
    );
  }

  factory CatalogValidator.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CatalogValidator(
      sourceId: serializer.fromJson<int>(json['sourceId']),
      feed: $CatalogValidatorsTable.$converterfeed.fromJson(
        serializer.fromJson<String>(json['feed']),
      ),
      etag: serializer.fromJson<String?>(json['etag']),
      lastModified: serializer.fromJson<String?>(json['lastModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sourceId': serializer.toJson<int>(sourceId),
      'feed': serializer.toJson<String>(
        $CatalogValidatorsTable.$converterfeed.toJson(feed),
      ),
      'etag': serializer.toJson<String?>(etag),
      'lastModified': serializer.toJson<String?>(lastModified),
    };
  }

  CatalogValidator copyWith({
    int? sourceId,
    CatalogFeed? feed,
    Value<String?> etag = const Value.absent(),
    Value<String?> lastModified = const Value.absent(),
  }) => CatalogValidator(
    sourceId: sourceId ?? this.sourceId,
    feed: feed ?? this.feed,
    etag: etag.present ? etag.value : this.etag,
    lastModified: lastModified.present ? lastModified.value : this.lastModified,
  );
  CatalogValidator copyWithCompanion(CatalogValidatorsCompanion data) {
    return CatalogValidator(
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      feed: data.feed.present ? data.feed.value : this.feed,
      etag: data.etag.present ? data.etag.value : this.etag,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CatalogValidator(')
          ..write('sourceId: $sourceId, ')
          ..write('feed: $feed, ')
          ..write('etag: $etag, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sourceId, feed, etag, lastModified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CatalogValidator &&
          other.sourceId == this.sourceId &&
          other.feed == this.feed &&
          other.etag == this.etag &&
          other.lastModified == this.lastModified);
}

class CatalogValidatorsCompanion extends UpdateCompanion<CatalogValidator> {
  final Value<int> sourceId;
  final Value<CatalogFeed> feed;
  final Value<String?> etag;
  final Value<String?> lastModified;
  final Value<int> rowid;
  const CatalogValidatorsCompanion({
    this.sourceId = const Value.absent(),
    this.feed = const Value.absent(),
    this.etag = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CatalogValidatorsCompanion.insert({
    required int sourceId,
    required CatalogFeed feed,
    this.etag = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sourceId = Value(sourceId),
       feed = Value(feed);
  static Insertable<CatalogValidator> custom({
    Expression<int>? sourceId,
    Expression<String>? feed,
    Expression<String>? etag,
    Expression<String>? lastModified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceId != null) 'source_id': sourceId,
      if (feed != null) 'feed': feed,
      if (etag != null) 'etag': etag,
      if (lastModified != null) 'last_modified': lastModified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CatalogValidatorsCompanion copyWith({
    Value<int>? sourceId,
    Value<CatalogFeed>? feed,
    Value<String?>? etag,
    Value<String?>? lastModified,
    Value<int>? rowid,
  }) {
    return CatalogValidatorsCompanion(
      sourceId: sourceId ?? this.sourceId,
      feed: feed ?? this.feed,
      etag: etag ?? this.etag,
      lastModified: lastModified ?? this.lastModified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceId.present) {
      map['source_id'] = Variable<int>(sourceId.value);
    }
    if (feed.present) {
      map['feed'] = Variable<String>(
        $CatalogValidatorsTable.$converterfeed.toSql(feed.value),
      );
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<String>(lastModified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CatalogValidatorsCompanion(')
          ..write('sourceId: $sourceId, ')
          ..write('feed: $feed, ')
          ..write('etag: $etag, ')
          ..write('lastModified: $lastModified, ')
          ..write('rowid: $rowid')
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
  static const VerificationMeta _searchNameMeta = const VerificationMeta(
    'searchName',
  );
  @override
  late final GeneratedColumn<String> searchName = GeneratedColumn<String>(
    'search_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
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
    searchName,
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
    if (data.containsKey('search_name')) {
      context.handle(
        _searchNameMeta,
        searchName.isAcceptableOrUnknown(data['search_name']!, _searchNameMeta),
      );
    }
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
      searchName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search_name'],
      )!,
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
  final String searchName;
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
    required this.searchName,
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
    map['search_name'] = Variable<String>(searchName);
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
      searchName: Value(searchName),
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
      searchName: serializer.fromJson<String>(json['searchName']),
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
      'searchName': serializer.toJson<String>(searchName),
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
    String? searchName,
    int? sourceId,
    int? streamId,
    String? name,
    Value<String?> icon = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    Value<String?> epgChannelId = const Value.absent(),
    Value<int?> channelNumber = const Value.absent(),
    Value<String?> streamUrl = const Value.absent(),
  }) => LiveChannel(
    searchName: searchName ?? this.searchName,
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
      searchName: data.searchName.present
          ? data.searchName.value
          : this.searchName,
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
          ..write('searchName: $searchName, ')
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
    searchName,
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
          other.searchName == this.searchName &&
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
  final Value<String> searchName;
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
    this.searchName = const Value.absent(),
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
    this.searchName = const Value.absent(),
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
    Expression<String>? searchName,
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
      if (searchName != null) 'search_name': searchName,
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
    Value<String>? searchName,
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
      searchName: searchName ?? this.searchName,
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
    if (searchName.present) {
      map['search_name'] = Variable<String>(searchName.value);
    }
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
          ..write('searchName: $searchName, ')
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
  static const VerificationMeta _matchNameMeta = const VerificationMeta(
    'matchName',
  );
  @override
  late final GeneratedColumn<String> matchName = GeneratedColumn<String>(
    'match_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _releaseYearMeta = const VerificationMeta(
    'releaseYear',
  );
  @override
  late final GeneratedColumn<int> releaseYear = GeneratedColumn<int>(
    'release_year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _externalIdMeta = const VerificationMeta(
    'externalId',
  );
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
    'external_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratingScaleMeta = const VerificationMeta(
    'ratingScale',
  );
  @override
  late final GeneratedColumn<int> ratingScale = GeneratedColumn<int>(
    'rating_scale',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _searchNameMeta = const VerificationMeta(
    'searchName',
  );
  @override
  late final GeneratedColumn<String> searchName = GeneratedColumn<String>(
    'search_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
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
    matchName,
    releaseYear,
    externalId,
    ratingScale,
    searchName,
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
    if (data.containsKey('match_name')) {
      context.handle(
        _matchNameMeta,
        matchName.isAcceptableOrUnknown(data['match_name']!, _matchNameMeta),
      );
    }
    if (data.containsKey('release_year')) {
      context.handle(
        _releaseYearMeta,
        releaseYear.isAcceptableOrUnknown(
          data['release_year']!,
          _releaseYearMeta,
        ),
      );
    }
    if (data.containsKey('external_id')) {
      context.handle(
        _externalIdMeta,
        externalId.isAcceptableOrUnknown(data['external_id']!, _externalIdMeta),
      );
    }
    if (data.containsKey('rating_scale')) {
      context.handle(
        _ratingScaleMeta,
        ratingScale.isAcceptableOrUnknown(
          data['rating_scale']!,
          _ratingScaleMeta,
        ),
      );
    }
    if (data.containsKey('search_name')) {
      context.handle(
        _searchNameMeta,
        searchName.isAcceptableOrUnknown(data['search_name']!, _searchNameMeta),
      );
    }
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
      matchName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}match_name'],
      )!,
      releaseYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}release_year'],
      ),
      externalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_id'],
      ),
      ratingScale: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating_scale'],
      ),
      searchName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search_name'],
      )!,
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
  final String matchName;
  final int? releaseYear;
  final String? externalId;
  final int? ratingScale;
  final String searchName;
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
    required this.matchName,
    this.releaseYear,
    this.externalId,
    this.ratingScale,
    required this.searchName,
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
    map['match_name'] = Variable<String>(matchName);
    if (!nullToAbsent || releaseYear != null) {
      map['release_year'] = Variable<int>(releaseYear);
    }
    if (!nullToAbsent || externalId != null) {
      map['external_id'] = Variable<String>(externalId);
    }
    if (!nullToAbsent || ratingScale != null) {
      map['rating_scale'] = Variable<int>(ratingScale);
    }
    map['search_name'] = Variable<String>(searchName);
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
      matchName: Value(matchName),
      releaseYear: releaseYear == null && nullToAbsent
          ? const Value.absent()
          : Value(releaseYear),
      externalId: externalId == null && nullToAbsent
          ? const Value.absent()
          : Value(externalId),
      ratingScale: ratingScale == null && nullToAbsent
          ? const Value.absent()
          : Value(ratingScale),
      searchName: Value(searchName),
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
      matchName: serializer.fromJson<String>(json['matchName']),
      releaseYear: serializer.fromJson<int?>(json['releaseYear']),
      externalId: serializer.fromJson<String?>(json['externalId']),
      ratingScale: serializer.fromJson<int?>(json['ratingScale']),
      searchName: serializer.fromJson<String>(json['searchName']),
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
      'matchName': serializer.toJson<String>(matchName),
      'releaseYear': serializer.toJson<int?>(releaseYear),
      'externalId': serializer.toJson<String?>(externalId),
      'ratingScale': serializer.toJson<int?>(ratingScale),
      'searchName': serializer.toJson<String>(searchName),
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
    String? matchName,
    Value<int?> releaseYear = const Value.absent(),
    Value<String?> externalId = const Value.absent(),
    Value<int?> ratingScale = const Value.absent(),
    String? searchName,
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
    matchName: matchName ?? this.matchName,
    releaseYear: releaseYear.present ? releaseYear.value : this.releaseYear,
    externalId: externalId.present ? externalId.value : this.externalId,
    ratingScale: ratingScale.present ? ratingScale.value : this.ratingScale,
    searchName: searchName ?? this.searchName,
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
      matchName: data.matchName.present ? data.matchName.value : this.matchName,
      releaseYear: data.releaseYear.present
          ? data.releaseYear.value
          : this.releaseYear,
      externalId: data.externalId.present
          ? data.externalId.value
          : this.externalId,
      ratingScale: data.ratingScale.present
          ? data.ratingScale.value
          : this.ratingScale,
      searchName: data.searchName.present
          ? data.searchName.value
          : this.searchName,
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
          ..write('matchName: $matchName, ')
          ..write('releaseYear: $releaseYear, ')
          ..write('externalId: $externalId, ')
          ..write('ratingScale: $ratingScale, ')
          ..write('searchName: $searchName, ')
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
    matchName,
    releaseYear,
    externalId,
    ratingScale,
    searchName,
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
          other.matchName == this.matchName &&
          other.releaseYear == this.releaseYear &&
          other.externalId == this.externalId &&
          other.ratingScale == this.ratingScale &&
          other.searchName == this.searchName &&
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
  final Value<String> matchName;
  final Value<int?> releaseYear;
  final Value<String?> externalId;
  final Value<int?> ratingScale;
  final Value<String> searchName;
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
    this.matchName = const Value.absent(),
    this.releaseYear = const Value.absent(),
    this.externalId = const Value.absent(),
    this.ratingScale = const Value.absent(),
    this.searchName = const Value.absent(),
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
    this.matchName = const Value.absent(),
    this.releaseYear = const Value.absent(),
    this.externalId = const Value.absent(),
    this.ratingScale = const Value.absent(),
    this.searchName = const Value.absent(),
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
    Expression<String>? matchName,
    Expression<int>? releaseYear,
    Expression<String>? externalId,
    Expression<int>? ratingScale,
    Expression<String>? searchName,
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
      if (matchName != null) 'match_name': matchName,
      if (releaseYear != null) 'release_year': releaseYear,
      if (externalId != null) 'external_id': externalId,
      if (ratingScale != null) 'rating_scale': ratingScale,
      if (searchName != null) 'search_name': searchName,
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
    Value<String>? matchName,
    Value<int?>? releaseYear,
    Value<String?>? externalId,
    Value<int?>? ratingScale,
    Value<String>? searchName,
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
      matchName: matchName ?? this.matchName,
      releaseYear: releaseYear ?? this.releaseYear,
      externalId: externalId ?? this.externalId,
      ratingScale: ratingScale ?? this.ratingScale,
      searchName: searchName ?? this.searchName,
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
    if (matchName.present) {
      map['match_name'] = Variable<String>(matchName.value);
    }
    if (releaseYear.present) {
      map['release_year'] = Variable<int>(releaseYear.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (ratingScale.present) {
      map['rating_scale'] = Variable<int>(ratingScale.value);
    }
    if (searchName.present) {
      map['search_name'] = Variable<String>(searchName.value);
    }
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
          ..write('matchName: $matchName, ')
          ..write('releaseYear: $releaseYear, ')
          ..write('externalId: $externalId, ')
          ..write('ratingScale: $ratingScale, ')
          ..write('searchName: $searchName, ')
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
  static const VerificationMeta _matchNameMeta = const VerificationMeta(
    'matchName',
  );
  @override
  late final GeneratedColumn<String> matchName = GeneratedColumn<String>(
    'match_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _releaseYearMeta = const VerificationMeta(
    'releaseYear',
  );
  @override
  late final GeneratedColumn<int> releaseYear = GeneratedColumn<int>(
    'release_year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _externalIdMeta = const VerificationMeta(
    'externalId',
  );
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
    'external_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratingScaleMeta = const VerificationMeta(
    'ratingScale',
  );
  @override
  late final GeneratedColumn<int> ratingScale = GeneratedColumn<int>(
    'rating_scale',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _searchNameMeta = const VerificationMeta(
    'searchName',
  );
  @override
  late final GeneratedColumn<String> searchName = GeneratedColumn<String>(
    'search_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
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
    matchName,
    releaseYear,
    externalId,
    ratingScale,
    searchName,
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
    if (data.containsKey('match_name')) {
      context.handle(
        _matchNameMeta,
        matchName.isAcceptableOrUnknown(data['match_name']!, _matchNameMeta),
      );
    }
    if (data.containsKey('release_year')) {
      context.handle(
        _releaseYearMeta,
        releaseYear.isAcceptableOrUnknown(
          data['release_year']!,
          _releaseYearMeta,
        ),
      );
    }
    if (data.containsKey('external_id')) {
      context.handle(
        _externalIdMeta,
        externalId.isAcceptableOrUnknown(data['external_id']!, _externalIdMeta),
      );
    }
    if (data.containsKey('rating_scale')) {
      context.handle(
        _ratingScaleMeta,
        ratingScale.isAcceptableOrUnknown(
          data['rating_scale']!,
          _ratingScaleMeta,
        ),
      );
    }
    if (data.containsKey('search_name')) {
      context.handle(
        _searchNameMeta,
        searchName.isAcceptableOrUnknown(data['search_name']!, _searchNameMeta),
      );
    }
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
      matchName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}match_name'],
      )!,
      releaseYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}release_year'],
      ),
      externalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_id'],
      ),
      ratingScale: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating_scale'],
      ),
      searchName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search_name'],
      )!,
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
  final String matchName;
  final int? releaseYear;
  final String? externalId;
  final int? ratingScale;
  final String searchName;
  final int sourceId;
  final int seriesId;
  final String name;
  final String? cover;
  final String? categoryId;
  final String? plot;
  final double? rating;
  final DateTime? lastModifiedAt;
  const SeriesItem({
    required this.matchName,
    this.releaseYear,
    this.externalId,
    this.ratingScale,
    required this.searchName,
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
    map['match_name'] = Variable<String>(matchName);
    if (!nullToAbsent || releaseYear != null) {
      map['release_year'] = Variable<int>(releaseYear);
    }
    if (!nullToAbsent || externalId != null) {
      map['external_id'] = Variable<String>(externalId);
    }
    if (!nullToAbsent || ratingScale != null) {
      map['rating_scale'] = Variable<int>(ratingScale);
    }
    map['search_name'] = Variable<String>(searchName);
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
      matchName: Value(matchName),
      releaseYear: releaseYear == null && nullToAbsent
          ? const Value.absent()
          : Value(releaseYear),
      externalId: externalId == null && nullToAbsent
          ? const Value.absent()
          : Value(externalId),
      ratingScale: ratingScale == null && nullToAbsent
          ? const Value.absent()
          : Value(ratingScale),
      searchName: Value(searchName),
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
      matchName: serializer.fromJson<String>(json['matchName']),
      releaseYear: serializer.fromJson<int?>(json['releaseYear']),
      externalId: serializer.fromJson<String?>(json['externalId']),
      ratingScale: serializer.fromJson<int?>(json['ratingScale']),
      searchName: serializer.fromJson<String>(json['searchName']),
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
      'matchName': serializer.toJson<String>(matchName),
      'releaseYear': serializer.toJson<int?>(releaseYear),
      'externalId': serializer.toJson<String?>(externalId),
      'ratingScale': serializer.toJson<int?>(ratingScale),
      'searchName': serializer.toJson<String>(searchName),
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
    String? matchName,
    Value<int?> releaseYear = const Value.absent(),
    Value<String?> externalId = const Value.absent(),
    Value<int?> ratingScale = const Value.absent(),
    String? searchName,
    int? sourceId,
    int? seriesId,
    String? name,
    Value<String?> cover = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    Value<String?> plot = const Value.absent(),
    Value<double?> rating = const Value.absent(),
    Value<DateTime?> lastModifiedAt = const Value.absent(),
  }) => SeriesItem(
    matchName: matchName ?? this.matchName,
    releaseYear: releaseYear.present ? releaseYear.value : this.releaseYear,
    externalId: externalId.present ? externalId.value : this.externalId,
    ratingScale: ratingScale.present ? ratingScale.value : this.ratingScale,
    searchName: searchName ?? this.searchName,
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
      matchName: data.matchName.present ? data.matchName.value : this.matchName,
      releaseYear: data.releaseYear.present
          ? data.releaseYear.value
          : this.releaseYear,
      externalId: data.externalId.present
          ? data.externalId.value
          : this.externalId,
      ratingScale: data.ratingScale.present
          ? data.ratingScale.value
          : this.ratingScale,
      searchName: data.searchName.present
          ? data.searchName.value
          : this.searchName,
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
          ..write('matchName: $matchName, ')
          ..write('releaseYear: $releaseYear, ')
          ..write('externalId: $externalId, ')
          ..write('ratingScale: $ratingScale, ')
          ..write('searchName: $searchName, ')
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
    matchName,
    releaseYear,
    externalId,
    ratingScale,
    searchName,
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
          other.matchName == this.matchName &&
          other.releaseYear == this.releaseYear &&
          other.externalId == this.externalId &&
          other.ratingScale == this.ratingScale &&
          other.searchName == this.searchName &&
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
  final Value<String> matchName;
  final Value<int?> releaseYear;
  final Value<String?> externalId;
  final Value<int?> ratingScale;
  final Value<String> searchName;
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
    this.matchName = const Value.absent(),
    this.releaseYear = const Value.absent(),
    this.externalId = const Value.absent(),
    this.ratingScale = const Value.absent(),
    this.searchName = const Value.absent(),
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
    this.matchName = const Value.absent(),
    this.releaseYear = const Value.absent(),
    this.externalId = const Value.absent(),
    this.ratingScale = const Value.absent(),
    this.searchName = const Value.absent(),
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
    Expression<String>? matchName,
    Expression<int>? releaseYear,
    Expression<String>? externalId,
    Expression<int>? ratingScale,
    Expression<String>? searchName,
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
      if (matchName != null) 'match_name': matchName,
      if (releaseYear != null) 'release_year': releaseYear,
      if (externalId != null) 'external_id': externalId,
      if (ratingScale != null) 'rating_scale': ratingScale,
      if (searchName != null) 'search_name': searchName,
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
    Value<String>? matchName,
    Value<int?>? releaseYear,
    Value<String?>? externalId,
    Value<int?>? ratingScale,
    Value<String>? searchName,
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
      matchName: matchName ?? this.matchName,
      releaseYear: releaseYear ?? this.releaseYear,
      externalId: externalId ?? this.externalId,
      ratingScale: ratingScale ?? this.ratingScale,
      searchName: searchName ?? this.searchName,
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
    if (matchName.present) {
      map['match_name'] = Variable<String>(matchName.value);
    }
    if (releaseYear.present) {
      map['release_year'] = Variable<int>(releaseYear.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (ratingScale.present) {
      map['rating_scale'] = Variable<int>(ratingScale.value);
    }
    if (searchName.present) {
      map['search_name'] = Variable<String>(searchName.value);
    }
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
          ..write('matchName: $matchName, ')
          ..write('releaseYear: $releaseYear, ')
          ..write('externalId: $externalId, ')
          ..write('ratingScale: $ratingScale, ')
          ..write('searchName: $searchName, ')
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

class $RecentChannelsTable extends RecentChannels
    with TableInfo<$RecentChannelsTable, RecentChannel> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecentChannelsTable(this.attachedDatabase, [this._alias]);
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
  @override
  List<GeneratedColumn> get $columns => [id, sourceId, streamId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recent_channels';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecentChannel> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {sourceId, streamId},
  ];
  @override
  RecentChannel map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecentChannel(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_id'],
      )!,
      streamId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stream_id'],
      )!,
    );
  }

  @override
  $RecentChannelsTable createAlias(String alias) {
    return $RecentChannelsTable(attachedDatabase, alias);
  }
}

class RecentChannel extends DataClass implements Insertable<RecentChannel> {
  final int id;
  final int sourceId;
  final int streamId;
  const RecentChannel({
    required this.id,
    required this.sourceId,
    required this.streamId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['source_id'] = Variable<int>(sourceId);
    map['stream_id'] = Variable<int>(streamId);
    return map;
  }

  RecentChannelsCompanion toCompanion(bool nullToAbsent) {
    return RecentChannelsCompanion(
      id: Value(id),
      sourceId: Value(sourceId),
      streamId: Value(streamId),
    );
  }

  factory RecentChannel.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecentChannel(
      id: serializer.fromJson<int>(json['id']),
      sourceId: serializer.fromJson<int>(json['sourceId']),
      streamId: serializer.fromJson<int>(json['streamId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sourceId': serializer.toJson<int>(sourceId),
      'streamId': serializer.toJson<int>(streamId),
    };
  }

  RecentChannel copyWith({int? id, int? sourceId, int? streamId}) =>
      RecentChannel(
        id: id ?? this.id,
        sourceId: sourceId ?? this.sourceId,
        streamId: streamId ?? this.streamId,
      );
  RecentChannel copyWithCompanion(RecentChannelsCompanion data) {
    return RecentChannel(
      id: data.id.present ? data.id.value : this.id,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      streamId: data.streamId.present ? data.streamId.value : this.streamId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecentChannel(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('streamId: $streamId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sourceId, streamId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecentChannel &&
          other.id == this.id &&
          other.sourceId == this.sourceId &&
          other.streamId == this.streamId);
}

class RecentChannelsCompanion extends UpdateCompanion<RecentChannel> {
  final Value<int> id;
  final Value<int> sourceId;
  final Value<int> streamId;
  const RecentChannelsCompanion({
    this.id = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.streamId = const Value.absent(),
  });
  RecentChannelsCompanion.insert({
    this.id = const Value.absent(),
    required int sourceId,
    required int streamId,
  }) : sourceId = Value(sourceId),
       streamId = Value(streamId);
  static Insertable<RecentChannel> custom({
    Expression<int>? id,
    Expression<int>? sourceId,
    Expression<int>? streamId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceId != null) 'source_id': sourceId,
      if (streamId != null) 'stream_id': streamId,
    });
  }

  RecentChannelsCompanion copyWith({
    Value<int>? id,
    Value<int>? sourceId,
    Value<int>? streamId,
  }) {
    return RecentChannelsCompanion(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      streamId: streamId ?? this.streamId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<int>(sourceId.value);
    }
    if (streamId.present) {
      map['stream_id'] = Variable<int>(streamId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecentChannelsCompanion(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('streamId: $streamId')
          ..write(')'))
        .toString();
  }
}

class $LiveViewingTable extends LiveViewing
    with TableInfo<$LiveViewingTable, LiveViewingData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LiveViewingTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _viewerMeta = const VerificationMeta('viewer');
  @override
  late final GeneratedColumn<String> viewer = GeneratedColumn<String>(
    'viewer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<int> day = GeneratedColumn<int>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  static const VerificationMeta _secondsMeta = const VerificationMeta(
    'seconds',
  );
  @override
  late final GeneratedColumn<int> seconds = GeneratedColumn<int>(
    'seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastWatchedMeta = const VerificationMeta(
    'lastWatched',
  );
  @override
  late final GeneratedColumn<DateTime> lastWatched = GeneratedColumn<DateTime>(
    'last_watched',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sourceId,
    viewer,
    day,
    streamId,
    seconds,
    lastWatched,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'live_viewing';
  @override
  VerificationContext validateIntegrity(
    Insertable<LiveViewingData> instance, {
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
    if (data.containsKey('viewer')) {
      context.handle(
        _viewerMeta,
        viewer.isAcceptableOrUnknown(data['viewer']!, _viewerMeta),
      );
    } else if (isInserting) {
      context.missing(_viewerMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('stream_id')) {
      context.handle(
        _streamIdMeta,
        streamId.isAcceptableOrUnknown(data['stream_id']!, _streamIdMeta),
      );
    } else if (isInserting) {
      context.missing(_streamIdMeta);
    }
    if (data.containsKey('seconds')) {
      context.handle(
        _secondsMeta,
        seconds.isAcceptableOrUnknown(data['seconds']!, _secondsMeta),
      );
    } else if (isInserting) {
      context.missing(_secondsMeta);
    }
    if (data.containsKey('last_watched')) {
      context.handle(
        _lastWatchedMeta,
        lastWatched.isAcceptableOrUnknown(
          data['last_watched']!,
          _lastWatchedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastWatchedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceId, viewer, day, streamId};
  @override
  LiveViewingData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LiveViewingData(
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_id'],
      )!,
      viewer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}viewer'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day'],
      )!,
      streamId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stream_id'],
      )!,
      seconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seconds'],
      )!,
      lastWatched: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_watched'],
      )!,
    );
  }

  @override
  $LiveViewingTable createAlias(String alias) {
    return $LiveViewingTable(attachedDatabase, alias);
  }
}

class LiveViewingData extends DataClass implements Insertable<LiveViewingData> {
  final int sourceId;
  final String viewer;
  final int day;
  final int streamId;
  final int seconds;
  final DateTime lastWatched;
  const LiveViewingData({
    required this.sourceId,
    required this.viewer,
    required this.day,
    required this.streamId,
    required this.seconds,
    required this.lastWatched,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_id'] = Variable<int>(sourceId);
    map['viewer'] = Variable<String>(viewer);
    map['day'] = Variable<int>(day);
    map['stream_id'] = Variable<int>(streamId);
    map['seconds'] = Variable<int>(seconds);
    map['last_watched'] = Variable<DateTime>(lastWatched);
    return map;
  }

  LiveViewingCompanion toCompanion(bool nullToAbsent) {
    return LiveViewingCompanion(
      sourceId: Value(sourceId),
      viewer: Value(viewer),
      day: Value(day),
      streamId: Value(streamId),
      seconds: Value(seconds),
      lastWatched: Value(lastWatched),
    );
  }

  factory LiveViewingData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LiveViewingData(
      sourceId: serializer.fromJson<int>(json['sourceId']),
      viewer: serializer.fromJson<String>(json['viewer']),
      day: serializer.fromJson<int>(json['day']),
      streamId: serializer.fromJson<int>(json['streamId']),
      seconds: serializer.fromJson<int>(json['seconds']),
      lastWatched: serializer.fromJson<DateTime>(json['lastWatched']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sourceId': serializer.toJson<int>(sourceId),
      'viewer': serializer.toJson<String>(viewer),
      'day': serializer.toJson<int>(day),
      'streamId': serializer.toJson<int>(streamId),
      'seconds': serializer.toJson<int>(seconds),
      'lastWatched': serializer.toJson<DateTime>(lastWatched),
    };
  }

  LiveViewingData copyWith({
    int? sourceId,
    String? viewer,
    int? day,
    int? streamId,
    int? seconds,
    DateTime? lastWatched,
  }) => LiveViewingData(
    sourceId: sourceId ?? this.sourceId,
    viewer: viewer ?? this.viewer,
    day: day ?? this.day,
    streamId: streamId ?? this.streamId,
    seconds: seconds ?? this.seconds,
    lastWatched: lastWatched ?? this.lastWatched,
  );
  LiveViewingData copyWithCompanion(LiveViewingCompanion data) {
    return LiveViewingData(
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      viewer: data.viewer.present ? data.viewer.value : this.viewer,
      day: data.day.present ? data.day.value : this.day,
      streamId: data.streamId.present ? data.streamId.value : this.streamId,
      seconds: data.seconds.present ? data.seconds.value : this.seconds,
      lastWatched: data.lastWatched.present
          ? data.lastWatched.value
          : this.lastWatched,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LiveViewingData(')
          ..write('sourceId: $sourceId, ')
          ..write('viewer: $viewer, ')
          ..write('day: $day, ')
          ..write('streamId: $streamId, ')
          ..write('seconds: $seconds, ')
          ..write('lastWatched: $lastWatched')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(sourceId, viewer, day, streamId, seconds, lastWatched);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LiveViewingData &&
          other.sourceId == this.sourceId &&
          other.viewer == this.viewer &&
          other.day == this.day &&
          other.streamId == this.streamId &&
          other.seconds == this.seconds &&
          other.lastWatched == this.lastWatched);
}

class LiveViewingCompanion extends UpdateCompanion<LiveViewingData> {
  final Value<int> sourceId;
  final Value<String> viewer;
  final Value<int> day;
  final Value<int> streamId;
  final Value<int> seconds;
  final Value<DateTime> lastWatched;
  final Value<int> rowid;
  const LiveViewingCompanion({
    this.sourceId = const Value.absent(),
    this.viewer = const Value.absent(),
    this.day = const Value.absent(),
    this.streamId = const Value.absent(),
    this.seconds = const Value.absent(),
    this.lastWatched = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LiveViewingCompanion.insert({
    required int sourceId,
    required String viewer,
    required int day,
    required int streamId,
    required int seconds,
    required DateTime lastWatched,
    this.rowid = const Value.absent(),
  }) : sourceId = Value(sourceId),
       viewer = Value(viewer),
       day = Value(day),
       streamId = Value(streamId),
       seconds = Value(seconds),
       lastWatched = Value(lastWatched);
  static Insertable<LiveViewingData> custom({
    Expression<int>? sourceId,
    Expression<String>? viewer,
    Expression<int>? day,
    Expression<int>? streamId,
    Expression<int>? seconds,
    Expression<DateTime>? lastWatched,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceId != null) 'source_id': sourceId,
      if (viewer != null) 'viewer': viewer,
      if (day != null) 'day': day,
      if (streamId != null) 'stream_id': streamId,
      if (seconds != null) 'seconds': seconds,
      if (lastWatched != null) 'last_watched': lastWatched,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LiveViewingCompanion copyWith({
    Value<int>? sourceId,
    Value<String>? viewer,
    Value<int>? day,
    Value<int>? streamId,
    Value<int>? seconds,
    Value<DateTime>? lastWatched,
    Value<int>? rowid,
  }) {
    return LiveViewingCompanion(
      sourceId: sourceId ?? this.sourceId,
      viewer: viewer ?? this.viewer,
      day: day ?? this.day,
      streamId: streamId ?? this.streamId,
      seconds: seconds ?? this.seconds,
      lastWatched: lastWatched ?? this.lastWatched,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceId.present) {
      map['source_id'] = Variable<int>(sourceId.value);
    }
    if (viewer.present) {
      map['viewer'] = Variable<String>(viewer.value);
    }
    if (day.present) {
      map['day'] = Variable<int>(day.value);
    }
    if (streamId.present) {
      map['stream_id'] = Variable<int>(streamId.value);
    }
    if (seconds.present) {
      map['seconds'] = Variable<int>(seconds.value);
    }
    if (lastWatched.present) {
      map['last_watched'] = Variable<DateTime>(lastWatched.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LiveViewingCompanion(')
          ..write('sourceId: $sourceId, ')
          ..write('viewer: $viewer, ')
          ..write('day: $day, ')
          ..write('streamId: $streamId, ')
          ..write('seconds: $seconds, ')
          ..write('lastWatched: $lastWatched, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LiveTuningTable extends LiveTuning
    with TableInfo<$LiveTuningTable, LiveTuningData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LiveTuningTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _viewerMeta = const VerificationMeta('viewer');
  @override
  late final GeneratedColumn<String> viewer = GeneratedColumn<String>(
    'viewer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _channelKeyMeta = const VerificationMeta(
    'channelKey',
  );
  @override
  late final GeneratedColumn<String> channelKey = GeneratedColumn<String>(
    'channel_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _preferredStreamMeta = const VerificationMeta(
    'preferredStream',
  );
  @override
  late final GeneratedColumn<int> preferredStream = GeneratedColumn<int>(
    'preferred_stream',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _successfulStreamMeta = const VerificationMeta(
    'successfulStream',
  );
  @override
  late final GeneratedColumn<int> successfulStream = GeneratedColumn<int>(
    'successful_stream',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sourceId,
    viewer,
    channelKey,
    preferredStream,
    successfulStream,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'live_tuning';
  @override
  VerificationContext validateIntegrity(
    Insertable<LiveTuningData> instance, {
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
    if (data.containsKey('viewer')) {
      context.handle(
        _viewerMeta,
        viewer.isAcceptableOrUnknown(data['viewer']!, _viewerMeta),
      );
    } else if (isInserting) {
      context.missing(_viewerMeta);
    }
    if (data.containsKey('channel_key')) {
      context.handle(
        _channelKeyMeta,
        channelKey.isAcceptableOrUnknown(data['channel_key']!, _channelKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_channelKeyMeta);
    }
    if (data.containsKey('preferred_stream')) {
      context.handle(
        _preferredStreamMeta,
        preferredStream.isAcceptableOrUnknown(
          data['preferred_stream']!,
          _preferredStreamMeta,
        ),
      );
    }
    if (data.containsKey('successful_stream')) {
      context.handle(
        _successfulStreamMeta,
        successfulStream.isAcceptableOrUnknown(
          data['successful_stream']!,
          _successfulStreamMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceId, viewer, channelKey};
  @override
  LiveTuningData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LiveTuningData(
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_id'],
      )!,
      viewer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}viewer'],
      )!,
      channelKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel_key'],
      )!,
      preferredStream: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}preferred_stream'],
      ),
      successfulStream: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}successful_stream'],
      ),
    );
  }

  @override
  $LiveTuningTable createAlias(String alias) {
    return $LiveTuningTable(attachedDatabase, alias);
  }
}

class LiveTuningData extends DataClass implements Insertable<LiveTuningData> {
  final int sourceId;
  final String viewer;
  final String channelKey;
  final int? preferredStream;
  final int? successfulStream;
  const LiveTuningData({
    required this.sourceId,
    required this.viewer,
    required this.channelKey,
    this.preferredStream,
    this.successfulStream,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_id'] = Variable<int>(sourceId);
    map['viewer'] = Variable<String>(viewer);
    map['channel_key'] = Variable<String>(channelKey);
    if (!nullToAbsent || preferredStream != null) {
      map['preferred_stream'] = Variable<int>(preferredStream);
    }
    if (!nullToAbsent || successfulStream != null) {
      map['successful_stream'] = Variable<int>(successfulStream);
    }
    return map;
  }

  LiveTuningCompanion toCompanion(bool nullToAbsent) {
    return LiveTuningCompanion(
      sourceId: Value(sourceId),
      viewer: Value(viewer),
      channelKey: Value(channelKey),
      preferredStream: preferredStream == null && nullToAbsent
          ? const Value.absent()
          : Value(preferredStream),
      successfulStream: successfulStream == null && nullToAbsent
          ? const Value.absent()
          : Value(successfulStream),
    );
  }

  factory LiveTuningData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LiveTuningData(
      sourceId: serializer.fromJson<int>(json['sourceId']),
      viewer: serializer.fromJson<String>(json['viewer']),
      channelKey: serializer.fromJson<String>(json['channelKey']),
      preferredStream: serializer.fromJson<int?>(json['preferredStream']),
      successfulStream: serializer.fromJson<int?>(json['successfulStream']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sourceId': serializer.toJson<int>(sourceId),
      'viewer': serializer.toJson<String>(viewer),
      'channelKey': serializer.toJson<String>(channelKey),
      'preferredStream': serializer.toJson<int?>(preferredStream),
      'successfulStream': serializer.toJson<int?>(successfulStream),
    };
  }

  LiveTuningData copyWith({
    int? sourceId,
    String? viewer,
    String? channelKey,
    Value<int?> preferredStream = const Value.absent(),
    Value<int?> successfulStream = const Value.absent(),
  }) => LiveTuningData(
    sourceId: sourceId ?? this.sourceId,
    viewer: viewer ?? this.viewer,
    channelKey: channelKey ?? this.channelKey,
    preferredStream: preferredStream.present
        ? preferredStream.value
        : this.preferredStream,
    successfulStream: successfulStream.present
        ? successfulStream.value
        : this.successfulStream,
  );
  LiveTuningData copyWithCompanion(LiveTuningCompanion data) {
    return LiveTuningData(
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      viewer: data.viewer.present ? data.viewer.value : this.viewer,
      channelKey: data.channelKey.present
          ? data.channelKey.value
          : this.channelKey,
      preferredStream: data.preferredStream.present
          ? data.preferredStream.value
          : this.preferredStream,
      successfulStream: data.successfulStream.present
          ? data.successfulStream.value
          : this.successfulStream,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LiveTuningData(')
          ..write('sourceId: $sourceId, ')
          ..write('viewer: $viewer, ')
          ..write('channelKey: $channelKey, ')
          ..write('preferredStream: $preferredStream, ')
          ..write('successfulStream: $successfulStream')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sourceId,
    viewer,
    channelKey,
    preferredStream,
    successfulStream,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LiveTuningData &&
          other.sourceId == this.sourceId &&
          other.viewer == this.viewer &&
          other.channelKey == this.channelKey &&
          other.preferredStream == this.preferredStream &&
          other.successfulStream == this.successfulStream);
}

class LiveTuningCompanion extends UpdateCompanion<LiveTuningData> {
  final Value<int> sourceId;
  final Value<String> viewer;
  final Value<String> channelKey;
  final Value<int?> preferredStream;
  final Value<int?> successfulStream;
  final Value<int> rowid;
  const LiveTuningCompanion({
    this.sourceId = const Value.absent(),
    this.viewer = const Value.absent(),
    this.channelKey = const Value.absent(),
    this.preferredStream = const Value.absent(),
    this.successfulStream = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LiveTuningCompanion.insert({
    required int sourceId,
    required String viewer,
    required String channelKey,
    this.preferredStream = const Value.absent(),
    this.successfulStream = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sourceId = Value(sourceId),
       viewer = Value(viewer),
       channelKey = Value(channelKey);
  static Insertable<LiveTuningData> custom({
    Expression<int>? sourceId,
    Expression<String>? viewer,
    Expression<String>? channelKey,
    Expression<int>? preferredStream,
    Expression<int>? successfulStream,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceId != null) 'source_id': sourceId,
      if (viewer != null) 'viewer': viewer,
      if (channelKey != null) 'channel_key': channelKey,
      if (preferredStream != null) 'preferred_stream': preferredStream,
      if (successfulStream != null) 'successful_stream': successfulStream,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LiveTuningCompanion copyWith({
    Value<int>? sourceId,
    Value<String>? viewer,
    Value<String>? channelKey,
    Value<int?>? preferredStream,
    Value<int?>? successfulStream,
    Value<int>? rowid,
  }) {
    return LiveTuningCompanion(
      sourceId: sourceId ?? this.sourceId,
      viewer: viewer ?? this.viewer,
      channelKey: channelKey ?? this.channelKey,
      preferredStream: preferredStream ?? this.preferredStream,
      successfulStream: successfulStream ?? this.successfulStream,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceId.present) {
      map['source_id'] = Variable<int>(sourceId.value);
    }
    if (viewer.present) {
      map['viewer'] = Variable<String>(viewer.value);
    }
    if (channelKey.present) {
      map['channel_key'] = Variable<String>(channelKey.value);
    }
    if (preferredStream.present) {
      map['preferred_stream'] = Variable<int>(preferredStream.value);
    }
    if (successfulStream.present) {
      map['successful_stream'] = Variable<int>(successfulStream.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LiveTuningCompanion(')
          ..write('sourceId: $sourceId, ')
          ..write('viewer: $viewer, ')
          ..write('channelKey: $channelKey, ')
          ..write('preferredStream: $preferredStream, ')
          ..write('successfulStream: $successfulStream, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LiveGuideLinksTable extends LiveGuideLinks
    with TableInfo<$LiveGuideLinksTable, LiveGuideLink> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LiveGuideLinksTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _channelKeyMeta = const VerificationMeta(
    'channelKey',
  );
  @override
  late final GeneratedColumn<String> channelKey = GeneratedColumn<String>(
    'channel_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _guideIdMeta = const VerificationMeta(
    'guideId',
  );
  @override
  late final GeneratedColumn<String> guideId = GeneratedColumn<String>(
    'guide_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _manualMeta = const VerificationMeta('manual');
  @override
  late final GeneratedColumn<bool> manual = GeneratedColumn<bool>(
    'manual',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("manual" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [sourceId, channelKey, guideId, manual];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'live_guide_links';
  @override
  VerificationContext validateIntegrity(
    Insertable<LiveGuideLink> instance, {
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
    if (data.containsKey('channel_key')) {
      context.handle(
        _channelKeyMeta,
        channelKey.isAcceptableOrUnknown(data['channel_key']!, _channelKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_channelKeyMeta);
    }
    if (data.containsKey('guide_id')) {
      context.handle(
        _guideIdMeta,
        guideId.isAcceptableOrUnknown(data['guide_id']!, _guideIdMeta),
      );
    } else if (isInserting) {
      context.missing(_guideIdMeta);
    }
    if (data.containsKey('manual')) {
      context.handle(
        _manualMeta,
        manual.isAcceptableOrUnknown(data['manual']!, _manualMeta),
      );
    } else if (isInserting) {
      context.missing(_manualMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceId, channelKey};
  @override
  LiveGuideLink map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LiveGuideLink(
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_id'],
      )!,
      channelKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel_key'],
      )!,
      guideId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}guide_id'],
      )!,
      manual: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}manual'],
      )!,
    );
  }

  @override
  $LiveGuideLinksTable createAlias(String alias) {
    return $LiveGuideLinksTable(attachedDatabase, alias);
  }
}

class LiveGuideLink extends DataClass implements Insertable<LiveGuideLink> {
  final int sourceId;
  final String channelKey;
  final String guideId;
  final bool manual;
  const LiveGuideLink({
    required this.sourceId,
    required this.channelKey,
    required this.guideId,
    required this.manual,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_id'] = Variable<int>(sourceId);
    map['channel_key'] = Variable<String>(channelKey);
    map['guide_id'] = Variable<String>(guideId);
    map['manual'] = Variable<bool>(manual);
    return map;
  }

  LiveGuideLinksCompanion toCompanion(bool nullToAbsent) {
    return LiveGuideLinksCompanion(
      sourceId: Value(sourceId),
      channelKey: Value(channelKey),
      guideId: Value(guideId),
      manual: Value(manual),
    );
  }

  factory LiveGuideLink.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LiveGuideLink(
      sourceId: serializer.fromJson<int>(json['sourceId']),
      channelKey: serializer.fromJson<String>(json['channelKey']),
      guideId: serializer.fromJson<String>(json['guideId']),
      manual: serializer.fromJson<bool>(json['manual']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sourceId': serializer.toJson<int>(sourceId),
      'channelKey': serializer.toJson<String>(channelKey),
      'guideId': serializer.toJson<String>(guideId),
      'manual': serializer.toJson<bool>(manual),
    };
  }

  LiveGuideLink copyWith({
    int? sourceId,
    String? channelKey,
    String? guideId,
    bool? manual,
  }) => LiveGuideLink(
    sourceId: sourceId ?? this.sourceId,
    channelKey: channelKey ?? this.channelKey,
    guideId: guideId ?? this.guideId,
    manual: manual ?? this.manual,
  );
  LiveGuideLink copyWithCompanion(LiveGuideLinksCompanion data) {
    return LiveGuideLink(
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      channelKey: data.channelKey.present
          ? data.channelKey.value
          : this.channelKey,
      guideId: data.guideId.present ? data.guideId.value : this.guideId,
      manual: data.manual.present ? data.manual.value : this.manual,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LiveGuideLink(')
          ..write('sourceId: $sourceId, ')
          ..write('channelKey: $channelKey, ')
          ..write('guideId: $guideId, ')
          ..write('manual: $manual')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sourceId, channelKey, guideId, manual);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LiveGuideLink &&
          other.sourceId == this.sourceId &&
          other.channelKey == this.channelKey &&
          other.guideId == this.guideId &&
          other.manual == this.manual);
}

class LiveGuideLinksCompanion extends UpdateCompanion<LiveGuideLink> {
  final Value<int> sourceId;
  final Value<String> channelKey;
  final Value<String> guideId;
  final Value<bool> manual;
  final Value<int> rowid;
  const LiveGuideLinksCompanion({
    this.sourceId = const Value.absent(),
    this.channelKey = const Value.absent(),
    this.guideId = const Value.absent(),
    this.manual = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LiveGuideLinksCompanion.insert({
    required int sourceId,
    required String channelKey,
    required String guideId,
    required bool manual,
    this.rowid = const Value.absent(),
  }) : sourceId = Value(sourceId),
       channelKey = Value(channelKey),
       guideId = Value(guideId),
       manual = Value(manual);
  static Insertable<LiveGuideLink> custom({
    Expression<int>? sourceId,
    Expression<String>? channelKey,
    Expression<String>? guideId,
    Expression<bool>? manual,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceId != null) 'source_id': sourceId,
      if (channelKey != null) 'channel_key': channelKey,
      if (guideId != null) 'guide_id': guideId,
      if (manual != null) 'manual': manual,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LiveGuideLinksCompanion copyWith({
    Value<int>? sourceId,
    Value<String>? channelKey,
    Value<String>? guideId,
    Value<bool>? manual,
    Value<int>? rowid,
  }) {
    return LiveGuideLinksCompanion(
      sourceId: sourceId ?? this.sourceId,
      channelKey: channelKey ?? this.channelKey,
      guideId: guideId ?? this.guideId,
      manual: manual ?? this.manual,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceId.present) {
      map['source_id'] = Variable<int>(sourceId.value);
    }
    if (channelKey.present) {
      map['channel_key'] = Variable<String>(channelKey.value);
    }
    if (guideId.present) {
      map['guide_id'] = Variable<String>(guideId.value);
    }
    if (manual.present) {
      map['manual'] = Variable<bool>(manual.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LiveGuideLinksCompanion(')
          ..write('sourceId: $sourceId, ')
          ..write('channelKey: $channelKey, ')
          ..write('guideId: $guideId, ')
          ..write('manual: $manual, ')
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

class $WatchedTitlesTable extends WatchedTitles
    with TableInfo<$WatchedTitlesTable, WatchedTitle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WatchedTitlesTable(this.attachedDatabase, [this._alias]);
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
      ).withConverter<CatalogKind>($WatchedTitlesTable.$converterkind);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _watchedAtMeta = const VerificationMeta(
    'watchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> watchedAt = GeneratedColumn<DateTime>(
    'watched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [sourceId, kind, itemId, watchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'watched_titles';
  @override
  VerificationContext validateIntegrity(
    Insertable<WatchedTitle> instance, {
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
    if (data.containsKey('watched_at')) {
      context.handle(
        _watchedAtMeta,
        watchedAt.isAcceptableOrUnknown(data['watched_at']!, _watchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_watchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceId, kind, itemId};
  @override
  WatchedTitle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WatchedTitle(
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_id'],
      )!,
      kind: $WatchedTitlesTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_id'],
      )!,
      watchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}watched_at'],
      )!,
    );
  }

  @override
  $WatchedTitlesTable createAlias(String alias) {
    return $WatchedTitlesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CatalogKind, String, String> $converterkind =
      const EnumNameConverter<CatalogKind>(CatalogKind.values);
}

class WatchedTitle extends DataClass implements Insertable<WatchedTitle> {
  final int sourceId;
  final CatalogKind kind;
  final int itemId;
  final DateTime watchedAt;
  const WatchedTitle({
    required this.sourceId,
    required this.kind,
    required this.itemId,
    required this.watchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_id'] = Variable<int>(sourceId);
    {
      map['kind'] = Variable<String>(
        $WatchedTitlesTable.$converterkind.toSql(kind),
      );
    }
    map['item_id'] = Variable<int>(itemId);
    map['watched_at'] = Variable<DateTime>(watchedAt);
    return map;
  }

  WatchedTitlesCompanion toCompanion(bool nullToAbsent) {
    return WatchedTitlesCompanion(
      sourceId: Value(sourceId),
      kind: Value(kind),
      itemId: Value(itemId),
      watchedAt: Value(watchedAt),
    );
  }

  factory WatchedTitle.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WatchedTitle(
      sourceId: serializer.fromJson<int>(json['sourceId']),
      kind: $WatchedTitlesTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      itemId: serializer.fromJson<int>(json['itemId']),
      watchedAt: serializer.fromJson<DateTime>(json['watchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sourceId': serializer.toJson<int>(sourceId),
      'kind': serializer.toJson<String>(
        $WatchedTitlesTable.$converterkind.toJson(kind),
      ),
      'itemId': serializer.toJson<int>(itemId),
      'watchedAt': serializer.toJson<DateTime>(watchedAt),
    };
  }

  WatchedTitle copyWith({
    int? sourceId,
    CatalogKind? kind,
    int? itemId,
    DateTime? watchedAt,
  }) => WatchedTitle(
    sourceId: sourceId ?? this.sourceId,
    kind: kind ?? this.kind,
    itemId: itemId ?? this.itemId,
    watchedAt: watchedAt ?? this.watchedAt,
  );
  WatchedTitle copyWithCompanion(WatchedTitlesCompanion data) {
    return WatchedTitle(
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      kind: data.kind.present ? data.kind.value : this.kind,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      watchedAt: data.watchedAt.present ? data.watchedAt.value : this.watchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WatchedTitle(')
          ..write('sourceId: $sourceId, ')
          ..write('kind: $kind, ')
          ..write('itemId: $itemId, ')
          ..write('watchedAt: $watchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sourceId, kind, itemId, watchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WatchedTitle &&
          other.sourceId == this.sourceId &&
          other.kind == this.kind &&
          other.itemId == this.itemId &&
          other.watchedAt == this.watchedAt);
}

class WatchedTitlesCompanion extends UpdateCompanion<WatchedTitle> {
  final Value<int> sourceId;
  final Value<CatalogKind> kind;
  final Value<int> itemId;
  final Value<DateTime> watchedAt;
  final Value<int> rowid;
  const WatchedTitlesCompanion({
    this.sourceId = const Value.absent(),
    this.kind = const Value.absent(),
    this.itemId = const Value.absent(),
    this.watchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WatchedTitlesCompanion.insert({
    required int sourceId,
    required CatalogKind kind,
    required int itemId,
    required DateTime watchedAt,
    this.rowid = const Value.absent(),
  }) : sourceId = Value(sourceId),
       kind = Value(kind),
       itemId = Value(itemId),
       watchedAt = Value(watchedAt);
  static Insertable<WatchedTitle> custom({
    Expression<int>? sourceId,
    Expression<String>? kind,
    Expression<int>? itemId,
    Expression<DateTime>? watchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceId != null) 'source_id': sourceId,
      if (kind != null) 'kind': kind,
      if (itemId != null) 'item_id': itemId,
      if (watchedAt != null) 'watched_at': watchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WatchedTitlesCompanion copyWith({
    Value<int>? sourceId,
    Value<CatalogKind>? kind,
    Value<int>? itemId,
    Value<DateTime>? watchedAt,
    Value<int>? rowid,
  }) {
    return WatchedTitlesCompanion(
      sourceId: sourceId ?? this.sourceId,
      kind: kind ?? this.kind,
      itemId: itemId ?? this.itemId,
      watchedAt: watchedAt ?? this.watchedAt,
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
        $WatchedTitlesTable.$converterkind.toSql(kind.value),
      );
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (watchedAt.present) {
      map['watched_at'] = Variable<DateTime>(watchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WatchedTitlesCompanion(')
          ..write('sourceId: $sourceId, ')
          ..write('kind: $kind, ')
          ..write('itemId: $itemId, ')
          ..write('watchedAt: $watchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WatchedEpisodesTable extends WatchedEpisodes
    with TableInfo<$WatchedEpisodesTable, WatchedEpisode> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WatchedEpisodesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _episodeIdMeta = const VerificationMeta(
    'episodeId',
  );
  @override
  late final GeneratedColumn<int> episodeId = GeneratedColumn<int>(
    'episode_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [sourceId, episodeId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'watched_episodes';
  @override
  VerificationContext validateIntegrity(
    Insertable<WatchedEpisode> instance, {
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
    if (data.containsKey('episode_id')) {
      context.handle(
        _episodeIdMeta,
        episodeId.isAcceptableOrUnknown(data['episode_id']!, _episodeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_episodeIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceId, episodeId};
  @override
  WatchedEpisode map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WatchedEpisode(
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_id'],
      )!,
      episodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}episode_id'],
      )!,
    );
  }

  @override
  $WatchedEpisodesTable createAlias(String alias) {
    return $WatchedEpisodesTable(attachedDatabase, alias);
  }
}

class WatchedEpisode extends DataClass implements Insertable<WatchedEpisode> {
  final int sourceId;
  final int episodeId;
  const WatchedEpisode({required this.sourceId, required this.episodeId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_id'] = Variable<int>(sourceId);
    map['episode_id'] = Variable<int>(episodeId);
    return map;
  }

  WatchedEpisodesCompanion toCompanion(bool nullToAbsent) {
    return WatchedEpisodesCompanion(
      sourceId: Value(sourceId),
      episodeId: Value(episodeId),
    );
  }

  factory WatchedEpisode.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WatchedEpisode(
      sourceId: serializer.fromJson<int>(json['sourceId']),
      episodeId: serializer.fromJson<int>(json['episodeId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sourceId': serializer.toJson<int>(sourceId),
      'episodeId': serializer.toJson<int>(episodeId),
    };
  }

  WatchedEpisode copyWith({int? sourceId, int? episodeId}) => WatchedEpisode(
    sourceId: sourceId ?? this.sourceId,
    episodeId: episodeId ?? this.episodeId,
  );
  WatchedEpisode copyWithCompanion(WatchedEpisodesCompanion data) {
    return WatchedEpisode(
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      episodeId: data.episodeId.present ? data.episodeId.value : this.episodeId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WatchedEpisode(')
          ..write('sourceId: $sourceId, ')
          ..write('episodeId: $episodeId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sourceId, episodeId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WatchedEpisode &&
          other.sourceId == this.sourceId &&
          other.episodeId == this.episodeId);
}

class WatchedEpisodesCompanion extends UpdateCompanion<WatchedEpisode> {
  final Value<int> sourceId;
  final Value<int> episodeId;
  final Value<int> rowid;
  const WatchedEpisodesCompanion({
    this.sourceId = const Value.absent(),
    this.episodeId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WatchedEpisodesCompanion.insert({
    required int sourceId,
    required int episodeId,
    this.rowid = const Value.absent(),
  }) : sourceId = Value(sourceId),
       episodeId = Value(episodeId);
  static Insertable<WatchedEpisode> custom({
    Expression<int>? sourceId,
    Expression<int>? episodeId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceId != null) 'source_id': sourceId,
      if (episodeId != null) 'episode_id': episodeId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WatchedEpisodesCompanion copyWith({
    Value<int>? sourceId,
    Value<int>? episodeId,
    Value<int>? rowid,
  }) {
    return WatchedEpisodesCompanion(
      sourceId: sourceId ?? this.sourceId,
      episodeId: episodeId ?? this.episodeId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceId.present) {
      map['source_id'] = Variable<int>(sourceId.value);
    }
    if (episodeId.present) {
      map['episode_id'] = Variable<int>(episodeId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WatchedEpisodesCompanion(')
          ..write('sourceId: $sourceId, ')
          ..write('episodeId: $episodeId, ')
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

class $DiscoveryEntriesTable extends DiscoveryEntries
    with TableInfo<$DiscoveryEntriesTable, DiscoveryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiscoveryEntriesTable(this.attachedDatabase, [this._alias]);
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
      ).withConverter<CatalogKind>($DiscoveryEntriesTable.$converterkind);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fingerprintMeta = const VerificationMeta(
    'fingerprint',
  );
  @override
  late final GeneratedColumn<String> fingerprint = GeneratedColumn<String>(
    'fingerprint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
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
    fingerprint,
    payload,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'discovery_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<DiscoveryEntry> instance, {
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
    if (data.containsKey('fingerprint')) {
      context.handle(
        _fingerprintMeta,
        fingerprint.isAcceptableOrUnknown(
          data['fingerprint']!,
          _fingerprintMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fingerprintMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceId, kind, itemId};
  @override
  DiscoveryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiscoveryEntry(
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_id'],
      )!,
      kind: $DiscoveryEntriesTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_id'],
      )!,
      fingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fingerprint'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $DiscoveryEntriesTable createAlias(String alias) {
    return $DiscoveryEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CatalogKind, String, String> $converterkind =
      const EnumNameConverter<CatalogKind>(CatalogKind.values);
}

class DiscoveryEntry extends DataClass implements Insertable<DiscoveryEntry> {
  final int sourceId;
  final CatalogKind kind;
  final int itemId;
  final String fingerprint;
  final String payload;
  final DateTime fetchedAt;
  const DiscoveryEntry({
    required this.sourceId,
    required this.kind,
    required this.itemId,
    required this.fingerprint,
    required this.payload,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_id'] = Variable<int>(sourceId);
    {
      map['kind'] = Variable<String>(
        $DiscoveryEntriesTable.$converterkind.toSql(kind),
      );
    }
    map['item_id'] = Variable<int>(itemId);
    map['fingerprint'] = Variable<String>(fingerprint);
    map['payload'] = Variable<String>(payload);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  DiscoveryEntriesCompanion toCompanion(bool nullToAbsent) {
    return DiscoveryEntriesCompanion(
      sourceId: Value(sourceId),
      kind: Value(kind),
      itemId: Value(itemId),
      fingerprint: Value(fingerprint),
      payload: Value(payload),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory DiscoveryEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiscoveryEntry(
      sourceId: serializer.fromJson<int>(json['sourceId']),
      kind: $DiscoveryEntriesTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      itemId: serializer.fromJson<int>(json['itemId']),
      fingerprint: serializer.fromJson<String>(json['fingerprint']),
      payload: serializer.fromJson<String>(json['payload']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sourceId': serializer.toJson<int>(sourceId),
      'kind': serializer.toJson<String>(
        $DiscoveryEntriesTable.$converterkind.toJson(kind),
      ),
      'itemId': serializer.toJson<int>(itemId),
      'fingerprint': serializer.toJson<String>(fingerprint),
      'payload': serializer.toJson<String>(payload),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  DiscoveryEntry copyWith({
    int? sourceId,
    CatalogKind? kind,
    int? itemId,
    String? fingerprint,
    String? payload,
    DateTime? fetchedAt,
  }) => DiscoveryEntry(
    sourceId: sourceId ?? this.sourceId,
    kind: kind ?? this.kind,
    itemId: itemId ?? this.itemId,
    fingerprint: fingerprint ?? this.fingerprint,
    payload: payload ?? this.payload,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  DiscoveryEntry copyWithCompanion(DiscoveryEntriesCompanion data) {
    return DiscoveryEntry(
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      kind: data.kind.present ? data.kind.value : this.kind,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      fingerprint: data.fingerprint.present
          ? data.fingerprint.value
          : this.fingerprint,
      payload: data.payload.present ? data.payload.value : this.payload,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiscoveryEntry(')
          ..write('sourceId: $sourceId, ')
          ..write('kind: $kind, ')
          ..write('itemId: $itemId, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('payload: $payload, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(sourceId, kind, itemId, fingerprint, payload, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiscoveryEntry &&
          other.sourceId == this.sourceId &&
          other.kind == this.kind &&
          other.itemId == this.itemId &&
          other.fingerprint == this.fingerprint &&
          other.payload == this.payload &&
          other.fetchedAt == this.fetchedAt);
}

class DiscoveryEntriesCompanion extends UpdateCompanion<DiscoveryEntry> {
  final Value<int> sourceId;
  final Value<CatalogKind> kind;
  final Value<int> itemId;
  final Value<String> fingerprint;
  final Value<String> payload;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const DiscoveryEntriesCompanion({
    this.sourceId = const Value.absent(),
    this.kind = const Value.absent(),
    this.itemId = const Value.absent(),
    this.fingerprint = const Value.absent(),
    this.payload = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DiscoveryEntriesCompanion.insert({
    required int sourceId,
    required CatalogKind kind,
    required int itemId,
    required String fingerprint,
    required String payload,
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : sourceId = Value(sourceId),
       kind = Value(kind),
       itemId = Value(itemId),
       fingerprint = Value(fingerprint),
       payload = Value(payload),
       fetchedAt = Value(fetchedAt);
  static Insertable<DiscoveryEntry> custom({
    Expression<int>? sourceId,
    Expression<String>? kind,
    Expression<int>? itemId,
    Expression<String>? fingerprint,
    Expression<String>? payload,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceId != null) 'source_id': sourceId,
      if (kind != null) 'kind': kind,
      if (itemId != null) 'item_id': itemId,
      if (fingerprint != null) 'fingerprint': fingerprint,
      if (payload != null) 'payload': payload,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DiscoveryEntriesCompanion copyWith({
    Value<int>? sourceId,
    Value<CatalogKind>? kind,
    Value<int>? itemId,
    Value<String>? fingerprint,
    Value<String>? payload,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return DiscoveryEntriesCompanion(
      sourceId: sourceId ?? this.sourceId,
      kind: kind ?? this.kind,
      itemId: itemId ?? this.itemId,
      fingerprint: fingerprint ?? this.fingerprint,
      payload: payload ?? this.payload,
      fetchedAt: fetchedAt ?? this.fetchedAt,
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
        $DiscoveryEntriesTable.$converterkind.toSql(kind.value),
      );
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (fingerprint.present) {
      map['fingerprint'] = Variable<String>(fingerprint.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiscoveryEntriesCompanion(')
          ..write('sourceId: $sourceId, ')
          ..write('kind: $kind, ')
          ..write('itemId: $itemId, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('payload: $payload, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecommendationSnapshotsTable extends RecommendationSnapshots
    with TableInfo<$RecommendationSnapshotsTable, RecommendationSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecommendationSnapshotsTable(this.attachedDatabase, [this._alias]);
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
  );
  static const VerificationMeta _slotMeta = const VerificationMeta('slot');
  @override
  late final GeneratedColumn<String> slot = GeneratedColumn<String>(
    'slot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [sourceId, slot, day, payload];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recommendation_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecommendationSnapshot> instance, {
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
    if (data.containsKey('slot')) {
      context.handle(
        _slotMeta,
        slot.isAcceptableOrUnknown(data['slot']!, _slotMeta),
      );
    } else if (isInserting) {
      context.missing(_slotMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceId, slot};
  @override
  RecommendationSnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecommendationSnapshot(
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_id'],
      )!,
      slot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slot'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $RecommendationSnapshotsTable createAlias(String alias) {
    return $RecommendationSnapshotsTable(attachedDatabase, alias);
  }
}

class RecommendationSnapshot extends DataClass
    implements Insertable<RecommendationSnapshot> {
  final int sourceId;
  final String slot;
  final String day;
  final String payload;
  const RecommendationSnapshot({
    required this.sourceId,
    required this.slot,
    required this.day,
    required this.payload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_id'] = Variable<int>(sourceId);
    map['slot'] = Variable<String>(slot);
    map['day'] = Variable<String>(day);
    map['payload'] = Variable<String>(payload);
    return map;
  }

  RecommendationSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return RecommendationSnapshotsCompanion(
      sourceId: Value(sourceId),
      slot: Value(slot),
      day: Value(day),
      payload: Value(payload),
    );
  }

  factory RecommendationSnapshot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecommendationSnapshot(
      sourceId: serializer.fromJson<int>(json['sourceId']),
      slot: serializer.fromJson<String>(json['slot']),
      day: serializer.fromJson<String>(json['day']),
      payload: serializer.fromJson<String>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sourceId': serializer.toJson<int>(sourceId),
      'slot': serializer.toJson<String>(slot),
      'day': serializer.toJson<String>(day),
      'payload': serializer.toJson<String>(payload),
    };
  }

  RecommendationSnapshot copyWith({
    int? sourceId,
    String? slot,
    String? day,
    String? payload,
  }) => RecommendationSnapshot(
    sourceId: sourceId ?? this.sourceId,
    slot: slot ?? this.slot,
    day: day ?? this.day,
    payload: payload ?? this.payload,
  );
  RecommendationSnapshot copyWithCompanion(
    RecommendationSnapshotsCompanion data,
  ) {
    return RecommendationSnapshot(
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      slot: data.slot.present ? data.slot.value : this.slot,
      day: data.day.present ? data.day.value : this.day,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecommendationSnapshot(')
          ..write('sourceId: $sourceId, ')
          ..write('slot: $slot, ')
          ..write('day: $day, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sourceId, slot, day, payload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecommendationSnapshot &&
          other.sourceId == this.sourceId &&
          other.slot == this.slot &&
          other.day == this.day &&
          other.payload == this.payload);
}

class RecommendationSnapshotsCompanion
    extends UpdateCompanion<RecommendationSnapshot> {
  final Value<int> sourceId;
  final Value<String> slot;
  final Value<String> day;
  final Value<String> payload;
  final Value<int> rowid;
  const RecommendationSnapshotsCompanion({
    this.sourceId = const Value.absent(),
    this.slot = const Value.absent(),
    this.day = const Value.absent(),
    this.payload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecommendationSnapshotsCompanion.insert({
    required int sourceId,
    required String slot,
    required String day,
    required String payload,
    this.rowid = const Value.absent(),
  }) : sourceId = Value(sourceId),
       slot = Value(slot),
       day = Value(day),
       payload = Value(payload);
  static Insertable<RecommendationSnapshot> custom({
    Expression<int>? sourceId,
    Expression<String>? slot,
    Expression<String>? day,
    Expression<String>? payload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceId != null) 'source_id': sourceId,
      if (slot != null) 'slot': slot,
      if (day != null) 'day': day,
      if (payload != null) 'payload': payload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecommendationSnapshotsCompanion copyWith({
    Value<int>? sourceId,
    Value<String>? slot,
    Value<String>? day,
    Value<String>? payload,
    Value<int>? rowid,
  }) {
    return RecommendationSnapshotsCompanion(
      sourceId: sourceId ?? this.sourceId,
      slot: slot ?? this.slot,
      day: day ?? this.day,
      payload: payload ?? this.payload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceId.present) {
      map['source_id'] = Variable<int>(sourceId.value);
    }
    if (slot.present) {
      map['slot'] = Variable<String>(slot.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecommendationSnapshotsCompanion(')
          ..write('sourceId: $sourceId, ')
          ..write('slot: $slot, ')
          ..write('day: $day, ')
          ..write('payload: $payload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SourcesTable sources = $SourcesTable(this);
  late final $CatalogValidatorsTable catalogValidators =
      $CatalogValidatorsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $LiveChannelsTable liveChannels = $LiveChannelsTable(this);
  late final $MoviesTable movies = $MoviesTable(this);
  late final $SeriesItemsTable seriesItems = $SeriesItemsTable(this);
  late final $EpgProgrammesTable epgProgrammes = $EpgProgrammesTable(this);
  late final $FavoritesTable favorites = $FavoritesTable(this);
  late final $RecentChannelsTable recentChannels = $RecentChannelsTable(this);
  late final $LiveViewingTable liveViewing = $LiveViewingTable(this);
  late final $LiveTuningTable liveTuning = $LiveTuningTable(this);
  late final $LiveGuideLinksTable liveGuideLinks = $LiveGuideLinksTable(this);
  late final $PlaybackPositionsTable playbackPositions =
      $PlaybackPositionsTable(this);
  late final $WatchedTitlesTable watchedTitles = $WatchedTitlesTable(this);
  late final $WatchedEpisodesTable watchedEpisodes = $WatchedEpisodesTable(
    this,
  );
  late final $SyncTombstonesTable syncTombstones = $SyncTombstonesTable(this);
  late final $DownloadsTable downloads = $DownloadsTable(this);
  late final $DiscoveryEntriesTable discoveryEntries = $DiscoveryEntriesTable(
    this,
  );
  late final $RecommendationSnapshotsTable recommendationSnapshots =
      $RecommendationSnapshotsTable(this);
  late final Index liveSourceNumber = Index(
    'live_source_number',
    'CREATE INDEX live_source_number ON live_channels (source_id, channel_number, name, stream_id)',
  );
  late final Index movieSourceRecent = Index(
    'movie_source_recent',
    'CREATE INDEX movie_source_recent ON movies (source_id, added_at DESC, name, stream_id)',
  );
  late final Index moviesDiscoveryName = Index(
    'movies_discovery_name',
    'CREATE INDEX movies_discovery_name ON movies (source_id, match_name)',
  );
  late final Index moviesExternalId = Index(
    'movies_external_id',
    'CREATE INDEX movies_external_id ON movies (source_id, external_id)',
  );
  late final Index seriesSourceRecent = Index(
    'series_source_recent',
    'CREATE INDEX series_source_recent ON series_items (source_id, last_modified_at DESC, name, series_id)',
  );
  late final Index seriesItemsDiscoveryName = Index(
    'series_items_discovery_name',
    'CREATE INDEX series_items_discovery_name ON series_items (source_id, match_name)',
  );
  late final Index seriesItemsExternalId = Index(
    'series_items_external_id',
    'CREATE INDEX series_items_external_id ON series_items (source_id, external_id)',
  );
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
    catalogValidators,
    categories,
    liveChannels,
    movies,
    seriesItems,
    epgProgrammes,
    favorites,
    recentChannels,
    liveViewing,
    liveTuning,
    liveGuideLinks,
    playbackPositions,
    watchedTitles,
    watchedEpisodes,
    syncTombstones,
    downloads,
    discoveryEntries,
    recommendationSnapshots,
    liveSourceNumber,
    movieSourceRecent,
    moviesDiscoveryName,
    moviesExternalId,
    seriesSourceRecent,
    seriesItemsDiscoveryName,
    seriesItemsExternalId,
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
      Value<String?> discoveredEpgUrl,
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
      Value<String?> discoveredEpgUrl,
      Value<DateTime?> lastSyncAt,
    });

final class $$SourcesTableReferences
    extends BaseReferences<_$AppDatabase, $SourcesTable, Source> {
  $$SourcesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CatalogValidatorsTable, List<CatalogValidator>>
  _catalogValidatorsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.catalogValidators,
        aliasName: $_aliasNameGenerator(
          db.sources.id,
          db.catalogValidators.sourceId,
        ),
      );

  $$CatalogValidatorsTableProcessedTableManager get catalogValidatorsRefs {
    final manager = $$CatalogValidatorsTableTableManager(
      $_db,
      $_db.catalogValidators,
    ).filter((f) => f.sourceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _catalogValidatorsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

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

  static MultiTypedResultKey<$RecentChannelsTable, List<RecentChannel>>
  _recentChannelsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.recentChannels,
    aliasName: $_aliasNameGenerator(db.sources.id, db.recentChannels.sourceId),
  );

  $$RecentChannelsTableProcessedTableManager get recentChannelsRefs {
    final manager = $$RecentChannelsTableTableManager(
      $_db,
      $_db.recentChannels,
    ).filter((f) => f.sourceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_recentChannelsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LiveViewingTable, List<LiveViewingData>>
  _liveViewingRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.liveViewing,
    aliasName: $_aliasNameGenerator(db.sources.id, db.liveViewing.sourceId),
  );

  $$LiveViewingTableProcessedTableManager get liveViewingRefs {
    final manager = $$LiveViewingTableTableManager(
      $_db,
      $_db.liveViewing,
    ).filter((f) => f.sourceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_liveViewingRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LiveTuningTable, List<LiveTuningData>>
  _liveTuningRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.liveTuning,
    aliasName: $_aliasNameGenerator(db.sources.id, db.liveTuning.sourceId),
  );

  $$LiveTuningTableProcessedTableManager get liveTuningRefs {
    final manager = $$LiveTuningTableTableManager(
      $_db,
      $_db.liveTuning,
    ).filter((f) => f.sourceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_liveTuningRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LiveGuideLinksTable, List<LiveGuideLink>>
  _liveGuideLinksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.liveGuideLinks,
    aliasName: $_aliasNameGenerator(db.sources.id, db.liveGuideLinks.sourceId),
  );

  $$LiveGuideLinksTableProcessedTableManager get liveGuideLinksRefs {
    final manager = $$LiveGuideLinksTableTableManager(
      $_db,
      $_db.liveGuideLinks,
    ).filter((f) => f.sourceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_liveGuideLinksRefsTable($_db));
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

  static MultiTypedResultKey<$WatchedTitlesTable, List<WatchedTitle>>
  _watchedTitlesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.watchedTitles,
    aliasName: $_aliasNameGenerator(db.sources.id, db.watchedTitles.sourceId),
  );

  $$WatchedTitlesTableProcessedTableManager get watchedTitlesRefs {
    final manager = $$WatchedTitlesTableTableManager(
      $_db,
      $_db.watchedTitles,
    ).filter((f) => f.sourceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_watchedTitlesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WatchedEpisodesTable, List<WatchedEpisode>>
  _watchedEpisodesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.watchedEpisodes,
    aliasName: $_aliasNameGenerator(db.sources.id, db.watchedEpisodes.sourceId),
  );

  $$WatchedEpisodesTableProcessedTableManager get watchedEpisodesRefs {
    final manager = $$WatchedEpisodesTableTableManager(
      $_db,
      $_db.watchedEpisodes,
    ).filter((f) => f.sourceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _watchedEpisodesRefsTable($_db),
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

  static MultiTypedResultKey<$DiscoveryEntriesTable, List<DiscoveryEntry>>
  _discoveryEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.discoveryEntries,
    aliasName: $_aliasNameGenerator(
      db.sources.id,
      db.discoveryEntries.sourceId,
    ),
  );

  $$DiscoveryEntriesTableProcessedTableManager get discoveryEntriesRefs {
    final manager = $$DiscoveryEntriesTableTableManager(
      $_db,
      $_db.discoveryEntries,
    ).filter((f) => f.sourceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _discoveryEntriesRefsTable($_db),
    );
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

  ColumnFilters<String> get discoveredEpgUrl => $composableBuilder(
    column: $table.discoveredEpgUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> catalogValidatorsRefs(
    Expression<bool> Function($$CatalogValidatorsTableFilterComposer f) f,
  ) {
    final $$CatalogValidatorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.catalogValidators,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogValidatorsTableFilterComposer(
            $db: $db,
            $table: $db.catalogValidators,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

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

  Expression<bool> recentChannelsRefs(
    Expression<bool> Function($$RecentChannelsTableFilterComposer f) f,
  ) {
    final $$RecentChannelsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recentChannels,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecentChannelsTableFilterComposer(
            $db: $db,
            $table: $db.recentChannels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> liveViewingRefs(
    Expression<bool> Function($$LiveViewingTableFilterComposer f) f,
  ) {
    final $$LiveViewingTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.liveViewing,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LiveViewingTableFilterComposer(
            $db: $db,
            $table: $db.liveViewing,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> liveTuningRefs(
    Expression<bool> Function($$LiveTuningTableFilterComposer f) f,
  ) {
    final $$LiveTuningTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.liveTuning,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LiveTuningTableFilterComposer(
            $db: $db,
            $table: $db.liveTuning,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> liveGuideLinksRefs(
    Expression<bool> Function($$LiveGuideLinksTableFilterComposer f) f,
  ) {
    final $$LiveGuideLinksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.liveGuideLinks,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LiveGuideLinksTableFilterComposer(
            $db: $db,
            $table: $db.liveGuideLinks,
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

  Expression<bool> watchedTitlesRefs(
    Expression<bool> Function($$WatchedTitlesTableFilterComposer f) f,
  ) {
    final $$WatchedTitlesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.watchedTitles,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WatchedTitlesTableFilterComposer(
            $db: $db,
            $table: $db.watchedTitles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> watchedEpisodesRefs(
    Expression<bool> Function($$WatchedEpisodesTableFilterComposer f) f,
  ) {
    final $$WatchedEpisodesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.watchedEpisodes,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WatchedEpisodesTableFilterComposer(
            $db: $db,
            $table: $db.watchedEpisodes,
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

  Expression<bool> discoveryEntriesRefs(
    Expression<bool> Function($$DiscoveryEntriesTableFilterComposer f) f,
  ) {
    final $$DiscoveryEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.discoveryEntries,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiscoveryEntriesTableFilterComposer(
            $db: $db,
            $table: $db.discoveryEntries,
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

  ColumnOrderings<String> get discoveredEpgUrl => $composableBuilder(
    column: $table.discoveredEpgUrl,
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

  GeneratedColumn<String> get discoveredEpgUrl => $composableBuilder(
    column: $table.discoveredEpgUrl,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => column,
  );

  Expression<T> catalogValidatorsRefs<T extends Object>(
    Expression<T> Function($$CatalogValidatorsTableAnnotationComposer a) f,
  ) {
    final $$CatalogValidatorsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.catalogValidators,
          getReferencedColumn: (t) => t.sourceId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CatalogValidatorsTableAnnotationComposer(
                $db: $db,
                $table: $db.catalogValidators,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

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

  Expression<T> recentChannelsRefs<T extends Object>(
    Expression<T> Function($$RecentChannelsTableAnnotationComposer a) f,
  ) {
    final $$RecentChannelsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recentChannels,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecentChannelsTableAnnotationComposer(
            $db: $db,
            $table: $db.recentChannels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> liveViewingRefs<T extends Object>(
    Expression<T> Function($$LiveViewingTableAnnotationComposer a) f,
  ) {
    final $$LiveViewingTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.liveViewing,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LiveViewingTableAnnotationComposer(
            $db: $db,
            $table: $db.liveViewing,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> liveTuningRefs<T extends Object>(
    Expression<T> Function($$LiveTuningTableAnnotationComposer a) f,
  ) {
    final $$LiveTuningTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.liveTuning,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LiveTuningTableAnnotationComposer(
            $db: $db,
            $table: $db.liveTuning,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> liveGuideLinksRefs<T extends Object>(
    Expression<T> Function($$LiveGuideLinksTableAnnotationComposer a) f,
  ) {
    final $$LiveGuideLinksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.liveGuideLinks,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LiveGuideLinksTableAnnotationComposer(
            $db: $db,
            $table: $db.liveGuideLinks,
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

  Expression<T> watchedTitlesRefs<T extends Object>(
    Expression<T> Function($$WatchedTitlesTableAnnotationComposer a) f,
  ) {
    final $$WatchedTitlesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.watchedTitles,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WatchedTitlesTableAnnotationComposer(
            $db: $db,
            $table: $db.watchedTitles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> watchedEpisodesRefs<T extends Object>(
    Expression<T> Function($$WatchedEpisodesTableAnnotationComposer a) f,
  ) {
    final $$WatchedEpisodesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.watchedEpisodes,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WatchedEpisodesTableAnnotationComposer(
            $db: $db,
            $table: $db.watchedEpisodes,
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

  Expression<T> discoveryEntriesRefs<T extends Object>(
    Expression<T> Function($$DiscoveryEntriesTableAnnotationComposer a) f,
  ) {
    final $$DiscoveryEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.discoveryEntries,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiscoveryEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.discoveryEntries,
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
            bool catalogValidatorsRefs,
            bool categoriesRefs,
            bool liveChannelsRefs,
            bool moviesRefs,
            bool seriesItemsRefs,
            bool epgProgrammesRefs,
            bool favoritesRefs,
            bool recentChannelsRefs,
            bool liveViewingRefs,
            bool liveTuningRefs,
            bool liveGuideLinksRefs,
            bool playbackPositionsRefs,
            bool watchedTitlesRefs,
            bool watchedEpisodesRefs,
            bool syncTombstonesRefs,
            bool downloadsRefs,
            bool discoveryEntriesRefs,
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
                Value<String?> discoveredEpgUrl = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
              }) => SourcesCompanion(
                id: id,
                name: name,
                sourceType: sourceType,
                serverUrl: serverUrl,
                username: username,
                password: password,
                epgUrl: epgUrl,
                discoveredEpgUrl: discoveredEpgUrl,
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
                Value<String?> discoveredEpgUrl = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
              }) => SourcesCompanion.insert(
                id: id,
                name: name,
                sourceType: sourceType,
                serverUrl: serverUrl,
                username: username,
                password: password,
                epgUrl: epgUrl,
                discoveredEpgUrl: discoveredEpgUrl,
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
                catalogValidatorsRefs = false,
                categoriesRefs = false,
                liveChannelsRefs = false,
                moviesRefs = false,
                seriesItemsRefs = false,
                epgProgrammesRefs = false,
                favoritesRefs = false,
                recentChannelsRefs = false,
                liveViewingRefs = false,
                liveTuningRefs = false,
                liveGuideLinksRefs = false,
                playbackPositionsRefs = false,
                watchedTitlesRefs = false,
                watchedEpisodesRefs = false,
                syncTombstonesRefs = false,
                downloadsRefs = false,
                discoveryEntriesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (catalogValidatorsRefs) db.catalogValidators,
                    if (categoriesRefs) db.categories,
                    if (liveChannelsRefs) db.liveChannels,
                    if (moviesRefs) db.movies,
                    if (seriesItemsRefs) db.seriesItems,
                    if (epgProgrammesRefs) db.epgProgrammes,
                    if (favoritesRefs) db.favorites,
                    if (recentChannelsRefs) db.recentChannels,
                    if (liveViewingRefs) db.liveViewing,
                    if (liveTuningRefs) db.liveTuning,
                    if (liveGuideLinksRefs) db.liveGuideLinks,
                    if (playbackPositionsRefs) db.playbackPositions,
                    if (watchedTitlesRefs) db.watchedTitles,
                    if (watchedEpisodesRefs) db.watchedEpisodes,
                    if (syncTombstonesRefs) db.syncTombstones,
                    if (downloadsRefs) db.downloads,
                    if (discoveryEntriesRefs) db.discoveryEntries,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (catalogValidatorsRefs)
                        await $_getPrefetchedData<
                          Source,
                          $SourcesTable,
                          CatalogValidator
                        >(
                          currentTable: table,
                          referencedTable: $$SourcesTableReferences
                              ._catalogValidatorsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SourcesTableReferences(
                                db,
                                table,
                                p0,
                              ).catalogValidatorsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sourceId == item.id,
                              ),
                          typedResults: items,
                        ),
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
                      if (recentChannelsRefs)
                        await $_getPrefetchedData<
                          Source,
                          $SourcesTable,
                          RecentChannel
                        >(
                          currentTable: table,
                          referencedTable: $$SourcesTableReferences
                              ._recentChannelsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SourcesTableReferences(
                                db,
                                table,
                                p0,
                              ).recentChannelsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sourceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (liveViewingRefs)
                        await $_getPrefetchedData<
                          Source,
                          $SourcesTable,
                          LiveViewingData
                        >(
                          currentTable: table,
                          referencedTable: $$SourcesTableReferences
                              ._liveViewingRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SourcesTableReferences(
                                db,
                                table,
                                p0,
                              ).liveViewingRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sourceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (liveTuningRefs)
                        await $_getPrefetchedData<
                          Source,
                          $SourcesTable,
                          LiveTuningData
                        >(
                          currentTable: table,
                          referencedTable: $$SourcesTableReferences
                              ._liveTuningRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SourcesTableReferences(
                                db,
                                table,
                                p0,
                              ).liveTuningRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sourceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (liveGuideLinksRefs)
                        await $_getPrefetchedData<
                          Source,
                          $SourcesTable,
                          LiveGuideLink
                        >(
                          currentTable: table,
                          referencedTable: $$SourcesTableReferences
                              ._liveGuideLinksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SourcesTableReferences(
                                db,
                                table,
                                p0,
                              ).liveGuideLinksRefs,
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
                      if (watchedTitlesRefs)
                        await $_getPrefetchedData<
                          Source,
                          $SourcesTable,
                          WatchedTitle
                        >(
                          currentTable: table,
                          referencedTable: $$SourcesTableReferences
                              ._watchedTitlesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SourcesTableReferences(
                                db,
                                table,
                                p0,
                              ).watchedTitlesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sourceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (watchedEpisodesRefs)
                        await $_getPrefetchedData<
                          Source,
                          $SourcesTable,
                          WatchedEpisode
                        >(
                          currentTable: table,
                          referencedTable: $$SourcesTableReferences
                              ._watchedEpisodesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SourcesTableReferences(
                                db,
                                table,
                                p0,
                              ).watchedEpisodesRefs,
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
                      if (discoveryEntriesRefs)
                        await $_getPrefetchedData<
                          Source,
                          $SourcesTable,
                          DiscoveryEntry
                        >(
                          currentTable: table,
                          referencedTable: $$SourcesTableReferences
                              ._discoveryEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SourcesTableReferences(
                                db,
                                table,
                                p0,
                              ).discoveryEntriesRefs,
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
        bool catalogValidatorsRefs,
        bool categoriesRefs,
        bool liveChannelsRefs,
        bool moviesRefs,
        bool seriesItemsRefs,
        bool epgProgrammesRefs,
        bool favoritesRefs,
        bool recentChannelsRefs,
        bool liveViewingRefs,
        bool liveTuningRefs,
        bool liveGuideLinksRefs,
        bool playbackPositionsRefs,
        bool watchedTitlesRefs,
        bool watchedEpisodesRefs,
        bool syncTombstonesRefs,
        bool downloadsRefs,
        bool discoveryEntriesRefs,
      })
    >;
typedef $$CatalogValidatorsTableCreateCompanionBuilder =
    CatalogValidatorsCompanion Function({
      required int sourceId,
      required CatalogFeed feed,
      Value<String?> etag,
      Value<String?> lastModified,
      Value<int> rowid,
    });
typedef $$CatalogValidatorsTableUpdateCompanionBuilder =
    CatalogValidatorsCompanion Function({
      Value<int> sourceId,
      Value<CatalogFeed> feed,
      Value<String?> etag,
      Value<String?> lastModified,
      Value<int> rowid,
    });

final class $$CatalogValidatorsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CatalogValidatorsTable,
          CatalogValidator
        > {
  $$CatalogValidatorsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SourcesTable _sourceIdTable(_$AppDatabase db) =>
      db.sources.createAlias(
        $_aliasNameGenerator(db.catalogValidators.sourceId, db.sources.id),
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

class $$CatalogValidatorsTableFilterComposer
    extends Composer<_$AppDatabase, $CatalogValidatorsTable> {
  $$CatalogValidatorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<CatalogFeed, CatalogFeed, String> get feed =>
      $composableBuilder(
        column: $table.feed,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastModified => $composableBuilder(
    column: $table.lastModified,
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

class $$CatalogValidatorsTableOrderingComposer
    extends Composer<_$AppDatabase, $CatalogValidatorsTable> {
  $$CatalogValidatorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get feed => $composableBuilder(
    column: $table.feed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastModified => $composableBuilder(
    column: $table.lastModified,
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

class $$CatalogValidatorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CatalogValidatorsTable> {
  $$CatalogValidatorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<CatalogFeed, String> get feed =>
      $composableBuilder(column: $table.feed, builder: (column) => column);

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);

  GeneratedColumn<String> get lastModified => $composableBuilder(
    column: $table.lastModified,
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

class $$CatalogValidatorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CatalogValidatorsTable,
          CatalogValidator,
          $$CatalogValidatorsTableFilterComposer,
          $$CatalogValidatorsTableOrderingComposer,
          $$CatalogValidatorsTableAnnotationComposer,
          $$CatalogValidatorsTableCreateCompanionBuilder,
          $$CatalogValidatorsTableUpdateCompanionBuilder,
          (CatalogValidator, $$CatalogValidatorsTableReferences),
          CatalogValidator,
          PrefetchHooks Function({bool sourceId})
        > {
  $$CatalogValidatorsTableTableManager(
    _$AppDatabase db,
    $CatalogValidatorsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CatalogValidatorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CatalogValidatorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CatalogValidatorsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> sourceId = const Value.absent(),
                Value<CatalogFeed> feed = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<String?> lastModified = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CatalogValidatorsCompanion(
                sourceId: sourceId,
                feed: feed,
                etag: etag,
                lastModified: lastModified,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int sourceId,
                required CatalogFeed feed,
                Value<String?> etag = const Value.absent(),
                Value<String?> lastModified = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CatalogValidatorsCompanion.insert(
                sourceId: sourceId,
                feed: feed,
                etag: etag,
                lastModified: lastModified,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CatalogValidatorsTableReferences(db, table, e),
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
                                    $$CatalogValidatorsTableReferences
                                        ._sourceIdTable(db),
                                referencedColumn:
                                    $$CatalogValidatorsTableReferences
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

typedef $$CatalogValidatorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CatalogValidatorsTable,
      CatalogValidator,
      $$CatalogValidatorsTableFilterComposer,
      $$CatalogValidatorsTableOrderingComposer,
      $$CatalogValidatorsTableAnnotationComposer,
      $$CatalogValidatorsTableCreateCompanionBuilder,
      $$CatalogValidatorsTableUpdateCompanionBuilder,
      (CatalogValidator, $$CatalogValidatorsTableReferences),
      CatalogValidator,
      PrefetchHooks Function({bool sourceId})
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
      Value<String> searchName,
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
      Value<String> searchName,
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
  ColumnFilters<String> get searchName => $composableBuilder(
    column: $table.searchName,
    builder: (column) => ColumnFilters(column),
  );

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
  ColumnOrderings<String> get searchName => $composableBuilder(
    column: $table.searchName,
    builder: (column) => ColumnOrderings(column),
  );

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
  GeneratedColumn<String> get searchName => $composableBuilder(
    column: $table.searchName,
    builder: (column) => column,
  );

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
                Value<String> searchName = const Value.absent(),
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
                searchName: searchName,
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
                Value<String> searchName = const Value.absent(),
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
                searchName: searchName,
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
      Value<String> matchName,
      Value<int?> releaseYear,
      Value<String?> externalId,
      Value<int?> ratingScale,
      Value<String> searchName,
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
      Value<String> matchName,
      Value<int?> releaseYear,
      Value<String?> externalId,
      Value<int?> ratingScale,
      Value<String> searchName,
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
  ColumnFilters<String> get matchName => $composableBuilder(
    column: $table.matchName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get releaseYear => $composableBuilder(
    column: $table.releaseYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ratingScale => $composableBuilder(
    column: $table.ratingScale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get searchName => $composableBuilder(
    column: $table.searchName,
    builder: (column) => ColumnFilters(column),
  );

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
  ColumnOrderings<String> get matchName => $composableBuilder(
    column: $table.matchName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get releaseYear => $composableBuilder(
    column: $table.releaseYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ratingScale => $composableBuilder(
    column: $table.ratingScale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get searchName => $composableBuilder(
    column: $table.searchName,
    builder: (column) => ColumnOrderings(column),
  );

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
  GeneratedColumn<String> get matchName =>
      $composableBuilder(column: $table.matchName, builder: (column) => column);

  GeneratedColumn<int> get releaseYear => $composableBuilder(
    column: $table.releaseYear,
    builder: (column) => column,
  );

  GeneratedColumn<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ratingScale => $composableBuilder(
    column: $table.ratingScale,
    builder: (column) => column,
  );

  GeneratedColumn<String> get searchName => $composableBuilder(
    column: $table.searchName,
    builder: (column) => column,
  );

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
                Value<String> matchName = const Value.absent(),
                Value<int?> releaseYear = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                Value<int?> ratingScale = const Value.absent(),
                Value<String> searchName = const Value.absent(),
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
                matchName: matchName,
                releaseYear: releaseYear,
                externalId: externalId,
                ratingScale: ratingScale,
                searchName: searchName,
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
                Value<String> matchName = const Value.absent(),
                Value<int?> releaseYear = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                Value<int?> ratingScale = const Value.absent(),
                Value<String> searchName = const Value.absent(),
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
                matchName: matchName,
                releaseYear: releaseYear,
                externalId: externalId,
                ratingScale: ratingScale,
                searchName: searchName,
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
      Value<String> matchName,
      Value<int?> releaseYear,
      Value<String?> externalId,
      Value<int?> ratingScale,
      Value<String> searchName,
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
      Value<String> matchName,
      Value<int?> releaseYear,
      Value<String?> externalId,
      Value<int?> ratingScale,
      Value<String> searchName,
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
  ColumnFilters<String> get matchName => $composableBuilder(
    column: $table.matchName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get releaseYear => $composableBuilder(
    column: $table.releaseYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ratingScale => $composableBuilder(
    column: $table.ratingScale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get searchName => $composableBuilder(
    column: $table.searchName,
    builder: (column) => ColumnFilters(column),
  );

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
  ColumnOrderings<String> get matchName => $composableBuilder(
    column: $table.matchName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get releaseYear => $composableBuilder(
    column: $table.releaseYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ratingScale => $composableBuilder(
    column: $table.ratingScale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get searchName => $composableBuilder(
    column: $table.searchName,
    builder: (column) => ColumnOrderings(column),
  );

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
  GeneratedColumn<String> get matchName =>
      $composableBuilder(column: $table.matchName, builder: (column) => column);

  GeneratedColumn<int> get releaseYear => $composableBuilder(
    column: $table.releaseYear,
    builder: (column) => column,
  );

  GeneratedColumn<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ratingScale => $composableBuilder(
    column: $table.ratingScale,
    builder: (column) => column,
  );

  GeneratedColumn<String> get searchName => $composableBuilder(
    column: $table.searchName,
    builder: (column) => column,
  );

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
                Value<String> matchName = const Value.absent(),
                Value<int?> releaseYear = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                Value<int?> ratingScale = const Value.absent(),
                Value<String> searchName = const Value.absent(),
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
                matchName: matchName,
                releaseYear: releaseYear,
                externalId: externalId,
                ratingScale: ratingScale,
                searchName: searchName,
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
                Value<String> matchName = const Value.absent(),
                Value<int?> releaseYear = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                Value<int?> ratingScale = const Value.absent(),
                Value<String> searchName = const Value.absent(),
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
                matchName: matchName,
                releaseYear: releaseYear,
                externalId: externalId,
                ratingScale: ratingScale,
                searchName: searchName,
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
typedef $$RecentChannelsTableCreateCompanionBuilder =
    RecentChannelsCompanion Function({
      Value<int> id,
      required int sourceId,
      required int streamId,
    });
typedef $$RecentChannelsTableUpdateCompanionBuilder =
    RecentChannelsCompanion Function({
      Value<int> id,
      Value<int> sourceId,
      Value<int> streamId,
    });

final class $$RecentChannelsTableReferences
    extends BaseReferences<_$AppDatabase, $RecentChannelsTable, RecentChannel> {
  $$RecentChannelsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SourcesTable _sourceIdTable(_$AppDatabase db) =>
      db.sources.createAlias(
        $_aliasNameGenerator(db.recentChannels.sourceId, db.sources.id),
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

class $$RecentChannelsTableFilterComposer
    extends Composer<_$AppDatabase, $RecentChannelsTable> {
  $$RecentChannelsTableFilterComposer({
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

  ColumnFilters<int> get streamId => $composableBuilder(
    column: $table.streamId,
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

class $$RecentChannelsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecentChannelsTable> {
  $$RecentChannelsTableOrderingComposer({
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

  ColumnOrderings<int> get streamId => $composableBuilder(
    column: $table.streamId,
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

class $$RecentChannelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecentChannelsTable> {
  $$RecentChannelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get streamId =>
      $composableBuilder(column: $table.streamId, builder: (column) => column);

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

class $$RecentChannelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecentChannelsTable,
          RecentChannel,
          $$RecentChannelsTableFilterComposer,
          $$RecentChannelsTableOrderingComposer,
          $$RecentChannelsTableAnnotationComposer,
          $$RecentChannelsTableCreateCompanionBuilder,
          $$RecentChannelsTableUpdateCompanionBuilder,
          (RecentChannel, $$RecentChannelsTableReferences),
          RecentChannel,
          PrefetchHooks Function({bool sourceId})
        > {
  $$RecentChannelsTableTableManager(
    _$AppDatabase db,
    $RecentChannelsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecentChannelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecentChannelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecentChannelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sourceId = const Value.absent(),
                Value<int> streamId = const Value.absent(),
              }) => RecentChannelsCompanion(
                id: id,
                sourceId: sourceId,
                streamId: streamId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sourceId,
                required int streamId,
              }) => RecentChannelsCompanion.insert(
                id: id,
                sourceId: sourceId,
                streamId: streamId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RecentChannelsTableReferences(db, table, e),
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
                                referencedTable: $$RecentChannelsTableReferences
                                    ._sourceIdTable(db),
                                referencedColumn:
                                    $$RecentChannelsTableReferences
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

typedef $$RecentChannelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecentChannelsTable,
      RecentChannel,
      $$RecentChannelsTableFilterComposer,
      $$RecentChannelsTableOrderingComposer,
      $$RecentChannelsTableAnnotationComposer,
      $$RecentChannelsTableCreateCompanionBuilder,
      $$RecentChannelsTableUpdateCompanionBuilder,
      (RecentChannel, $$RecentChannelsTableReferences),
      RecentChannel,
      PrefetchHooks Function({bool sourceId})
    >;
typedef $$LiveViewingTableCreateCompanionBuilder =
    LiveViewingCompanion Function({
      required int sourceId,
      required String viewer,
      required int day,
      required int streamId,
      required int seconds,
      required DateTime lastWatched,
      Value<int> rowid,
    });
typedef $$LiveViewingTableUpdateCompanionBuilder =
    LiveViewingCompanion Function({
      Value<int> sourceId,
      Value<String> viewer,
      Value<int> day,
      Value<int> streamId,
      Value<int> seconds,
      Value<DateTime> lastWatched,
      Value<int> rowid,
    });

final class $$LiveViewingTableReferences
    extends BaseReferences<_$AppDatabase, $LiveViewingTable, LiveViewingData> {
  $$LiveViewingTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SourcesTable _sourceIdTable(_$AppDatabase db) =>
      db.sources.createAlias(
        $_aliasNameGenerator(db.liveViewing.sourceId, db.sources.id),
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

class $$LiveViewingTableFilterComposer
    extends Composer<_$AppDatabase, $LiveViewingTable> {
  $$LiveViewingTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get viewer => $composableBuilder(
    column: $table.viewer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get streamId => $composableBuilder(
    column: $table.streamId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seconds => $composableBuilder(
    column: $table.seconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastWatched => $composableBuilder(
    column: $table.lastWatched,
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

class $$LiveViewingTableOrderingComposer
    extends Composer<_$AppDatabase, $LiveViewingTable> {
  $$LiveViewingTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get viewer => $composableBuilder(
    column: $table.viewer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get streamId => $composableBuilder(
    column: $table.streamId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seconds => $composableBuilder(
    column: $table.seconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastWatched => $composableBuilder(
    column: $table.lastWatched,
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

class $$LiveViewingTableAnnotationComposer
    extends Composer<_$AppDatabase, $LiveViewingTable> {
  $$LiveViewingTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get viewer =>
      $composableBuilder(column: $table.viewer, builder: (column) => column);

  GeneratedColumn<int> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<int> get streamId =>
      $composableBuilder(column: $table.streamId, builder: (column) => column);

  GeneratedColumn<int> get seconds =>
      $composableBuilder(column: $table.seconds, builder: (column) => column);

  GeneratedColumn<DateTime> get lastWatched => $composableBuilder(
    column: $table.lastWatched,
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

class $$LiveViewingTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LiveViewingTable,
          LiveViewingData,
          $$LiveViewingTableFilterComposer,
          $$LiveViewingTableOrderingComposer,
          $$LiveViewingTableAnnotationComposer,
          $$LiveViewingTableCreateCompanionBuilder,
          $$LiveViewingTableUpdateCompanionBuilder,
          (LiveViewingData, $$LiveViewingTableReferences),
          LiveViewingData,
          PrefetchHooks Function({bool sourceId})
        > {
  $$LiveViewingTableTableManager(_$AppDatabase db, $LiveViewingTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LiveViewingTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LiveViewingTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LiveViewingTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> sourceId = const Value.absent(),
                Value<String> viewer = const Value.absent(),
                Value<int> day = const Value.absent(),
                Value<int> streamId = const Value.absent(),
                Value<int> seconds = const Value.absent(),
                Value<DateTime> lastWatched = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LiveViewingCompanion(
                sourceId: sourceId,
                viewer: viewer,
                day: day,
                streamId: streamId,
                seconds: seconds,
                lastWatched: lastWatched,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int sourceId,
                required String viewer,
                required int day,
                required int streamId,
                required int seconds,
                required DateTime lastWatched,
                Value<int> rowid = const Value.absent(),
              }) => LiveViewingCompanion.insert(
                sourceId: sourceId,
                viewer: viewer,
                day: day,
                streamId: streamId,
                seconds: seconds,
                lastWatched: lastWatched,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LiveViewingTableReferences(db, table, e),
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
                                referencedTable: $$LiveViewingTableReferences
                                    ._sourceIdTable(db),
                                referencedColumn: $$LiveViewingTableReferences
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

typedef $$LiveViewingTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LiveViewingTable,
      LiveViewingData,
      $$LiveViewingTableFilterComposer,
      $$LiveViewingTableOrderingComposer,
      $$LiveViewingTableAnnotationComposer,
      $$LiveViewingTableCreateCompanionBuilder,
      $$LiveViewingTableUpdateCompanionBuilder,
      (LiveViewingData, $$LiveViewingTableReferences),
      LiveViewingData,
      PrefetchHooks Function({bool sourceId})
    >;
typedef $$LiveTuningTableCreateCompanionBuilder =
    LiveTuningCompanion Function({
      required int sourceId,
      required String viewer,
      required String channelKey,
      Value<int?> preferredStream,
      Value<int?> successfulStream,
      Value<int> rowid,
    });
typedef $$LiveTuningTableUpdateCompanionBuilder =
    LiveTuningCompanion Function({
      Value<int> sourceId,
      Value<String> viewer,
      Value<String> channelKey,
      Value<int?> preferredStream,
      Value<int?> successfulStream,
      Value<int> rowid,
    });

final class $$LiveTuningTableReferences
    extends BaseReferences<_$AppDatabase, $LiveTuningTable, LiveTuningData> {
  $$LiveTuningTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SourcesTable _sourceIdTable(_$AppDatabase db) => db.sources
      .createAlias($_aliasNameGenerator(db.liveTuning.sourceId, db.sources.id));

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

class $$LiveTuningTableFilterComposer
    extends Composer<_$AppDatabase, $LiveTuningTable> {
  $$LiveTuningTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get viewer => $composableBuilder(
    column: $table.viewer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get channelKey => $composableBuilder(
    column: $table.channelKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get preferredStream => $composableBuilder(
    column: $table.preferredStream,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get successfulStream => $composableBuilder(
    column: $table.successfulStream,
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

class $$LiveTuningTableOrderingComposer
    extends Composer<_$AppDatabase, $LiveTuningTable> {
  $$LiveTuningTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get viewer => $composableBuilder(
    column: $table.viewer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get channelKey => $composableBuilder(
    column: $table.channelKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get preferredStream => $composableBuilder(
    column: $table.preferredStream,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get successfulStream => $composableBuilder(
    column: $table.successfulStream,
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

class $$LiveTuningTableAnnotationComposer
    extends Composer<_$AppDatabase, $LiveTuningTable> {
  $$LiveTuningTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get viewer =>
      $composableBuilder(column: $table.viewer, builder: (column) => column);

  GeneratedColumn<String> get channelKey => $composableBuilder(
    column: $table.channelKey,
    builder: (column) => column,
  );

  GeneratedColumn<int> get preferredStream => $composableBuilder(
    column: $table.preferredStream,
    builder: (column) => column,
  );

  GeneratedColumn<int> get successfulStream => $composableBuilder(
    column: $table.successfulStream,
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

class $$LiveTuningTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LiveTuningTable,
          LiveTuningData,
          $$LiveTuningTableFilterComposer,
          $$LiveTuningTableOrderingComposer,
          $$LiveTuningTableAnnotationComposer,
          $$LiveTuningTableCreateCompanionBuilder,
          $$LiveTuningTableUpdateCompanionBuilder,
          (LiveTuningData, $$LiveTuningTableReferences),
          LiveTuningData,
          PrefetchHooks Function({bool sourceId})
        > {
  $$LiveTuningTableTableManager(_$AppDatabase db, $LiveTuningTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LiveTuningTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LiveTuningTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LiveTuningTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> sourceId = const Value.absent(),
                Value<String> viewer = const Value.absent(),
                Value<String> channelKey = const Value.absent(),
                Value<int?> preferredStream = const Value.absent(),
                Value<int?> successfulStream = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LiveTuningCompanion(
                sourceId: sourceId,
                viewer: viewer,
                channelKey: channelKey,
                preferredStream: preferredStream,
                successfulStream: successfulStream,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int sourceId,
                required String viewer,
                required String channelKey,
                Value<int?> preferredStream = const Value.absent(),
                Value<int?> successfulStream = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LiveTuningCompanion.insert(
                sourceId: sourceId,
                viewer: viewer,
                channelKey: channelKey,
                preferredStream: preferredStream,
                successfulStream: successfulStream,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LiveTuningTableReferences(db, table, e),
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
                                referencedTable: $$LiveTuningTableReferences
                                    ._sourceIdTable(db),
                                referencedColumn: $$LiveTuningTableReferences
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

typedef $$LiveTuningTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LiveTuningTable,
      LiveTuningData,
      $$LiveTuningTableFilterComposer,
      $$LiveTuningTableOrderingComposer,
      $$LiveTuningTableAnnotationComposer,
      $$LiveTuningTableCreateCompanionBuilder,
      $$LiveTuningTableUpdateCompanionBuilder,
      (LiveTuningData, $$LiveTuningTableReferences),
      LiveTuningData,
      PrefetchHooks Function({bool sourceId})
    >;
typedef $$LiveGuideLinksTableCreateCompanionBuilder =
    LiveGuideLinksCompanion Function({
      required int sourceId,
      required String channelKey,
      required String guideId,
      required bool manual,
      Value<int> rowid,
    });
typedef $$LiveGuideLinksTableUpdateCompanionBuilder =
    LiveGuideLinksCompanion Function({
      Value<int> sourceId,
      Value<String> channelKey,
      Value<String> guideId,
      Value<bool> manual,
      Value<int> rowid,
    });

final class $$LiveGuideLinksTableReferences
    extends BaseReferences<_$AppDatabase, $LiveGuideLinksTable, LiveGuideLink> {
  $$LiveGuideLinksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SourcesTable _sourceIdTable(_$AppDatabase db) =>
      db.sources.createAlias(
        $_aliasNameGenerator(db.liveGuideLinks.sourceId, db.sources.id),
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

class $$LiveGuideLinksTableFilterComposer
    extends Composer<_$AppDatabase, $LiveGuideLinksTable> {
  $$LiveGuideLinksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get channelKey => $composableBuilder(
    column: $table.channelKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get guideId => $composableBuilder(
    column: $table.guideId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get manual => $composableBuilder(
    column: $table.manual,
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

class $$LiveGuideLinksTableOrderingComposer
    extends Composer<_$AppDatabase, $LiveGuideLinksTable> {
  $$LiveGuideLinksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get channelKey => $composableBuilder(
    column: $table.channelKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get guideId => $composableBuilder(
    column: $table.guideId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get manual => $composableBuilder(
    column: $table.manual,
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

class $$LiveGuideLinksTableAnnotationComposer
    extends Composer<_$AppDatabase, $LiveGuideLinksTable> {
  $$LiveGuideLinksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get channelKey => $composableBuilder(
    column: $table.channelKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get guideId =>
      $composableBuilder(column: $table.guideId, builder: (column) => column);

  GeneratedColumn<bool> get manual =>
      $composableBuilder(column: $table.manual, builder: (column) => column);

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

class $$LiveGuideLinksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LiveGuideLinksTable,
          LiveGuideLink,
          $$LiveGuideLinksTableFilterComposer,
          $$LiveGuideLinksTableOrderingComposer,
          $$LiveGuideLinksTableAnnotationComposer,
          $$LiveGuideLinksTableCreateCompanionBuilder,
          $$LiveGuideLinksTableUpdateCompanionBuilder,
          (LiveGuideLink, $$LiveGuideLinksTableReferences),
          LiveGuideLink,
          PrefetchHooks Function({bool sourceId})
        > {
  $$LiveGuideLinksTableTableManager(
    _$AppDatabase db,
    $LiveGuideLinksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LiveGuideLinksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LiveGuideLinksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LiveGuideLinksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> sourceId = const Value.absent(),
                Value<String> channelKey = const Value.absent(),
                Value<String> guideId = const Value.absent(),
                Value<bool> manual = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LiveGuideLinksCompanion(
                sourceId: sourceId,
                channelKey: channelKey,
                guideId: guideId,
                manual: manual,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int sourceId,
                required String channelKey,
                required String guideId,
                required bool manual,
                Value<int> rowid = const Value.absent(),
              }) => LiveGuideLinksCompanion.insert(
                sourceId: sourceId,
                channelKey: channelKey,
                guideId: guideId,
                manual: manual,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LiveGuideLinksTableReferences(db, table, e),
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
                                referencedTable: $$LiveGuideLinksTableReferences
                                    ._sourceIdTable(db),
                                referencedColumn:
                                    $$LiveGuideLinksTableReferences
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

typedef $$LiveGuideLinksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LiveGuideLinksTable,
      LiveGuideLink,
      $$LiveGuideLinksTableFilterComposer,
      $$LiveGuideLinksTableOrderingComposer,
      $$LiveGuideLinksTableAnnotationComposer,
      $$LiveGuideLinksTableCreateCompanionBuilder,
      $$LiveGuideLinksTableUpdateCompanionBuilder,
      (LiveGuideLink, $$LiveGuideLinksTableReferences),
      LiveGuideLink,
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
typedef $$WatchedTitlesTableCreateCompanionBuilder =
    WatchedTitlesCompanion Function({
      required int sourceId,
      required CatalogKind kind,
      required int itemId,
      required DateTime watchedAt,
      Value<int> rowid,
    });
typedef $$WatchedTitlesTableUpdateCompanionBuilder =
    WatchedTitlesCompanion Function({
      Value<int> sourceId,
      Value<CatalogKind> kind,
      Value<int> itemId,
      Value<DateTime> watchedAt,
      Value<int> rowid,
    });

final class $$WatchedTitlesTableReferences
    extends BaseReferences<_$AppDatabase, $WatchedTitlesTable, WatchedTitle> {
  $$WatchedTitlesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SourcesTable _sourceIdTable(_$AppDatabase db) =>
      db.sources.createAlias(
        $_aliasNameGenerator(db.watchedTitles.sourceId, db.sources.id),
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

class $$WatchedTitlesTableFilterComposer
    extends Composer<_$AppDatabase, $WatchedTitlesTable> {
  $$WatchedTitlesTableFilterComposer({
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

  ColumnFilters<DateTime> get watchedAt => $composableBuilder(
    column: $table.watchedAt,
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

class $$WatchedTitlesTableOrderingComposer
    extends Composer<_$AppDatabase, $WatchedTitlesTable> {
  $$WatchedTitlesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get watchedAt => $composableBuilder(
    column: $table.watchedAt,
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

class $$WatchedTitlesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WatchedTitlesTable> {
  $$WatchedTitlesTableAnnotationComposer({
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

  GeneratedColumn<DateTime> get watchedAt =>
      $composableBuilder(column: $table.watchedAt, builder: (column) => column);

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

class $$WatchedTitlesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WatchedTitlesTable,
          WatchedTitle,
          $$WatchedTitlesTableFilterComposer,
          $$WatchedTitlesTableOrderingComposer,
          $$WatchedTitlesTableAnnotationComposer,
          $$WatchedTitlesTableCreateCompanionBuilder,
          $$WatchedTitlesTableUpdateCompanionBuilder,
          (WatchedTitle, $$WatchedTitlesTableReferences),
          WatchedTitle,
          PrefetchHooks Function({bool sourceId})
        > {
  $$WatchedTitlesTableTableManager(_$AppDatabase db, $WatchedTitlesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WatchedTitlesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WatchedTitlesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WatchedTitlesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> sourceId = const Value.absent(),
                Value<CatalogKind> kind = const Value.absent(),
                Value<int> itemId = const Value.absent(),
                Value<DateTime> watchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WatchedTitlesCompanion(
                sourceId: sourceId,
                kind: kind,
                itemId: itemId,
                watchedAt: watchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int sourceId,
                required CatalogKind kind,
                required int itemId,
                required DateTime watchedAt,
                Value<int> rowid = const Value.absent(),
              }) => WatchedTitlesCompanion.insert(
                sourceId: sourceId,
                kind: kind,
                itemId: itemId,
                watchedAt: watchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WatchedTitlesTableReferences(db, table, e),
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
                                referencedTable: $$WatchedTitlesTableReferences
                                    ._sourceIdTable(db),
                                referencedColumn: $$WatchedTitlesTableReferences
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

typedef $$WatchedTitlesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WatchedTitlesTable,
      WatchedTitle,
      $$WatchedTitlesTableFilterComposer,
      $$WatchedTitlesTableOrderingComposer,
      $$WatchedTitlesTableAnnotationComposer,
      $$WatchedTitlesTableCreateCompanionBuilder,
      $$WatchedTitlesTableUpdateCompanionBuilder,
      (WatchedTitle, $$WatchedTitlesTableReferences),
      WatchedTitle,
      PrefetchHooks Function({bool sourceId})
    >;
typedef $$WatchedEpisodesTableCreateCompanionBuilder =
    WatchedEpisodesCompanion Function({
      required int sourceId,
      required int episodeId,
      Value<int> rowid,
    });
typedef $$WatchedEpisodesTableUpdateCompanionBuilder =
    WatchedEpisodesCompanion Function({
      Value<int> sourceId,
      Value<int> episodeId,
      Value<int> rowid,
    });

final class $$WatchedEpisodesTableReferences
    extends
        BaseReferences<_$AppDatabase, $WatchedEpisodesTable, WatchedEpisode> {
  $$WatchedEpisodesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SourcesTable _sourceIdTable(_$AppDatabase db) =>
      db.sources.createAlias(
        $_aliasNameGenerator(db.watchedEpisodes.sourceId, db.sources.id),
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

class $$WatchedEpisodesTableFilterComposer
    extends Composer<_$AppDatabase, $WatchedEpisodesTable> {
  $$WatchedEpisodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get episodeId => $composableBuilder(
    column: $table.episodeId,
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

class $$WatchedEpisodesTableOrderingComposer
    extends Composer<_$AppDatabase, $WatchedEpisodesTable> {
  $$WatchedEpisodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get episodeId => $composableBuilder(
    column: $table.episodeId,
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

class $$WatchedEpisodesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WatchedEpisodesTable> {
  $$WatchedEpisodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get episodeId =>
      $composableBuilder(column: $table.episodeId, builder: (column) => column);

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

class $$WatchedEpisodesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WatchedEpisodesTable,
          WatchedEpisode,
          $$WatchedEpisodesTableFilterComposer,
          $$WatchedEpisodesTableOrderingComposer,
          $$WatchedEpisodesTableAnnotationComposer,
          $$WatchedEpisodesTableCreateCompanionBuilder,
          $$WatchedEpisodesTableUpdateCompanionBuilder,
          (WatchedEpisode, $$WatchedEpisodesTableReferences),
          WatchedEpisode,
          PrefetchHooks Function({bool sourceId})
        > {
  $$WatchedEpisodesTableTableManager(
    _$AppDatabase db,
    $WatchedEpisodesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WatchedEpisodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WatchedEpisodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WatchedEpisodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> sourceId = const Value.absent(),
                Value<int> episodeId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WatchedEpisodesCompanion(
                sourceId: sourceId,
                episodeId: episodeId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int sourceId,
                required int episodeId,
                Value<int> rowid = const Value.absent(),
              }) => WatchedEpisodesCompanion.insert(
                sourceId: sourceId,
                episodeId: episodeId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WatchedEpisodesTableReferences(db, table, e),
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
                                    $$WatchedEpisodesTableReferences
                                        ._sourceIdTable(db),
                                referencedColumn:
                                    $$WatchedEpisodesTableReferences
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

typedef $$WatchedEpisodesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WatchedEpisodesTable,
      WatchedEpisode,
      $$WatchedEpisodesTableFilterComposer,
      $$WatchedEpisodesTableOrderingComposer,
      $$WatchedEpisodesTableAnnotationComposer,
      $$WatchedEpisodesTableCreateCompanionBuilder,
      $$WatchedEpisodesTableUpdateCompanionBuilder,
      (WatchedEpisode, $$WatchedEpisodesTableReferences),
      WatchedEpisode,
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
typedef $$DiscoveryEntriesTableCreateCompanionBuilder =
    DiscoveryEntriesCompanion Function({
      required int sourceId,
      required CatalogKind kind,
      required int itemId,
      required String fingerprint,
      required String payload,
      required DateTime fetchedAt,
      Value<int> rowid,
    });
typedef $$DiscoveryEntriesTableUpdateCompanionBuilder =
    DiscoveryEntriesCompanion Function({
      Value<int> sourceId,
      Value<CatalogKind> kind,
      Value<int> itemId,
      Value<String> fingerprint,
      Value<String> payload,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });

final class $$DiscoveryEntriesTableReferences
    extends
        BaseReferences<_$AppDatabase, $DiscoveryEntriesTable, DiscoveryEntry> {
  $$DiscoveryEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SourcesTable _sourceIdTable(_$AppDatabase db) =>
      db.sources.createAlias(
        $_aliasNameGenerator(db.discoveryEntries.sourceId, db.sources.id),
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

class $$DiscoveryEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $DiscoveryEntriesTable> {
  $$DiscoveryEntriesTableFilterComposer({
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

  ColumnFilters<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
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

class $$DiscoveryEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $DiscoveryEntriesTable> {
  $$DiscoveryEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
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

class $$DiscoveryEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DiscoveryEntriesTable> {
  $$DiscoveryEntriesTableAnnotationComposer({
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

  GeneratedColumn<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

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

class $$DiscoveryEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DiscoveryEntriesTable,
          DiscoveryEntry,
          $$DiscoveryEntriesTableFilterComposer,
          $$DiscoveryEntriesTableOrderingComposer,
          $$DiscoveryEntriesTableAnnotationComposer,
          $$DiscoveryEntriesTableCreateCompanionBuilder,
          $$DiscoveryEntriesTableUpdateCompanionBuilder,
          (DiscoveryEntry, $$DiscoveryEntriesTableReferences),
          DiscoveryEntry,
          PrefetchHooks Function({bool sourceId})
        > {
  $$DiscoveryEntriesTableTableManager(
    _$AppDatabase db,
    $DiscoveryEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DiscoveryEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DiscoveryEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DiscoveryEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> sourceId = const Value.absent(),
                Value<CatalogKind> kind = const Value.absent(),
                Value<int> itemId = const Value.absent(),
                Value<String> fingerprint = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DiscoveryEntriesCompanion(
                sourceId: sourceId,
                kind: kind,
                itemId: itemId,
                fingerprint: fingerprint,
                payload: payload,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int sourceId,
                required CatalogKind kind,
                required int itemId,
                required String fingerprint,
                required String payload,
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => DiscoveryEntriesCompanion.insert(
                sourceId: sourceId,
                kind: kind,
                itemId: itemId,
                fingerprint: fingerprint,
                payload: payload,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DiscoveryEntriesTableReferences(db, table, e),
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
                                    $$DiscoveryEntriesTableReferences
                                        ._sourceIdTable(db),
                                referencedColumn:
                                    $$DiscoveryEntriesTableReferences
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

typedef $$DiscoveryEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DiscoveryEntriesTable,
      DiscoveryEntry,
      $$DiscoveryEntriesTableFilterComposer,
      $$DiscoveryEntriesTableOrderingComposer,
      $$DiscoveryEntriesTableAnnotationComposer,
      $$DiscoveryEntriesTableCreateCompanionBuilder,
      $$DiscoveryEntriesTableUpdateCompanionBuilder,
      (DiscoveryEntry, $$DiscoveryEntriesTableReferences),
      DiscoveryEntry,
      PrefetchHooks Function({bool sourceId})
    >;
typedef $$RecommendationSnapshotsTableCreateCompanionBuilder =
    RecommendationSnapshotsCompanion Function({
      required int sourceId,
      required String slot,
      required String day,
      required String payload,
      Value<int> rowid,
    });
typedef $$RecommendationSnapshotsTableUpdateCompanionBuilder =
    RecommendationSnapshotsCompanion Function({
      Value<int> sourceId,
      Value<String> slot,
      Value<String> day,
      Value<String> payload,
      Value<int> rowid,
    });

class $$RecommendationSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $RecommendationSnapshotsTable> {
  $$RecommendationSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecommendationSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecommendationSnapshotsTable> {
  $$RecommendationSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecommendationSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecommendationSnapshotsTable> {
  $$RecommendationSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get slot =>
      $composableBuilder(column: $table.slot, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);
}

class $$RecommendationSnapshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecommendationSnapshotsTable,
          RecommendationSnapshot,
          $$RecommendationSnapshotsTableFilterComposer,
          $$RecommendationSnapshotsTableOrderingComposer,
          $$RecommendationSnapshotsTableAnnotationComposer,
          $$RecommendationSnapshotsTableCreateCompanionBuilder,
          $$RecommendationSnapshotsTableUpdateCompanionBuilder,
          (
            RecommendationSnapshot,
            BaseReferences<
              _$AppDatabase,
              $RecommendationSnapshotsTable,
              RecommendationSnapshot
            >,
          ),
          RecommendationSnapshot,
          PrefetchHooks Function()
        > {
  $$RecommendationSnapshotsTableTableManager(
    _$AppDatabase db,
    $RecommendationSnapshotsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecommendationSnapshotsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$RecommendationSnapshotsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RecommendationSnapshotsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> sourceId = const Value.absent(),
                Value<String> slot = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecommendationSnapshotsCompanion(
                sourceId: sourceId,
                slot: slot,
                day: day,
                payload: payload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int sourceId,
                required String slot,
                required String day,
                required String payload,
                Value<int> rowid = const Value.absent(),
              }) => RecommendationSnapshotsCompanion.insert(
                sourceId: sourceId,
                slot: slot,
                day: day,
                payload: payload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecommendationSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecommendationSnapshotsTable,
      RecommendationSnapshot,
      $$RecommendationSnapshotsTableFilterComposer,
      $$RecommendationSnapshotsTableOrderingComposer,
      $$RecommendationSnapshotsTableAnnotationComposer,
      $$RecommendationSnapshotsTableCreateCompanionBuilder,
      $$RecommendationSnapshotsTableUpdateCompanionBuilder,
      (
        RecommendationSnapshot,
        BaseReferences<
          _$AppDatabase,
          $RecommendationSnapshotsTable,
          RecommendationSnapshot
        >,
      ),
      RecommendationSnapshot,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SourcesTableTableManager get sources =>
      $$SourcesTableTableManager(_db, _db.sources);
  $$CatalogValidatorsTableTableManager get catalogValidators =>
      $$CatalogValidatorsTableTableManager(_db, _db.catalogValidators);
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
  $$RecentChannelsTableTableManager get recentChannels =>
      $$RecentChannelsTableTableManager(_db, _db.recentChannels);
  $$LiveViewingTableTableManager get liveViewing =>
      $$LiveViewingTableTableManager(_db, _db.liveViewing);
  $$LiveTuningTableTableManager get liveTuning =>
      $$LiveTuningTableTableManager(_db, _db.liveTuning);
  $$LiveGuideLinksTableTableManager get liveGuideLinks =>
      $$LiveGuideLinksTableTableManager(_db, _db.liveGuideLinks);
  $$PlaybackPositionsTableTableManager get playbackPositions =>
      $$PlaybackPositionsTableTableManager(_db, _db.playbackPositions);
  $$WatchedTitlesTableTableManager get watchedTitles =>
      $$WatchedTitlesTableTableManager(_db, _db.watchedTitles);
  $$WatchedEpisodesTableTableManager get watchedEpisodes =>
      $$WatchedEpisodesTableTableManager(_db, _db.watchedEpisodes);
  $$SyncTombstonesTableTableManager get syncTombstones =>
      $$SyncTombstonesTableTableManager(_db, _db.syncTombstones);
  $$DownloadsTableTableManager get downloads =>
      $$DownloadsTableTableManager(_db, _db.downloads);
  $$DiscoveryEntriesTableTableManager get discoveryEntries =>
      $$DiscoveryEntriesTableTableManager(_db, _db.discoveryEntries);
  $$RecommendationSnapshotsTableTableManager get recommendationSnapshots =>
      $$RecommendationSnapshotsTableTableManager(
        _db,
        _db.recommendationSnapshots,
      );
}
