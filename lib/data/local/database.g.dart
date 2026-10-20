// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $AccountsTable extends Accounts with TableInfo<$AccountsTable, Account> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
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
  static const VerificationMeta _imapHostMeta = const VerificationMeta(
    'imapHost',
  );
  @override
  late final GeneratedColumn<String> imapHost = GeneratedColumn<String>(
    'imap_host',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imapPortMeta = const VerificationMeta(
    'imapPort',
  );
  @override
  late final GeneratedColumn<int> imapPort = GeneratedColumn<int>(
    'imap_port',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imapSecurityMeta = const VerificationMeta(
    'imapSecurity',
  );
  @override
  late final GeneratedColumn<String> imapSecurity = GeneratedColumn<String>(
    'imap_security',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _smtpHostMeta = const VerificationMeta(
    'smtpHost',
  );
  @override
  late final GeneratedColumn<String> smtpHost = GeneratedColumn<String>(
    'smtp_host',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _smtpPortMeta = const VerificationMeta(
    'smtpPort',
  );
  @override
  late final GeneratedColumn<int> smtpPort = GeneratedColumn<int>(
    'smtp_port',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _smtpSecurityMeta = const VerificationMeta(
    'smtpSecurity',
  );
  @override
  late final GeneratedColumn<String> smtpSecurity = GeneratedColumn<String>(
    'smtp_security',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _smtpUsernameMeta = const VerificationMeta(
    'smtpUsername',
  );
  @override
  late final GeneratedColumn<String> smtpUsername = GeneratedColumn<String>(
    'smtp_username',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _authMeta = const VerificationMeta('auth');
  @override
  late final GeneratedColumn<String> auth = GeneratedColumn<String>(
    'auth',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('password'),
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    displayName,
    email,
    username,
    imapHost,
    imapPort,
    imapSecurity,
    smtpHost,
    smtpPort,
    smtpSecurity,
    smtpUsername,
    auth,
    enabled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Account> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('imap_host')) {
      context.handle(
        _imapHostMeta,
        imapHost.isAcceptableOrUnknown(data['imap_host']!, _imapHostMeta),
      );
    } else if (isInserting) {
      context.missing(_imapHostMeta);
    }
    if (data.containsKey('imap_port')) {
      context.handle(
        _imapPortMeta,
        imapPort.isAcceptableOrUnknown(data['imap_port']!, _imapPortMeta),
      );
    } else if (isInserting) {
      context.missing(_imapPortMeta);
    }
    if (data.containsKey('imap_security')) {
      context.handle(
        _imapSecurityMeta,
        imapSecurity.isAcceptableOrUnknown(
          data['imap_security']!,
          _imapSecurityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_imapSecurityMeta);
    }
    if (data.containsKey('smtp_host')) {
      context.handle(
        _smtpHostMeta,
        smtpHost.isAcceptableOrUnknown(data['smtp_host']!, _smtpHostMeta),
      );
    } else if (isInserting) {
      context.missing(_smtpHostMeta);
    }
    if (data.containsKey('smtp_port')) {
      context.handle(
        _smtpPortMeta,
        smtpPort.isAcceptableOrUnknown(data['smtp_port']!, _smtpPortMeta),
      );
    } else if (isInserting) {
      context.missing(_smtpPortMeta);
    }
    if (data.containsKey('smtp_security')) {
      context.handle(
        _smtpSecurityMeta,
        smtpSecurity.isAcceptableOrUnknown(
          data['smtp_security']!,
          _smtpSecurityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_smtpSecurityMeta);
    }
    if (data.containsKey('smtp_username')) {
      context.handle(
        _smtpUsernameMeta,
        smtpUsername.isAcceptableOrUnknown(
          data['smtp_username']!,
          _smtpUsernameMeta,
        ),
      );
    }
    if (data.containsKey('auth')) {
      context.handle(
        _authMeta,
        auth.isAcceptableOrUnknown(data['auth']!, _authMeta),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Account map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Account(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      imapHost: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}imap_host'],
      )!,
      imapPort: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}imap_port'],
      )!,
      imapSecurity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}imap_security'],
      )!,
      smtpHost: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}smtp_host'],
      )!,
      smtpPort: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}smtp_port'],
      )!,
      smtpSecurity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}smtp_security'],
      )!,
      smtpUsername: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}smtp_username'],
      ),
      auth: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}auth'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class Account extends DataClass implements Insertable<Account> {
  final String id;
  final String displayName;
  final String email;
  final String username;
  final String imapHost;
  final int imapPort;
  final String imapSecurity;
  final String smtpHost;
  final int smtpPort;
  final String smtpSecurity;
  final String? smtpUsername;
  final String auth;
  final bool enabled;
  const Account({
    required this.id,
    required this.displayName,
    required this.email,
    required this.username,
    required this.imapHost,
    required this.imapPort,
    required this.imapSecurity,
    required this.smtpHost,
    required this.smtpPort,
    required this.smtpSecurity,
    this.smtpUsername,
    required this.auth,
    required this.enabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['display_name'] = Variable<String>(displayName);
    map['email'] = Variable<String>(email);
    map['username'] = Variable<String>(username);
    map['imap_host'] = Variable<String>(imapHost);
    map['imap_port'] = Variable<int>(imapPort);
    map['imap_security'] = Variable<String>(imapSecurity);
    map['smtp_host'] = Variable<String>(smtpHost);
    map['smtp_port'] = Variable<int>(smtpPort);
    map['smtp_security'] = Variable<String>(smtpSecurity);
    if (!nullToAbsent || smtpUsername != null) {
      map['smtp_username'] = Variable<String>(smtpUsername);
    }
    map['auth'] = Variable<String>(auth);
    map['enabled'] = Variable<bool>(enabled);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      displayName: Value(displayName),
      email: Value(email),
      username: Value(username),
      imapHost: Value(imapHost),
      imapPort: Value(imapPort),
      imapSecurity: Value(imapSecurity),
      smtpHost: Value(smtpHost),
      smtpPort: Value(smtpPort),
      smtpSecurity: Value(smtpSecurity),
      smtpUsername: smtpUsername == null && nullToAbsent
          ? const Value.absent()
          : Value(smtpUsername),
      auth: Value(auth),
      enabled: Value(enabled),
    );
  }

  factory Account.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      id: serializer.fromJson<String>(json['id']),
      displayName: serializer.fromJson<String>(json['displayName']),
      email: serializer.fromJson<String>(json['email']),
      username: serializer.fromJson<String>(json['username']),
      imapHost: serializer.fromJson<String>(json['imapHost']),
      imapPort: serializer.fromJson<int>(json['imapPort']),
      imapSecurity: serializer.fromJson<String>(json['imapSecurity']),
      smtpHost: serializer.fromJson<String>(json['smtpHost']),
      smtpPort: serializer.fromJson<int>(json['smtpPort']),
      smtpSecurity: serializer.fromJson<String>(json['smtpSecurity']),
      smtpUsername: serializer.fromJson<String?>(json['smtpUsername']),
      auth: serializer.fromJson<String>(json['auth']),
      enabled: serializer.fromJson<bool>(json['enabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'displayName': serializer.toJson<String>(displayName),
      'email': serializer.toJson<String>(email),
      'username': serializer.toJson<String>(username),
      'imapHost': serializer.toJson<String>(imapHost),
      'imapPort': serializer.toJson<int>(imapPort),
      'imapSecurity': serializer.toJson<String>(imapSecurity),
      'smtpHost': serializer.toJson<String>(smtpHost),
      'smtpPort': serializer.toJson<int>(smtpPort),
      'smtpSecurity': serializer.toJson<String>(smtpSecurity),
      'smtpUsername': serializer.toJson<String?>(smtpUsername),
      'auth': serializer.toJson<String>(auth),
      'enabled': serializer.toJson<bool>(enabled),
    };
  }

  Account copyWith({
    String? id,
    String? displayName,
    String? email,
    String? username,
    String? imapHost,
    int? imapPort,
    String? imapSecurity,
    String? smtpHost,
    int? smtpPort,
    String? smtpSecurity,
    Value<String?> smtpUsername = const Value.absent(),
    String? auth,
    bool? enabled,
  }) => Account(
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    email: email ?? this.email,
    username: username ?? this.username,
    imapHost: imapHost ?? this.imapHost,
    imapPort: imapPort ?? this.imapPort,
    imapSecurity: imapSecurity ?? this.imapSecurity,
    smtpHost: smtpHost ?? this.smtpHost,
    smtpPort: smtpPort ?? this.smtpPort,
    smtpSecurity: smtpSecurity ?? this.smtpSecurity,
    smtpUsername: smtpUsername.present ? smtpUsername.value : this.smtpUsername,
    auth: auth ?? this.auth,
    enabled: enabled ?? this.enabled,
  );
  Account copyWithCompanion(AccountsCompanion data) {
    return Account(
      id: data.id.present ? data.id.value : this.id,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      email: data.email.present ? data.email.value : this.email,
      username: data.username.present ? data.username.value : this.username,
      imapHost: data.imapHost.present ? data.imapHost.value : this.imapHost,
      imapPort: data.imapPort.present ? data.imapPort.value : this.imapPort,
      imapSecurity: data.imapSecurity.present
          ? data.imapSecurity.value
          : this.imapSecurity,
      smtpHost: data.smtpHost.present ? data.smtpHost.value : this.smtpHost,
      smtpPort: data.smtpPort.present ? data.smtpPort.value : this.smtpPort,
      smtpSecurity: data.smtpSecurity.present
          ? data.smtpSecurity.value
          : this.smtpSecurity,
      smtpUsername: data.smtpUsername.present
          ? data.smtpUsername.value
          : this.smtpUsername,
      auth: data.auth.present ? data.auth.value : this.auth,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Account(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('email: $email, ')
          ..write('username: $username, ')
          ..write('imapHost: $imapHost, ')
          ..write('imapPort: $imapPort, ')
          ..write('imapSecurity: $imapSecurity, ')
          ..write('smtpHost: $smtpHost, ')
          ..write('smtpPort: $smtpPort, ')
          ..write('smtpSecurity: $smtpSecurity, ')
          ..write('smtpUsername: $smtpUsername, ')
          ..write('auth: $auth, ')
          ..write('enabled: $enabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    displayName,
    email,
    username,
    imapHost,
    imapPort,
    imapSecurity,
    smtpHost,
    smtpPort,
    smtpSecurity,
    smtpUsername,
    auth,
    enabled,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Account &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.email == this.email &&
          other.username == this.username &&
          other.imapHost == this.imapHost &&
          other.imapPort == this.imapPort &&
          other.imapSecurity == this.imapSecurity &&
          other.smtpHost == this.smtpHost &&
          other.smtpPort == this.smtpPort &&
          other.smtpSecurity == this.smtpSecurity &&
          other.smtpUsername == this.smtpUsername &&
          other.auth == this.auth &&
          other.enabled == this.enabled);
}

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<String> id;
  final Value<String> displayName;
  final Value<String> email;
  final Value<String> username;
  final Value<String> imapHost;
  final Value<int> imapPort;
  final Value<String> imapSecurity;
  final Value<String> smtpHost;
  final Value<int> smtpPort;
  final Value<String> smtpSecurity;
  final Value<String?> smtpUsername;
  final Value<String> auth;
  final Value<bool> enabled;
  final Value<int> rowid;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.email = const Value.absent(),
    this.username = const Value.absent(),
    this.imapHost = const Value.absent(),
    this.imapPort = const Value.absent(),
    this.imapSecurity = const Value.absent(),
    this.smtpHost = const Value.absent(),
    this.smtpPort = const Value.absent(),
    this.smtpSecurity = const Value.absent(),
    this.smtpUsername = const Value.absent(),
    this.auth = const Value.absent(),
    this.enabled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsCompanion.insert({
    required String id,
    required String displayName,
    required String email,
    required String username,
    required String imapHost,
    required int imapPort,
    required String imapSecurity,
    required String smtpHost,
    required int smtpPort,
    required String smtpSecurity,
    this.smtpUsername = const Value.absent(),
    this.auth = const Value.absent(),
    this.enabled = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       displayName = Value(displayName),
       email = Value(email),
       username = Value(username),
       imapHost = Value(imapHost),
       imapPort = Value(imapPort),
       imapSecurity = Value(imapSecurity),
       smtpHost = Value(smtpHost),
       smtpPort = Value(smtpPort),
       smtpSecurity = Value(smtpSecurity);
  static Insertable<Account> custom({
    Expression<String>? id,
    Expression<String>? displayName,
    Expression<String>? email,
    Expression<String>? username,
    Expression<String>? imapHost,
    Expression<int>? imapPort,
    Expression<String>? imapSecurity,
    Expression<String>? smtpHost,
    Expression<int>? smtpPort,
    Expression<String>? smtpSecurity,
    Expression<String>? smtpUsername,
    Expression<String>? auth,
    Expression<bool>? enabled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (email != null) 'email': email,
      if (username != null) 'username': username,
      if (imapHost != null) 'imap_host': imapHost,
      if (imapPort != null) 'imap_port': imapPort,
      if (imapSecurity != null) 'imap_security': imapSecurity,
      if (smtpHost != null) 'smtp_host': smtpHost,
      if (smtpPort != null) 'smtp_port': smtpPort,
      if (smtpSecurity != null) 'smtp_security': smtpSecurity,
      if (smtpUsername != null) 'smtp_username': smtpUsername,
      if (auth != null) 'auth': auth,
      if (enabled != null) 'enabled': enabled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsCompanion copyWith({
    Value<String>? id,
    Value<String>? displayName,
    Value<String>? email,
    Value<String>? username,
    Value<String>? imapHost,
    Value<int>? imapPort,
    Value<String>? imapSecurity,
    Value<String>? smtpHost,
    Value<int>? smtpPort,
    Value<String>? smtpSecurity,
    Value<String?>? smtpUsername,
    Value<String>? auth,
    Value<bool>? enabled,
    Value<int>? rowid,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      username: username ?? this.username,
      imapHost: imapHost ?? this.imapHost,
      imapPort: imapPort ?? this.imapPort,
      imapSecurity: imapSecurity ?? this.imapSecurity,
      smtpHost: smtpHost ?? this.smtpHost,
      smtpPort: smtpPort ?? this.smtpPort,
      smtpSecurity: smtpSecurity ?? this.smtpSecurity,
      smtpUsername: smtpUsername ?? this.smtpUsername,
      auth: auth ?? this.auth,
      enabled: enabled ?? this.enabled,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (imapHost.present) {
      map['imap_host'] = Variable<String>(imapHost.value);
    }
    if (imapPort.present) {
      map['imap_port'] = Variable<int>(imapPort.value);
    }
    if (imapSecurity.present) {
      map['imap_security'] = Variable<String>(imapSecurity.value);
    }
    if (smtpHost.present) {
      map['smtp_host'] = Variable<String>(smtpHost.value);
    }
    if (smtpPort.present) {
      map['smtp_port'] = Variable<int>(smtpPort.value);
    }
    if (smtpSecurity.present) {
      map['smtp_security'] = Variable<String>(smtpSecurity.value);
    }
    if (smtpUsername.present) {
      map['smtp_username'] = Variable<String>(smtpUsername.value);
    }
    if (auth.present) {
      map['auth'] = Variable<String>(auth.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('email: $email, ')
          ..write('username: $username, ')
          ..write('imapHost: $imapHost, ')
          ..write('imapPort: $imapPort, ')
          ..write('imapSecurity: $imapSecurity, ')
          ..write('smtpHost: $smtpHost, ')
          ..write('smtpPort: $smtpPort, ')
          ..write('smtpSecurity: $smtpSecurity, ')
          ..write('smtpUsername: $smtpUsername, ')
          ..write('auth: $auth, ')
          ..write('enabled: $enabled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IdentitiesTable extends Identities
    with TableInfo<$IdentitiesTable, Identity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IdentitiesTable(this.attachedDatabase, [this._alias]);
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id) ON DELETE CASCADE',
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
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _replyToMeta = const VerificationMeta(
    'replyTo',
  );
  @override
  late final GeneratedColumn<String> replyTo = GeneratedColumn<String>(
    'reply_to',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _signatureMeta = const VerificationMeta(
    'signature',
  );
  @override
  late final GeneratedColumn<String> signature = GeneratedColumn<String>(
    'signature',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _signatureHtmlMeta = const VerificationMeta(
    'signatureHtml',
  );
  @override
  late final GeneratedColumn<String> signatureHtml = GeneratedColumn<String>(
    'signature_html',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    name,
    email,
    replyTo,
    signature,
    signatureHtml,
    isDefault,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'identities';
  @override
  VerificationContext validateIntegrity(
    Insertable<Identity> instance, {
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
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('reply_to')) {
      context.handle(
        _replyToMeta,
        replyTo.isAcceptableOrUnknown(data['reply_to']!, _replyToMeta),
      );
    }
    if (data.containsKey('signature')) {
      context.handle(
        _signatureMeta,
        signature.isAcceptableOrUnknown(data['signature']!, _signatureMeta),
      );
    }
    if (data.containsKey('signature_html')) {
      context.handle(
        _signatureHtmlMeta,
        signatureHtml.isAcceptableOrUnknown(
          data['signature_html']!,
          _signatureHtmlMeta,
        ),
      );
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Identity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Identity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      replyTo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reply_to'],
      ),
      signature: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}signature'],
      )!,
      signatureHtml: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}signature_html'],
      ),
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
    );
  }

  @override
  $IdentitiesTable createAlias(String alias) {
    return $IdentitiesTable(attachedDatabase, alias);
  }
}

class Identity extends DataClass implements Insertable<Identity> {
  final String id;
  final String accountId;
  final String name;
  final String email;
  final String? replyTo;
  final String signature;

  /// Optional HTML signature (schema v3).
  final String? signatureHtml;
  final bool isDefault;
  const Identity({
    required this.id,
    required this.accountId,
    required this.name,
    required this.email,
    this.replyTo,
    required this.signature,
    this.signatureHtml,
    required this.isDefault,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    map['name'] = Variable<String>(name);
    map['email'] = Variable<String>(email);
    if (!nullToAbsent || replyTo != null) {
      map['reply_to'] = Variable<String>(replyTo);
    }
    map['signature'] = Variable<String>(signature);
    if (!nullToAbsent || signatureHtml != null) {
      map['signature_html'] = Variable<String>(signatureHtml);
    }
    map['is_default'] = Variable<bool>(isDefault);
    return map;
  }

  IdentitiesCompanion toCompanion(bool nullToAbsent) {
    return IdentitiesCompanion(
      id: Value(id),
      accountId: Value(accountId),
      name: Value(name),
      email: Value(email),
      replyTo: replyTo == null && nullToAbsent
          ? const Value.absent()
          : Value(replyTo),
      signature: Value(signature),
      signatureHtml: signatureHtml == null && nullToAbsent
          ? const Value.absent()
          : Value(signatureHtml),
      isDefault: Value(isDefault),
    );
  }

  factory Identity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Identity(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      name: serializer.fromJson<String>(json['name']),
      email: serializer.fromJson<String>(json['email']),
      replyTo: serializer.fromJson<String?>(json['replyTo']),
      signature: serializer.fromJson<String>(json['signature']),
      signatureHtml: serializer.fromJson<String?>(json['signatureHtml']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'name': serializer.toJson<String>(name),
      'email': serializer.toJson<String>(email),
      'replyTo': serializer.toJson<String?>(replyTo),
      'signature': serializer.toJson<String>(signature),
      'signatureHtml': serializer.toJson<String?>(signatureHtml),
      'isDefault': serializer.toJson<bool>(isDefault),
    };
  }

  Identity copyWith({
    String? id,
    String? accountId,
    String? name,
    String? email,
    Value<String?> replyTo = const Value.absent(),
    String? signature,
    Value<String?> signatureHtml = const Value.absent(),
    bool? isDefault,
  }) => Identity(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    name: name ?? this.name,
    email: email ?? this.email,
    replyTo: replyTo.present ? replyTo.value : this.replyTo,
    signature: signature ?? this.signature,
    signatureHtml: signatureHtml.present
        ? signatureHtml.value
        : this.signatureHtml,
    isDefault: isDefault ?? this.isDefault,
  );
  Identity copyWithCompanion(IdentitiesCompanion data) {
    return Identity(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      name: data.name.present ? data.name.value : this.name,
      email: data.email.present ? data.email.value : this.email,
      replyTo: data.replyTo.present ? data.replyTo.value : this.replyTo,
      signature: data.signature.present ? data.signature.value : this.signature,
      signatureHtml: data.signatureHtml.present
          ? data.signatureHtml.value
          : this.signatureHtml,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Identity(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('replyTo: $replyTo, ')
          ..write('signature: $signature, ')
          ..write('signatureHtml: $signatureHtml, ')
          ..write('isDefault: $isDefault')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountId,
    name,
    email,
    replyTo,
    signature,
    signatureHtml,
    isDefault,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Identity &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.name == this.name &&
          other.email == this.email &&
          other.replyTo == this.replyTo &&
          other.signature == this.signature &&
          other.signatureHtml == this.signatureHtml &&
          other.isDefault == this.isDefault);
}

class IdentitiesCompanion extends UpdateCompanion<Identity> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<String> name;
  final Value<String> email;
  final Value<String?> replyTo;
  final Value<String> signature;
  final Value<String?> signatureHtml;
  final Value<bool> isDefault;
  final Value<int> rowid;
  const IdentitiesCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.replyTo = const Value.absent(),
    this.signature = const Value.absent(),
    this.signatureHtml = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IdentitiesCompanion.insert({
    required String id,
    required String accountId,
    required String name,
    required String email,
    this.replyTo = const Value.absent(),
    this.signature = const Value.absent(),
    this.signatureHtml = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accountId = Value(accountId),
       name = Value(name),
       email = Value(email);
  static Insertable<Identity> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<String>? name,
    Expression<String>? email,
    Expression<String>? replyTo,
    Expression<String>? signature,
    Expression<String>? signatureHtml,
    Expression<bool>? isDefault,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (replyTo != null) 'reply_to': replyTo,
      if (signature != null) 'signature': signature,
      if (signatureHtml != null) 'signature_html': signatureHtml,
      if (isDefault != null) 'is_default': isDefault,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IdentitiesCompanion copyWith({
    Value<String>? id,
    Value<String>? accountId,
    Value<String>? name,
    Value<String>? email,
    Value<String?>? replyTo,
    Value<String>? signature,
    Value<String?>? signatureHtml,
    Value<bool>? isDefault,
    Value<int>? rowid,
  }) {
    return IdentitiesCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      name: name ?? this.name,
      email: email ?? this.email,
      replyTo: replyTo ?? this.replyTo,
      signature: signature ?? this.signature,
      signatureHtml: signatureHtml ?? this.signatureHtml,
      isDefault: isDefault ?? this.isDefault,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (replyTo.present) {
      map['reply_to'] = Variable<String>(replyTo.value);
    }
    if (signature.present) {
      map['signature'] = Variable<String>(signature.value);
    }
    if (signatureHtml.present) {
      map['signature_html'] = Variable<String>(signatureHtml.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IdentitiesCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('replyTo: $replyTo, ')
          ..write('signature: $signature, ')
          ..write('signatureHtml: $signatureHtml, ')
          ..write('isDefault: $isDefault, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FoldersTable extends Folders with TableInfo<$FoldersTable, Folder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoldersTable(this.attachedDatabase, [this._alias]);
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
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
  static const VerificationMeta _delimiterMeta = const VerificationMeta(
    'delimiter',
  );
  @override
  late final GeneratedColumn<String> delimiter = GeneratedColumn<String>(
    'delimiter',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _specialUseMeta = const VerificationMeta(
    'specialUse',
  );
  @override
  late final GeneratedColumn<String> specialUse = GeneratedColumn<String>(
    'special_use',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _uidValidityMeta = const VerificationMeta(
    'uidValidity',
  );
  @override
  late final GeneratedColumn<int> uidValidity = GeneratedColumn<int>(
    'uid_validity',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uidNextMeta = const VerificationMeta(
    'uidNext',
  );
  @override
  late final GeneratedColumn<int> uidNext = GeneratedColumn<int>(
    'uid_next',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _highestModSeqMeta = const VerificationMeta(
    'highestModSeq',
  );
  @override
  late final GeneratedColumn<int> highestModSeq = GeneratedColumn<int>(
    'highest_mod_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _messageCountMeta = const VerificationMeta(
    'messageCount',
  );
  @override
  late final GeneratedColumn<int> messageCount = GeneratedColumn<int>(
    'message_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _unseenCountMeta = const VerificationMeta(
    'unseenCount',
  );
  @override
  late final GeneratedColumn<int> unseenCount = GeneratedColumn<int>(
    'unseen_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _subscribedMeta = const VerificationMeta(
    'subscribed',
  );
  @override
  late final GeneratedColumn<bool> subscribed = GeneratedColumn<bool>(
    'subscribed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("subscribed" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _selectableMeta = const VerificationMeta(
    'selectable',
  );
  @override
  late final GeneratedColumn<bool> selectable = GeneratedColumn<bool>(
    'selectable',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("selectable" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<int> lastSyncedAt = GeneratedColumn<int>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    path,
    name,
    delimiter,
    specialUse,
    uidValidity,
    uidNext,
    highestModSeq,
    messageCount,
    unseenCount,
    subscribed,
    selectable,
    lastSyncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'folders';
  @override
  VerificationContext validateIntegrity(
    Insertable<Folder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('delimiter')) {
      context.handle(
        _delimiterMeta,
        delimiter.isAcceptableOrUnknown(data['delimiter']!, _delimiterMeta),
      );
    } else if (isInserting) {
      context.missing(_delimiterMeta);
    }
    if (data.containsKey('special_use')) {
      context.handle(
        _specialUseMeta,
        specialUse.isAcceptableOrUnknown(data['special_use']!, _specialUseMeta),
      );
    }
    if (data.containsKey('uid_validity')) {
      context.handle(
        _uidValidityMeta,
        uidValidity.isAcceptableOrUnknown(
          data['uid_validity']!,
          _uidValidityMeta,
        ),
      );
    }
    if (data.containsKey('uid_next')) {
      context.handle(
        _uidNextMeta,
        uidNext.isAcceptableOrUnknown(data['uid_next']!, _uidNextMeta),
      );
    }
    if (data.containsKey('highest_mod_seq')) {
      context.handle(
        _highestModSeqMeta,
        highestModSeq.isAcceptableOrUnknown(
          data['highest_mod_seq']!,
          _highestModSeqMeta,
        ),
      );
    }
    if (data.containsKey('message_count')) {
      context.handle(
        _messageCountMeta,
        messageCount.isAcceptableOrUnknown(
          data['message_count']!,
          _messageCountMeta,
        ),
      );
    }
    if (data.containsKey('unseen_count')) {
      context.handle(
        _unseenCountMeta,
        unseenCount.isAcceptableOrUnknown(
          data['unseen_count']!,
          _unseenCountMeta,
        ),
      );
    }
    if (data.containsKey('subscribed')) {
      context.handle(
        _subscribedMeta,
        subscribed.isAcceptableOrUnknown(data['subscribed']!, _subscribedMeta),
      );
    }
    if (data.containsKey('selectable')) {
      context.handle(
        _selectableMeta,
        selectable.isAcceptableOrUnknown(data['selectable']!, _selectableMeta),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, path};
  @override
  Folder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Folder(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      delimiter: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}delimiter'],
      )!,
      specialUse: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}special_use'],
      )!,
      uidValidity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}uid_validity'],
      ),
      uidNext: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}uid_next'],
      ),
      highestModSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}highest_mod_seq'],
      ),
      messageCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}message_count'],
      )!,
      unseenCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unseen_count'],
      )!,
      subscribed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}subscribed'],
      )!,
      selectable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}selectable'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_synced_at'],
      ),
    );
  }

  @override
  $FoldersTable createAlias(String alias) {
    return $FoldersTable(attachedDatabase, alias);
  }
}

class Folder extends DataClass implements Insertable<Folder> {
  final String accountId;
  final String path;
  final String name;
  final String delimiter;
  final String specialUse;
  final int? uidValidity;
  final int? uidNext;
  final int? highestModSeq;
  final int messageCount;
  final int unseenCount;
  final bool subscribed;
  final bool selectable;
  final int? lastSyncedAt;
  const Folder({
    required this.accountId,
    required this.path,
    required this.name,
    required this.delimiter,
    required this.specialUse,
    this.uidValidity,
    this.uidNext,
    this.highestModSeq,
    required this.messageCount,
    required this.unseenCount,
    required this.subscribed,
    required this.selectable,
    this.lastSyncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['path'] = Variable<String>(path);
    map['name'] = Variable<String>(name);
    map['delimiter'] = Variable<String>(delimiter);
    map['special_use'] = Variable<String>(specialUse);
    if (!nullToAbsent || uidValidity != null) {
      map['uid_validity'] = Variable<int>(uidValidity);
    }
    if (!nullToAbsent || uidNext != null) {
      map['uid_next'] = Variable<int>(uidNext);
    }
    if (!nullToAbsent || highestModSeq != null) {
      map['highest_mod_seq'] = Variable<int>(highestModSeq);
    }
    map['message_count'] = Variable<int>(messageCount);
    map['unseen_count'] = Variable<int>(unseenCount);
    map['subscribed'] = Variable<bool>(subscribed);
    map['selectable'] = Variable<bool>(selectable);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<int>(lastSyncedAt);
    }
    return map;
  }

  FoldersCompanion toCompanion(bool nullToAbsent) {
    return FoldersCompanion(
      accountId: Value(accountId),
      path: Value(path),
      name: Value(name),
      delimiter: Value(delimiter),
      specialUse: Value(specialUse),
      uidValidity: uidValidity == null && nullToAbsent
          ? const Value.absent()
          : Value(uidValidity),
      uidNext: uidNext == null && nullToAbsent
          ? const Value.absent()
          : Value(uidNext),
      highestModSeq: highestModSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(highestModSeq),
      messageCount: Value(messageCount),
      unseenCount: Value(unseenCount),
      subscribed: Value(subscribed),
      selectable: Value(selectable),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
    );
  }

  factory Folder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Folder(
      accountId: serializer.fromJson<String>(json['accountId']),
      path: serializer.fromJson<String>(json['path']),
      name: serializer.fromJson<String>(json['name']),
      delimiter: serializer.fromJson<String>(json['delimiter']),
      specialUse: serializer.fromJson<String>(json['specialUse']),
      uidValidity: serializer.fromJson<int?>(json['uidValidity']),
      uidNext: serializer.fromJson<int?>(json['uidNext']),
      highestModSeq: serializer.fromJson<int?>(json['highestModSeq']),
      messageCount: serializer.fromJson<int>(json['messageCount']),
      unseenCount: serializer.fromJson<int>(json['unseenCount']),
      subscribed: serializer.fromJson<bool>(json['subscribed']),
      selectable: serializer.fromJson<bool>(json['selectable']),
      lastSyncedAt: serializer.fromJson<int?>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'path': serializer.toJson<String>(path),
      'name': serializer.toJson<String>(name),
      'delimiter': serializer.toJson<String>(delimiter),
      'specialUse': serializer.toJson<String>(specialUse),
      'uidValidity': serializer.toJson<int?>(uidValidity),
      'uidNext': serializer.toJson<int?>(uidNext),
      'highestModSeq': serializer.toJson<int?>(highestModSeq),
      'messageCount': serializer.toJson<int>(messageCount),
      'unseenCount': serializer.toJson<int>(unseenCount),
      'subscribed': serializer.toJson<bool>(subscribed),
      'selectable': serializer.toJson<bool>(selectable),
      'lastSyncedAt': serializer.toJson<int?>(lastSyncedAt),
    };
  }

  Folder copyWith({
    String? accountId,
    String? path,
    String? name,
    String? delimiter,
    String? specialUse,
    Value<int?> uidValidity = const Value.absent(),
    Value<int?> uidNext = const Value.absent(),
    Value<int?> highestModSeq = const Value.absent(),
    int? messageCount,
    int? unseenCount,
    bool? subscribed,
    bool? selectable,
    Value<int?> lastSyncedAt = const Value.absent(),
  }) => Folder(
    accountId: accountId ?? this.accountId,
    path: path ?? this.path,
    name: name ?? this.name,
    delimiter: delimiter ?? this.delimiter,
    specialUse: specialUse ?? this.specialUse,
    uidValidity: uidValidity.present ? uidValidity.value : this.uidValidity,
    uidNext: uidNext.present ? uidNext.value : this.uidNext,
    highestModSeq: highestModSeq.present
        ? highestModSeq.value
        : this.highestModSeq,
    messageCount: messageCount ?? this.messageCount,
    unseenCount: unseenCount ?? this.unseenCount,
    subscribed: subscribed ?? this.subscribed,
    selectable: selectable ?? this.selectable,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
  );
  Folder copyWithCompanion(FoldersCompanion data) {
    return Folder(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      path: data.path.present ? data.path.value : this.path,
      name: data.name.present ? data.name.value : this.name,
      delimiter: data.delimiter.present ? data.delimiter.value : this.delimiter,
      specialUse: data.specialUse.present
          ? data.specialUse.value
          : this.specialUse,
      uidValidity: data.uidValidity.present
          ? data.uidValidity.value
          : this.uidValidity,
      uidNext: data.uidNext.present ? data.uidNext.value : this.uidNext,
      highestModSeq: data.highestModSeq.present
          ? data.highestModSeq.value
          : this.highestModSeq,
      messageCount: data.messageCount.present
          ? data.messageCount.value
          : this.messageCount,
      unseenCount: data.unseenCount.present
          ? data.unseenCount.value
          : this.unseenCount,
      subscribed: data.subscribed.present
          ? data.subscribed.value
          : this.subscribed,
      selectable: data.selectable.present
          ? data.selectable.value
          : this.selectable,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Folder(')
          ..write('accountId: $accountId, ')
          ..write('path: $path, ')
          ..write('name: $name, ')
          ..write('delimiter: $delimiter, ')
          ..write('specialUse: $specialUse, ')
          ..write('uidValidity: $uidValidity, ')
          ..write('uidNext: $uidNext, ')
          ..write('highestModSeq: $highestModSeq, ')
          ..write('messageCount: $messageCount, ')
          ..write('unseenCount: $unseenCount, ')
          ..write('subscribed: $subscribed, ')
          ..write('selectable: $selectable, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    accountId,
    path,
    name,
    delimiter,
    specialUse,
    uidValidity,
    uidNext,
    highestModSeq,
    messageCount,
    unseenCount,
    subscribed,
    selectable,
    lastSyncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Folder &&
          other.accountId == this.accountId &&
          other.path == this.path &&
          other.name == this.name &&
          other.delimiter == this.delimiter &&
          other.specialUse == this.specialUse &&
          other.uidValidity == this.uidValidity &&
          other.uidNext == this.uidNext &&
          other.highestModSeq == this.highestModSeq &&
          other.messageCount == this.messageCount &&
          other.unseenCount == this.unseenCount &&
          other.subscribed == this.subscribed &&
          other.selectable == this.selectable &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class FoldersCompanion extends UpdateCompanion<Folder> {
  final Value<String> accountId;
  final Value<String> path;
  final Value<String> name;
  final Value<String> delimiter;
  final Value<String> specialUse;
  final Value<int?> uidValidity;
  final Value<int?> uidNext;
  final Value<int?> highestModSeq;
  final Value<int> messageCount;
  final Value<int> unseenCount;
  final Value<bool> subscribed;
  final Value<bool> selectable;
  final Value<int?> lastSyncedAt;
  final Value<int> rowid;
  const FoldersCompanion({
    this.accountId = const Value.absent(),
    this.path = const Value.absent(),
    this.name = const Value.absent(),
    this.delimiter = const Value.absent(),
    this.specialUse = const Value.absent(),
    this.uidValidity = const Value.absent(),
    this.uidNext = const Value.absent(),
    this.highestModSeq = const Value.absent(),
    this.messageCount = const Value.absent(),
    this.unseenCount = const Value.absent(),
    this.subscribed = const Value.absent(),
    this.selectable = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FoldersCompanion.insert({
    required String accountId,
    required String path,
    required String name,
    required String delimiter,
    this.specialUse = const Value.absent(),
    this.uidValidity = const Value.absent(),
    this.uidNext = const Value.absent(),
    this.highestModSeq = const Value.absent(),
    this.messageCount = const Value.absent(),
    this.unseenCount = const Value.absent(),
    this.subscribed = const Value.absent(),
    this.selectable = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       path = Value(path),
       name = Value(name),
       delimiter = Value(delimiter);
  static Insertable<Folder> custom({
    Expression<String>? accountId,
    Expression<String>? path,
    Expression<String>? name,
    Expression<String>? delimiter,
    Expression<String>? specialUse,
    Expression<int>? uidValidity,
    Expression<int>? uidNext,
    Expression<int>? highestModSeq,
    Expression<int>? messageCount,
    Expression<int>? unseenCount,
    Expression<bool>? subscribed,
    Expression<bool>? selectable,
    Expression<int>? lastSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (path != null) 'path': path,
      if (name != null) 'name': name,
      if (delimiter != null) 'delimiter': delimiter,
      if (specialUse != null) 'special_use': specialUse,
      if (uidValidity != null) 'uid_validity': uidValidity,
      if (uidNext != null) 'uid_next': uidNext,
      if (highestModSeq != null) 'highest_mod_seq': highestModSeq,
      if (messageCount != null) 'message_count': messageCount,
      if (unseenCount != null) 'unseen_count': unseenCount,
      if (subscribed != null) 'subscribed': subscribed,
      if (selectable != null) 'selectable': selectable,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FoldersCompanion copyWith({
    Value<String>? accountId,
    Value<String>? path,
    Value<String>? name,
    Value<String>? delimiter,
    Value<String>? specialUse,
    Value<int?>? uidValidity,
    Value<int?>? uidNext,
    Value<int?>? highestModSeq,
    Value<int>? messageCount,
    Value<int>? unseenCount,
    Value<bool>? subscribed,
    Value<bool>? selectable,
    Value<int?>? lastSyncedAt,
    Value<int>? rowid,
  }) {
    return FoldersCompanion(
      accountId: accountId ?? this.accountId,
      path: path ?? this.path,
      name: name ?? this.name,
      delimiter: delimiter ?? this.delimiter,
      specialUse: specialUse ?? this.specialUse,
      uidValidity: uidValidity ?? this.uidValidity,
      uidNext: uidNext ?? this.uidNext,
      highestModSeq: highestModSeq ?? this.highestModSeq,
      messageCount: messageCount ?? this.messageCount,
      unseenCount: unseenCount ?? this.unseenCount,
      subscribed: subscribed ?? this.subscribed,
      selectable: selectable ?? this.selectable,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (delimiter.present) {
      map['delimiter'] = Variable<String>(delimiter.value);
    }
    if (specialUse.present) {
      map['special_use'] = Variable<String>(specialUse.value);
    }
    if (uidValidity.present) {
      map['uid_validity'] = Variable<int>(uidValidity.value);
    }
    if (uidNext.present) {
      map['uid_next'] = Variable<int>(uidNext.value);
    }
    if (highestModSeq.present) {
      map['highest_mod_seq'] = Variable<int>(highestModSeq.value);
    }
    if (messageCount.present) {
      map['message_count'] = Variable<int>(messageCount.value);
    }
    if (unseenCount.present) {
      map['unseen_count'] = Variable<int>(unseenCount.value);
    }
    if (subscribed.present) {
      map['subscribed'] = Variable<bool>(subscribed.value);
    }
    if (selectable.present) {
      map['selectable'] = Variable<bool>(selectable.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<int>(lastSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoldersCompanion(')
          ..write('accountId: $accountId, ')
          ..write('path: $path, ')
          ..write('name: $name, ')
          ..write('delimiter: $delimiter, ')
          ..write('specialUse: $specialUse, ')
          ..write('uidValidity: $uidValidity, ')
          ..write('uidNext: $uidNext, ')
          ..write('highestModSeq: $highestModSeq, ')
          ..write('messageCount: $messageCount, ')
          ..write('unseenCount: $unseenCount, ')
          ..write('subscribed: $subscribed, ')
          ..write('selectable: $selectable, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages with TableInfo<$MessagesTable, Message> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _messageIdHashMeta = const VerificationMeta(
    'messageIdHash',
  );
  @override
  late final GeneratedColumn<String> messageIdHash = GeneratedColumn<String>(
    'message_id_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _folderPathMeta = const VerificationMeta(
    'folderPath',
  );
  @override
  late final GeneratedColumn<String> folderPath = GeneratedColumn<String>(
    'folder_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<int> uid = GeneratedColumn<int>(
    'uid',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uidValidityMeta = const VerificationMeta(
    'uidValidity',
  );
  @override
  late final GeneratedColumn<int> uidValidity = GeneratedColumn<int>(
    'uid_validity',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _fromEmailMeta = const VerificationMeta(
    'fromEmail',
  );
  @override
  late final GeneratedColumn<String> fromEmail = GeneratedColumn<String>(
    'from_email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fromNameMeta = const VerificationMeta(
    'fromName',
  );
  @override
  late final GeneratedColumn<String> fromName = GeneratedColumn<String>(
    'from_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _toAddressesJsonMeta = const VerificationMeta(
    'toAddressesJson',
  );
  @override
  late final GeneratedColumn<String> toAddressesJson = GeneratedColumn<String>(
    'to_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _ccJsonMeta = const VerificationMeta('ccJson');
  @override
  late final GeneratedColumn<String> ccJson = GeneratedColumn<String>(
    'cc_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _replyToMeta = const VerificationMeta(
    'replyTo',
  );
  @override
  late final GeneratedColumn<String> replyTo = GeneratedColumn<String>(
    'reply_to',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<int> date = GeneratedColumn<int>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _internalDateMeta = const VerificationMeta(
    'internalDate',
  );
  @override
  late final GeneratedColumn<int> internalDate = GeneratedColumn<int>(
    'internal_date',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _listIdMeta = const VerificationMeta('listId');
  @override
  late final GeneratedColumn<String> listId = GeneratedColumn<String>(
    'list_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inReplyToMeta = const VerificationMeta(
    'inReplyTo',
  );
  @override
  late final GeneratedColumn<String> inReplyTo = GeneratedColumn<String>(
    'in_reply_to',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _referencesJsonMeta = const VerificationMeta(
    'referencesJson',
  );
  @override
  late final GeneratedColumn<String> referencesJson = GeneratedColumn<String>(
    'references_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _precedenceMeta = const VerificationMeta(
    'precedence',
  );
  @override
  late final GeneratedColumn<String> precedence = GeneratedColumn<String>(
    'precedence',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _autoSubmittedMeta = const VerificationMeta(
    'autoSubmitted',
  );
  @override
  late final GeneratedColumn<String> autoSubmitted = GeneratedColumn<String>(
    'auto_submitted',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hasListUnsubscribeMeta =
      const VerificationMeta('hasListUnsubscribe');
  @override
  late final GeneratedColumn<bool> hasListUnsubscribe = GeneratedColumn<bool>(
    'has_list_unsubscribe',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_list_unsubscribe" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _flagsJsonMeta = const VerificationMeta(
    'flagsJson',
  );
  @override
  late final GeneratedColumn<String> flagsJson = GeneratedColumn<String>(
    'flags_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
    'size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _snippetMeta = const VerificationMeta(
    'snippet',
  );
  @override
  late final GeneratedColumn<String> snippet = GeneratedColumn<String>(
    'snippet',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _attachmentsJsonMeta = const VerificationMeta(
    'attachmentsJson',
  );
  @override
  late final GeneratedColumn<String> attachmentsJson = GeneratedColumn<String>(
    'attachments_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _lastOpenedAtMeta = const VerificationMeta(
    'lastOpenedAt',
  );
  @override
  late final GeneratedColumn<int> lastOpenedAt = GeneratedColumn<int>(
    'last_opened_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    messageIdHash,
    folderPath,
    uid,
    uidValidity,
    messageId,
    subject,
    fromEmail,
    fromName,
    toAddressesJson,
    ccJson,
    replyTo,
    date,
    internalDate,
    listId,
    inReplyTo,
    referencesJson,
    precedence,
    autoSubmitted,
    hasListUnsubscribe,
    flagsJson,
    size,
    snippet,
    attachmentsJson,
    lastOpenedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<Message> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('message_id_hash')) {
      context.handle(
        _messageIdHashMeta,
        messageIdHash.isAcceptableOrUnknown(
          data['message_id_hash']!,
          _messageIdHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_messageIdHashMeta);
    }
    if (data.containsKey('folder_path')) {
      context.handle(
        _folderPathMeta,
        folderPath.isAcceptableOrUnknown(data['folder_path']!, _folderPathMeta),
      );
    } else if (isInserting) {
      context.missing(_folderPathMeta);
    }
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    }
    if (data.containsKey('uid_validity')) {
      context.handle(
        _uidValidityMeta,
        uidValidity.isAcceptableOrUnknown(
          data['uid_validity']!,
          _uidValidityMeta,
        ),
      );
    }
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    }
    if (data.containsKey('from_email')) {
      context.handle(
        _fromEmailMeta,
        fromEmail.isAcceptableOrUnknown(data['from_email']!, _fromEmailMeta),
      );
    }
    if (data.containsKey('from_name')) {
      context.handle(
        _fromNameMeta,
        fromName.isAcceptableOrUnknown(data['from_name']!, _fromNameMeta),
      );
    }
    if (data.containsKey('to_json')) {
      context.handle(
        _toAddressesJsonMeta,
        toAddressesJson.isAcceptableOrUnknown(
          data['to_json']!,
          _toAddressesJsonMeta,
        ),
      );
    }
    if (data.containsKey('cc_json')) {
      context.handle(
        _ccJsonMeta,
        ccJson.isAcceptableOrUnknown(data['cc_json']!, _ccJsonMeta),
      );
    }
    if (data.containsKey('reply_to')) {
      context.handle(
        _replyToMeta,
        replyTo.isAcceptableOrUnknown(data['reply_to']!, _replyToMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('internal_date')) {
      context.handle(
        _internalDateMeta,
        internalDate.isAcceptableOrUnknown(
          data['internal_date']!,
          _internalDateMeta,
        ),
      );
    }
    if (data.containsKey('list_id')) {
      context.handle(
        _listIdMeta,
        listId.isAcceptableOrUnknown(data['list_id']!, _listIdMeta),
      );
    }
    if (data.containsKey('in_reply_to')) {
      context.handle(
        _inReplyToMeta,
        inReplyTo.isAcceptableOrUnknown(data['in_reply_to']!, _inReplyToMeta),
      );
    }
    if (data.containsKey('references_json')) {
      context.handle(
        _referencesJsonMeta,
        referencesJson.isAcceptableOrUnknown(
          data['references_json']!,
          _referencesJsonMeta,
        ),
      );
    }
    if (data.containsKey('precedence')) {
      context.handle(
        _precedenceMeta,
        precedence.isAcceptableOrUnknown(data['precedence']!, _precedenceMeta),
      );
    }
    if (data.containsKey('auto_submitted')) {
      context.handle(
        _autoSubmittedMeta,
        autoSubmitted.isAcceptableOrUnknown(
          data['auto_submitted']!,
          _autoSubmittedMeta,
        ),
      );
    }
    if (data.containsKey('has_list_unsubscribe')) {
      context.handle(
        _hasListUnsubscribeMeta,
        hasListUnsubscribe.isAcceptableOrUnknown(
          data['has_list_unsubscribe']!,
          _hasListUnsubscribeMeta,
        ),
      );
    }
    if (data.containsKey('flags_json')) {
      context.handle(
        _flagsJsonMeta,
        flagsJson.isAcceptableOrUnknown(data['flags_json']!, _flagsJsonMeta),
      );
    }
    if (data.containsKey('size')) {
      context.handle(
        _sizeMeta,
        size.isAcceptableOrUnknown(data['size']!, _sizeMeta),
      );
    }
    if (data.containsKey('snippet')) {
      context.handle(
        _snippetMeta,
        snippet.isAcceptableOrUnknown(data['snippet']!, _snippetMeta),
      );
    }
    if (data.containsKey('attachments_json')) {
      context.handle(
        _attachmentsJsonMeta,
        attachmentsJson.isAcceptableOrUnknown(
          data['attachments_json']!,
          _attachmentsJsonMeta,
        ),
      );
    }
    if (data.containsKey('last_opened_at')) {
      context.handle(
        _lastOpenedAtMeta,
        lastOpenedAt.isAcceptableOrUnknown(
          data['last_opened_at']!,
          _lastOpenedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    accountId,
    messageIdHash,
    folderPath,
  };
  @override
  Message map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Message(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      messageIdHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id_hash'],
      )!,
      folderPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_path'],
      )!,
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}uid'],
      ),
      uidValidity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}uid_validity'],
      ),
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id'],
      ),
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      )!,
      fromEmail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_email'],
      ),
      fromName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_name'],
      ),
      toAddressesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_json'],
      )!,
      ccJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cc_json'],
      )!,
      replyTo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reply_to'],
      ),
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date'],
      )!,
      internalDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}internal_date'],
      ),
      listId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}list_id'],
      ),
      inReplyTo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}in_reply_to'],
      ),
      referencesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}references_json'],
      )!,
      precedence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}precedence'],
      ),
      autoSubmitted: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}auto_submitted'],
      ),
      hasListUnsubscribe: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_list_unsubscribe'],
      )!,
      flagsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}flags_json'],
      )!,
      size: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size'],
      )!,
      snippet: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}snippet'],
      )!,
      attachmentsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attachments_json'],
      )!,
      lastOpenedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_opened_at'],
      ),
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class Message extends DataClass implements Insertable<Message> {
  final String accountId;
  final String messageIdHash;
  final String folderPath;

  /// Null after a UIDVALIDITY change until relinked.
  final int? uid;
  final int? uidValidity;
  final String? messageId;
  final String subject;
  final String? fromEmail;
  final String? fromName;

  /// Recipient list as JSON. Named `toAddressesJson` in Dart because drift's
  /// generated data class already has a `toJson()` method.
  final String toAddressesJson;
  final String ccJson;
  final String? replyTo;
  final int date;
  final int? internalDate;
  final String? listId;
  final String? inReplyTo;
  final String referencesJson;
  final String? precedence;
  final String? autoSubmitted;
  final bool hasListUnsubscribe;
  final String flagsJson;
  final int size;
  final String snippet;
  final String attachmentsJson;
  final int? lastOpenedAt;
  const Message({
    required this.accountId,
    required this.messageIdHash,
    required this.folderPath,
    this.uid,
    this.uidValidity,
    this.messageId,
    required this.subject,
    this.fromEmail,
    this.fromName,
    required this.toAddressesJson,
    required this.ccJson,
    this.replyTo,
    required this.date,
    this.internalDate,
    this.listId,
    this.inReplyTo,
    required this.referencesJson,
    this.precedence,
    this.autoSubmitted,
    required this.hasListUnsubscribe,
    required this.flagsJson,
    required this.size,
    required this.snippet,
    required this.attachmentsJson,
    this.lastOpenedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['message_id_hash'] = Variable<String>(messageIdHash);
    map['folder_path'] = Variable<String>(folderPath);
    if (!nullToAbsent || uid != null) {
      map['uid'] = Variable<int>(uid);
    }
    if (!nullToAbsent || uidValidity != null) {
      map['uid_validity'] = Variable<int>(uidValidity);
    }
    if (!nullToAbsent || messageId != null) {
      map['message_id'] = Variable<String>(messageId);
    }
    map['subject'] = Variable<String>(subject);
    if (!nullToAbsent || fromEmail != null) {
      map['from_email'] = Variable<String>(fromEmail);
    }
    if (!nullToAbsent || fromName != null) {
      map['from_name'] = Variable<String>(fromName);
    }
    map['to_json'] = Variable<String>(toAddressesJson);
    map['cc_json'] = Variable<String>(ccJson);
    if (!nullToAbsent || replyTo != null) {
      map['reply_to'] = Variable<String>(replyTo);
    }
    map['date'] = Variable<int>(date);
    if (!nullToAbsent || internalDate != null) {
      map['internal_date'] = Variable<int>(internalDate);
    }
    if (!nullToAbsent || listId != null) {
      map['list_id'] = Variable<String>(listId);
    }
    if (!nullToAbsent || inReplyTo != null) {
      map['in_reply_to'] = Variable<String>(inReplyTo);
    }
    map['references_json'] = Variable<String>(referencesJson);
    if (!nullToAbsent || precedence != null) {
      map['precedence'] = Variable<String>(precedence);
    }
    if (!nullToAbsent || autoSubmitted != null) {
      map['auto_submitted'] = Variable<String>(autoSubmitted);
    }
    map['has_list_unsubscribe'] = Variable<bool>(hasListUnsubscribe);
    map['flags_json'] = Variable<String>(flagsJson);
    map['size'] = Variable<int>(size);
    map['snippet'] = Variable<String>(snippet);
    map['attachments_json'] = Variable<String>(attachmentsJson);
    if (!nullToAbsent || lastOpenedAt != null) {
      map['last_opened_at'] = Variable<int>(lastOpenedAt);
    }
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      accountId: Value(accountId),
      messageIdHash: Value(messageIdHash),
      folderPath: Value(folderPath),
      uid: uid == null && nullToAbsent ? const Value.absent() : Value(uid),
      uidValidity: uidValidity == null && nullToAbsent
          ? const Value.absent()
          : Value(uidValidity),
      messageId: messageId == null && nullToAbsent
          ? const Value.absent()
          : Value(messageId),
      subject: Value(subject),
      fromEmail: fromEmail == null && nullToAbsent
          ? const Value.absent()
          : Value(fromEmail),
      fromName: fromName == null && nullToAbsent
          ? const Value.absent()
          : Value(fromName),
      toAddressesJson: Value(toAddressesJson),
      ccJson: Value(ccJson),
      replyTo: replyTo == null && nullToAbsent
          ? const Value.absent()
          : Value(replyTo),
      date: Value(date),
      internalDate: internalDate == null && nullToAbsent
          ? const Value.absent()
          : Value(internalDate),
      listId: listId == null && nullToAbsent
          ? const Value.absent()
          : Value(listId),
      inReplyTo: inReplyTo == null && nullToAbsent
          ? const Value.absent()
          : Value(inReplyTo),
      referencesJson: Value(referencesJson),
      precedence: precedence == null && nullToAbsent
          ? const Value.absent()
          : Value(precedence),
      autoSubmitted: autoSubmitted == null && nullToAbsent
          ? const Value.absent()
          : Value(autoSubmitted),
      hasListUnsubscribe: Value(hasListUnsubscribe),
      flagsJson: Value(flagsJson),
      size: Value(size),
      snippet: Value(snippet),
      attachmentsJson: Value(attachmentsJson),
      lastOpenedAt: lastOpenedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastOpenedAt),
    );
  }

  factory Message.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Message(
      accountId: serializer.fromJson<String>(json['accountId']),
      messageIdHash: serializer.fromJson<String>(json['messageIdHash']),
      folderPath: serializer.fromJson<String>(json['folderPath']),
      uid: serializer.fromJson<int?>(json['uid']),
      uidValidity: serializer.fromJson<int?>(json['uidValidity']),
      messageId: serializer.fromJson<String?>(json['messageId']),
      subject: serializer.fromJson<String>(json['subject']),
      fromEmail: serializer.fromJson<String?>(json['fromEmail']),
      fromName: serializer.fromJson<String?>(json['fromName']),
      toAddressesJson: serializer.fromJson<String>(json['toAddressesJson']),
      ccJson: serializer.fromJson<String>(json['ccJson']),
      replyTo: serializer.fromJson<String?>(json['replyTo']),
      date: serializer.fromJson<int>(json['date']),
      internalDate: serializer.fromJson<int?>(json['internalDate']),
      listId: serializer.fromJson<String?>(json['listId']),
      inReplyTo: serializer.fromJson<String?>(json['inReplyTo']),
      referencesJson: serializer.fromJson<String>(json['referencesJson']),
      precedence: serializer.fromJson<String?>(json['precedence']),
      autoSubmitted: serializer.fromJson<String?>(json['autoSubmitted']),
      hasListUnsubscribe: serializer.fromJson<bool>(json['hasListUnsubscribe']),
      flagsJson: serializer.fromJson<String>(json['flagsJson']),
      size: serializer.fromJson<int>(json['size']),
      snippet: serializer.fromJson<String>(json['snippet']),
      attachmentsJson: serializer.fromJson<String>(json['attachmentsJson']),
      lastOpenedAt: serializer.fromJson<int?>(json['lastOpenedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'messageIdHash': serializer.toJson<String>(messageIdHash),
      'folderPath': serializer.toJson<String>(folderPath),
      'uid': serializer.toJson<int?>(uid),
      'uidValidity': serializer.toJson<int?>(uidValidity),
      'messageId': serializer.toJson<String?>(messageId),
      'subject': serializer.toJson<String>(subject),
      'fromEmail': serializer.toJson<String?>(fromEmail),
      'fromName': serializer.toJson<String?>(fromName),
      'toAddressesJson': serializer.toJson<String>(toAddressesJson),
      'ccJson': serializer.toJson<String>(ccJson),
      'replyTo': serializer.toJson<String?>(replyTo),
      'date': serializer.toJson<int>(date),
      'internalDate': serializer.toJson<int?>(internalDate),
      'listId': serializer.toJson<String?>(listId),
      'inReplyTo': serializer.toJson<String?>(inReplyTo),
      'referencesJson': serializer.toJson<String>(referencesJson),
      'precedence': serializer.toJson<String?>(precedence),
      'autoSubmitted': serializer.toJson<String?>(autoSubmitted),
      'hasListUnsubscribe': serializer.toJson<bool>(hasListUnsubscribe),
      'flagsJson': serializer.toJson<String>(flagsJson),
      'size': serializer.toJson<int>(size),
      'snippet': serializer.toJson<String>(snippet),
      'attachmentsJson': serializer.toJson<String>(attachmentsJson),
      'lastOpenedAt': serializer.toJson<int?>(lastOpenedAt),
    };
  }

  Message copyWith({
    String? accountId,
    String? messageIdHash,
    String? folderPath,
    Value<int?> uid = const Value.absent(),
    Value<int?> uidValidity = const Value.absent(),
    Value<String?> messageId = const Value.absent(),
    String? subject,
    Value<String?> fromEmail = const Value.absent(),
    Value<String?> fromName = const Value.absent(),
    String? toAddressesJson,
    String? ccJson,
    Value<String?> replyTo = const Value.absent(),
    int? date,
    Value<int?> internalDate = const Value.absent(),
    Value<String?> listId = const Value.absent(),
    Value<String?> inReplyTo = const Value.absent(),
    String? referencesJson,
    Value<String?> precedence = const Value.absent(),
    Value<String?> autoSubmitted = const Value.absent(),
    bool? hasListUnsubscribe,
    String? flagsJson,
    int? size,
    String? snippet,
    String? attachmentsJson,
    Value<int?> lastOpenedAt = const Value.absent(),
  }) => Message(
    accountId: accountId ?? this.accountId,
    messageIdHash: messageIdHash ?? this.messageIdHash,
    folderPath: folderPath ?? this.folderPath,
    uid: uid.present ? uid.value : this.uid,
    uidValidity: uidValidity.present ? uidValidity.value : this.uidValidity,
    messageId: messageId.present ? messageId.value : this.messageId,
    subject: subject ?? this.subject,
    fromEmail: fromEmail.present ? fromEmail.value : this.fromEmail,
    fromName: fromName.present ? fromName.value : this.fromName,
    toAddressesJson: toAddressesJson ?? this.toAddressesJson,
    ccJson: ccJson ?? this.ccJson,
    replyTo: replyTo.present ? replyTo.value : this.replyTo,
    date: date ?? this.date,
    internalDate: internalDate.present ? internalDate.value : this.internalDate,
    listId: listId.present ? listId.value : this.listId,
    inReplyTo: inReplyTo.present ? inReplyTo.value : this.inReplyTo,
    referencesJson: referencesJson ?? this.referencesJson,
    precedence: precedence.present ? precedence.value : this.precedence,
    autoSubmitted: autoSubmitted.present
        ? autoSubmitted.value
        : this.autoSubmitted,
    hasListUnsubscribe: hasListUnsubscribe ?? this.hasListUnsubscribe,
    flagsJson: flagsJson ?? this.flagsJson,
    size: size ?? this.size,
    snippet: snippet ?? this.snippet,
    attachmentsJson: attachmentsJson ?? this.attachmentsJson,
    lastOpenedAt: lastOpenedAt.present ? lastOpenedAt.value : this.lastOpenedAt,
  );
  Message copyWithCompanion(MessagesCompanion data) {
    return Message(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      messageIdHash: data.messageIdHash.present
          ? data.messageIdHash.value
          : this.messageIdHash,
      folderPath: data.folderPath.present
          ? data.folderPath.value
          : this.folderPath,
      uid: data.uid.present ? data.uid.value : this.uid,
      uidValidity: data.uidValidity.present
          ? data.uidValidity.value
          : this.uidValidity,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      subject: data.subject.present ? data.subject.value : this.subject,
      fromEmail: data.fromEmail.present ? data.fromEmail.value : this.fromEmail,
      fromName: data.fromName.present ? data.fromName.value : this.fromName,
      toAddressesJson: data.toAddressesJson.present
          ? data.toAddressesJson.value
          : this.toAddressesJson,
      ccJson: data.ccJson.present ? data.ccJson.value : this.ccJson,
      replyTo: data.replyTo.present ? data.replyTo.value : this.replyTo,
      date: data.date.present ? data.date.value : this.date,
      internalDate: data.internalDate.present
          ? data.internalDate.value
          : this.internalDate,
      listId: data.listId.present ? data.listId.value : this.listId,
      inReplyTo: data.inReplyTo.present ? data.inReplyTo.value : this.inReplyTo,
      referencesJson: data.referencesJson.present
          ? data.referencesJson.value
          : this.referencesJson,
      precedence: data.precedence.present
          ? data.precedence.value
          : this.precedence,
      autoSubmitted: data.autoSubmitted.present
          ? data.autoSubmitted.value
          : this.autoSubmitted,
      hasListUnsubscribe: data.hasListUnsubscribe.present
          ? data.hasListUnsubscribe.value
          : this.hasListUnsubscribe,
      flagsJson: data.flagsJson.present ? data.flagsJson.value : this.flagsJson,
      size: data.size.present ? data.size.value : this.size,
      snippet: data.snippet.present ? data.snippet.value : this.snippet,
      attachmentsJson: data.attachmentsJson.present
          ? data.attachmentsJson.value
          : this.attachmentsJson,
      lastOpenedAt: data.lastOpenedAt.present
          ? data.lastOpenedAt.value
          : this.lastOpenedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Message(')
          ..write('accountId: $accountId, ')
          ..write('messageIdHash: $messageIdHash, ')
          ..write('folderPath: $folderPath, ')
          ..write('uid: $uid, ')
          ..write('uidValidity: $uidValidity, ')
          ..write('messageId: $messageId, ')
          ..write('subject: $subject, ')
          ..write('fromEmail: $fromEmail, ')
          ..write('fromName: $fromName, ')
          ..write('toAddressesJson: $toAddressesJson, ')
          ..write('ccJson: $ccJson, ')
          ..write('replyTo: $replyTo, ')
          ..write('date: $date, ')
          ..write('internalDate: $internalDate, ')
          ..write('listId: $listId, ')
          ..write('inReplyTo: $inReplyTo, ')
          ..write('referencesJson: $referencesJson, ')
          ..write('precedence: $precedence, ')
          ..write('autoSubmitted: $autoSubmitted, ')
          ..write('hasListUnsubscribe: $hasListUnsubscribe, ')
          ..write('flagsJson: $flagsJson, ')
          ..write('size: $size, ')
          ..write('snippet: $snippet, ')
          ..write('attachmentsJson: $attachmentsJson, ')
          ..write('lastOpenedAt: $lastOpenedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    accountId,
    messageIdHash,
    folderPath,
    uid,
    uidValidity,
    messageId,
    subject,
    fromEmail,
    fromName,
    toAddressesJson,
    ccJson,
    replyTo,
    date,
    internalDate,
    listId,
    inReplyTo,
    referencesJson,
    precedence,
    autoSubmitted,
    hasListUnsubscribe,
    flagsJson,
    size,
    snippet,
    attachmentsJson,
    lastOpenedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Message &&
          other.accountId == this.accountId &&
          other.messageIdHash == this.messageIdHash &&
          other.folderPath == this.folderPath &&
          other.uid == this.uid &&
          other.uidValidity == this.uidValidity &&
          other.messageId == this.messageId &&
          other.subject == this.subject &&
          other.fromEmail == this.fromEmail &&
          other.fromName == this.fromName &&
          other.toAddressesJson == this.toAddressesJson &&
          other.ccJson == this.ccJson &&
          other.replyTo == this.replyTo &&
          other.date == this.date &&
          other.internalDate == this.internalDate &&
          other.listId == this.listId &&
          other.inReplyTo == this.inReplyTo &&
          other.referencesJson == this.referencesJson &&
          other.precedence == this.precedence &&
          other.autoSubmitted == this.autoSubmitted &&
          other.hasListUnsubscribe == this.hasListUnsubscribe &&
          other.flagsJson == this.flagsJson &&
          other.size == this.size &&
          other.snippet == this.snippet &&
          other.attachmentsJson == this.attachmentsJson &&
          other.lastOpenedAt == this.lastOpenedAt);
}

class MessagesCompanion extends UpdateCompanion<Message> {
  final Value<String> accountId;
  final Value<String> messageIdHash;
  final Value<String> folderPath;
  final Value<int?> uid;
  final Value<int?> uidValidity;
  final Value<String?> messageId;
  final Value<String> subject;
  final Value<String?> fromEmail;
  final Value<String?> fromName;
  final Value<String> toAddressesJson;
  final Value<String> ccJson;
  final Value<String?> replyTo;
  final Value<int> date;
  final Value<int?> internalDate;
  final Value<String?> listId;
  final Value<String?> inReplyTo;
  final Value<String> referencesJson;
  final Value<String?> precedence;
  final Value<String?> autoSubmitted;
  final Value<bool> hasListUnsubscribe;
  final Value<String> flagsJson;
  final Value<int> size;
  final Value<String> snippet;
  final Value<String> attachmentsJson;
  final Value<int?> lastOpenedAt;
  final Value<int> rowid;
  const MessagesCompanion({
    this.accountId = const Value.absent(),
    this.messageIdHash = const Value.absent(),
    this.folderPath = const Value.absent(),
    this.uid = const Value.absent(),
    this.uidValidity = const Value.absent(),
    this.messageId = const Value.absent(),
    this.subject = const Value.absent(),
    this.fromEmail = const Value.absent(),
    this.fromName = const Value.absent(),
    this.toAddressesJson = const Value.absent(),
    this.ccJson = const Value.absent(),
    this.replyTo = const Value.absent(),
    this.date = const Value.absent(),
    this.internalDate = const Value.absent(),
    this.listId = const Value.absent(),
    this.inReplyTo = const Value.absent(),
    this.referencesJson = const Value.absent(),
    this.precedence = const Value.absent(),
    this.autoSubmitted = const Value.absent(),
    this.hasListUnsubscribe = const Value.absent(),
    this.flagsJson = const Value.absent(),
    this.size = const Value.absent(),
    this.snippet = const Value.absent(),
    this.attachmentsJson = const Value.absent(),
    this.lastOpenedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessagesCompanion.insert({
    required String accountId,
    required String messageIdHash,
    required String folderPath,
    this.uid = const Value.absent(),
    this.uidValidity = const Value.absent(),
    this.messageId = const Value.absent(),
    this.subject = const Value.absent(),
    this.fromEmail = const Value.absent(),
    this.fromName = const Value.absent(),
    this.toAddressesJson = const Value.absent(),
    this.ccJson = const Value.absent(),
    this.replyTo = const Value.absent(),
    required int date,
    this.internalDate = const Value.absent(),
    this.listId = const Value.absent(),
    this.inReplyTo = const Value.absent(),
    this.referencesJson = const Value.absent(),
    this.precedence = const Value.absent(),
    this.autoSubmitted = const Value.absent(),
    this.hasListUnsubscribe = const Value.absent(),
    this.flagsJson = const Value.absent(),
    this.size = const Value.absent(),
    this.snippet = const Value.absent(),
    this.attachmentsJson = const Value.absent(),
    this.lastOpenedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       messageIdHash = Value(messageIdHash),
       folderPath = Value(folderPath),
       date = Value(date);
  static Insertable<Message> custom({
    Expression<String>? accountId,
    Expression<String>? messageIdHash,
    Expression<String>? folderPath,
    Expression<int>? uid,
    Expression<int>? uidValidity,
    Expression<String>? messageId,
    Expression<String>? subject,
    Expression<String>? fromEmail,
    Expression<String>? fromName,
    Expression<String>? toAddressesJson,
    Expression<String>? ccJson,
    Expression<String>? replyTo,
    Expression<int>? date,
    Expression<int>? internalDate,
    Expression<String>? listId,
    Expression<String>? inReplyTo,
    Expression<String>? referencesJson,
    Expression<String>? precedence,
    Expression<String>? autoSubmitted,
    Expression<bool>? hasListUnsubscribe,
    Expression<String>? flagsJson,
    Expression<int>? size,
    Expression<String>? snippet,
    Expression<String>? attachmentsJson,
    Expression<int>? lastOpenedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (messageIdHash != null) 'message_id_hash': messageIdHash,
      if (folderPath != null) 'folder_path': folderPath,
      if (uid != null) 'uid': uid,
      if (uidValidity != null) 'uid_validity': uidValidity,
      if (messageId != null) 'message_id': messageId,
      if (subject != null) 'subject': subject,
      if (fromEmail != null) 'from_email': fromEmail,
      if (fromName != null) 'from_name': fromName,
      if (toAddressesJson != null) 'to_json': toAddressesJson,
      if (ccJson != null) 'cc_json': ccJson,
      if (replyTo != null) 'reply_to': replyTo,
      if (date != null) 'date': date,
      if (internalDate != null) 'internal_date': internalDate,
      if (listId != null) 'list_id': listId,
      if (inReplyTo != null) 'in_reply_to': inReplyTo,
      if (referencesJson != null) 'references_json': referencesJson,
      if (precedence != null) 'precedence': precedence,
      if (autoSubmitted != null) 'auto_submitted': autoSubmitted,
      if (hasListUnsubscribe != null)
        'has_list_unsubscribe': hasListUnsubscribe,
      if (flagsJson != null) 'flags_json': flagsJson,
      if (size != null) 'size': size,
      if (snippet != null) 'snippet': snippet,
      if (attachmentsJson != null) 'attachments_json': attachmentsJson,
      if (lastOpenedAt != null) 'last_opened_at': lastOpenedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessagesCompanion copyWith({
    Value<String>? accountId,
    Value<String>? messageIdHash,
    Value<String>? folderPath,
    Value<int?>? uid,
    Value<int?>? uidValidity,
    Value<String?>? messageId,
    Value<String>? subject,
    Value<String?>? fromEmail,
    Value<String?>? fromName,
    Value<String>? toAddressesJson,
    Value<String>? ccJson,
    Value<String?>? replyTo,
    Value<int>? date,
    Value<int?>? internalDate,
    Value<String?>? listId,
    Value<String?>? inReplyTo,
    Value<String>? referencesJson,
    Value<String?>? precedence,
    Value<String?>? autoSubmitted,
    Value<bool>? hasListUnsubscribe,
    Value<String>? flagsJson,
    Value<int>? size,
    Value<String>? snippet,
    Value<String>? attachmentsJson,
    Value<int?>? lastOpenedAt,
    Value<int>? rowid,
  }) {
    return MessagesCompanion(
      accountId: accountId ?? this.accountId,
      messageIdHash: messageIdHash ?? this.messageIdHash,
      folderPath: folderPath ?? this.folderPath,
      uid: uid ?? this.uid,
      uidValidity: uidValidity ?? this.uidValidity,
      messageId: messageId ?? this.messageId,
      subject: subject ?? this.subject,
      fromEmail: fromEmail ?? this.fromEmail,
      fromName: fromName ?? this.fromName,
      toAddressesJson: toAddressesJson ?? this.toAddressesJson,
      ccJson: ccJson ?? this.ccJson,
      replyTo: replyTo ?? this.replyTo,
      date: date ?? this.date,
      internalDate: internalDate ?? this.internalDate,
      listId: listId ?? this.listId,
      inReplyTo: inReplyTo ?? this.inReplyTo,
      referencesJson: referencesJson ?? this.referencesJson,
      precedence: precedence ?? this.precedence,
      autoSubmitted: autoSubmitted ?? this.autoSubmitted,
      hasListUnsubscribe: hasListUnsubscribe ?? this.hasListUnsubscribe,
      flagsJson: flagsJson ?? this.flagsJson,
      size: size ?? this.size,
      snippet: snippet ?? this.snippet,
      attachmentsJson: attachmentsJson ?? this.attachmentsJson,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (messageIdHash.present) {
      map['message_id_hash'] = Variable<String>(messageIdHash.value);
    }
    if (folderPath.present) {
      map['folder_path'] = Variable<String>(folderPath.value);
    }
    if (uid.present) {
      map['uid'] = Variable<int>(uid.value);
    }
    if (uidValidity.present) {
      map['uid_validity'] = Variable<int>(uidValidity.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (fromEmail.present) {
      map['from_email'] = Variable<String>(fromEmail.value);
    }
    if (fromName.present) {
      map['from_name'] = Variable<String>(fromName.value);
    }
    if (toAddressesJson.present) {
      map['to_json'] = Variable<String>(toAddressesJson.value);
    }
    if (ccJson.present) {
      map['cc_json'] = Variable<String>(ccJson.value);
    }
    if (replyTo.present) {
      map['reply_to'] = Variable<String>(replyTo.value);
    }
    if (date.present) {
      map['date'] = Variable<int>(date.value);
    }
    if (internalDate.present) {
      map['internal_date'] = Variable<int>(internalDate.value);
    }
    if (listId.present) {
      map['list_id'] = Variable<String>(listId.value);
    }
    if (inReplyTo.present) {
      map['in_reply_to'] = Variable<String>(inReplyTo.value);
    }
    if (referencesJson.present) {
      map['references_json'] = Variable<String>(referencesJson.value);
    }
    if (precedence.present) {
      map['precedence'] = Variable<String>(precedence.value);
    }
    if (autoSubmitted.present) {
      map['auto_submitted'] = Variable<String>(autoSubmitted.value);
    }
    if (hasListUnsubscribe.present) {
      map['has_list_unsubscribe'] = Variable<bool>(hasListUnsubscribe.value);
    }
    if (flagsJson.present) {
      map['flags_json'] = Variable<String>(flagsJson.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (snippet.present) {
      map['snippet'] = Variable<String>(snippet.value);
    }
    if (attachmentsJson.present) {
      map['attachments_json'] = Variable<String>(attachmentsJson.value);
    }
    if (lastOpenedAt.present) {
      map['last_opened_at'] = Variable<int>(lastOpenedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('accountId: $accountId, ')
          ..write('messageIdHash: $messageIdHash, ')
          ..write('folderPath: $folderPath, ')
          ..write('uid: $uid, ')
          ..write('uidValidity: $uidValidity, ')
          ..write('messageId: $messageId, ')
          ..write('subject: $subject, ')
          ..write('fromEmail: $fromEmail, ')
          ..write('fromName: $fromName, ')
          ..write('toAddressesJson: $toAddressesJson, ')
          ..write('ccJson: $ccJson, ')
          ..write('replyTo: $replyTo, ')
          ..write('date: $date, ')
          ..write('internalDate: $internalDate, ')
          ..write('listId: $listId, ')
          ..write('inReplyTo: $inReplyTo, ')
          ..write('referencesJson: $referencesJson, ')
          ..write('precedence: $precedence, ')
          ..write('autoSubmitted: $autoSubmitted, ')
          ..write('hasListUnsubscribe: $hasListUnsubscribe, ')
          ..write('flagsJson: $flagsJson, ')
          ..write('size: $size, ')
          ..write('snippet: $snippet, ')
          ..write('attachmentsJson: $attachmentsJson, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessageBodiesTable extends MessageBodies
    with TableInfo<$MessageBodiesTable, MessageBody> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessageBodiesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _messageIdHashMeta = const VerificationMeta(
    'messageIdHash',
  );
  @override
  late final GeneratedColumn<String> messageIdHash = GeneratedColumn<String>(
    'message_id_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyTextMeta = const VerificationMeta(
    'bodyText',
  );
  @override
  late final GeneratedColumn<String> bodyText = GeneratedColumn<String>(
    'body_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _htmlMeta = const VerificationMeta('html');
  @override
  late final GeneratedColumn<String> html = GeneratedColumn<String>(
    'html',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inlineJsonMeta = const VerificationMeta(
    'inlineJson',
  );
  @override
  late final GeneratedColumn<String> inlineJson = GeneratedColumn<String>(
    'inline_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _calendarTextMeta = const VerificationMeta(
    'calendarText',
  );
  @override
  late final GeneratedColumn<String> calendarText = GeneratedColumn<String>(
    'calendar_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<int> cachedAt = GeneratedColumn<int>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastAccessAtMeta = const VerificationMeta(
    'lastAccessAt',
  );
  @override
  late final GeneratedColumn<int> lastAccessAt = GeneratedColumn<int>(
    'last_access_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    messageIdHash,
    bodyText,
    html,
    inlineJson,
    calendarText,
    sizeBytes,
    cachedAt,
    lastAccessAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'message_bodies';
  @override
  VerificationContext validateIntegrity(
    Insertable<MessageBody> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('message_id_hash')) {
      context.handle(
        _messageIdHashMeta,
        messageIdHash.isAcceptableOrUnknown(
          data['message_id_hash']!,
          _messageIdHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_messageIdHashMeta);
    }
    if (data.containsKey('body_text')) {
      context.handle(
        _bodyTextMeta,
        bodyText.isAcceptableOrUnknown(data['body_text']!, _bodyTextMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyTextMeta);
    }
    if (data.containsKey('html')) {
      context.handle(
        _htmlMeta,
        html.isAcceptableOrUnknown(data['html']!, _htmlMeta),
      );
    }
    if (data.containsKey('inline_json')) {
      context.handle(
        _inlineJsonMeta,
        inlineJson.isAcceptableOrUnknown(data['inline_json']!, _inlineJsonMeta),
      );
    }
    if (data.containsKey('calendar_text')) {
      context.handle(
        _calendarTextMeta,
        calendarText.isAcceptableOrUnknown(
          data['calendar_text']!,
          _calendarTextMeta,
        ),
      );
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    if (data.containsKey('last_access_at')) {
      context.handle(
        _lastAccessAtMeta,
        lastAccessAt.isAcceptableOrUnknown(
          data['last_access_at']!,
          _lastAccessAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastAccessAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, messageIdHash};
  @override
  MessageBody map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessageBody(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      messageIdHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id_hash'],
      )!,
      bodyText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body_text'],
      )!,
      html: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}html'],
      ),
      inlineJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inline_json'],
      )!,
      calendarText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}calendar_text'],
      ),
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cached_at'],
      )!,
      lastAccessAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_access_at'],
      )!,
    );
  }

  @override
  $MessageBodiesTable createAlias(String alias) {
    return $MessageBodiesTable(attachedDatabase, alias);
  }
}

class MessageBody extends DataClass implements Insertable<MessageBody> {
  final String accountId;
  final String messageIdHash;
  final String bodyText;
  final String? html;

  /// JSON map cid -> base64.
  final String inlineJson;

  /// The text/calendar part, when the mail carries one (schema 5).
  final String? calendarText;
  final int sizeBytes;
  final int cachedAt;
  final int lastAccessAt;
  const MessageBody({
    required this.accountId,
    required this.messageIdHash,
    required this.bodyText,
    this.html,
    required this.inlineJson,
    this.calendarText,
    required this.sizeBytes,
    required this.cachedAt,
    required this.lastAccessAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['message_id_hash'] = Variable<String>(messageIdHash);
    map['body_text'] = Variable<String>(bodyText);
    if (!nullToAbsent || html != null) {
      map['html'] = Variable<String>(html);
    }
    map['inline_json'] = Variable<String>(inlineJson);
    if (!nullToAbsent || calendarText != null) {
      map['calendar_text'] = Variable<String>(calendarText);
    }
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['cached_at'] = Variable<int>(cachedAt);
    map['last_access_at'] = Variable<int>(lastAccessAt);
    return map;
  }

  MessageBodiesCompanion toCompanion(bool nullToAbsent) {
    return MessageBodiesCompanion(
      accountId: Value(accountId),
      messageIdHash: Value(messageIdHash),
      bodyText: Value(bodyText),
      html: html == null && nullToAbsent ? const Value.absent() : Value(html),
      inlineJson: Value(inlineJson),
      calendarText: calendarText == null && nullToAbsent
          ? const Value.absent()
          : Value(calendarText),
      sizeBytes: Value(sizeBytes),
      cachedAt: Value(cachedAt),
      lastAccessAt: Value(lastAccessAt),
    );
  }

  factory MessageBody.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessageBody(
      accountId: serializer.fromJson<String>(json['accountId']),
      messageIdHash: serializer.fromJson<String>(json['messageIdHash']),
      bodyText: serializer.fromJson<String>(json['bodyText']),
      html: serializer.fromJson<String?>(json['html']),
      inlineJson: serializer.fromJson<String>(json['inlineJson']),
      calendarText: serializer.fromJson<String?>(json['calendarText']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      cachedAt: serializer.fromJson<int>(json['cachedAt']),
      lastAccessAt: serializer.fromJson<int>(json['lastAccessAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'messageIdHash': serializer.toJson<String>(messageIdHash),
      'bodyText': serializer.toJson<String>(bodyText),
      'html': serializer.toJson<String?>(html),
      'inlineJson': serializer.toJson<String>(inlineJson),
      'calendarText': serializer.toJson<String?>(calendarText),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'cachedAt': serializer.toJson<int>(cachedAt),
      'lastAccessAt': serializer.toJson<int>(lastAccessAt),
    };
  }

  MessageBody copyWith({
    String? accountId,
    String? messageIdHash,
    String? bodyText,
    Value<String?> html = const Value.absent(),
    String? inlineJson,
    Value<String?> calendarText = const Value.absent(),
    int? sizeBytes,
    int? cachedAt,
    int? lastAccessAt,
  }) => MessageBody(
    accountId: accountId ?? this.accountId,
    messageIdHash: messageIdHash ?? this.messageIdHash,
    bodyText: bodyText ?? this.bodyText,
    html: html.present ? html.value : this.html,
    inlineJson: inlineJson ?? this.inlineJson,
    calendarText: calendarText.present ? calendarText.value : this.calendarText,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    cachedAt: cachedAt ?? this.cachedAt,
    lastAccessAt: lastAccessAt ?? this.lastAccessAt,
  );
  MessageBody copyWithCompanion(MessageBodiesCompanion data) {
    return MessageBody(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      messageIdHash: data.messageIdHash.present
          ? data.messageIdHash.value
          : this.messageIdHash,
      bodyText: data.bodyText.present ? data.bodyText.value : this.bodyText,
      html: data.html.present ? data.html.value : this.html,
      inlineJson: data.inlineJson.present
          ? data.inlineJson.value
          : this.inlineJson,
      calendarText: data.calendarText.present
          ? data.calendarText.value
          : this.calendarText,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      lastAccessAt: data.lastAccessAt.present
          ? data.lastAccessAt.value
          : this.lastAccessAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessageBody(')
          ..write('accountId: $accountId, ')
          ..write('messageIdHash: $messageIdHash, ')
          ..write('bodyText: $bodyText, ')
          ..write('html: $html, ')
          ..write('inlineJson: $inlineJson, ')
          ..write('calendarText: $calendarText, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('lastAccessAt: $lastAccessAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    accountId,
    messageIdHash,
    bodyText,
    html,
    inlineJson,
    calendarText,
    sizeBytes,
    cachedAt,
    lastAccessAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessageBody &&
          other.accountId == this.accountId &&
          other.messageIdHash == this.messageIdHash &&
          other.bodyText == this.bodyText &&
          other.html == this.html &&
          other.inlineJson == this.inlineJson &&
          other.calendarText == this.calendarText &&
          other.sizeBytes == this.sizeBytes &&
          other.cachedAt == this.cachedAt &&
          other.lastAccessAt == this.lastAccessAt);
}

class MessageBodiesCompanion extends UpdateCompanion<MessageBody> {
  final Value<String> accountId;
  final Value<String> messageIdHash;
  final Value<String> bodyText;
  final Value<String?> html;
  final Value<String> inlineJson;
  final Value<String?> calendarText;
  final Value<int> sizeBytes;
  final Value<int> cachedAt;
  final Value<int> lastAccessAt;
  final Value<int> rowid;
  const MessageBodiesCompanion({
    this.accountId = const Value.absent(),
    this.messageIdHash = const Value.absent(),
    this.bodyText = const Value.absent(),
    this.html = const Value.absent(),
    this.inlineJson = const Value.absent(),
    this.calendarText = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.lastAccessAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessageBodiesCompanion.insert({
    required String accountId,
    required String messageIdHash,
    required String bodyText,
    this.html = const Value.absent(),
    this.inlineJson = const Value.absent(),
    this.calendarText = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    required int cachedAt,
    required int lastAccessAt,
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       messageIdHash = Value(messageIdHash),
       bodyText = Value(bodyText),
       cachedAt = Value(cachedAt),
       lastAccessAt = Value(lastAccessAt);
  static Insertable<MessageBody> custom({
    Expression<String>? accountId,
    Expression<String>? messageIdHash,
    Expression<String>? bodyText,
    Expression<String>? html,
    Expression<String>? inlineJson,
    Expression<String>? calendarText,
    Expression<int>? sizeBytes,
    Expression<int>? cachedAt,
    Expression<int>? lastAccessAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (messageIdHash != null) 'message_id_hash': messageIdHash,
      if (bodyText != null) 'body_text': bodyText,
      if (html != null) 'html': html,
      if (inlineJson != null) 'inline_json': inlineJson,
      if (calendarText != null) 'calendar_text': calendarText,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (lastAccessAt != null) 'last_access_at': lastAccessAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessageBodiesCompanion copyWith({
    Value<String>? accountId,
    Value<String>? messageIdHash,
    Value<String>? bodyText,
    Value<String?>? html,
    Value<String>? inlineJson,
    Value<String?>? calendarText,
    Value<int>? sizeBytes,
    Value<int>? cachedAt,
    Value<int>? lastAccessAt,
    Value<int>? rowid,
  }) {
    return MessageBodiesCompanion(
      accountId: accountId ?? this.accountId,
      messageIdHash: messageIdHash ?? this.messageIdHash,
      bodyText: bodyText ?? this.bodyText,
      html: html ?? this.html,
      inlineJson: inlineJson ?? this.inlineJson,
      calendarText: calendarText ?? this.calendarText,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      cachedAt: cachedAt ?? this.cachedAt,
      lastAccessAt: lastAccessAt ?? this.lastAccessAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (messageIdHash.present) {
      map['message_id_hash'] = Variable<String>(messageIdHash.value);
    }
    if (bodyText.present) {
      map['body_text'] = Variable<String>(bodyText.value);
    }
    if (html.present) {
      map['html'] = Variable<String>(html.value);
    }
    if (inlineJson.present) {
      map['inline_json'] = Variable<String>(inlineJson.value);
    }
    if (calendarText.present) {
      map['calendar_text'] = Variable<String>(calendarText.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<int>(cachedAt.value);
    }
    if (lastAccessAt.present) {
      map['last_access_at'] = Variable<int>(lastAccessAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessageBodiesCompanion(')
          ..write('accountId: $accountId, ')
          ..write('messageIdHash: $messageIdHash, ')
          ..write('bodyText: $bodyText, ')
          ..write('html: $html, ')
          ..write('inlineJson: $inlineJson, ')
          ..write('calendarText: $calendarText, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('lastAccessAt: $lastAccessAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingOpsTable extends PendingOps
    with TableInfo<$PendingOpsTable, PendingOp> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingOpsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
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
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<int> nextAttemptAt = GeneratedColumn<int>(
    'next_attempt_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    type,
    payloadJson,
    createdAt,
    attempts,
    nextAttemptAt,
    status,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_ops';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingOp> instance, {
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
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
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
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingOp map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingOp(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_attempt_at'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $PendingOpsTable createAlias(String alias) {
    return $PendingOpsTable(attachedDatabase, alias);
  }
}

class PendingOp extends DataClass implements Insertable<PendingOp> {
  final String id;
  final String accountId;
  final String type;
  final String payloadJson;
  final int createdAt;
  final int attempts;
  final int? nextAttemptAt;
  final String status;
  final String? lastError;
  const PendingOp({
    required this.id,
    required this.accountId,
    required this.type,
    required this.payloadJson,
    required this.createdAt,
    required this.attempts,
    this.nextAttemptAt,
    required this.status,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    map['type'] = Variable<String>(type);
    map['payload_json'] = Variable<String>(payloadJson);
    map['created_at'] = Variable<int>(createdAt);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<int>(nextAttemptAt);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  PendingOpsCompanion toCompanion(bool nullToAbsent) {
    return PendingOpsCompanion(
      id: Value(id),
      accountId: Value(accountId),
      type: Value(type),
      payloadJson: Value(payloadJson),
      createdAt: Value(createdAt),
      attempts: Value(attempts),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
      status: Value(status),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory PendingOp.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingOp(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      type: serializer.fromJson<String>(json['type']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      attempts: serializer.fromJson<int>(json['attempts']),
      nextAttemptAt: serializer.fromJson<int?>(json['nextAttemptAt']),
      status: serializer.fromJson<String>(json['status']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'type': serializer.toJson<String>(type),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'createdAt': serializer.toJson<int>(createdAt),
      'attempts': serializer.toJson<int>(attempts),
      'nextAttemptAt': serializer.toJson<int?>(nextAttemptAt),
      'status': serializer.toJson<String>(status),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  PendingOp copyWith({
    String? id,
    String? accountId,
    String? type,
    String? payloadJson,
    int? createdAt,
    int? attempts,
    Value<int?> nextAttemptAt = const Value.absent(),
    String? status,
    Value<String?> lastError = const Value.absent(),
  }) => PendingOp(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    type: type ?? this.type,
    payloadJson: payloadJson ?? this.payloadJson,
    createdAt: createdAt ?? this.createdAt,
    attempts: attempts ?? this.attempts,
    nextAttemptAt: nextAttemptAt.present
        ? nextAttemptAt.value
        : this.nextAttemptAt,
    status: status ?? this.status,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  PendingOp copyWithCompanion(PendingOpsCompanion data) {
    return PendingOp(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      type: data.type.present ? data.type.value : this.type,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      status: data.status.present ? data.status.value : this.status,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingOp(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('type: $type, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('status: $status, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountId,
    type,
    payloadJson,
    createdAt,
    attempts,
    nextAttemptAt,
    status,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingOp &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.type == this.type &&
          other.payloadJson == this.payloadJson &&
          other.createdAt == this.createdAt &&
          other.attempts == this.attempts &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.status == this.status &&
          other.lastError == this.lastError);
}

class PendingOpsCompanion extends UpdateCompanion<PendingOp> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<String> type;
  final Value<String> payloadJson;
  final Value<int> createdAt;
  final Value<int> attempts;
  final Value<int?> nextAttemptAt;
  final Value<String> status;
  final Value<String?> lastError;
  final Value<int> rowid;
  const PendingOpsCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.type = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.status = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingOpsCompanion.insert({
    required String id,
    required String accountId,
    required String type,
    required String payloadJson,
    required int createdAt,
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.status = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accountId = Value(accountId),
       type = Value(type),
       payloadJson = Value(payloadJson),
       createdAt = Value(createdAt);
  static Insertable<PendingOp> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<String>? type,
    Expression<String>? payloadJson,
    Expression<int>? createdAt,
    Expression<int>? attempts,
    Expression<int>? nextAttemptAt,
    Expression<String>? status,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (type != null) 'type': type,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (createdAt != null) 'created_at': createdAt,
      if (attempts != null) 'attempts': attempts,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (status != null) 'status': status,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingOpsCompanion copyWith({
    Value<String>? id,
    Value<String>? accountId,
    Value<String>? type,
    Value<String>? payloadJson,
    Value<int>? createdAt,
    Value<int>? attempts,
    Value<int?>? nextAttemptAt,
    Value<String>? status,
    Value<String?>? lastError,
    Value<int>? rowid,
  }) {
    return PendingOpsCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      type: type ?? this.type,
      payloadJson: payloadJson ?? this.payloadJson,
      createdAt: createdAt ?? this.createdAt,
      attempts: attempts ?? this.attempts,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      status: status ?? this.status,
      lastError: lastError ?? this.lastError,
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
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<int>(nextAttemptAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingOpsCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('type: $type, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('status: $status, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
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
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      ),
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String? value;
  const Setting({required this.key, this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      key: Value(key),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
    );
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String?>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String?>(value),
    };
  }

  Setting copyWith({
    String? key,
    Value<String?> value = const Value.absent(),
  }) => Setting(
    key: key ?? this.key,
    value: value.present ? value.value : this.value,
  );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String?> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String?>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SortDecisionsTable extends SortDecisions
    with TableInfo<$SortDecisionsTable, SortDecision> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SortDecisionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _messageIdHashMeta = const VerificationMeta(
    'messageIdHash',
  );
  @override
  late final GeneratedColumn<String> messageIdHash = GeneratedColumn<String>(
    'message_id_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<int> uid = GeneratedColumn<int>(
    'uid',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uidValidityMeta = const VerificationMeta(
    'uidValidity',
  );
  @override
  late final GeneratedColumn<int> uidValidity = GeneratedColumn<int>(
    'uid_validity',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceFolderMeta = const VerificationMeta(
    'sourceFolder',
  );
  @override
  late final GeneratedColumn<String> sourceFolder = GeneratedColumn<String>(
    'source_folder',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _destinationMeta = const VerificationMeta(
    'destination',
  );
  @override
  late final GeneratedColumn<String> destination = GeneratedColumn<String>(
    'destination',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _layerMeta = const VerificationMeta('layer');
  @override
  late final GeneratedColumn<String> layer = GeneratedColumn<String>(
    'layer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _matchedKeyMeta = const VerificationMeta(
    'matchedKey',
  );
  @override
  late final GeneratedColumn<String> matchedKey = GeneratedColumn<String>(
    'matched_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelIdMeta = const VerificationMeta(
    'modelId',
  );
  @override
  late final GeneratedColumn<String> modelId = GeneratedColumn<String>(
    'model_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _folderProfileVersionMeta =
      const VerificationMeta('folderProfileVersion');
  @override
  late final GeneratedColumn<int> folderProfileVersion = GeneratedColumn<int>(
    'folder_profile_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _costUsdMeta = const VerificationMeta(
    'costUsd',
  );
  @override
  late final GeneratedColumn<double> costUsd = GeneratedColumn<double>(
    'cost_usd',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _epochMeta = const VerificationMeta('epoch');
  @override
  late final GeneratedColumn<int> epoch = GeneratedColumn<int>(
    'epoch',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dryRunMeta = const VerificationMeta('dryRun');
  @override
  late final GeneratedColumn<bool> dryRun = GeneratedColumn<bool>(
    'dry_run',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dry_run" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appliedAtMeta = const VerificationMeta(
    'appliedAt',
  );
  @override
  late final GeneratedColumn<int> appliedAt = GeneratedColumn<int>(
    'applied_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seenObservedAtMeta = const VerificationMeta(
    'seenObservedAt',
  );
  @override
  late final GeneratedColumn<int> seenObservedAt = GeneratedColumn<int>(
    'seen_observed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _finalFolderMeta = const VerificationMeta(
    'finalFolder',
  );
  @override
  late final GeneratedColumn<String> finalFolder = GeneratedColumn<String>(
    'final_folder',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    messageIdHash,
    uid,
    uidValidity,
    sourceFolder,
    destination,
    layer,
    matchedKey,
    confidence,
    reason,
    mode,
    status,
    modelId,
    folderProfileVersion,
    costUsd,
    deviceId,
    epoch,
    dryRun,
    createdAt,
    appliedAt,
    seenObservedAt,
    finalFolder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sort_decisions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SortDecision> instance, {
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
    if (data.containsKey('message_id_hash')) {
      context.handle(
        _messageIdHashMeta,
        messageIdHash.isAcceptableOrUnknown(
          data['message_id_hash']!,
          _messageIdHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_messageIdHashMeta);
    }
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    }
    if (data.containsKey('uid_validity')) {
      context.handle(
        _uidValidityMeta,
        uidValidity.isAcceptableOrUnknown(
          data['uid_validity']!,
          _uidValidityMeta,
        ),
      );
    }
    if (data.containsKey('source_folder')) {
      context.handle(
        _sourceFolderMeta,
        sourceFolder.isAcceptableOrUnknown(
          data['source_folder']!,
          _sourceFolderMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceFolderMeta);
    }
    if (data.containsKey('destination')) {
      context.handle(
        _destinationMeta,
        destination.isAcceptableOrUnknown(
          data['destination']!,
          _destinationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_destinationMeta);
    }
    if (data.containsKey('layer')) {
      context.handle(
        _layerMeta,
        layer.isAcceptableOrUnknown(data['layer']!, _layerMeta),
      );
    } else if (isInserting) {
      context.missing(_layerMeta);
    }
    if (data.containsKey('matched_key')) {
      context.handle(
        _matchedKeyMeta,
        matchedKey.isAcceptableOrUnknown(data['matched_key']!, _matchedKeyMeta),
      );
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    } else if (isInserting) {
      context.missing(_confidenceMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('model_id')) {
      context.handle(
        _modelIdMeta,
        modelId.isAcceptableOrUnknown(data['model_id']!, _modelIdMeta),
      );
    }
    if (data.containsKey('folder_profile_version')) {
      context.handle(
        _folderProfileVersionMeta,
        folderProfileVersion.isAcceptableOrUnknown(
          data['folder_profile_version']!,
          _folderProfileVersionMeta,
        ),
      );
    }
    if (data.containsKey('cost_usd')) {
      context.handle(
        _costUsdMeta,
        costUsd.isAcceptableOrUnknown(data['cost_usd']!, _costUsdMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('epoch')) {
      context.handle(
        _epochMeta,
        epoch.isAcceptableOrUnknown(data['epoch']!, _epochMeta),
      );
    }
    if (data.containsKey('dry_run')) {
      context.handle(
        _dryRunMeta,
        dryRun.isAcceptableOrUnknown(data['dry_run']!, _dryRunMeta),
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
    if (data.containsKey('applied_at')) {
      context.handle(
        _appliedAtMeta,
        appliedAt.isAcceptableOrUnknown(data['applied_at']!, _appliedAtMeta),
      );
    }
    if (data.containsKey('seen_observed_at')) {
      context.handle(
        _seenObservedAtMeta,
        seenObservedAt.isAcceptableOrUnknown(
          data['seen_observed_at']!,
          _seenObservedAtMeta,
        ),
      );
    }
    if (data.containsKey('final_folder')) {
      context.handle(
        _finalFolderMeta,
        finalFolder.isAcceptableOrUnknown(
          data['final_folder']!,
          _finalFolderMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SortDecision map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SortDecision(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      messageIdHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id_hash'],
      )!,
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}uid'],
      ),
      uidValidity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}uid_validity'],
      ),
      sourceFolder: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_folder'],
      )!,
      destination: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination'],
      )!,
      layer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}layer'],
      )!,
      matchedKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}matched_key'],
      ),
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      modelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_id'],
      ),
      folderProfileVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}folder_profile_version'],
      ),
      costUsd: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cost_usd'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
      epoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}epoch'],
      ),
      dryRun: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dry_run'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      appliedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}applied_at'],
      ),
      seenObservedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seen_observed_at'],
      ),
      finalFolder: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}final_folder'],
      ),
    );
  }

  @override
  $SortDecisionsTable createAlias(String alias) {
    return $SortDecisionsTable(attachedDatabase, alias);
  }
}

class SortDecision extends DataClass implements Insertable<SortDecision> {
  final String id;
  final String accountId;
  final String messageIdHash;
  final int? uid;
  final int? uidValidity;
  final String sourceFolder;
  final String destination;
  final String layer;
  final String? matchedKey;
  final double confidence;
  final String reason;
  final String mode;
  final String status;
  final String? modelId;
  final int? folderProfileVersion;
  final double? costUsd;
  final String? deviceId;
  final int? epoch;
  final bool dryRun;
  final int createdAt;
  final int? appliedAt;
  final int? seenObservedAt;
  final String? finalFolder;
  const SortDecision({
    required this.id,
    required this.accountId,
    required this.messageIdHash,
    this.uid,
    this.uidValidity,
    required this.sourceFolder,
    required this.destination,
    required this.layer,
    this.matchedKey,
    required this.confidence,
    required this.reason,
    required this.mode,
    required this.status,
    this.modelId,
    this.folderProfileVersion,
    this.costUsd,
    this.deviceId,
    this.epoch,
    required this.dryRun,
    required this.createdAt,
    this.appliedAt,
    this.seenObservedAt,
    this.finalFolder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    map['message_id_hash'] = Variable<String>(messageIdHash);
    if (!nullToAbsent || uid != null) {
      map['uid'] = Variable<int>(uid);
    }
    if (!nullToAbsent || uidValidity != null) {
      map['uid_validity'] = Variable<int>(uidValidity);
    }
    map['source_folder'] = Variable<String>(sourceFolder);
    map['destination'] = Variable<String>(destination);
    map['layer'] = Variable<String>(layer);
    if (!nullToAbsent || matchedKey != null) {
      map['matched_key'] = Variable<String>(matchedKey);
    }
    map['confidence'] = Variable<double>(confidence);
    map['reason'] = Variable<String>(reason);
    map['mode'] = Variable<String>(mode);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || modelId != null) {
      map['model_id'] = Variable<String>(modelId);
    }
    if (!nullToAbsent || folderProfileVersion != null) {
      map['folder_profile_version'] = Variable<int>(folderProfileVersion);
    }
    if (!nullToAbsent || costUsd != null) {
      map['cost_usd'] = Variable<double>(costUsd);
    }
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    if (!nullToAbsent || epoch != null) {
      map['epoch'] = Variable<int>(epoch);
    }
    map['dry_run'] = Variable<bool>(dryRun);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || appliedAt != null) {
      map['applied_at'] = Variable<int>(appliedAt);
    }
    if (!nullToAbsent || seenObservedAt != null) {
      map['seen_observed_at'] = Variable<int>(seenObservedAt);
    }
    if (!nullToAbsent || finalFolder != null) {
      map['final_folder'] = Variable<String>(finalFolder);
    }
    return map;
  }

  SortDecisionsCompanion toCompanion(bool nullToAbsent) {
    return SortDecisionsCompanion(
      id: Value(id),
      accountId: Value(accountId),
      messageIdHash: Value(messageIdHash),
      uid: uid == null && nullToAbsent ? const Value.absent() : Value(uid),
      uidValidity: uidValidity == null && nullToAbsent
          ? const Value.absent()
          : Value(uidValidity),
      sourceFolder: Value(sourceFolder),
      destination: Value(destination),
      layer: Value(layer),
      matchedKey: matchedKey == null && nullToAbsent
          ? const Value.absent()
          : Value(matchedKey),
      confidence: Value(confidence),
      reason: Value(reason),
      mode: Value(mode),
      status: Value(status),
      modelId: modelId == null && nullToAbsent
          ? const Value.absent()
          : Value(modelId),
      folderProfileVersion: folderProfileVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(folderProfileVersion),
      costUsd: costUsd == null && nullToAbsent
          ? const Value.absent()
          : Value(costUsd),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      epoch: epoch == null && nullToAbsent
          ? const Value.absent()
          : Value(epoch),
      dryRun: Value(dryRun),
      createdAt: Value(createdAt),
      appliedAt: appliedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(appliedAt),
      seenObservedAt: seenObservedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(seenObservedAt),
      finalFolder: finalFolder == null && nullToAbsent
          ? const Value.absent()
          : Value(finalFolder),
    );
  }

  factory SortDecision.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SortDecision(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      messageIdHash: serializer.fromJson<String>(json['messageIdHash']),
      uid: serializer.fromJson<int?>(json['uid']),
      uidValidity: serializer.fromJson<int?>(json['uidValidity']),
      sourceFolder: serializer.fromJson<String>(json['sourceFolder']),
      destination: serializer.fromJson<String>(json['destination']),
      layer: serializer.fromJson<String>(json['layer']),
      matchedKey: serializer.fromJson<String?>(json['matchedKey']),
      confidence: serializer.fromJson<double>(json['confidence']),
      reason: serializer.fromJson<String>(json['reason']),
      mode: serializer.fromJson<String>(json['mode']),
      status: serializer.fromJson<String>(json['status']),
      modelId: serializer.fromJson<String?>(json['modelId']),
      folderProfileVersion: serializer.fromJson<int?>(
        json['folderProfileVersion'],
      ),
      costUsd: serializer.fromJson<double?>(json['costUsd']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      epoch: serializer.fromJson<int?>(json['epoch']),
      dryRun: serializer.fromJson<bool>(json['dryRun']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      appliedAt: serializer.fromJson<int?>(json['appliedAt']),
      seenObservedAt: serializer.fromJson<int?>(json['seenObservedAt']),
      finalFolder: serializer.fromJson<String?>(json['finalFolder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'messageIdHash': serializer.toJson<String>(messageIdHash),
      'uid': serializer.toJson<int?>(uid),
      'uidValidity': serializer.toJson<int?>(uidValidity),
      'sourceFolder': serializer.toJson<String>(sourceFolder),
      'destination': serializer.toJson<String>(destination),
      'layer': serializer.toJson<String>(layer),
      'matchedKey': serializer.toJson<String?>(matchedKey),
      'confidence': serializer.toJson<double>(confidence),
      'reason': serializer.toJson<String>(reason),
      'mode': serializer.toJson<String>(mode),
      'status': serializer.toJson<String>(status),
      'modelId': serializer.toJson<String?>(modelId),
      'folderProfileVersion': serializer.toJson<int?>(folderProfileVersion),
      'costUsd': serializer.toJson<double?>(costUsd),
      'deviceId': serializer.toJson<String?>(deviceId),
      'epoch': serializer.toJson<int?>(epoch),
      'dryRun': serializer.toJson<bool>(dryRun),
      'createdAt': serializer.toJson<int>(createdAt),
      'appliedAt': serializer.toJson<int?>(appliedAt),
      'seenObservedAt': serializer.toJson<int?>(seenObservedAt),
      'finalFolder': serializer.toJson<String?>(finalFolder),
    };
  }

  SortDecision copyWith({
    String? id,
    String? accountId,
    String? messageIdHash,
    Value<int?> uid = const Value.absent(),
    Value<int?> uidValidity = const Value.absent(),
    String? sourceFolder,
    String? destination,
    String? layer,
    Value<String?> matchedKey = const Value.absent(),
    double? confidence,
    String? reason,
    String? mode,
    String? status,
    Value<String?> modelId = const Value.absent(),
    Value<int?> folderProfileVersion = const Value.absent(),
    Value<double?> costUsd = const Value.absent(),
    Value<String?> deviceId = const Value.absent(),
    Value<int?> epoch = const Value.absent(),
    bool? dryRun,
    int? createdAt,
    Value<int?> appliedAt = const Value.absent(),
    Value<int?> seenObservedAt = const Value.absent(),
    Value<String?> finalFolder = const Value.absent(),
  }) => SortDecision(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    messageIdHash: messageIdHash ?? this.messageIdHash,
    uid: uid.present ? uid.value : this.uid,
    uidValidity: uidValidity.present ? uidValidity.value : this.uidValidity,
    sourceFolder: sourceFolder ?? this.sourceFolder,
    destination: destination ?? this.destination,
    layer: layer ?? this.layer,
    matchedKey: matchedKey.present ? matchedKey.value : this.matchedKey,
    confidence: confidence ?? this.confidence,
    reason: reason ?? this.reason,
    mode: mode ?? this.mode,
    status: status ?? this.status,
    modelId: modelId.present ? modelId.value : this.modelId,
    folderProfileVersion: folderProfileVersion.present
        ? folderProfileVersion.value
        : this.folderProfileVersion,
    costUsd: costUsd.present ? costUsd.value : this.costUsd,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
    epoch: epoch.present ? epoch.value : this.epoch,
    dryRun: dryRun ?? this.dryRun,
    createdAt: createdAt ?? this.createdAt,
    appliedAt: appliedAt.present ? appliedAt.value : this.appliedAt,
    seenObservedAt: seenObservedAt.present
        ? seenObservedAt.value
        : this.seenObservedAt,
    finalFolder: finalFolder.present ? finalFolder.value : this.finalFolder,
  );
  SortDecision copyWithCompanion(SortDecisionsCompanion data) {
    return SortDecision(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      messageIdHash: data.messageIdHash.present
          ? data.messageIdHash.value
          : this.messageIdHash,
      uid: data.uid.present ? data.uid.value : this.uid,
      uidValidity: data.uidValidity.present
          ? data.uidValidity.value
          : this.uidValidity,
      sourceFolder: data.sourceFolder.present
          ? data.sourceFolder.value
          : this.sourceFolder,
      destination: data.destination.present
          ? data.destination.value
          : this.destination,
      layer: data.layer.present ? data.layer.value : this.layer,
      matchedKey: data.matchedKey.present
          ? data.matchedKey.value
          : this.matchedKey,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      reason: data.reason.present ? data.reason.value : this.reason,
      mode: data.mode.present ? data.mode.value : this.mode,
      status: data.status.present ? data.status.value : this.status,
      modelId: data.modelId.present ? data.modelId.value : this.modelId,
      folderProfileVersion: data.folderProfileVersion.present
          ? data.folderProfileVersion.value
          : this.folderProfileVersion,
      costUsd: data.costUsd.present ? data.costUsd.value : this.costUsd,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      epoch: data.epoch.present ? data.epoch.value : this.epoch,
      dryRun: data.dryRun.present ? data.dryRun.value : this.dryRun,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      appliedAt: data.appliedAt.present ? data.appliedAt.value : this.appliedAt,
      seenObservedAt: data.seenObservedAt.present
          ? data.seenObservedAt.value
          : this.seenObservedAt,
      finalFolder: data.finalFolder.present
          ? data.finalFolder.value
          : this.finalFolder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SortDecision(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('messageIdHash: $messageIdHash, ')
          ..write('uid: $uid, ')
          ..write('uidValidity: $uidValidity, ')
          ..write('sourceFolder: $sourceFolder, ')
          ..write('destination: $destination, ')
          ..write('layer: $layer, ')
          ..write('matchedKey: $matchedKey, ')
          ..write('confidence: $confidence, ')
          ..write('reason: $reason, ')
          ..write('mode: $mode, ')
          ..write('status: $status, ')
          ..write('modelId: $modelId, ')
          ..write('folderProfileVersion: $folderProfileVersion, ')
          ..write('costUsd: $costUsd, ')
          ..write('deviceId: $deviceId, ')
          ..write('epoch: $epoch, ')
          ..write('dryRun: $dryRun, ')
          ..write('createdAt: $createdAt, ')
          ..write('appliedAt: $appliedAt, ')
          ..write('seenObservedAt: $seenObservedAt, ')
          ..write('finalFolder: $finalFolder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    accountId,
    messageIdHash,
    uid,
    uidValidity,
    sourceFolder,
    destination,
    layer,
    matchedKey,
    confidence,
    reason,
    mode,
    status,
    modelId,
    folderProfileVersion,
    costUsd,
    deviceId,
    epoch,
    dryRun,
    createdAt,
    appliedAt,
    seenObservedAt,
    finalFolder,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SortDecision &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.messageIdHash == this.messageIdHash &&
          other.uid == this.uid &&
          other.uidValidity == this.uidValidity &&
          other.sourceFolder == this.sourceFolder &&
          other.destination == this.destination &&
          other.layer == this.layer &&
          other.matchedKey == this.matchedKey &&
          other.confidence == this.confidence &&
          other.reason == this.reason &&
          other.mode == this.mode &&
          other.status == this.status &&
          other.modelId == this.modelId &&
          other.folderProfileVersion == this.folderProfileVersion &&
          other.costUsd == this.costUsd &&
          other.deviceId == this.deviceId &&
          other.epoch == this.epoch &&
          other.dryRun == this.dryRun &&
          other.createdAt == this.createdAt &&
          other.appliedAt == this.appliedAt &&
          other.seenObservedAt == this.seenObservedAt &&
          other.finalFolder == this.finalFolder);
}

class SortDecisionsCompanion extends UpdateCompanion<SortDecision> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<String> messageIdHash;
  final Value<int?> uid;
  final Value<int?> uidValidity;
  final Value<String> sourceFolder;
  final Value<String> destination;
  final Value<String> layer;
  final Value<String?> matchedKey;
  final Value<double> confidence;
  final Value<String> reason;
  final Value<String> mode;
  final Value<String> status;
  final Value<String?> modelId;
  final Value<int?> folderProfileVersion;
  final Value<double?> costUsd;
  final Value<String?> deviceId;
  final Value<int?> epoch;
  final Value<bool> dryRun;
  final Value<int> createdAt;
  final Value<int?> appliedAt;
  final Value<int?> seenObservedAt;
  final Value<String?> finalFolder;
  final Value<int> rowid;
  const SortDecisionsCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.messageIdHash = const Value.absent(),
    this.uid = const Value.absent(),
    this.uidValidity = const Value.absent(),
    this.sourceFolder = const Value.absent(),
    this.destination = const Value.absent(),
    this.layer = const Value.absent(),
    this.matchedKey = const Value.absent(),
    this.confidence = const Value.absent(),
    this.reason = const Value.absent(),
    this.mode = const Value.absent(),
    this.status = const Value.absent(),
    this.modelId = const Value.absent(),
    this.folderProfileVersion = const Value.absent(),
    this.costUsd = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.epoch = const Value.absent(),
    this.dryRun = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.appliedAt = const Value.absent(),
    this.seenObservedAt = const Value.absent(),
    this.finalFolder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SortDecisionsCompanion.insert({
    required String id,
    required String accountId,
    required String messageIdHash,
    this.uid = const Value.absent(),
    this.uidValidity = const Value.absent(),
    required String sourceFolder,
    required String destination,
    required String layer,
    this.matchedKey = const Value.absent(),
    required double confidence,
    this.reason = const Value.absent(),
    required String mode,
    required String status,
    this.modelId = const Value.absent(),
    this.folderProfileVersion = const Value.absent(),
    this.costUsd = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.epoch = const Value.absent(),
    this.dryRun = const Value.absent(),
    required int createdAt,
    this.appliedAt = const Value.absent(),
    this.seenObservedAt = const Value.absent(),
    this.finalFolder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accountId = Value(accountId),
       messageIdHash = Value(messageIdHash),
       sourceFolder = Value(sourceFolder),
       destination = Value(destination),
       layer = Value(layer),
       confidence = Value(confidence),
       mode = Value(mode),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<SortDecision> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<String>? messageIdHash,
    Expression<int>? uid,
    Expression<int>? uidValidity,
    Expression<String>? sourceFolder,
    Expression<String>? destination,
    Expression<String>? layer,
    Expression<String>? matchedKey,
    Expression<double>? confidence,
    Expression<String>? reason,
    Expression<String>? mode,
    Expression<String>? status,
    Expression<String>? modelId,
    Expression<int>? folderProfileVersion,
    Expression<double>? costUsd,
    Expression<String>? deviceId,
    Expression<int>? epoch,
    Expression<bool>? dryRun,
    Expression<int>? createdAt,
    Expression<int>? appliedAt,
    Expression<int>? seenObservedAt,
    Expression<String>? finalFolder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (messageIdHash != null) 'message_id_hash': messageIdHash,
      if (uid != null) 'uid': uid,
      if (uidValidity != null) 'uid_validity': uidValidity,
      if (sourceFolder != null) 'source_folder': sourceFolder,
      if (destination != null) 'destination': destination,
      if (layer != null) 'layer': layer,
      if (matchedKey != null) 'matched_key': matchedKey,
      if (confidence != null) 'confidence': confidence,
      if (reason != null) 'reason': reason,
      if (mode != null) 'mode': mode,
      if (status != null) 'status': status,
      if (modelId != null) 'model_id': modelId,
      if (folderProfileVersion != null)
        'folder_profile_version': folderProfileVersion,
      if (costUsd != null) 'cost_usd': costUsd,
      if (deviceId != null) 'device_id': deviceId,
      if (epoch != null) 'epoch': epoch,
      if (dryRun != null) 'dry_run': dryRun,
      if (createdAt != null) 'created_at': createdAt,
      if (appliedAt != null) 'applied_at': appliedAt,
      if (seenObservedAt != null) 'seen_observed_at': seenObservedAt,
      if (finalFolder != null) 'final_folder': finalFolder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SortDecisionsCompanion copyWith({
    Value<String>? id,
    Value<String>? accountId,
    Value<String>? messageIdHash,
    Value<int?>? uid,
    Value<int?>? uidValidity,
    Value<String>? sourceFolder,
    Value<String>? destination,
    Value<String>? layer,
    Value<String?>? matchedKey,
    Value<double>? confidence,
    Value<String>? reason,
    Value<String>? mode,
    Value<String>? status,
    Value<String?>? modelId,
    Value<int?>? folderProfileVersion,
    Value<double?>? costUsd,
    Value<String?>? deviceId,
    Value<int?>? epoch,
    Value<bool>? dryRun,
    Value<int>? createdAt,
    Value<int?>? appliedAt,
    Value<int?>? seenObservedAt,
    Value<String?>? finalFolder,
    Value<int>? rowid,
  }) {
    return SortDecisionsCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      messageIdHash: messageIdHash ?? this.messageIdHash,
      uid: uid ?? this.uid,
      uidValidity: uidValidity ?? this.uidValidity,
      sourceFolder: sourceFolder ?? this.sourceFolder,
      destination: destination ?? this.destination,
      layer: layer ?? this.layer,
      matchedKey: matchedKey ?? this.matchedKey,
      confidence: confidence ?? this.confidence,
      reason: reason ?? this.reason,
      mode: mode ?? this.mode,
      status: status ?? this.status,
      modelId: modelId ?? this.modelId,
      folderProfileVersion: folderProfileVersion ?? this.folderProfileVersion,
      costUsd: costUsd ?? this.costUsd,
      deviceId: deviceId ?? this.deviceId,
      epoch: epoch ?? this.epoch,
      dryRun: dryRun ?? this.dryRun,
      createdAt: createdAt ?? this.createdAt,
      appliedAt: appliedAt ?? this.appliedAt,
      seenObservedAt: seenObservedAt ?? this.seenObservedAt,
      finalFolder: finalFolder ?? this.finalFolder,
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
    if (messageIdHash.present) {
      map['message_id_hash'] = Variable<String>(messageIdHash.value);
    }
    if (uid.present) {
      map['uid'] = Variable<int>(uid.value);
    }
    if (uidValidity.present) {
      map['uid_validity'] = Variable<int>(uidValidity.value);
    }
    if (sourceFolder.present) {
      map['source_folder'] = Variable<String>(sourceFolder.value);
    }
    if (destination.present) {
      map['destination'] = Variable<String>(destination.value);
    }
    if (layer.present) {
      map['layer'] = Variable<String>(layer.value);
    }
    if (matchedKey.present) {
      map['matched_key'] = Variable<String>(matchedKey.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (modelId.present) {
      map['model_id'] = Variable<String>(modelId.value);
    }
    if (folderProfileVersion.present) {
      map['folder_profile_version'] = Variable<int>(folderProfileVersion.value);
    }
    if (costUsd.present) {
      map['cost_usd'] = Variable<double>(costUsd.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (epoch.present) {
      map['epoch'] = Variable<int>(epoch.value);
    }
    if (dryRun.present) {
      map['dry_run'] = Variable<bool>(dryRun.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (appliedAt.present) {
      map['applied_at'] = Variable<int>(appliedAt.value);
    }
    if (seenObservedAt.present) {
      map['seen_observed_at'] = Variable<int>(seenObservedAt.value);
    }
    if (finalFolder.present) {
      map['final_folder'] = Variable<String>(finalFolder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SortDecisionsCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('messageIdHash: $messageIdHash, ')
          ..write('uid: $uid, ')
          ..write('uidValidity: $uidValidity, ')
          ..write('sourceFolder: $sourceFolder, ')
          ..write('destination: $destination, ')
          ..write('layer: $layer, ')
          ..write('matchedKey: $matchedKey, ')
          ..write('confidence: $confidence, ')
          ..write('reason: $reason, ')
          ..write('mode: $mode, ')
          ..write('status: $status, ')
          ..write('modelId: $modelId, ')
          ..write('folderProfileVersion: $folderProfileVersion, ')
          ..write('costUsd: $costUsd, ')
          ..write('deviceId: $deviceId, ')
          ..write('epoch: $epoch, ')
          ..write('dryRun: $dryRun, ')
          ..write('createdAt: $createdAt, ')
          ..write('appliedAt: $appliedAt, ')
          ..write('seenObservedAt: $seenObservedAt, ')
          ..write('finalFolder: $finalFolder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CorrectionsTable extends Corrections
    with TableInfo<$CorrectionsTable, Correction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CorrectionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _messageIdHashMeta = const VerificationMeta(
    'messageIdHash',
  );
  @override
  late final GeneratedColumn<String> messageIdHash = GeneratedColumn<String>(
    'message_id_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _decisionIdMeta = const VerificationMeta(
    'decisionId',
  );
  @override
  late final GeneratedColumn<String> decisionId = GeneratedColumn<String>(
    'decision_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
    'weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _predictedFolderMeta = const VerificationMeta(
    'predictedFolder',
  );
  @override
  late final GeneratedColumn<String> predictedFolder = GeneratedColumn<String>(
    'predicted_folder',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actualFolderMeta = const VerificationMeta(
    'actualFolder',
  );
  @override
  late final GeneratedColumn<String> actualFolder = GeneratedColumn<String>(
    'actual_folder',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromAddressMeta = const VerificationMeta(
    'fromAddress',
  );
  @override
  late final GeneratedColumn<String> fromAddress = GeneratedColumn<String>(
    'from_address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fromDomainMeta = const VerificationMeta(
    'fromDomain',
  );
  @override
  late final GeneratedColumn<String> fromDomain = GeneratedColumn<String>(
    'from_domain',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _listIdMeta = const VerificationMeta('listId');
  @override
  late final GeneratedColumn<String> listId = GeneratedColumn<String>(
    'list_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subjectNormMeta = const VerificationMeta(
    'subjectNorm',
  );
  @override
  late final GeneratedColumn<String> subjectNorm = GeneratedColumn<String>(
    'subject_norm',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _supersededMeta = const VerificationMeta(
    'superseded',
  );
  @override
  late final GeneratedColumn<bool> superseded = GeneratedColumn<bool>(
    'superseded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("superseded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    messageIdHash,
    decisionId,
    kind,
    weight,
    predictedFolder,
    actualFolder,
    fromAddress,
    fromDomain,
    listId,
    subjectNorm,
    superseded,
    deviceId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'corrections';
  @override
  VerificationContext validateIntegrity(
    Insertable<Correction> instance, {
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
    if (data.containsKey('message_id_hash')) {
      context.handle(
        _messageIdHashMeta,
        messageIdHash.isAcceptableOrUnknown(
          data['message_id_hash']!,
          _messageIdHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_messageIdHashMeta);
    }
    if (data.containsKey('decision_id')) {
      context.handle(
        _decisionIdMeta,
        decisionId.isAcceptableOrUnknown(data['decision_id']!, _decisionIdMeta),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('weight')) {
      context.handle(
        _weightMeta,
        weight.isAcceptableOrUnknown(data['weight']!, _weightMeta),
      );
    } else if (isInserting) {
      context.missing(_weightMeta);
    }
    if (data.containsKey('predicted_folder')) {
      context.handle(
        _predictedFolderMeta,
        predictedFolder.isAcceptableOrUnknown(
          data['predicted_folder']!,
          _predictedFolderMeta,
        ),
      );
    }
    if (data.containsKey('actual_folder')) {
      context.handle(
        _actualFolderMeta,
        actualFolder.isAcceptableOrUnknown(
          data['actual_folder']!,
          _actualFolderMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_actualFolderMeta);
    }
    if (data.containsKey('from_address')) {
      context.handle(
        _fromAddressMeta,
        fromAddress.isAcceptableOrUnknown(
          data['from_address']!,
          _fromAddressMeta,
        ),
      );
    }
    if (data.containsKey('from_domain')) {
      context.handle(
        _fromDomainMeta,
        fromDomain.isAcceptableOrUnknown(data['from_domain']!, _fromDomainMeta),
      );
    }
    if (data.containsKey('list_id')) {
      context.handle(
        _listIdMeta,
        listId.isAcceptableOrUnknown(data['list_id']!, _listIdMeta),
      );
    }
    if (data.containsKey('subject_norm')) {
      context.handle(
        _subjectNormMeta,
        subjectNorm.isAcceptableOrUnknown(
          data['subject_norm']!,
          _subjectNormMeta,
        ),
      );
    }
    if (data.containsKey('superseded')) {
      context.handle(
        _supersededMeta,
        superseded.isAcceptableOrUnknown(data['superseded']!, _supersededMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Correction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Correction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      messageIdHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id_hash'],
      )!,
      decisionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}decision_id'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      weight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight'],
      )!,
      predictedFolder: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}predicted_folder'],
      ),
      actualFolder: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actual_folder'],
      )!,
      fromAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_address'],
      ),
      fromDomain: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_domain'],
      ),
      listId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}list_id'],
      ),
      subjectNorm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_norm'],
      ),
      superseded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}superseded'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CorrectionsTable createAlias(String alias) {
    return $CorrectionsTable(attachedDatabase, alias);
  }
}

class Correction extends DataClass implements Insertable<Correction> {
  final String id;
  final String accountId;
  final String messageIdHash;
  final String? decisionId;
  final String kind;
  final double weight;
  final String? predictedFolder;
  final String actualFolder;
  final String? fromAddress;
  final String? fromDomain;
  final String? listId;
  final String? subjectNorm;
  final bool superseded;
  final String? deviceId;
  final int createdAt;
  const Correction({
    required this.id,
    required this.accountId,
    required this.messageIdHash,
    this.decisionId,
    required this.kind,
    required this.weight,
    this.predictedFolder,
    required this.actualFolder,
    this.fromAddress,
    this.fromDomain,
    this.listId,
    this.subjectNorm,
    required this.superseded,
    this.deviceId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    map['message_id_hash'] = Variable<String>(messageIdHash);
    if (!nullToAbsent || decisionId != null) {
      map['decision_id'] = Variable<String>(decisionId);
    }
    map['kind'] = Variable<String>(kind);
    map['weight'] = Variable<double>(weight);
    if (!nullToAbsent || predictedFolder != null) {
      map['predicted_folder'] = Variable<String>(predictedFolder);
    }
    map['actual_folder'] = Variable<String>(actualFolder);
    if (!nullToAbsent || fromAddress != null) {
      map['from_address'] = Variable<String>(fromAddress);
    }
    if (!nullToAbsent || fromDomain != null) {
      map['from_domain'] = Variable<String>(fromDomain);
    }
    if (!nullToAbsent || listId != null) {
      map['list_id'] = Variable<String>(listId);
    }
    if (!nullToAbsent || subjectNorm != null) {
      map['subject_norm'] = Variable<String>(subjectNorm);
    }
    map['superseded'] = Variable<bool>(superseded);
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  CorrectionsCompanion toCompanion(bool nullToAbsent) {
    return CorrectionsCompanion(
      id: Value(id),
      accountId: Value(accountId),
      messageIdHash: Value(messageIdHash),
      decisionId: decisionId == null && nullToAbsent
          ? const Value.absent()
          : Value(decisionId),
      kind: Value(kind),
      weight: Value(weight),
      predictedFolder: predictedFolder == null && nullToAbsent
          ? const Value.absent()
          : Value(predictedFolder),
      actualFolder: Value(actualFolder),
      fromAddress: fromAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(fromAddress),
      fromDomain: fromDomain == null && nullToAbsent
          ? const Value.absent()
          : Value(fromDomain),
      listId: listId == null && nullToAbsent
          ? const Value.absent()
          : Value(listId),
      subjectNorm: subjectNorm == null && nullToAbsent
          ? const Value.absent()
          : Value(subjectNorm),
      superseded: Value(superseded),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      createdAt: Value(createdAt),
    );
  }

  factory Correction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Correction(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      messageIdHash: serializer.fromJson<String>(json['messageIdHash']),
      decisionId: serializer.fromJson<String?>(json['decisionId']),
      kind: serializer.fromJson<String>(json['kind']),
      weight: serializer.fromJson<double>(json['weight']),
      predictedFolder: serializer.fromJson<String?>(json['predictedFolder']),
      actualFolder: serializer.fromJson<String>(json['actualFolder']),
      fromAddress: serializer.fromJson<String?>(json['fromAddress']),
      fromDomain: serializer.fromJson<String?>(json['fromDomain']),
      listId: serializer.fromJson<String?>(json['listId']),
      subjectNorm: serializer.fromJson<String?>(json['subjectNorm']),
      superseded: serializer.fromJson<bool>(json['superseded']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'messageIdHash': serializer.toJson<String>(messageIdHash),
      'decisionId': serializer.toJson<String?>(decisionId),
      'kind': serializer.toJson<String>(kind),
      'weight': serializer.toJson<double>(weight),
      'predictedFolder': serializer.toJson<String?>(predictedFolder),
      'actualFolder': serializer.toJson<String>(actualFolder),
      'fromAddress': serializer.toJson<String?>(fromAddress),
      'fromDomain': serializer.toJson<String?>(fromDomain),
      'listId': serializer.toJson<String?>(listId),
      'subjectNorm': serializer.toJson<String?>(subjectNorm),
      'superseded': serializer.toJson<bool>(superseded),
      'deviceId': serializer.toJson<String?>(deviceId),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  Correction copyWith({
    String? id,
    String? accountId,
    String? messageIdHash,
    Value<String?> decisionId = const Value.absent(),
    String? kind,
    double? weight,
    Value<String?> predictedFolder = const Value.absent(),
    String? actualFolder,
    Value<String?> fromAddress = const Value.absent(),
    Value<String?> fromDomain = const Value.absent(),
    Value<String?> listId = const Value.absent(),
    Value<String?> subjectNorm = const Value.absent(),
    bool? superseded,
    Value<String?> deviceId = const Value.absent(),
    int? createdAt,
  }) => Correction(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    messageIdHash: messageIdHash ?? this.messageIdHash,
    decisionId: decisionId.present ? decisionId.value : this.decisionId,
    kind: kind ?? this.kind,
    weight: weight ?? this.weight,
    predictedFolder: predictedFolder.present
        ? predictedFolder.value
        : this.predictedFolder,
    actualFolder: actualFolder ?? this.actualFolder,
    fromAddress: fromAddress.present ? fromAddress.value : this.fromAddress,
    fromDomain: fromDomain.present ? fromDomain.value : this.fromDomain,
    listId: listId.present ? listId.value : this.listId,
    subjectNorm: subjectNorm.present ? subjectNorm.value : this.subjectNorm,
    superseded: superseded ?? this.superseded,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
    createdAt: createdAt ?? this.createdAt,
  );
  Correction copyWithCompanion(CorrectionsCompanion data) {
    return Correction(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      messageIdHash: data.messageIdHash.present
          ? data.messageIdHash.value
          : this.messageIdHash,
      decisionId: data.decisionId.present
          ? data.decisionId.value
          : this.decisionId,
      kind: data.kind.present ? data.kind.value : this.kind,
      weight: data.weight.present ? data.weight.value : this.weight,
      predictedFolder: data.predictedFolder.present
          ? data.predictedFolder.value
          : this.predictedFolder,
      actualFolder: data.actualFolder.present
          ? data.actualFolder.value
          : this.actualFolder,
      fromAddress: data.fromAddress.present
          ? data.fromAddress.value
          : this.fromAddress,
      fromDomain: data.fromDomain.present
          ? data.fromDomain.value
          : this.fromDomain,
      listId: data.listId.present ? data.listId.value : this.listId,
      subjectNorm: data.subjectNorm.present
          ? data.subjectNorm.value
          : this.subjectNorm,
      superseded: data.superseded.present
          ? data.superseded.value
          : this.superseded,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Correction(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('messageIdHash: $messageIdHash, ')
          ..write('decisionId: $decisionId, ')
          ..write('kind: $kind, ')
          ..write('weight: $weight, ')
          ..write('predictedFolder: $predictedFolder, ')
          ..write('actualFolder: $actualFolder, ')
          ..write('fromAddress: $fromAddress, ')
          ..write('fromDomain: $fromDomain, ')
          ..write('listId: $listId, ')
          ..write('subjectNorm: $subjectNorm, ')
          ..write('superseded: $superseded, ')
          ..write('deviceId: $deviceId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountId,
    messageIdHash,
    decisionId,
    kind,
    weight,
    predictedFolder,
    actualFolder,
    fromAddress,
    fromDomain,
    listId,
    subjectNorm,
    superseded,
    deviceId,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Correction &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.messageIdHash == this.messageIdHash &&
          other.decisionId == this.decisionId &&
          other.kind == this.kind &&
          other.weight == this.weight &&
          other.predictedFolder == this.predictedFolder &&
          other.actualFolder == this.actualFolder &&
          other.fromAddress == this.fromAddress &&
          other.fromDomain == this.fromDomain &&
          other.listId == this.listId &&
          other.subjectNorm == this.subjectNorm &&
          other.superseded == this.superseded &&
          other.deviceId == this.deviceId &&
          other.createdAt == this.createdAt);
}

class CorrectionsCompanion extends UpdateCompanion<Correction> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<String> messageIdHash;
  final Value<String?> decisionId;
  final Value<String> kind;
  final Value<double> weight;
  final Value<String?> predictedFolder;
  final Value<String> actualFolder;
  final Value<String?> fromAddress;
  final Value<String?> fromDomain;
  final Value<String?> listId;
  final Value<String?> subjectNorm;
  final Value<bool> superseded;
  final Value<String?> deviceId;
  final Value<int> createdAt;
  final Value<int> rowid;
  const CorrectionsCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.messageIdHash = const Value.absent(),
    this.decisionId = const Value.absent(),
    this.kind = const Value.absent(),
    this.weight = const Value.absent(),
    this.predictedFolder = const Value.absent(),
    this.actualFolder = const Value.absent(),
    this.fromAddress = const Value.absent(),
    this.fromDomain = const Value.absent(),
    this.listId = const Value.absent(),
    this.subjectNorm = const Value.absent(),
    this.superseded = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CorrectionsCompanion.insert({
    required String id,
    required String accountId,
    required String messageIdHash,
    this.decisionId = const Value.absent(),
    required String kind,
    required double weight,
    this.predictedFolder = const Value.absent(),
    required String actualFolder,
    this.fromAddress = const Value.absent(),
    this.fromDomain = const Value.absent(),
    this.listId = const Value.absent(),
    this.subjectNorm = const Value.absent(),
    this.superseded = const Value.absent(),
    this.deviceId = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accountId = Value(accountId),
       messageIdHash = Value(messageIdHash),
       kind = Value(kind),
       weight = Value(weight),
       actualFolder = Value(actualFolder),
       createdAt = Value(createdAt);
  static Insertable<Correction> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<String>? messageIdHash,
    Expression<String>? decisionId,
    Expression<String>? kind,
    Expression<double>? weight,
    Expression<String>? predictedFolder,
    Expression<String>? actualFolder,
    Expression<String>? fromAddress,
    Expression<String>? fromDomain,
    Expression<String>? listId,
    Expression<String>? subjectNorm,
    Expression<bool>? superseded,
    Expression<String>? deviceId,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (messageIdHash != null) 'message_id_hash': messageIdHash,
      if (decisionId != null) 'decision_id': decisionId,
      if (kind != null) 'kind': kind,
      if (weight != null) 'weight': weight,
      if (predictedFolder != null) 'predicted_folder': predictedFolder,
      if (actualFolder != null) 'actual_folder': actualFolder,
      if (fromAddress != null) 'from_address': fromAddress,
      if (fromDomain != null) 'from_domain': fromDomain,
      if (listId != null) 'list_id': listId,
      if (subjectNorm != null) 'subject_norm': subjectNorm,
      if (superseded != null) 'superseded': superseded,
      if (deviceId != null) 'device_id': deviceId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CorrectionsCompanion copyWith({
    Value<String>? id,
    Value<String>? accountId,
    Value<String>? messageIdHash,
    Value<String?>? decisionId,
    Value<String>? kind,
    Value<double>? weight,
    Value<String?>? predictedFolder,
    Value<String>? actualFolder,
    Value<String?>? fromAddress,
    Value<String?>? fromDomain,
    Value<String?>? listId,
    Value<String?>? subjectNorm,
    Value<bool>? superseded,
    Value<String?>? deviceId,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return CorrectionsCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      messageIdHash: messageIdHash ?? this.messageIdHash,
      decisionId: decisionId ?? this.decisionId,
      kind: kind ?? this.kind,
      weight: weight ?? this.weight,
      predictedFolder: predictedFolder ?? this.predictedFolder,
      actualFolder: actualFolder ?? this.actualFolder,
      fromAddress: fromAddress ?? this.fromAddress,
      fromDomain: fromDomain ?? this.fromDomain,
      listId: listId ?? this.listId,
      subjectNorm: subjectNorm ?? this.subjectNorm,
      superseded: superseded ?? this.superseded,
      deviceId: deviceId ?? this.deviceId,
      createdAt: createdAt ?? this.createdAt,
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
    if (messageIdHash.present) {
      map['message_id_hash'] = Variable<String>(messageIdHash.value);
    }
    if (decisionId.present) {
      map['decision_id'] = Variable<String>(decisionId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (predictedFolder.present) {
      map['predicted_folder'] = Variable<String>(predictedFolder.value);
    }
    if (actualFolder.present) {
      map['actual_folder'] = Variable<String>(actualFolder.value);
    }
    if (fromAddress.present) {
      map['from_address'] = Variable<String>(fromAddress.value);
    }
    if (fromDomain.present) {
      map['from_domain'] = Variable<String>(fromDomain.value);
    }
    if (listId.present) {
      map['list_id'] = Variable<String>(listId.value);
    }
    if (subjectNorm.present) {
      map['subject_norm'] = Variable<String>(subjectNorm.value);
    }
    if (superseded.present) {
      map['superseded'] = Variable<bool>(superseded.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CorrectionsCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('messageIdHash: $messageIdHash, ')
          ..write('decisionId: $decisionId, ')
          ..write('kind: $kind, ')
          ..write('weight: $weight, ')
          ..write('predictedFolder: $predictedFolder, ')
          ..write('actualFolder: $actualFolder, ')
          ..write('fromAddress: $fromAddress, ')
          ..write('fromDomain: $fromDomain, ')
          ..write('listId: $listId, ')
          ..write('subjectNorm: $subjectNorm, ')
          ..write('superseded: $superseded, ')
          ..write('deviceId: $deviceId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FolderProfilesTable extends FolderProfiles
    with TableInfo<$FolderProfilesTable, FolderProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FolderProfilesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
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
  static const VerificationMeta _specialUseMeta = const VerificationMeta(
    'specialUse',
  );
  @override
  late final GeneratedColumn<String> specialUse = GeneratedColumn<String>(
    'special_use',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _neverSortMeta = const VerificationMeta(
    'neverSort',
  );
  @override
  late final GeneratedColumn<bool> neverSort = GeneratedColumn<bool>(
    'never_sort',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("never_sort" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _neverSortSourceMeta = const VerificationMeta(
    'neverSortSource',
  );
  @override
  late final GeneratedColumn<String> neverSortSource = GeneratedColumn<String>(
    'never_sort_source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('default'),
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
  static const VerificationMeta _descriptionSourceMeta = const VerificationMeta(
    'descriptionSource',
  );
  @override
  late final GeneratedColumn<String> descriptionSource =
      GeneratedColumn<String>(
        'description_source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('auto'),
      );
  static const VerificationMeta _topSendersJsonMeta = const VerificationMeta(
    'topSendersJson',
  );
  @override
  late final GeneratedColumn<String> topSendersJson = GeneratedColumn<String>(
    'top_senders_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _topListIdsJsonMeta = const VerificationMeta(
    'topListIdsJson',
  );
  @override
  late final GeneratedColumn<String> topListIdsJson = GeneratedColumn<String>(
    'top_list_ids_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _topDomainsJsonMeta = const VerificationMeta(
    'topDomainsJson',
  );
  @override
  late final GeneratedColumn<String> topDomainsJson = GeneratedColumn<String>(
    'top_domains_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _sampleSubjectsJsonMeta =
      const VerificationMeta('sampleSubjectsJson');
  @override
  late final GeneratedColumn<String> sampleSubjectsJson =
      GeneratedColumn<String>(
        'sample_subjects_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _messageCountMeta = const VerificationMeta(
    'messageCount',
  );
  @override
  late final GeneratedColumn<int> messageCount = GeneratedColumn<int>(
    'message_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _userFiledCountMeta = const VerificationMeta(
    'userFiledCount',
  );
  @override
  late final GeneratedColumn<int> userFiledCount = GeneratedColumn<int>(
    'user_filed_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastUserFiledAtMeta = const VerificationMeta(
    'lastUserFiledAt',
  );
  @override
  late final GeneratedColumn<int> lastUserFiledAt = GeneratedColumn<int>(
    'last_user_filed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _profileVersionMeta = const VerificationMeta(
    'profileVersion',
  );
  @override
  late final GeneratedColumn<int> profileVersion = GeneratedColumn<int>(
    'profile_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _renderedTextMeta = const VerificationMeta(
    'renderedText',
  );
  @override
  late final GeneratedColumn<String> renderedText = GeneratedColumn<String>(
    'rendered_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    path,
    name,
    specialUse,
    neverSort,
    neverSortSource,
    description,
    descriptionSource,
    topSendersJson,
    topListIdsJson,
    topDomainsJson,
    sampleSubjectsJson,
    messageCount,
    userFiledCount,
    lastUserFiledAt,
    profileVersion,
    renderedText,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'folder_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<FolderProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('special_use')) {
      context.handle(
        _specialUseMeta,
        specialUse.isAcceptableOrUnknown(data['special_use']!, _specialUseMeta),
      );
    }
    if (data.containsKey('never_sort')) {
      context.handle(
        _neverSortMeta,
        neverSort.isAcceptableOrUnknown(data['never_sort']!, _neverSortMeta),
      );
    }
    if (data.containsKey('never_sort_source')) {
      context.handle(
        _neverSortSourceMeta,
        neverSortSource.isAcceptableOrUnknown(
          data['never_sort_source']!,
          _neverSortSourceMeta,
        ),
      );
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
    if (data.containsKey('description_source')) {
      context.handle(
        _descriptionSourceMeta,
        descriptionSource.isAcceptableOrUnknown(
          data['description_source']!,
          _descriptionSourceMeta,
        ),
      );
    }
    if (data.containsKey('top_senders_json')) {
      context.handle(
        _topSendersJsonMeta,
        topSendersJson.isAcceptableOrUnknown(
          data['top_senders_json']!,
          _topSendersJsonMeta,
        ),
      );
    }
    if (data.containsKey('top_list_ids_json')) {
      context.handle(
        _topListIdsJsonMeta,
        topListIdsJson.isAcceptableOrUnknown(
          data['top_list_ids_json']!,
          _topListIdsJsonMeta,
        ),
      );
    }
    if (data.containsKey('top_domains_json')) {
      context.handle(
        _topDomainsJsonMeta,
        topDomainsJson.isAcceptableOrUnknown(
          data['top_domains_json']!,
          _topDomainsJsonMeta,
        ),
      );
    }
    if (data.containsKey('sample_subjects_json')) {
      context.handle(
        _sampleSubjectsJsonMeta,
        sampleSubjectsJson.isAcceptableOrUnknown(
          data['sample_subjects_json']!,
          _sampleSubjectsJsonMeta,
        ),
      );
    }
    if (data.containsKey('message_count')) {
      context.handle(
        _messageCountMeta,
        messageCount.isAcceptableOrUnknown(
          data['message_count']!,
          _messageCountMeta,
        ),
      );
    }
    if (data.containsKey('user_filed_count')) {
      context.handle(
        _userFiledCountMeta,
        userFiledCount.isAcceptableOrUnknown(
          data['user_filed_count']!,
          _userFiledCountMeta,
        ),
      );
    }
    if (data.containsKey('last_user_filed_at')) {
      context.handle(
        _lastUserFiledAtMeta,
        lastUserFiledAt.isAcceptableOrUnknown(
          data['last_user_filed_at']!,
          _lastUserFiledAtMeta,
        ),
      );
    }
    if (data.containsKey('profile_version')) {
      context.handle(
        _profileVersionMeta,
        profileVersion.isAcceptableOrUnknown(
          data['profile_version']!,
          _profileVersionMeta,
        ),
      );
    }
    if (data.containsKey('rendered_text')) {
      context.handle(
        _renderedTextMeta,
        renderedText.isAcceptableOrUnknown(
          data['rendered_text']!,
          _renderedTextMeta,
        ),
      );
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
  Set<GeneratedColumn> get $primaryKey => {accountId, path};
  @override
  FolderProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FolderProfile(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      specialUse: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}special_use'],
      ),
      neverSort: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}never_sort'],
      )!,
      neverSortSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}never_sort_source'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      descriptionSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description_source'],
      )!,
      topSendersJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}top_senders_json'],
      )!,
      topListIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}top_list_ids_json'],
      )!,
      topDomainsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}top_domains_json'],
      )!,
      sampleSubjectsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sample_subjects_json'],
      )!,
      messageCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}message_count'],
      )!,
      userFiledCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_filed_count'],
      )!,
      lastUserFiledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_user_filed_at'],
      ),
      profileVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_version'],
      )!,
      renderedText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rendered_text'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $FolderProfilesTable createAlias(String alias) {
    return $FolderProfilesTable(attachedDatabase, alias);
  }
}

class FolderProfile extends DataClass implements Insertable<FolderProfile> {
  final String accountId;
  final String path;
  final String name;
  final String? specialUse;
  final bool neverSort;
  final String neverSortSource;
  final String? description;
  final String descriptionSource;
  final String topSendersJson;
  final String topListIdsJson;
  final String topDomainsJson;
  final String sampleSubjectsJson;
  final int messageCount;
  final int userFiledCount;
  final int? lastUserFiledAt;
  final int profileVersion;
  final String? renderedText;
  final int updatedAt;
  const FolderProfile({
    required this.accountId,
    required this.path,
    required this.name,
    this.specialUse,
    required this.neverSort,
    required this.neverSortSource,
    this.description,
    required this.descriptionSource,
    required this.topSendersJson,
    required this.topListIdsJson,
    required this.topDomainsJson,
    required this.sampleSubjectsJson,
    required this.messageCount,
    required this.userFiledCount,
    this.lastUserFiledAt,
    required this.profileVersion,
    this.renderedText,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['path'] = Variable<String>(path);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || specialUse != null) {
      map['special_use'] = Variable<String>(specialUse);
    }
    map['never_sort'] = Variable<bool>(neverSort);
    map['never_sort_source'] = Variable<String>(neverSortSource);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['description_source'] = Variable<String>(descriptionSource);
    map['top_senders_json'] = Variable<String>(topSendersJson);
    map['top_list_ids_json'] = Variable<String>(topListIdsJson);
    map['top_domains_json'] = Variable<String>(topDomainsJson);
    map['sample_subjects_json'] = Variable<String>(sampleSubjectsJson);
    map['message_count'] = Variable<int>(messageCount);
    map['user_filed_count'] = Variable<int>(userFiledCount);
    if (!nullToAbsent || lastUserFiledAt != null) {
      map['last_user_filed_at'] = Variable<int>(lastUserFiledAt);
    }
    map['profile_version'] = Variable<int>(profileVersion);
    if (!nullToAbsent || renderedText != null) {
      map['rendered_text'] = Variable<String>(renderedText);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  FolderProfilesCompanion toCompanion(bool nullToAbsent) {
    return FolderProfilesCompanion(
      accountId: Value(accountId),
      path: Value(path),
      name: Value(name),
      specialUse: specialUse == null && nullToAbsent
          ? const Value.absent()
          : Value(specialUse),
      neverSort: Value(neverSort),
      neverSortSource: Value(neverSortSource),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      descriptionSource: Value(descriptionSource),
      topSendersJson: Value(topSendersJson),
      topListIdsJson: Value(topListIdsJson),
      topDomainsJson: Value(topDomainsJson),
      sampleSubjectsJson: Value(sampleSubjectsJson),
      messageCount: Value(messageCount),
      userFiledCount: Value(userFiledCount),
      lastUserFiledAt: lastUserFiledAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUserFiledAt),
      profileVersion: Value(profileVersion),
      renderedText: renderedText == null && nullToAbsent
          ? const Value.absent()
          : Value(renderedText),
      updatedAt: Value(updatedAt),
    );
  }

  factory FolderProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FolderProfile(
      accountId: serializer.fromJson<String>(json['accountId']),
      path: serializer.fromJson<String>(json['path']),
      name: serializer.fromJson<String>(json['name']),
      specialUse: serializer.fromJson<String?>(json['specialUse']),
      neverSort: serializer.fromJson<bool>(json['neverSort']),
      neverSortSource: serializer.fromJson<String>(json['neverSortSource']),
      description: serializer.fromJson<String?>(json['description']),
      descriptionSource: serializer.fromJson<String>(json['descriptionSource']),
      topSendersJson: serializer.fromJson<String>(json['topSendersJson']),
      topListIdsJson: serializer.fromJson<String>(json['topListIdsJson']),
      topDomainsJson: serializer.fromJson<String>(json['topDomainsJson']),
      sampleSubjectsJson: serializer.fromJson<String>(
        json['sampleSubjectsJson'],
      ),
      messageCount: serializer.fromJson<int>(json['messageCount']),
      userFiledCount: serializer.fromJson<int>(json['userFiledCount']),
      lastUserFiledAt: serializer.fromJson<int?>(json['lastUserFiledAt']),
      profileVersion: serializer.fromJson<int>(json['profileVersion']),
      renderedText: serializer.fromJson<String?>(json['renderedText']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'path': serializer.toJson<String>(path),
      'name': serializer.toJson<String>(name),
      'specialUse': serializer.toJson<String?>(specialUse),
      'neverSort': serializer.toJson<bool>(neverSort),
      'neverSortSource': serializer.toJson<String>(neverSortSource),
      'description': serializer.toJson<String?>(description),
      'descriptionSource': serializer.toJson<String>(descriptionSource),
      'topSendersJson': serializer.toJson<String>(topSendersJson),
      'topListIdsJson': serializer.toJson<String>(topListIdsJson),
      'topDomainsJson': serializer.toJson<String>(topDomainsJson),
      'sampleSubjectsJson': serializer.toJson<String>(sampleSubjectsJson),
      'messageCount': serializer.toJson<int>(messageCount),
      'userFiledCount': serializer.toJson<int>(userFiledCount),
      'lastUserFiledAt': serializer.toJson<int?>(lastUserFiledAt),
      'profileVersion': serializer.toJson<int>(profileVersion),
      'renderedText': serializer.toJson<String?>(renderedText),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  FolderProfile copyWith({
    String? accountId,
    String? path,
    String? name,
    Value<String?> specialUse = const Value.absent(),
    bool? neverSort,
    String? neverSortSource,
    Value<String?> description = const Value.absent(),
    String? descriptionSource,
    String? topSendersJson,
    String? topListIdsJson,
    String? topDomainsJson,
    String? sampleSubjectsJson,
    int? messageCount,
    int? userFiledCount,
    Value<int?> lastUserFiledAt = const Value.absent(),
    int? profileVersion,
    Value<String?> renderedText = const Value.absent(),
    int? updatedAt,
  }) => FolderProfile(
    accountId: accountId ?? this.accountId,
    path: path ?? this.path,
    name: name ?? this.name,
    specialUse: specialUse.present ? specialUse.value : this.specialUse,
    neverSort: neverSort ?? this.neverSort,
    neverSortSource: neverSortSource ?? this.neverSortSource,
    description: description.present ? description.value : this.description,
    descriptionSource: descriptionSource ?? this.descriptionSource,
    topSendersJson: topSendersJson ?? this.topSendersJson,
    topListIdsJson: topListIdsJson ?? this.topListIdsJson,
    topDomainsJson: topDomainsJson ?? this.topDomainsJson,
    sampleSubjectsJson: sampleSubjectsJson ?? this.sampleSubjectsJson,
    messageCount: messageCount ?? this.messageCount,
    userFiledCount: userFiledCount ?? this.userFiledCount,
    lastUserFiledAt: lastUserFiledAt.present
        ? lastUserFiledAt.value
        : this.lastUserFiledAt,
    profileVersion: profileVersion ?? this.profileVersion,
    renderedText: renderedText.present ? renderedText.value : this.renderedText,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  FolderProfile copyWithCompanion(FolderProfilesCompanion data) {
    return FolderProfile(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      path: data.path.present ? data.path.value : this.path,
      name: data.name.present ? data.name.value : this.name,
      specialUse: data.specialUse.present
          ? data.specialUse.value
          : this.specialUse,
      neverSort: data.neverSort.present ? data.neverSort.value : this.neverSort,
      neverSortSource: data.neverSortSource.present
          ? data.neverSortSource.value
          : this.neverSortSource,
      description: data.description.present
          ? data.description.value
          : this.description,
      descriptionSource: data.descriptionSource.present
          ? data.descriptionSource.value
          : this.descriptionSource,
      topSendersJson: data.topSendersJson.present
          ? data.topSendersJson.value
          : this.topSendersJson,
      topListIdsJson: data.topListIdsJson.present
          ? data.topListIdsJson.value
          : this.topListIdsJson,
      topDomainsJson: data.topDomainsJson.present
          ? data.topDomainsJson.value
          : this.topDomainsJson,
      sampleSubjectsJson: data.sampleSubjectsJson.present
          ? data.sampleSubjectsJson.value
          : this.sampleSubjectsJson,
      messageCount: data.messageCount.present
          ? data.messageCount.value
          : this.messageCount,
      userFiledCount: data.userFiledCount.present
          ? data.userFiledCount.value
          : this.userFiledCount,
      lastUserFiledAt: data.lastUserFiledAt.present
          ? data.lastUserFiledAt.value
          : this.lastUserFiledAt,
      profileVersion: data.profileVersion.present
          ? data.profileVersion.value
          : this.profileVersion,
      renderedText: data.renderedText.present
          ? data.renderedText.value
          : this.renderedText,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FolderProfile(')
          ..write('accountId: $accountId, ')
          ..write('path: $path, ')
          ..write('name: $name, ')
          ..write('specialUse: $specialUse, ')
          ..write('neverSort: $neverSort, ')
          ..write('neverSortSource: $neverSortSource, ')
          ..write('description: $description, ')
          ..write('descriptionSource: $descriptionSource, ')
          ..write('topSendersJson: $topSendersJson, ')
          ..write('topListIdsJson: $topListIdsJson, ')
          ..write('topDomainsJson: $topDomainsJson, ')
          ..write('sampleSubjectsJson: $sampleSubjectsJson, ')
          ..write('messageCount: $messageCount, ')
          ..write('userFiledCount: $userFiledCount, ')
          ..write('lastUserFiledAt: $lastUserFiledAt, ')
          ..write('profileVersion: $profileVersion, ')
          ..write('renderedText: $renderedText, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    accountId,
    path,
    name,
    specialUse,
    neverSort,
    neverSortSource,
    description,
    descriptionSource,
    topSendersJson,
    topListIdsJson,
    topDomainsJson,
    sampleSubjectsJson,
    messageCount,
    userFiledCount,
    lastUserFiledAt,
    profileVersion,
    renderedText,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FolderProfile &&
          other.accountId == this.accountId &&
          other.path == this.path &&
          other.name == this.name &&
          other.specialUse == this.specialUse &&
          other.neverSort == this.neverSort &&
          other.neverSortSource == this.neverSortSource &&
          other.description == this.description &&
          other.descriptionSource == this.descriptionSource &&
          other.topSendersJson == this.topSendersJson &&
          other.topListIdsJson == this.topListIdsJson &&
          other.topDomainsJson == this.topDomainsJson &&
          other.sampleSubjectsJson == this.sampleSubjectsJson &&
          other.messageCount == this.messageCount &&
          other.userFiledCount == this.userFiledCount &&
          other.lastUserFiledAt == this.lastUserFiledAt &&
          other.profileVersion == this.profileVersion &&
          other.renderedText == this.renderedText &&
          other.updatedAt == this.updatedAt);
}

class FolderProfilesCompanion extends UpdateCompanion<FolderProfile> {
  final Value<String> accountId;
  final Value<String> path;
  final Value<String> name;
  final Value<String?> specialUse;
  final Value<bool> neverSort;
  final Value<String> neverSortSource;
  final Value<String?> description;
  final Value<String> descriptionSource;
  final Value<String> topSendersJson;
  final Value<String> topListIdsJson;
  final Value<String> topDomainsJson;
  final Value<String> sampleSubjectsJson;
  final Value<int> messageCount;
  final Value<int> userFiledCount;
  final Value<int?> lastUserFiledAt;
  final Value<int> profileVersion;
  final Value<String?> renderedText;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const FolderProfilesCompanion({
    this.accountId = const Value.absent(),
    this.path = const Value.absent(),
    this.name = const Value.absent(),
    this.specialUse = const Value.absent(),
    this.neverSort = const Value.absent(),
    this.neverSortSource = const Value.absent(),
    this.description = const Value.absent(),
    this.descriptionSource = const Value.absent(),
    this.topSendersJson = const Value.absent(),
    this.topListIdsJson = const Value.absent(),
    this.topDomainsJson = const Value.absent(),
    this.sampleSubjectsJson = const Value.absent(),
    this.messageCount = const Value.absent(),
    this.userFiledCount = const Value.absent(),
    this.lastUserFiledAt = const Value.absent(),
    this.profileVersion = const Value.absent(),
    this.renderedText = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FolderProfilesCompanion.insert({
    required String accountId,
    required String path,
    required String name,
    this.specialUse = const Value.absent(),
    this.neverSort = const Value.absent(),
    this.neverSortSource = const Value.absent(),
    this.description = const Value.absent(),
    this.descriptionSource = const Value.absent(),
    this.topSendersJson = const Value.absent(),
    this.topListIdsJson = const Value.absent(),
    this.topDomainsJson = const Value.absent(),
    this.sampleSubjectsJson = const Value.absent(),
    this.messageCount = const Value.absent(),
    this.userFiledCount = const Value.absent(),
    this.lastUserFiledAt = const Value.absent(),
    this.profileVersion = const Value.absent(),
    this.renderedText = const Value.absent(),
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       path = Value(path),
       name = Value(name),
       updatedAt = Value(updatedAt);
  static Insertable<FolderProfile> custom({
    Expression<String>? accountId,
    Expression<String>? path,
    Expression<String>? name,
    Expression<String>? specialUse,
    Expression<bool>? neverSort,
    Expression<String>? neverSortSource,
    Expression<String>? description,
    Expression<String>? descriptionSource,
    Expression<String>? topSendersJson,
    Expression<String>? topListIdsJson,
    Expression<String>? topDomainsJson,
    Expression<String>? sampleSubjectsJson,
    Expression<int>? messageCount,
    Expression<int>? userFiledCount,
    Expression<int>? lastUserFiledAt,
    Expression<int>? profileVersion,
    Expression<String>? renderedText,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (path != null) 'path': path,
      if (name != null) 'name': name,
      if (specialUse != null) 'special_use': specialUse,
      if (neverSort != null) 'never_sort': neverSort,
      if (neverSortSource != null) 'never_sort_source': neverSortSource,
      if (description != null) 'description': description,
      if (descriptionSource != null) 'description_source': descriptionSource,
      if (topSendersJson != null) 'top_senders_json': topSendersJson,
      if (topListIdsJson != null) 'top_list_ids_json': topListIdsJson,
      if (topDomainsJson != null) 'top_domains_json': topDomainsJson,
      if (sampleSubjectsJson != null)
        'sample_subjects_json': sampleSubjectsJson,
      if (messageCount != null) 'message_count': messageCount,
      if (userFiledCount != null) 'user_filed_count': userFiledCount,
      if (lastUserFiledAt != null) 'last_user_filed_at': lastUserFiledAt,
      if (profileVersion != null) 'profile_version': profileVersion,
      if (renderedText != null) 'rendered_text': renderedText,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FolderProfilesCompanion copyWith({
    Value<String>? accountId,
    Value<String>? path,
    Value<String>? name,
    Value<String?>? specialUse,
    Value<bool>? neverSort,
    Value<String>? neverSortSource,
    Value<String?>? description,
    Value<String>? descriptionSource,
    Value<String>? topSendersJson,
    Value<String>? topListIdsJson,
    Value<String>? topDomainsJson,
    Value<String>? sampleSubjectsJson,
    Value<int>? messageCount,
    Value<int>? userFiledCount,
    Value<int?>? lastUserFiledAt,
    Value<int>? profileVersion,
    Value<String?>? renderedText,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return FolderProfilesCompanion(
      accountId: accountId ?? this.accountId,
      path: path ?? this.path,
      name: name ?? this.name,
      specialUse: specialUse ?? this.specialUse,
      neverSort: neverSort ?? this.neverSort,
      neverSortSource: neverSortSource ?? this.neverSortSource,
      description: description ?? this.description,
      descriptionSource: descriptionSource ?? this.descriptionSource,
      topSendersJson: topSendersJson ?? this.topSendersJson,
      topListIdsJson: topListIdsJson ?? this.topListIdsJson,
      topDomainsJson: topDomainsJson ?? this.topDomainsJson,
      sampleSubjectsJson: sampleSubjectsJson ?? this.sampleSubjectsJson,
      messageCount: messageCount ?? this.messageCount,
      userFiledCount: userFiledCount ?? this.userFiledCount,
      lastUserFiledAt: lastUserFiledAt ?? this.lastUserFiledAt,
      profileVersion: profileVersion ?? this.profileVersion,
      renderedText: renderedText ?? this.renderedText,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (specialUse.present) {
      map['special_use'] = Variable<String>(specialUse.value);
    }
    if (neverSort.present) {
      map['never_sort'] = Variable<bool>(neverSort.value);
    }
    if (neverSortSource.present) {
      map['never_sort_source'] = Variable<String>(neverSortSource.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (descriptionSource.present) {
      map['description_source'] = Variable<String>(descriptionSource.value);
    }
    if (topSendersJson.present) {
      map['top_senders_json'] = Variable<String>(topSendersJson.value);
    }
    if (topListIdsJson.present) {
      map['top_list_ids_json'] = Variable<String>(topListIdsJson.value);
    }
    if (topDomainsJson.present) {
      map['top_domains_json'] = Variable<String>(topDomainsJson.value);
    }
    if (sampleSubjectsJson.present) {
      map['sample_subjects_json'] = Variable<String>(sampleSubjectsJson.value);
    }
    if (messageCount.present) {
      map['message_count'] = Variable<int>(messageCount.value);
    }
    if (userFiledCount.present) {
      map['user_filed_count'] = Variable<int>(userFiledCount.value);
    }
    if (lastUserFiledAt.present) {
      map['last_user_filed_at'] = Variable<int>(lastUserFiledAt.value);
    }
    if (profileVersion.present) {
      map['profile_version'] = Variable<int>(profileVersion.value);
    }
    if (renderedText.present) {
      map['rendered_text'] = Variable<String>(renderedText.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FolderProfilesCompanion(')
          ..write('accountId: $accountId, ')
          ..write('path: $path, ')
          ..write('name: $name, ')
          ..write('specialUse: $specialUse, ')
          ..write('neverSort: $neverSort, ')
          ..write('neverSortSource: $neverSortSource, ')
          ..write('description: $description, ')
          ..write('descriptionSource: $descriptionSource, ')
          ..write('topSendersJson: $topSendersJson, ')
          ..write('topListIdsJson: $topListIdsJson, ')
          ..write('topDomainsJson: $topDomainsJson, ')
          ..write('sampleSubjectsJson: $sampleSubjectsJson, ')
          ..write('messageCount: $messageCount, ')
          ..write('userFiledCount: $userFiledCount, ')
          ..write('lastUserFiledAt: $lastUserFiledAt, ')
          ..write('profileVersion: $profileVersion, ')
          ..write('renderedText: $renderedText, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FolderProfileHistoryTable extends FolderProfileHistory
    with TableInfo<$FolderProfileHistoryTable, FolderProfileHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FolderProfileHistoryTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profileVersionMeta = const VerificationMeta(
    'profileVersion',
  );
  @override
  late final GeneratedColumn<int> profileVersion = GeneratedColumn<int>(
    'profile_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _renderedTextMeta = const VerificationMeta(
    'renderedText',
  );
  @override
  late final GeneratedColumn<String> renderedText = GeneratedColumn<String>(
    'rendered_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    path,
    profileVersion,
    renderedText,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'folder_profile_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<FolderProfileHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('profile_version')) {
      context.handle(
        _profileVersionMeta,
        profileVersion.isAcceptableOrUnknown(
          data['profile_version']!,
          _profileVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_profileVersionMeta);
    }
    if (data.containsKey('rendered_text')) {
      context.handle(
        _renderedTextMeta,
        renderedText.isAcceptableOrUnknown(
          data['rendered_text']!,
          _renderedTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_renderedTextMeta);
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
  Set<GeneratedColumn> get $primaryKey => {accountId, path, profileVersion};
  @override
  FolderProfileHistoryData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FolderProfileHistoryData(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      profileVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_version'],
      )!,
      renderedText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rendered_text'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FolderProfileHistoryTable createAlias(String alias) {
    return $FolderProfileHistoryTable(attachedDatabase, alias);
  }
}

class FolderProfileHistoryData extends DataClass
    implements Insertable<FolderProfileHistoryData> {
  final String accountId;
  final String path;
  final int profileVersion;
  final String renderedText;
  final int createdAt;
  const FolderProfileHistoryData({
    required this.accountId,
    required this.path,
    required this.profileVersion,
    required this.renderedText,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['path'] = Variable<String>(path);
    map['profile_version'] = Variable<int>(profileVersion);
    map['rendered_text'] = Variable<String>(renderedText);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  FolderProfileHistoryCompanion toCompanion(bool nullToAbsent) {
    return FolderProfileHistoryCompanion(
      accountId: Value(accountId),
      path: Value(path),
      profileVersion: Value(profileVersion),
      renderedText: Value(renderedText),
      createdAt: Value(createdAt),
    );
  }

  factory FolderProfileHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FolderProfileHistoryData(
      accountId: serializer.fromJson<String>(json['accountId']),
      path: serializer.fromJson<String>(json['path']),
      profileVersion: serializer.fromJson<int>(json['profileVersion']),
      renderedText: serializer.fromJson<String>(json['renderedText']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'path': serializer.toJson<String>(path),
      'profileVersion': serializer.toJson<int>(profileVersion),
      'renderedText': serializer.toJson<String>(renderedText),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  FolderProfileHistoryData copyWith({
    String? accountId,
    String? path,
    int? profileVersion,
    String? renderedText,
    int? createdAt,
  }) => FolderProfileHistoryData(
    accountId: accountId ?? this.accountId,
    path: path ?? this.path,
    profileVersion: profileVersion ?? this.profileVersion,
    renderedText: renderedText ?? this.renderedText,
    createdAt: createdAt ?? this.createdAt,
  );
  FolderProfileHistoryData copyWithCompanion(
    FolderProfileHistoryCompanion data,
  ) {
    return FolderProfileHistoryData(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      path: data.path.present ? data.path.value : this.path,
      profileVersion: data.profileVersion.present
          ? data.profileVersion.value
          : this.profileVersion,
      renderedText: data.renderedText.present
          ? data.renderedText.value
          : this.renderedText,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FolderProfileHistoryData(')
          ..write('accountId: $accountId, ')
          ..write('path: $path, ')
          ..write('profileVersion: $profileVersion, ')
          ..write('renderedText: $renderedText, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(accountId, path, profileVersion, renderedText, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FolderProfileHistoryData &&
          other.accountId == this.accountId &&
          other.path == this.path &&
          other.profileVersion == this.profileVersion &&
          other.renderedText == this.renderedText &&
          other.createdAt == this.createdAt);
}

class FolderProfileHistoryCompanion
    extends UpdateCompanion<FolderProfileHistoryData> {
  final Value<String> accountId;
  final Value<String> path;
  final Value<int> profileVersion;
  final Value<String> renderedText;
  final Value<int> createdAt;
  final Value<int> rowid;
  const FolderProfileHistoryCompanion({
    this.accountId = const Value.absent(),
    this.path = const Value.absent(),
    this.profileVersion = const Value.absent(),
    this.renderedText = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FolderProfileHistoryCompanion.insert({
    required String accountId,
    required String path,
    required int profileVersion,
    required String renderedText,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       path = Value(path),
       profileVersion = Value(profileVersion),
       renderedText = Value(renderedText),
       createdAt = Value(createdAt);
  static Insertable<FolderProfileHistoryData> custom({
    Expression<String>? accountId,
    Expression<String>? path,
    Expression<int>? profileVersion,
    Expression<String>? renderedText,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (path != null) 'path': path,
      if (profileVersion != null) 'profile_version': profileVersion,
      if (renderedText != null) 'rendered_text': renderedText,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FolderProfileHistoryCompanion copyWith({
    Value<String>? accountId,
    Value<String>? path,
    Value<int>? profileVersion,
    Value<String>? renderedText,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return FolderProfileHistoryCompanion(
      accountId: accountId ?? this.accountId,
      path: path ?? this.path,
      profileVersion: profileVersion ?? this.profileVersion,
      renderedText: renderedText ?? this.renderedText,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (profileVersion.present) {
      map['profile_version'] = Variable<int>(profileVersion.value);
    }
    if (renderedText.present) {
      map['rendered_text'] = Variable<String>(renderedText.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FolderProfileHistoryCompanion(')
          ..write('accountId: $accountId, ')
          ..write('path: $path, ')
          ..write('profileVersion: $profileVersion, ')
          ..write('renderedText: $renderedText, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SenderStatsTable extends SenderStats
    with TableInfo<$SenderStatsTable, SenderStat> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SenderStatsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _keyKindMeta = const VerificationMeta(
    'keyKind',
  );
  @override
  late final GeneratedColumn<String> keyKind = GeneratedColumn<String>(
    'key_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _folderPathMeta = const VerificationMeta(
    'folderPath',
  );
  @override
  late final GeneratedColumn<String> folderPath = GeneratedColumn<String>(
    'folder_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countMeta = const VerificationMeta('count');
  @override
  late final GeneratedColumn<double> count = GeneratedColumn<double>(
    'count',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _weightedCountMeta = const VerificationMeta(
    'weightedCount',
  );
  @override
  late final GeneratedColumn<double> weightedCount = GeneratedColumn<double>(
    'weighted_count',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _countAgainstMeta = const VerificationMeta(
    'countAgainst',
  );
  @override
  late final GeneratedColumn<int> countAgainst = GeneratedColumn<int>(
    'count_against',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _firstSeenAtMeta = const VerificationMeta(
    'firstSeenAt',
  );
  @override
  late final GeneratedColumn<int> firstSeenAt = GeneratedColumn<int>(
    'first_seen_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastUserAtMeta = const VerificationMeta(
    'lastUserAt',
  );
  @override
  late final GeneratedColumn<int> lastUserAt = GeneratedColumn<int>(
    'last_user_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    keyKind,
    key,
    folderPath,
    count,
    weightedCount,
    countAgainst,
    firstSeenAt,
    lastUserAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sender_stats';
  @override
  VerificationContext validateIntegrity(
    Insertable<SenderStat> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('key_kind')) {
      context.handle(
        _keyKindMeta,
        keyKind.isAcceptableOrUnknown(data['key_kind']!, _keyKindMeta),
      );
    } else if (isInserting) {
      context.missing(_keyKindMeta);
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('folder_path')) {
      context.handle(
        _folderPathMeta,
        folderPath.isAcceptableOrUnknown(data['folder_path']!, _folderPathMeta),
      );
    } else if (isInserting) {
      context.missing(_folderPathMeta);
    }
    if (data.containsKey('count')) {
      context.handle(
        _countMeta,
        count.isAcceptableOrUnknown(data['count']!, _countMeta),
      );
    }
    if (data.containsKey('weighted_count')) {
      context.handle(
        _weightedCountMeta,
        weightedCount.isAcceptableOrUnknown(
          data['weighted_count']!,
          _weightedCountMeta,
        ),
      );
    }
    if (data.containsKey('count_against')) {
      context.handle(
        _countAgainstMeta,
        countAgainst.isAcceptableOrUnknown(
          data['count_against']!,
          _countAgainstMeta,
        ),
      );
    }
    if (data.containsKey('first_seen_at')) {
      context.handle(
        _firstSeenAtMeta,
        firstSeenAt.isAcceptableOrUnknown(
          data['first_seen_at']!,
          _firstSeenAtMeta,
        ),
      );
    }
    if (data.containsKey('last_user_at')) {
      context.handle(
        _lastUserAtMeta,
        lastUserAt.isAcceptableOrUnknown(
          data['last_user_at']!,
          _lastUserAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, keyKind, key, folderPath};
  @override
  SenderStat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SenderStat(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      keyKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key_kind'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      folderPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_path'],
      )!,
      count: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}count'],
      )!,
      weightedCount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weighted_count'],
      )!,
      countAgainst: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}count_against'],
      )!,
      firstSeenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}first_seen_at'],
      ),
      lastUserAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_user_at'],
      ),
    );
  }

  @override
  $SenderStatsTable createAlias(String alias) {
    return $SenderStatsTable(attachedDatabase, alias);
  }
}

class SenderStat extends DataClass implements Insertable<SenderStat> {
  final String accountId;

  /// list_id | from_addr | from_domain
  final String keyKind;
  final String key;
  final String folderPath;
  final double count;
  final double weightedCount;
  final int countAgainst;
  final int? firstSeenAt;
  final int? lastUserAt;
  const SenderStat({
    required this.accountId,
    required this.keyKind,
    required this.key,
    required this.folderPath,
    required this.count,
    required this.weightedCount,
    required this.countAgainst,
    this.firstSeenAt,
    this.lastUserAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['key_kind'] = Variable<String>(keyKind);
    map['key'] = Variable<String>(key);
    map['folder_path'] = Variable<String>(folderPath);
    map['count'] = Variable<double>(count);
    map['weighted_count'] = Variable<double>(weightedCount);
    map['count_against'] = Variable<int>(countAgainst);
    if (!nullToAbsent || firstSeenAt != null) {
      map['first_seen_at'] = Variable<int>(firstSeenAt);
    }
    if (!nullToAbsent || lastUserAt != null) {
      map['last_user_at'] = Variable<int>(lastUserAt);
    }
    return map;
  }

  SenderStatsCompanion toCompanion(bool nullToAbsent) {
    return SenderStatsCompanion(
      accountId: Value(accountId),
      keyKind: Value(keyKind),
      key: Value(key),
      folderPath: Value(folderPath),
      count: Value(count),
      weightedCount: Value(weightedCount),
      countAgainst: Value(countAgainst),
      firstSeenAt: firstSeenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(firstSeenAt),
      lastUserAt: lastUserAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUserAt),
    );
  }

  factory SenderStat.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SenderStat(
      accountId: serializer.fromJson<String>(json['accountId']),
      keyKind: serializer.fromJson<String>(json['keyKind']),
      key: serializer.fromJson<String>(json['key']),
      folderPath: serializer.fromJson<String>(json['folderPath']),
      count: serializer.fromJson<double>(json['count']),
      weightedCount: serializer.fromJson<double>(json['weightedCount']),
      countAgainst: serializer.fromJson<int>(json['countAgainst']),
      firstSeenAt: serializer.fromJson<int?>(json['firstSeenAt']),
      lastUserAt: serializer.fromJson<int?>(json['lastUserAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'keyKind': serializer.toJson<String>(keyKind),
      'key': serializer.toJson<String>(key),
      'folderPath': serializer.toJson<String>(folderPath),
      'count': serializer.toJson<double>(count),
      'weightedCount': serializer.toJson<double>(weightedCount),
      'countAgainst': serializer.toJson<int>(countAgainst),
      'firstSeenAt': serializer.toJson<int?>(firstSeenAt),
      'lastUserAt': serializer.toJson<int?>(lastUserAt),
    };
  }

  SenderStat copyWith({
    String? accountId,
    String? keyKind,
    String? key,
    String? folderPath,
    double? count,
    double? weightedCount,
    int? countAgainst,
    Value<int?> firstSeenAt = const Value.absent(),
    Value<int?> lastUserAt = const Value.absent(),
  }) => SenderStat(
    accountId: accountId ?? this.accountId,
    keyKind: keyKind ?? this.keyKind,
    key: key ?? this.key,
    folderPath: folderPath ?? this.folderPath,
    count: count ?? this.count,
    weightedCount: weightedCount ?? this.weightedCount,
    countAgainst: countAgainst ?? this.countAgainst,
    firstSeenAt: firstSeenAt.present ? firstSeenAt.value : this.firstSeenAt,
    lastUserAt: lastUserAt.present ? lastUserAt.value : this.lastUserAt,
  );
  SenderStat copyWithCompanion(SenderStatsCompanion data) {
    return SenderStat(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      keyKind: data.keyKind.present ? data.keyKind.value : this.keyKind,
      key: data.key.present ? data.key.value : this.key,
      folderPath: data.folderPath.present
          ? data.folderPath.value
          : this.folderPath,
      count: data.count.present ? data.count.value : this.count,
      weightedCount: data.weightedCount.present
          ? data.weightedCount.value
          : this.weightedCount,
      countAgainst: data.countAgainst.present
          ? data.countAgainst.value
          : this.countAgainst,
      firstSeenAt: data.firstSeenAt.present
          ? data.firstSeenAt.value
          : this.firstSeenAt,
      lastUserAt: data.lastUserAt.present
          ? data.lastUserAt.value
          : this.lastUserAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SenderStat(')
          ..write('accountId: $accountId, ')
          ..write('keyKind: $keyKind, ')
          ..write('key: $key, ')
          ..write('folderPath: $folderPath, ')
          ..write('count: $count, ')
          ..write('weightedCount: $weightedCount, ')
          ..write('countAgainst: $countAgainst, ')
          ..write('firstSeenAt: $firstSeenAt, ')
          ..write('lastUserAt: $lastUserAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    accountId,
    keyKind,
    key,
    folderPath,
    count,
    weightedCount,
    countAgainst,
    firstSeenAt,
    lastUserAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SenderStat &&
          other.accountId == this.accountId &&
          other.keyKind == this.keyKind &&
          other.key == this.key &&
          other.folderPath == this.folderPath &&
          other.count == this.count &&
          other.weightedCount == this.weightedCount &&
          other.countAgainst == this.countAgainst &&
          other.firstSeenAt == this.firstSeenAt &&
          other.lastUserAt == this.lastUserAt);
}

class SenderStatsCompanion extends UpdateCompanion<SenderStat> {
  final Value<String> accountId;
  final Value<String> keyKind;
  final Value<String> key;
  final Value<String> folderPath;
  final Value<double> count;
  final Value<double> weightedCount;
  final Value<int> countAgainst;
  final Value<int?> firstSeenAt;
  final Value<int?> lastUserAt;
  final Value<int> rowid;
  const SenderStatsCompanion({
    this.accountId = const Value.absent(),
    this.keyKind = const Value.absent(),
    this.key = const Value.absent(),
    this.folderPath = const Value.absent(),
    this.count = const Value.absent(),
    this.weightedCount = const Value.absent(),
    this.countAgainst = const Value.absent(),
    this.firstSeenAt = const Value.absent(),
    this.lastUserAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SenderStatsCompanion.insert({
    required String accountId,
    required String keyKind,
    required String key,
    required String folderPath,
    this.count = const Value.absent(),
    this.weightedCount = const Value.absent(),
    this.countAgainst = const Value.absent(),
    this.firstSeenAt = const Value.absent(),
    this.lastUserAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       keyKind = Value(keyKind),
       key = Value(key),
       folderPath = Value(folderPath);
  static Insertable<SenderStat> custom({
    Expression<String>? accountId,
    Expression<String>? keyKind,
    Expression<String>? key,
    Expression<String>? folderPath,
    Expression<double>? count,
    Expression<double>? weightedCount,
    Expression<int>? countAgainst,
    Expression<int>? firstSeenAt,
    Expression<int>? lastUserAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (keyKind != null) 'key_kind': keyKind,
      if (key != null) 'key': key,
      if (folderPath != null) 'folder_path': folderPath,
      if (count != null) 'count': count,
      if (weightedCount != null) 'weighted_count': weightedCount,
      if (countAgainst != null) 'count_against': countAgainst,
      if (firstSeenAt != null) 'first_seen_at': firstSeenAt,
      if (lastUserAt != null) 'last_user_at': lastUserAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SenderStatsCompanion copyWith({
    Value<String>? accountId,
    Value<String>? keyKind,
    Value<String>? key,
    Value<String>? folderPath,
    Value<double>? count,
    Value<double>? weightedCount,
    Value<int>? countAgainst,
    Value<int?>? firstSeenAt,
    Value<int?>? lastUserAt,
    Value<int>? rowid,
  }) {
    return SenderStatsCompanion(
      accountId: accountId ?? this.accountId,
      keyKind: keyKind ?? this.keyKind,
      key: key ?? this.key,
      folderPath: folderPath ?? this.folderPath,
      count: count ?? this.count,
      weightedCount: weightedCount ?? this.weightedCount,
      countAgainst: countAgainst ?? this.countAgainst,
      firstSeenAt: firstSeenAt ?? this.firstSeenAt,
      lastUserAt: lastUserAt ?? this.lastUserAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (keyKind.present) {
      map['key_kind'] = Variable<String>(keyKind.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (folderPath.present) {
      map['folder_path'] = Variable<String>(folderPath.value);
    }
    if (count.present) {
      map['count'] = Variable<double>(count.value);
    }
    if (weightedCount.present) {
      map['weighted_count'] = Variable<double>(weightedCount.value);
    }
    if (countAgainst.present) {
      map['count_against'] = Variable<int>(countAgainst.value);
    }
    if (firstSeenAt.present) {
      map['first_seen_at'] = Variable<int>(firstSeenAt.value);
    }
    if (lastUserAt.present) {
      map['last_user_at'] = Variable<int>(lastUserAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SenderStatsCompanion(')
          ..write('accountId: $accountId, ')
          ..write('keyKind: $keyKind, ')
          ..write('key: $key, ')
          ..write('folderPath: $folderPath, ')
          ..write('count: $count, ')
          ..write('weightedCount: $weightedCount, ')
          ..write('countAgainst: $countAgainst, ')
          ..write('firstSeenAt: $firstSeenAt, ')
          ..write('lastUserAt: $lastUserAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserRulesTable extends UserRules
    with TableInfo<$UserRulesTable, UserRule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserRulesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _matchJsonMeta = const VerificationMeta(
    'matchJson',
  );
  @override
  late final GeneratedColumn<String> matchJson = GeneratedColumn<String>(
    'match_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _folderPathMeta = const VerificationMeta(
    'folderPath',
  );
  @override
  late final GeneratedColumn<String> folderPath = GeneratedColumn<String>(
    'folder_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hitsMeta = const VerificationMeta('hits');
  @override
  late final GeneratedColumn<int> hits = GeneratedColumn<int>(
    'hits',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    priority,
    matchJson,
    action,
    folderPath,
    hits,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserRule> instance, {
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
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    } else if (isInserting) {
      context.missing(_priorityMeta);
    }
    if (data.containsKey('match_json')) {
      context.handle(
        _matchJsonMeta,
        matchJson.isAcceptableOrUnknown(data['match_json']!, _matchJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_matchJsonMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('folder_path')) {
      context.handle(
        _folderPathMeta,
        folderPath.isAcceptableOrUnknown(data['folder_path']!, _folderPathMeta),
      );
    }
    if (data.containsKey('hits')) {
      context.handle(
        _hitsMeta,
        hits.isAcceptableOrUnknown(data['hits']!, _hitsMeta),
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserRule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserRule(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      matchJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}match_json'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      folderPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_path'],
      ),
      hits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hits'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $UserRulesTable createAlias(String alias) {
    return $UserRulesTable(attachedDatabase, alias);
  }
}

class UserRule extends DataClass implements Insertable<UserRule> {
  final String id;
  final String accountId;
  final int priority;
  final String matchJson;

  /// moveTo | keepInInbox | neverAutoSort
  final String action;
  final String? folderPath;
  final int hits;
  final int createdAt;
  const UserRule({
    required this.id,
    required this.accountId,
    required this.priority,
    required this.matchJson,
    required this.action,
    this.folderPath,
    required this.hits,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    map['priority'] = Variable<int>(priority);
    map['match_json'] = Variable<String>(matchJson);
    map['action'] = Variable<String>(action);
    if (!nullToAbsent || folderPath != null) {
      map['folder_path'] = Variable<String>(folderPath);
    }
    map['hits'] = Variable<int>(hits);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  UserRulesCompanion toCompanion(bool nullToAbsent) {
    return UserRulesCompanion(
      id: Value(id),
      accountId: Value(accountId),
      priority: Value(priority),
      matchJson: Value(matchJson),
      action: Value(action),
      folderPath: folderPath == null && nullToAbsent
          ? const Value.absent()
          : Value(folderPath),
      hits: Value(hits),
      createdAt: Value(createdAt),
    );
  }

  factory UserRule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserRule(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      priority: serializer.fromJson<int>(json['priority']),
      matchJson: serializer.fromJson<String>(json['matchJson']),
      action: serializer.fromJson<String>(json['action']),
      folderPath: serializer.fromJson<String?>(json['folderPath']),
      hits: serializer.fromJson<int>(json['hits']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'priority': serializer.toJson<int>(priority),
      'matchJson': serializer.toJson<String>(matchJson),
      'action': serializer.toJson<String>(action),
      'folderPath': serializer.toJson<String?>(folderPath),
      'hits': serializer.toJson<int>(hits),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  UserRule copyWith({
    String? id,
    String? accountId,
    int? priority,
    String? matchJson,
    String? action,
    Value<String?> folderPath = const Value.absent(),
    int? hits,
    int? createdAt,
  }) => UserRule(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    priority: priority ?? this.priority,
    matchJson: matchJson ?? this.matchJson,
    action: action ?? this.action,
    folderPath: folderPath.present ? folderPath.value : this.folderPath,
    hits: hits ?? this.hits,
    createdAt: createdAt ?? this.createdAt,
  );
  UserRule copyWithCompanion(UserRulesCompanion data) {
    return UserRule(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      priority: data.priority.present ? data.priority.value : this.priority,
      matchJson: data.matchJson.present ? data.matchJson.value : this.matchJson,
      action: data.action.present ? data.action.value : this.action,
      folderPath: data.folderPath.present
          ? data.folderPath.value
          : this.folderPath,
      hits: data.hits.present ? data.hits.value : this.hits,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserRule(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('priority: $priority, ')
          ..write('matchJson: $matchJson, ')
          ..write('action: $action, ')
          ..write('folderPath: $folderPath, ')
          ..write('hits: $hits, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountId,
    priority,
    matchJson,
    action,
    folderPath,
    hits,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserRule &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.priority == this.priority &&
          other.matchJson == this.matchJson &&
          other.action == this.action &&
          other.folderPath == this.folderPath &&
          other.hits == this.hits &&
          other.createdAt == this.createdAt);
}

class UserRulesCompanion extends UpdateCompanion<UserRule> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<int> priority;
  final Value<String> matchJson;
  final Value<String> action;
  final Value<String?> folderPath;
  final Value<int> hits;
  final Value<int> createdAt;
  final Value<int> rowid;
  const UserRulesCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.priority = const Value.absent(),
    this.matchJson = const Value.absent(),
    this.action = const Value.absent(),
    this.folderPath = const Value.absent(),
    this.hits = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserRulesCompanion.insert({
    required String id,
    required String accountId,
    required int priority,
    required String matchJson,
    required String action,
    this.folderPath = const Value.absent(),
    this.hits = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accountId = Value(accountId),
       priority = Value(priority),
       matchJson = Value(matchJson),
       action = Value(action),
       createdAt = Value(createdAt);
  static Insertable<UserRule> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<int>? priority,
    Expression<String>? matchJson,
    Expression<String>? action,
    Expression<String>? folderPath,
    Expression<int>? hits,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (priority != null) 'priority': priority,
      if (matchJson != null) 'match_json': matchJson,
      if (action != null) 'action': action,
      if (folderPath != null) 'folder_path': folderPath,
      if (hits != null) 'hits': hits,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserRulesCompanion copyWith({
    Value<String>? id,
    Value<String>? accountId,
    Value<int>? priority,
    Value<String>? matchJson,
    Value<String>? action,
    Value<String?>? folderPath,
    Value<int>? hits,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return UserRulesCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      priority: priority ?? this.priority,
      matchJson: matchJson ?? this.matchJson,
      action: action ?? this.action,
      folderPath: folderPath ?? this.folderPath,
      hits: hits ?? this.hits,
      createdAt: createdAt ?? this.createdAt,
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
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (matchJson.present) {
      map['match_json'] = Variable<String>(matchJson.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (folderPath.present) {
      map['folder_path'] = Variable<String>(folderPath.value);
    }
    if (hits.present) {
      map['hits'] = Variable<int>(hits.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserRulesCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('priority: $priority, ')
          ..write('matchJson: $matchJson, ')
          ..write('action: $action, ')
          ..write('folderPath: $folderPath, ')
          ..write('hits: $hits, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SortQueueTable extends SortQueue
    with TableInfo<$SortQueueTable, SortQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SortQueueTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _messageIdHashMeta = const VerificationMeta(
    'messageIdHash',
  );
  @override
  late final GeneratedColumn<String> messageIdHash = GeneratedColumn<String>(
    'message_id_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<int> uid = GeneratedColumn<int>(
    'uid',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _enqueuedAtMeta = const VerificationMeta(
    'enqueuedAt',
  );
  @override
  late final GeneratedColumn<int> enqueuedAt = GeneratedColumn<int>(
    'enqueued_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<int> nextAttemptAt = GeneratedColumn<int>(
    'next_attempt_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    messageIdHash,
    uid,
    enqueuedAt,
    attempts,
    nextAttemptAt,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sort_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SortQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('message_id_hash')) {
      context.handle(
        _messageIdHashMeta,
        messageIdHash.isAcceptableOrUnknown(
          data['message_id_hash']!,
          _messageIdHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_messageIdHashMeta);
    }
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    }
    if (data.containsKey('enqueued_at')) {
      context.handle(
        _enqueuedAtMeta,
        enqueuedAt.isAcceptableOrUnknown(data['enqueued_at']!, _enqueuedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_enqueuedAtMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, messageIdHash};
  @override
  SortQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SortQueueData(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      messageIdHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id_hash'],
      )!,
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}uid'],
      ),
      enqueuedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}enqueued_at'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_attempt_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $SortQueueTable createAlias(String alias) {
    return $SortQueueTable(attachedDatabase, alias);
  }
}

class SortQueueData extends DataClass implements Insertable<SortQueueData> {
  final String accountId;
  final String messageIdHash;
  final int? uid;
  final int enqueuedAt;
  final int attempts;
  final int? nextAttemptAt;
  final String? lastError;
  const SortQueueData({
    required this.accountId,
    required this.messageIdHash,
    this.uid,
    required this.enqueuedAt,
    required this.attempts,
    this.nextAttemptAt,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['message_id_hash'] = Variable<String>(messageIdHash);
    if (!nullToAbsent || uid != null) {
      map['uid'] = Variable<int>(uid);
    }
    map['enqueued_at'] = Variable<int>(enqueuedAt);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<int>(nextAttemptAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  SortQueueCompanion toCompanion(bool nullToAbsent) {
    return SortQueueCompanion(
      accountId: Value(accountId),
      messageIdHash: Value(messageIdHash),
      uid: uid == null && nullToAbsent ? const Value.absent() : Value(uid),
      enqueuedAt: Value(enqueuedAt),
      attempts: Value(attempts),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory SortQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SortQueueData(
      accountId: serializer.fromJson<String>(json['accountId']),
      messageIdHash: serializer.fromJson<String>(json['messageIdHash']),
      uid: serializer.fromJson<int?>(json['uid']),
      enqueuedAt: serializer.fromJson<int>(json['enqueuedAt']),
      attempts: serializer.fromJson<int>(json['attempts']),
      nextAttemptAt: serializer.fromJson<int?>(json['nextAttemptAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'messageIdHash': serializer.toJson<String>(messageIdHash),
      'uid': serializer.toJson<int?>(uid),
      'enqueuedAt': serializer.toJson<int>(enqueuedAt),
      'attempts': serializer.toJson<int>(attempts),
      'nextAttemptAt': serializer.toJson<int?>(nextAttemptAt),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  SortQueueData copyWith({
    String? accountId,
    String? messageIdHash,
    Value<int?> uid = const Value.absent(),
    int? enqueuedAt,
    int? attempts,
    Value<int?> nextAttemptAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
  }) => SortQueueData(
    accountId: accountId ?? this.accountId,
    messageIdHash: messageIdHash ?? this.messageIdHash,
    uid: uid.present ? uid.value : this.uid,
    enqueuedAt: enqueuedAt ?? this.enqueuedAt,
    attempts: attempts ?? this.attempts,
    nextAttemptAt: nextAttemptAt.present
        ? nextAttemptAt.value
        : this.nextAttemptAt,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  SortQueueData copyWithCompanion(SortQueueCompanion data) {
    return SortQueueData(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      messageIdHash: data.messageIdHash.present
          ? data.messageIdHash.value
          : this.messageIdHash,
      uid: data.uid.present ? data.uid.value : this.uid,
      enqueuedAt: data.enqueuedAt.present
          ? data.enqueuedAt.value
          : this.enqueuedAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SortQueueData(')
          ..write('accountId: $accountId, ')
          ..write('messageIdHash: $messageIdHash, ')
          ..write('uid: $uid, ')
          ..write('enqueuedAt: $enqueuedAt, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    accountId,
    messageIdHash,
    uid,
    enqueuedAt,
    attempts,
    nextAttemptAt,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SortQueueData &&
          other.accountId == this.accountId &&
          other.messageIdHash == this.messageIdHash &&
          other.uid == this.uid &&
          other.enqueuedAt == this.enqueuedAt &&
          other.attempts == this.attempts &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.lastError == this.lastError);
}

class SortQueueCompanion extends UpdateCompanion<SortQueueData> {
  final Value<String> accountId;
  final Value<String> messageIdHash;
  final Value<int?> uid;
  final Value<int> enqueuedAt;
  final Value<int> attempts;
  final Value<int?> nextAttemptAt;
  final Value<String?> lastError;
  final Value<int> rowid;
  const SortQueueCompanion({
    this.accountId = const Value.absent(),
    this.messageIdHash = const Value.absent(),
    this.uid = const Value.absent(),
    this.enqueuedAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SortQueueCompanion.insert({
    required String accountId,
    required String messageIdHash,
    this.uid = const Value.absent(),
    required int enqueuedAt,
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       messageIdHash = Value(messageIdHash),
       enqueuedAt = Value(enqueuedAt);
  static Insertable<SortQueueData> custom({
    Expression<String>? accountId,
    Expression<String>? messageIdHash,
    Expression<int>? uid,
    Expression<int>? enqueuedAt,
    Expression<int>? attempts,
    Expression<int>? nextAttemptAt,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (messageIdHash != null) 'message_id_hash': messageIdHash,
      if (uid != null) 'uid': uid,
      if (enqueuedAt != null) 'enqueued_at': enqueuedAt,
      if (attempts != null) 'attempts': attempts,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SortQueueCompanion copyWith({
    Value<String>? accountId,
    Value<String>? messageIdHash,
    Value<int?>? uid,
    Value<int>? enqueuedAt,
    Value<int>? attempts,
    Value<int?>? nextAttemptAt,
    Value<String?>? lastError,
    Value<int>? rowid,
  }) {
    return SortQueueCompanion(
      accountId: accountId ?? this.accountId,
      messageIdHash: messageIdHash ?? this.messageIdHash,
      uid: uid ?? this.uid,
      enqueuedAt: enqueuedAt ?? this.enqueuedAt,
      attempts: attempts ?? this.attempts,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (messageIdHash.present) {
      map['message_id_hash'] = Variable<String>(messageIdHash.value);
    }
    if (uid.present) {
      map['uid'] = Variable<int>(uid.value);
    }
    if (enqueuedAt.present) {
      map['enqueued_at'] = Variable<int>(enqueuedAt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<int>(nextAttemptAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SortQueueCompanion(')
          ..write('accountId: $accountId, ')
          ..write('messageIdHash: $messageIdHash, ')
          ..write('uid: $uid, ')
          ..write('enqueuedAt: $enqueuedAt, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SortEvidenceTable extends SortEvidence
    with TableInfo<$SortEvidenceTable, SortEvidenceData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SortEvidenceTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageIdHashMeta = const VerificationMeta(
    'messageIdHash',
  );
  @override
  late final GeneratedColumn<String> messageIdHash = GeneratedColumn<String>(
    'message_id_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromAddrMeta = const VerificationMeta(
    'fromAddr',
  );
  @override
  late final GeneratedColumn<String> fromAddr = GeneratedColumn<String>(
    'from_addr',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fromDomainMeta = const VerificationMeta(
    'fromDomain',
  );
  @override
  late final GeneratedColumn<String> fromDomain = GeneratedColumn<String>(
    'from_domain',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _listIdMeta = const VerificationMeta('listId');
  @override
  late final GeneratedColumn<String> listId = GeneratedColumn<String>(
    'list_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subjectNormMeta = const VerificationMeta(
    'subjectNorm',
  );
  @override
  late final GeneratedColumn<String> subjectNorm = GeneratedColumn<String>(
    'subject_norm',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _examplesJsonMeta = const VerificationMeta(
    'examplesJson',
  );
  @override
  late final GeneratedColumn<String> examplesJson = GeneratedColumn<String>(
    'examples_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _folderMeta = const VerificationMeta('folder');
  @override
  late final GeneratedColumn<String> folder = GeneratedColumn<String>(
    'folder',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seenCountMeta = const VerificationMeta(
    'seenCount',
  );
  @override
  late final GeneratedColumn<int> seenCount = GeneratedColumn<int>(
    'seen_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _firstAtMeta = const VerificationMeta(
    'firstAt',
  );
  @override
  late final GeneratedColumn<int> firstAt = GeneratedColumn<int>(
    'first_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastAtMeta = const VerificationMeta('lastAt');
  @override
  late final GeneratedColumn<int> lastAt = GeneratedColumn<int>(
    'last_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<int> sentAt = GeneratedColumn<int>(
    'sent_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _consumedAtMeta = const VerificationMeta(
    'consumedAt',
  );
  @override
  late final GeneratedColumn<int> consumedAt = GeneratedColumn<int>(
    'consumed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    kind,
    messageIdHash,
    fromAddr,
    fromDomain,
    listId,
    subjectNorm,
    examplesJson,
    folder,
    seenCount,
    firstAt,
    lastAt,
    sentAt,
    consumedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sort_evidence';
  @override
  VerificationContext validateIntegrity(
    Insertable<SortEvidenceData> instance, {
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
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('message_id_hash')) {
      context.handle(
        _messageIdHashMeta,
        messageIdHash.isAcceptableOrUnknown(
          data['message_id_hash']!,
          _messageIdHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_messageIdHashMeta);
    }
    if (data.containsKey('from_addr')) {
      context.handle(
        _fromAddrMeta,
        fromAddr.isAcceptableOrUnknown(data['from_addr']!, _fromAddrMeta),
      );
    }
    if (data.containsKey('from_domain')) {
      context.handle(
        _fromDomainMeta,
        fromDomain.isAcceptableOrUnknown(data['from_domain']!, _fromDomainMeta),
      );
    }
    if (data.containsKey('list_id')) {
      context.handle(
        _listIdMeta,
        listId.isAcceptableOrUnknown(data['list_id']!, _listIdMeta),
      );
    }
    if (data.containsKey('subject_norm')) {
      context.handle(
        _subjectNormMeta,
        subjectNorm.isAcceptableOrUnknown(
          data['subject_norm']!,
          _subjectNormMeta,
        ),
      );
    }
    if (data.containsKey('examples_json')) {
      context.handle(
        _examplesJsonMeta,
        examplesJson.isAcceptableOrUnknown(
          data['examples_json']!,
          _examplesJsonMeta,
        ),
      );
    }
    if (data.containsKey('folder')) {
      context.handle(
        _folderMeta,
        folder.isAcceptableOrUnknown(data['folder']!, _folderMeta),
      );
    }
    if (data.containsKey('seen_count')) {
      context.handle(
        _seenCountMeta,
        seenCount.isAcceptableOrUnknown(data['seen_count']!, _seenCountMeta),
      );
    }
    if (data.containsKey('first_at')) {
      context.handle(
        _firstAtMeta,
        firstAt.isAcceptableOrUnknown(data['first_at']!, _firstAtMeta),
      );
    } else if (isInserting) {
      context.missing(_firstAtMeta);
    }
    if (data.containsKey('last_at')) {
      context.handle(
        _lastAtMeta,
        lastAt.isAcceptableOrUnknown(data['last_at']!, _lastAtMeta),
      );
    } else if (isInserting) {
      context.missing(_lastAtMeta);
    }
    if (data.containsKey('sent_at')) {
      context.handle(
        _sentAtMeta,
        sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta),
      );
    }
    if (data.containsKey('consumed_at')) {
      context.handle(
        _consumedAtMeta,
        consumedAt.isAcceptableOrUnknown(data['consumed_at']!, _consumedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SortEvidenceData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SortEvidenceData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      messageIdHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id_hash'],
      )!,
      fromAddr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_addr'],
      ),
      fromDomain: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_domain'],
      ),
      listId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}list_id'],
      ),
      subjectNorm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_norm'],
      ),
      examplesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}examples_json'],
      )!,
      folder: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder'],
      ),
      seenCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seen_count'],
      )!,
      firstAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}first_at'],
      )!,
      lastAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_at'],
      )!,
      sentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sent_at'],
      ),
      consumedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}consumed_at'],
      ),
    );
  }

  @override
  $SortEvidenceTable createAlias(String alias) {
    return $SortEvidenceTable(attachedDatabase, alias);
  }
}

class SortEvidenceData extends DataClass
    implements Insertable<SortEvidenceData> {
  final String id;
  final String accountId;

  /// unsorted | manualMove | undo
  final String kind;
  final String messageIdHash;
  final String? fromAddr;
  final String? fromDomain;
  final String? listId;
  final String? subjectNorm;

  /// Up to three distinct normalised subjects (JSON list).
  final String examplesJson;

  /// Destination for moves; null for unsorted.
  final String? folder;
  final int seenCount;
  final int firstAt;
  final int lastAt;

  /// Last time the row was shown to the model (null = new since then).
  final int? sentAt;

  /// Set when a suggestion built on it was accepted or dismissed.
  final int? consumedAt;
  const SortEvidenceData({
    required this.id,
    required this.accountId,
    required this.kind,
    required this.messageIdHash,
    this.fromAddr,
    this.fromDomain,
    this.listId,
    this.subjectNorm,
    required this.examplesJson,
    this.folder,
    required this.seenCount,
    required this.firstAt,
    required this.lastAt,
    this.sentAt,
    this.consumedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    map['kind'] = Variable<String>(kind);
    map['message_id_hash'] = Variable<String>(messageIdHash);
    if (!nullToAbsent || fromAddr != null) {
      map['from_addr'] = Variable<String>(fromAddr);
    }
    if (!nullToAbsent || fromDomain != null) {
      map['from_domain'] = Variable<String>(fromDomain);
    }
    if (!nullToAbsent || listId != null) {
      map['list_id'] = Variable<String>(listId);
    }
    if (!nullToAbsent || subjectNorm != null) {
      map['subject_norm'] = Variable<String>(subjectNorm);
    }
    map['examples_json'] = Variable<String>(examplesJson);
    if (!nullToAbsent || folder != null) {
      map['folder'] = Variable<String>(folder);
    }
    map['seen_count'] = Variable<int>(seenCount);
    map['first_at'] = Variable<int>(firstAt);
    map['last_at'] = Variable<int>(lastAt);
    if (!nullToAbsent || sentAt != null) {
      map['sent_at'] = Variable<int>(sentAt);
    }
    if (!nullToAbsent || consumedAt != null) {
      map['consumed_at'] = Variable<int>(consumedAt);
    }
    return map;
  }

  SortEvidenceCompanion toCompanion(bool nullToAbsent) {
    return SortEvidenceCompanion(
      id: Value(id),
      accountId: Value(accountId),
      kind: Value(kind),
      messageIdHash: Value(messageIdHash),
      fromAddr: fromAddr == null && nullToAbsent
          ? const Value.absent()
          : Value(fromAddr),
      fromDomain: fromDomain == null && nullToAbsent
          ? const Value.absent()
          : Value(fromDomain),
      listId: listId == null && nullToAbsent
          ? const Value.absent()
          : Value(listId),
      subjectNorm: subjectNorm == null && nullToAbsent
          ? const Value.absent()
          : Value(subjectNorm),
      examplesJson: Value(examplesJson),
      folder: folder == null && nullToAbsent
          ? const Value.absent()
          : Value(folder),
      seenCount: Value(seenCount),
      firstAt: Value(firstAt),
      lastAt: Value(lastAt),
      sentAt: sentAt == null && nullToAbsent
          ? const Value.absent()
          : Value(sentAt),
      consumedAt: consumedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(consumedAt),
    );
  }

  factory SortEvidenceData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SortEvidenceData(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      kind: serializer.fromJson<String>(json['kind']),
      messageIdHash: serializer.fromJson<String>(json['messageIdHash']),
      fromAddr: serializer.fromJson<String?>(json['fromAddr']),
      fromDomain: serializer.fromJson<String?>(json['fromDomain']),
      listId: serializer.fromJson<String?>(json['listId']),
      subjectNorm: serializer.fromJson<String?>(json['subjectNorm']),
      examplesJson: serializer.fromJson<String>(json['examplesJson']),
      folder: serializer.fromJson<String?>(json['folder']),
      seenCount: serializer.fromJson<int>(json['seenCount']),
      firstAt: serializer.fromJson<int>(json['firstAt']),
      lastAt: serializer.fromJson<int>(json['lastAt']),
      sentAt: serializer.fromJson<int?>(json['sentAt']),
      consumedAt: serializer.fromJson<int?>(json['consumedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'kind': serializer.toJson<String>(kind),
      'messageIdHash': serializer.toJson<String>(messageIdHash),
      'fromAddr': serializer.toJson<String?>(fromAddr),
      'fromDomain': serializer.toJson<String?>(fromDomain),
      'listId': serializer.toJson<String?>(listId),
      'subjectNorm': serializer.toJson<String?>(subjectNorm),
      'examplesJson': serializer.toJson<String>(examplesJson),
      'folder': serializer.toJson<String?>(folder),
      'seenCount': serializer.toJson<int>(seenCount),
      'firstAt': serializer.toJson<int>(firstAt),
      'lastAt': serializer.toJson<int>(lastAt),
      'sentAt': serializer.toJson<int?>(sentAt),
      'consumedAt': serializer.toJson<int?>(consumedAt),
    };
  }

  SortEvidenceData copyWith({
    String? id,
    String? accountId,
    String? kind,
    String? messageIdHash,
    Value<String?> fromAddr = const Value.absent(),
    Value<String?> fromDomain = const Value.absent(),
    Value<String?> listId = const Value.absent(),
    Value<String?> subjectNorm = const Value.absent(),
    String? examplesJson,
    Value<String?> folder = const Value.absent(),
    int? seenCount,
    int? firstAt,
    int? lastAt,
    Value<int?> sentAt = const Value.absent(),
    Value<int?> consumedAt = const Value.absent(),
  }) => SortEvidenceData(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    kind: kind ?? this.kind,
    messageIdHash: messageIdHash ?? this.messageIdHash,
    fromAddr: fromAddr.present ? fromAddr.value : this.fromAddr,
    fromDomain: fromDomain.present ? fromDomain.value : this.fromDomain,
    listId: listId.present ? listId.value : this.listId,
    subjectNorm: subjectNorm.present ? subjectNorm.value : this.subjectNorm,
    examplesJson: examplesJson ?? this.examplesJson,
    folder: folder.present ? folder.value : this.folder,
    seenCount: seenCount ?? this.seenCount,
    firstAt: firstAt ?? this.firstAt,
    lastAt: lastAt ?? this.lastAt,
    sentAt: sentAt.present ? sentAt.value : this.sentAt,
    consumedAt: consumedAt.present ? consumedAt.value : this.consumedAt,
  );
  SortEvidenceData copyWithCompanion(SortEvidenceCompanion data) {
    return SortEvidenceData(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      kind: data.kind.present ? data.kind.value : this.kind,
      messageIdHash: data.messageIdHash.present
          ? data.messageIdHash.value
          : this.messageIdHash,
      fromAddr: data.fromAddr.present ? data.fromAddr.value : this.fromAddr,
      fromDomain: data.fromDomain.present
          ? data.fromDomain.value
          : this.fromDomain,
      listId: data.listId.present ? data.listId.value : this.listId,
      subjectNorm: data.subjectNorm.present
          ? data.subjectNorm.value
          : this.subjectNorm,
      examplesJson: data.examplesJson.present
          ? data.examplesJson.value
          : this.examplesJson,
      folder: data.folder.present ? data.folder.value : this.folder,
      seenCount: data.seenCount.present ? data.seenCount.value : this.seenCount,
      firstAt: data.firstAt.present ? data.firstAt.value : this.firstAt,
      lastAt: data.lastAt.present ? data.lastAt.value : this.lastAt,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
      consumedAt: data.consumedAt.present
          ? data.consumedAt.value
          : this.consumedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SortEvidenceData(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('kind: $kind, ')
          ..write('messageIdHash: $messageIdHash, ')
          ..write('fromAddr: $fromAddr, ')
          ..write('fromDomain: $fromDomain, ')
          ..write('listId: $listId, ')
          ..write('subjectNorm: $subjectNorm, ')
          ..write('examplesJson: $examplesJson, ')
          ..write('folder: $folder, ')
          ..write('seenCount: $seenCount, ')
          ..write('firstAt: $firstAt, ')
          ..write('lastAt: $lastAt, ')
          ..write('sentAt: $sentAt, ')
          ..write('consumedAt: $consumedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountId,
    kind,
    messageIdHash,
    fromAddr,
    fromDomain,
    listId,
    subjectNorm,
    examplesJson,
    folder,
    seenCount,
    firstAt,
    lastAt,
    sentAt,
    consumedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SortEvidenceData &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.kind == this.kind &&
          other.messageIdHash == this.messageIdHash &&
          other.fromAddr == this.fromAddr &&
          other.fromDomain == this.fromDomain &&
          other.listId == this.listId &&
          other.subjectNorm == this.subjectNorm &&
          other.examplesJson == this.examplesJson &&
          other.folder == this.folder &&
          other.seenCount == this.seenCount &&
          other.firstAt == this.firstAt &&
          other.lastAt == this.lastAt &&
          other.sentAt == this.sentAt &&
          other.consumedAt == this.consumedAt);
}

class SortEvidenceCompanion extends UpdateCompanion<SortEvidenceData> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<String> kind;
  final Value<String> messageIdHash;
  final Value<String?> fromAddr;
  final Value<String?> fromDomain;
  final Value<String?> listId;
  final Value<String?> subjectNorm;
  final Value<String> examplesJson;
  final Value<String?> folder;
  final Value<int> seenCount;
  final Value<int> firstAt;
  final Value<int> lastAt;
  final Value<int?> sentAt;
  final Value<int?> consumedAt;
  final Value<int> rowid;
  const SortEvidenceCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.kind = const Value.absent(),
    this.messageIdHash = const Value.absent(),
    this.fromAddr = const Value.absent(),
    this.fromDomain = const Value.absent(),
    this.listId = const Value.absent(),
    this.subjectNorm = const Value.absent(),
    this.examplesJson = const Value.absent(),
    this.folder = const Value.absent(),
    this.seenCount = const Value.absent(),
    this.firstAt = const Value.absent(),
    this.lastAt = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.consumedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SortEvidenceCompanion.insert({
    required String id,
    required String accountId,
    required String kind,
    required String messageIdHash,
    this.fromAddr = const Value.absent(),
    this.fromDomain = const Value.absent(),
    this.listId = const Value.absent(),
    this.subjectNorm = const Value.absent(),
    this.examplesJson = const Value.absent(),
    this.folder = const Value.absent(),
    this.seenCount = const Value.absent(),
    required int firstAt,
    required int lastAt,
    this.sentAt = const Value.absent(),
    this.consumedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accountId = Value(accountId),
       kind = Value(kind),
       messageIdHash = Value(messageIdHash),
       firstAt = Value(firstAt),
       lastAt = Value(lastAt);
  static Insertable<SortEvidenceData> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<String>? kind,
    Expression<String>? messageIdHash,
    Expression<String>? fromAddr,
    Expression<String>? fromDomain,
    Expression<String>? listId,
    Expression<String>? subjectNorm,
    Expression<String>? examplesJson,
    Expression<String>? folder,
    Expression<int>? seenCount,
    Expression<int>? firstAt,
    Expression<int>? lastAt,
    Expression<int>? sentAt,
    Expression<int>? consumedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (kind != null) 'kind': kind,
      if (messageIdHash != null) 'message_id_hash': messageIdHash,
      if (fromAddr != null) 'from_addr': fromAddr,
      if (fromDomain != null) 'from_domain': fromDomain,
      if (listId != null) 'list_id': listId,
      if (subjectNorm != null) 'subject_norm': subjectNorm,
      if (examplesJson != null) 'examples_json': examplesJson,
      if (folder != null) 'folder': folder,
      if (seenCount != null) 'seen_count': seenCount,
      if (firstAt != null) 'first_at': firstAt,
      if (lastAt != null) 'last_at': lastAt,
      if (sentAt != null) 'sent_at': sentAt,
      if (consumedAt != null) 'consumed_at': consumedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SortEvidenceCompanion copyWith({
    Value<String>? id,
    Value<String>? accountId,
    Value<String>? kind,
    Value<String>? messageIdHash,
    Value<String?>? fromAddr,
    Value<String?>? fromDomain,
    Value<String?>? listId,
    Value<String?>? subjectNorm,
    Value<String>? examplesJson,
    Value<String?>? folder,
    Value<int>? seenCount,
    Value<int>? firstAt,
    Value<int>? lastAt,
    Value<int?>? sentAt,
    Value<int?>? consumedAt,
    Value<int>? rowid,
  }) {
    return SortEvidenceCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      kind: kind ?? this.kind,
      messageIdHash: messageIdHash ?? this.messageIdHash,
      fromAddr: fromAddr ?? this.fromAddr,
      fromDomain: fromDomain ?? this.fromDomain,
      listId: listId ?? this.listId,
      subjectNorm: subjectNorm ?? this.subjectNorm,
      examplesJson: examplesJson ?? this.examplesJson,
      folder: folder ?? this.folder,
      seenCount: seenCount ?? this.seenCount,
      firstAt: firstAt ?? this.firstAt,
      lastAt: lastAt ?? this.lastAt,
      sentAt: sentAt ?? this.sentAt,
      consumedAt: consumedAt ?? this.consumedAt,
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
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (messageIdHash.present) {
      map['message_id_hash'] = Variable<String>(messageIdHash.value);
    }
    if (fromAddr.present) {
      map['from_addr'] = Variable<String>(fromAddr.value);
    }
    if (fromDomain.present) {
      map['from_domain'] = Variable<String>(fromDomain.value);
    }
    if (listId.present) {
      map['list_id'] = Variable<String>(listId.value);
    }
    if (subjectNorm.present) {
      map['subject_norm'] = Variable<String>(subjectNorm.value);
    }
    if (examplesJson.present) {
      map['examples_json'] = Variable<String>(examplesJson.value);
    }
    if (folder.present) {
      map['folder'] = Variable<String>(folder.value);
    }
    if (seenCount.present) {
      map['seen_count'] = Variable<int>(seenCount.value);
    }
    if (firstAt.present) {
      map['first_at'] = Variable<int>(firstAt.value);
    }
    if (lastAt.present) {
      map['last_at'] = Variable<int>(lastAt.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<int>(sentAt.value);
    }
    if (consumedAt.present) {
      map['consumed_at'] = Variable<int>(consumedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SortEvidenceCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('kind: $kind, ')
          ..write('messageIdHash: $messageIdHash, ')
          ..write('fromAddr: $fromAddr, ')
          ..write('fromDomain: $fromDomain, ')
          ..write('listId: $listId, ')
          ..write('subjectNorm: $subjectNorm, ')
          ..write('examplesJson: $examplesJson, ')
          ..write('folder: $folder, ')
          ..write('seenCount: $seenCount, ')
          ..write('firstAt: $firstAt, ')
          ..write('lastAt: $lastAt, ')
          ..write('sentAt: $sentAt, ')
          ..write('consumedAt: $consumedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RuleSuggestionsTable extends RuleSuggestions
    with TableInfo<$RuleSuggestionsTable, RuleSuggestion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RuleSuggestionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _matchJsonMeta = const VerificationMeta(
    'matchJson',
  );
  @override
  late final GeneratedColumn<String> matchJson = GeneratedColumn<String>(
    'match_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _folderPathMeta = const VerificationMeta(
    'folderPath',
  );
  @override
  late final GeneratedColumn<String> folderPath = GeneratedColumn<String>(
    'folder_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rationaleMeta = const VerificationMeta(
    'rationale',
  );
  @override
  late final GeneratedColumn<String> rationale = GeneratedColumn<String>(
    'rationale',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _evidenceCountMeta = const VerificationMeta(
    'evidenceCount',
  );
  @override
  late final GeneratedColumn<int> evidenceCount = GeneratedColumn<int>(
    'evidence_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _examplesJsonMeta = const VerificationMeta(
    'examplesJson',
  );
  @override
  late final GeneratedColumn<String> examplesJson = GeneratedColumn<String>(
    'examples_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _decidedAtMeta = const VerificationMeta(
    'decidedAt',
  );
  @override
  late final GeneratedColumn<int> decidedAt = GeneratedColumn<int>(
    'decided_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    matchJson,
    folderPath,
    rationale,
    confidence,
    source,
    evidenceCount,
    examplesJson,
    status,
    createdAt,
    decidedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rule_suggestions';
  @override
  VerificationContext validateIntegrity(
    Insertable<RuleSuggestion> instance, {
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
    if (data.containsKey('match_json')) {
      context.handle(
        _matchJsonMeta,
        matchJson.isAcceptableOrUnknown(data['match_json']!, _matchJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_matchJsonMeta);
    }
    if (data.containsKey('folder_path')) {
      context.handle(
        _folderPathMeta,
        folderPath.isAcceptableOrUnknown(data['folder_path']!, _folderPathMeta),
      );
    } else if (isInserting) {
      context.missing(_folderPathMeta);
    }
    if (data.containsKey('rationale')) {
      context.handle(
        _rationaleMeta,
        rationale.isAcceptableOrUnknown(data['rationale']!, _rationaleMeta),
      );
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    } else if (isInserting) {
      context.missing(_confidenceMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('evidence_count')) {
      context.handle(
        _evidenceCountMeta,
        evidenceCount.isAcceptableOrUnknown(
          data['evidence_count']!,
          _evidenceCountMeta,
        ),
      );
    }
    if (data.containsKey('examples_json')) {
      context.handle(
        _examplesJsonMeta,
        examplesJson.isAcceptableOrUnknown(
          data['examples_json']!,
          _examplesJsonMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
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
    if (data.containsKey('decided_at')) {
      context.handle(
        _decidedAtMeta,
        decidedAt.isAcceptableOrUnknown(data['decided_at']!, _decidedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RuleSuggestion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RuleSuggestion(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      matchJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}match_json'],
      )!,
      folderPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_path'],
      )!,
      rationale: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rationale'],
      )!,
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      evidenceCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}evidence_count'],
      )!,
      examplesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}examples_json'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      decidedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}decided_at'],
      ),
    );
  }

  @override
  $RuleSuggestionsTable createAlias(String alias) {
    return $RuleSuggestionsTable(attachedDatabase, alias);
  }
}

class RuleSuggestion extends DataClass implements Insertable<RuleSuggestion> {
  final String id;
  final String accountId;
  final String matchJson;
  final String folderPath;
  final String rationale;
  final double confidence;

  /// pattern | model
  final String source;
  final int evidenceCount;
  final String examplesJson;

  /// pending | accepted | dismissed
  final String status;
  final int createdAt;
  final int? decidedAt;
  const RuleSuggestion({
    required this.id,
    required this.accountId,
    required this.matchJson,
    required this.folderPath,
    required this.rationale,
    required this.confidence,
    required this.source,
    required this.evidenceCount,
    required this.examplesJson,
    required this.status,
    required this.createdAt,
    this.decidedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    map['match_json'] = Variable<String>(matchJson);
    map['folder_path'] = Variable<String>(folderPath);
    map['rationale'] = Variable<String>(rationale);
    map['confidence'] = Variable<double>(confidence);
    map['source'] = Variable<String>(source);
    map['evidence_count'] = Variable<int>(evidenceCount);
    map['examples_json'] = Variable<String>(examplesJson);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || decidedAt != null) {
      map['decided_at'] = Variable<int>(decidedAt);
    }
    return map;
  }

  RuleSuggestionsCompanion toCompanion(bool nullToAbsent) {
    return RuleSuggestionsCompanion(
      id: Value(id),
      accountId: Value(accountId),
      matchJson: Value(matchJson),
      folderPath: Value(folderPath),
      rationale: Value(rationale),
      confidence: Value(confidence),
      source: Value(source),
      evidenceCount: Value(evidenceCount),
      examplesJson: Value(examplesJson),
      status: Value(status),
      createdAt: Value(createdAt),
      decidedAt: decidedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(decidedAt),
    );
  }

  factory RuleSuggestion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RuleSuggestion(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      matchJson: serializer.fromJson<String>(json['matchJson']),
      folderPath: serializer.fromJson<String>(json['folderPath']),
      rationale: serializer.fromJson<String>(json['rationale']),
      confidence: serializer.fromJson<double>(json['confidence']),
      source: serializer.fromJson<String>(json['source']),
      evidenceCount: serializer.fromJson<int>(json['evidenceCount']),
      examplesJson: serializer.fromJson<String>(json['examplesJson']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      decidedAt: serializer.fromJson<int?>(json['decidedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'matchJson': serializer.toJson<String>(matchJson),
      'folderPath': serializer.toJson<String>(folderPath),
      'rationale': serializer.toJson<String>(rationale),
      'confidence': serializer.toJson<double>(confidence),
      'source': serializer.toJson<String>(source),
      'evidenceCount': serializer.toJson<int>(evidenceCount),
      'examplesJson': serializer.toJson<String>(examplesJson),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<int>(createdAt),
      'decidedAt': serializer.toJson<int?>(decidedAt),
    };
  }

  RuleSuggestion copyWith({
    String? id,
    String? accountId,
    String? matchJson,
    String? folderPath,
    String? rationale,
    double? confidence,
    String? source,
    int? evidenceCount,
    String? examplesJson,
    String? status,
    int? createdAt,
    Value<int?> decidedAt = const Value.absent(),
  }) => RuleSuggestion(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    matchJson: matchJson ?? this.matchJson,
    folderPath: folderPath ?? this.folderPath,
    rationale: rationale ?? this.rationale,
    confidence: confidence ?? this.confidence,
    source: source ?? this.source,
    evidenceCount: evidenceCount ?? this.evidenceCount,
    examplesJson: examplesJson ?? this.examplesJson,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    decidedAt: decidedAt.present ? decidedAt.value : this.decidedAt,
  );
  RuleSuggestion copyWithCompanion(RuleSuggestionsCompanion data) {
    return RuleSuggestion(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      matchJson: data.matchJson.present ? data.matchJson.value : this.matchJson,
      folderPath: data.folderPath.present
          ? data.folderPath.value
          : this.folderPath,
      rationale: data.rationale.present ? data.rationale.value : this.rationale,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      source: data.source.present ? data.source.value : this.source,
      evidenceCount: data.evidenceCount.present
          ? data.evidenceCount.value
          : this.evidenceCount,
      examplesJson: data.examplesJson.present
          ? data.examplesJson.value
          : this.examplesJson,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      decidedAt: data.decidedAt.present ? data.decidedAt.value : this.decidedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RuleSuggestion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('matchJson: $matchJson, ')
          ..write('folderPath: $folderPath, ')
          ..write('rationale: $rationale, ')
          ..write('confidence: $confidence, ')
          ..write('source: $source, ')
          ..write('evidenceCount: $evidenceCount, ')
          ..write('examplesJson: $examplesJson, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('decidedAt: $decidedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountId,
    matchJson,
    folderPath,
    rationale,
    confidence,
    source,
    evidenceCount,
    examplesJson,
    status,
    createdAt,
    decidedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RuleSuggestion &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.matchJson == this.matchJson &&
          other.folderPath == this.folderPath &&
          other.rationale == this.rationale &&
          other.confidence == this.confidence &&
          other.source == this.source &&
          other.evidenceCount == this.evidenceCount &&
          other.examplesJson == this.examplesJson &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.decidedAt == this.decidedAt);
}

class RuleSuggestionsCompanion extends UpdateCompanion<RuleSuggestion> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<String> matchJson;
  final Value<String> folderPath;
  final Value<String> rationale;
  final Value<double> confidence;
  final Value<String> source;
  final Value<int> evidenceCount;
  final Value<String> examplesJson;
  final Value<String> status;
  final Value<int> createdAt;
  final Value<int?> decidedAt;
  final Value<int> rowid;
  const RuleSuggestionsCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.matchJson = const Value.absent(),
    this.folderPath = const Value.absent(),
    this.rationale = const Value.absent(),
    this.confidence = const Value.absent(),
    this.source = const Value.absent(),
    this.evidenceCount = const Value.absent(),
    this.examplesJson = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.decidedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RuleSuggestionsCompanion.insert({
    required String id,
    required String accountId,
    required String matchJson,
    required String folderPath,
    this.rationale = const Value.absent(),
    required double confidence,
    required String source,
    this.evidenceCount = const Value.absent(),
    this.examplesJson = const Value.absent(),
    this.status = const Value.absent(),
    required int createdAt,
    this.decidedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accountId = Value(accountId),
       matchJson = Value(matchJson),
       folderPath = Value(folderPath),
       confidence = Value(confidence),
       source = Value(source),
       createdAt = Value(createdAt);
  static Insertable<RuleSuggestion> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<String>? matchJson,
    Expression<String>? folderPath,
    Expression<String>? rationale,
    Expression<double>? confidence,
    Expression<String>? source,
    Expression<int>? evidenceCount,
    Expression<String>? examplesJson,
    Expression<String>? status,
    Expression<int>? createdAt,
    Expression<int>? decidedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (matchJson != null) 'match_json': matchJson,
      if (folderPath != null) 'folder_path': folderPath,
      if (rationale != null) 'rationale': rationale,
      if (confidence != null) 'confidence': confidence,
      if (source != null) 'source': source,
      if (evidenceCount != null) 'evidence_count': evidenceCount,
      if (examplesJson != null) 'examples_json': examplesJson,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (decidedAt != null) 'decided_at': decidedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RuleSuggestionsCompanion copyWith({
    Value<String>? id,
    Value<String>? accountId,
    Value<String>? matchJson,
    Value<String>? folderPath,
    Value<String>? rationale,
    Value<double>? confidence,
    Value<String>? source,
    Value<int>? evidenceCount,
    Value<String>? examplesJson,
    Value<String>? status,
    Value<int>? createdAt,
    Value<int?>? decidedAt,
    Value<int>? rowid,
  }) {
    return RuleSuggestionsCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      matchJson: matchJson ?? this.matchJson,
      folderPath: folderPath ?? this.folderPath,
      rationale: rationale ?? this.rationale,
      confidence: confidence ?? this.confidence,
      source: source ?? this.source,
      evidenceCount: evidenceCount ?? this.evidenceCount,
      examplesJson: examplesJson ?? this.examplesJson,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      decidedAt: decidedAt ?? this.decidedAt,
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
    if (matchJson.present) {
      map['match_json'] = Variable<String>(matchJson.value);
    }
    if (folderPath.present) {
      map['folder_path'] = Variable<String>(folderPath.value);
    }
    if (rationale.present) {
      map['rationale'] = Variable<String>(rationale.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (evidenceCount.present) {
      map['evidence_count'] = Variable<int>(evidenceCount.value);
    }
    if (examplesJson.present) {
      map['examples_json'] = Variable<String>(examplesJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (decidedAt.present) {
      map['decided_at'] = Variable<int>(decidedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RuleSuggestionsCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('matchJson: $matchJson, ')
          ..write('folderPath: $folderPath, ')
          ..write('rationale: $rationale, ')
          ..write('confidence: $confidence, ')
          ..write('source: $source, ')
          ..write('evidenceCount: $evidenceCount, ')
          ..write('examplesJson: $examplesJson, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('decidedAt: $decidedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AiUsageTable extends AiUsage with TableInfo<$AiUsageTable, AiUsageData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiUsageTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _tsMeta = const VerificationMeta('ts');
  @override
  late final GeneratedColumn<int> ts = GeneratedColumn<int>(
    'ts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerMeta = const VerificationMeta(
    'provider',
  );
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
    'provider',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelIdMeta = const VerificationMeta(
    'modelId',
  );
  @override
  late final GeneratedColumn<String> modelId = GeneratedColumn<String>(
    'model_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inputTokensMeta = const VerificationMeta(
    'inputTokens',
  );
  @override
  late final GeneratedColumn<int> inputTokens = GeneratedColumn<int>(
    'input_tokens',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cacheReadTokensMeta = const VerificationMeta(
    'cacheReadTokens',
  );
  @override
  late final GeneratedColumn<int> cacheReadTokens = GeneratedColumn<int>(
    'cache_read_tokens',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cacheWriteTokensMeta = const VerificationMeta(
    'cacheWriteTokens',
  );
  @override
  late final GeneratedColumn<int> cacheWriteTokens = GeneratedColumn<int>(
    'cache_write_tokens',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _outputTokensMeta = const VerificationMeta(
    'outputTokens',
  );
  @override
  late final GeneratedColumn<int> outputTokens = GeneratedColumn<int>(
    'output_tokens',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _costUsdMeta = const VerificationMeta(
    'costUsd',
  );
  @override
  late final GeneratedColumn<double> costUsd = GeneratedColumn<double>(
    'cost_usd',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _batchIdMeta = const VerificationMeta(
    'batchId',
  );
  @override
  late final GeneratedColumn<String> batchId = GeneratedColumn<String>(
    'batch_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ts,
    provider,
    modelId,
    kind,
    inputTokens,
    cacheReadTokens,
    cacheWriteTokens,
    outputTokens,
    costUsd,
    batchId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_usage';
  @override
  VerificationContext validateIntegrity(
    Insertable<AiUsageData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts']!, _tsMeta));
    } else if (isInserting) {
      context.missing(_tsMeta);
    }
    if (data.containsKey('provider')) {
      context.handle(
        _providerMeta,
        provider.isAcceptableOrUnknown(data['provider']!, _providerMeta),
      );
    }
    if (data.containsKey('model_id')) {
      context.handle(
        _modelIdMeta,
        modelId.isAcceptableOrUnknown(data['model_id']!, _modelIdMeta),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('input_tokens')) {
      context.handle(
        _inputTokensMeta,
        inputTokens.isAcceptableOrUnknown(
          data['input_tokens']!,
          _inputTokensMeta,
        ),
      );
    }
    if (data.containsKey('cache_read_tokens')) {
      context.handle(
        _cacheReadTokensMeta,
        cacheReadTokens.isAcceptableOrUnknown(
          data['cache_read_tokens']!,
          _cacheReadTokensMeta,
        ),
      );
    }
    if (data.containsKey('cache_write_tokens')) {
      context.handle(
        _cacheWriteTokensMeta,
        cacheWriteTokens.isAcceptableOrUnknown(
          data['cache_write_tokens']!,
          _cacheWriteTokensMeta,
        ),
      );
    }
    if (data.containsKey('output_tokens')) {
      context.handle(
        _outputTokensMeta,
        outputTokens.isAcceptableOrUnknown(
          data['output_tokens']!,
          _outputTokensMeta,
        ),
      );
    }
    if (data.containsKey('cost_usd')) {
      context.handle(
        _costUsdMeta,
        costUsd.isAcceptableOrUnknown(data['cost_usd']!, _costUsdMeta),
      );
    } else if (isInserting) {
      context.missing(_costUsdMeta);
    }
    if (data.containsKey('batch_id')) {
      context.handle(
        _batchIdMeta,
        batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AiUsageData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiUsageData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      ts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ts'],
      )!,
      provider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider'],
      ),
      modelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_id'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      inputTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}input_tokens'],
      )!,
      cacheReadTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cache_read_tokens'],
      )!,
      cacheWriteTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cache_write_tokens'],
      )!,
      outputTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}output_tokens'],
      )!,
      costUsd: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cost_usd'],
      )!,
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_id'],
      ),
    );
  }

  @override
  $AiUsageTable createAlias(String alias) {
    return $AiUsageTable(attachedDatabase, alias);
  }
}

class AiUsageData extends DataClass implements Insertable<AiUsageData> {
  final int id;
  final int ts;
  final String? provider;
  final String? modelId;

  /// sort | bootstrap | test | accuracy | batch
  final String kind;
  final int inputTokens;
  final int cacheReadTokens;
  final int cacheWriteTokens;
  final int outputTokens;
  final double costUsd;
  final String? batchId;
  const AiUsageData({
    required this.id,
    required this.ts,
    this.provider,
    this.modelId,
    required this.kind,
    required this.inputTokens,
    required this.cacheReadTokens,
    required this.cacheWriteTokens,
    required this.outputTokens,
    required this.costUsd,
    this.batchId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ts'] = Variable<int>(ts);
    if (!nullToAbsent || provider != null) {
      map['provider'] = Variable<String>(provider);
    }
    if (!nullToAbsent || modelId != null) {
      map['model_id'] = Variable<String>(modelId);
    }
    map['kind'] = Variable<String>(kind);
    map['input_tokens'] = Variable<int>(inputTokens);
    map['cache_read_tokens'] = Variable<int>(cacheReadTokens);
    map['cache_write_tokens'] = Variable<int>(cacheWriteTokens);
    map['output_tokens'] = Variable<int>(outputTokens);
    map['cost_usd'] = Variable<double>(costUsd);
    if (!nullToAbsent || batchId != null) {
      map['batch_id'] = Variable<String>(batchId);
    }
    return map;
  }

  AiUsageCompanion toCompanion(bool nullToAbsent) {
    return AiUsageCompanion(
      id: Value(id),
      ts: Value(ts),
      provider: provider == null && nullToAbsent
          ? const Value.absent()
          : Value(provider),
      modelId: modelId == null && nullToAbsent
          ? const Value.absent()
          : Value(modelId),
      kind: Value(kind),
      inputTokens: Value(inputTokens),
      cacheReadTokens: Value(cacheReadTokens),
      cacheWriteTokens: Value(cacheWriteTokens),
      outputTokens: Value(outputTokens),
      costUsd: Value(costUsd),
      batchId: batchId == null && nullToAbsent
          ? const Value.absent()
          : Value(batchId),
    );
  }

  factory AiUsageData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiUsageData(
      id: serializer.fromJson<int>(json['id']),
      ts: serializer.fromJson<int>(json['ts']),
      provider: serializer.fromJson<String?>(json['provider']),
      modelId: serializer.fromJson<String?>(json['modelId']),
      kind: serializer.fromJson<String>(json['kind']),
      inputTokens: serializer.fromJson<int>(json['inputTokens']),
      cacheReadTokens: serializer.fromJson<int>(json['cacheReadTokens']),
      cacheWriteTokens: serializer.fromJson<int>(json['cacheWriteTokens']),
      outputTokens: serializer.fromJson<int>(json['outputTokens']),
      costUsd: serializer.fromJson<double>(json['costUsd']),
      batchId: serializer.fromJson<String?>(json['batchId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ts': serializer.toJson<int>(ts),
      'provider': serializer.toJson<String?>(provider),
      'modelId': serializer.toJson<String?>(modelId),
      'kind': serializer.toJson<String>(kind),
      'inputTokens': serializer.toJson<int>(inputTokens),
      'cacheReadTokens': serializer.toJson<int>(cacheReadTokens),
      'cacheWriteTokens': serializer.toJson<int>(cacheWriteTokens),
      'outputTokens': serializer.toJson<int>(outputTokens),
      'costUsd': serializer.toJson<double>(costUsd),
      'batchId': serializer.toJson<String?>(batchId),
    };
  }

  AiUsageData copyWith({
    int? id,
    int? ts,
    Value<String?> provider = const Value.absent(),
    Value<String?> modelId = const Value.absent(),
    String? kind,
    int? inputTokens,
    int? cacheReadTokens,
    int? cacheWriteTokens,
    int? outputTokens,
    double? costUsd,
    Value<String?> batchId = const Value.absent(),
  }) => AiUsageData(
    id: id ?? this.id,
    ts: ts ?? this.ts,
    provider: provider.present ? provider.value : this.provider,
    modelId: modelId.present ? modelId.value : this.modelId,
    kind: kind ?? this.kind,
    inputTokens: inputTokens ?? this.inputTokens,
    cacheReadTokens: cacheReadTokens ?? this.cacheReadTokens,
    cacheWriteTokens: cacheWriteTokens ?? this.cacheWriteTokens,
    outputTokens: outputTokens ?? this.outputTokens,
    costUsd: costUsd ?? this.costUsd,
    batchId: batchId.present ? batchId.value : this.batchId,
  );
  AiUsageData copyWithCompanion(AiUsageCompanion data) {
    return AiUsageData(
      id: data.id.present ? data.id.value : this.id,
      ts: data.ts.present ? data.ts.value : this.ts,
      provider: data.provider.present ? data.provider.value : this.provider,
      modelId: data.modelId.present ? data.modelId.value : this.modelId,
      kind: data.kind.present ? data.kind.value : this.kind,
      inputTokens: data.inputTokens.present
          ? data.inputTokens.value
          : this.inputTokens,
      cacheReadTokens: data.cacheReadTokens.present
          ? data.cacheReadTokens.value
          : this.cacheReadTokens,
      cacheWriteTokens: data.cacheWriteTokens.present
          ? data.cacheWriteTokens.value
          : this.cacheWriteTokens,
      outputTokens: data.outputTokens.present
          ? data.outputTokens.value
          : this.outputTokens,
      costUsd: data.costUsd.present ? data.costUsd.value : this.costUsd,
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiUsageData(')
          ..write('id: $id, ')
          ..write('ts: $ts, ')
          ..write('provider: $provider, ')
          ..write('modelId: $modelId, ')
          ..write('kind: $kind, ')
          ..write('inputTokens: $inputTokens, ')
          ..write('cacheReadTokens: $cacheReadTokens, ')
          ..write('cacheWriteTokens: $cacheWriteTokens, ')
          ..write('outputTokens: $outputTokens, ')
          ..write('costUsd: $costUsd, ')
          ..write('batchId: $batchId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ts,
    provider,
    modelId,
    kind,
    inputTokens,
    cacheReadTokens,
    cacheWriteTokens,
    outputTokens,
    costUsd,
    batchId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiUsageData &&
          other.id == this.id &&
          other.ts == this.ts &&
          other.provider == this.provider &&
          other.modelId == this.modelId &&
          other.kind == this.kind &&
          other.inputTokens == this.inputTokens &&
          other.cacheReadTokens == this.cacheReadTokens &&
          other.cacheWriteTokens == this.cacheWriteTokens &&
          other.outputTokens == this.outputTokens &&
          other.costUsd == this.costUsd &&
          other.batchId == this.batchId);
}

class AiUsageCompanion extends UpdateCompanion<AiUsageData> {
  final Value<int> id;
  final Value<int> ts;
  final Value<String?> provider;
  final Value<String?> modelId;
  final Value<String> kind;
  final Value<int> inputTokens;
  final Value<int> cacheReadTokens;
  final Value<int> cacheWriteTokens;
  final Value<int> outputTokens;
  final Value<double> costUsd;
  final Value<String?> batchId;
  const AiUsageCompanion({
    this.id = const Value.absent(),
    this.ts = const Value.absent(),
    this.provider = const Value.absent(),
    this.modelId = const Value.absent(),
    this.kind = const Value.absent(),
    this.inputTokens = const Value.absent(),
    this.cacheReadTokens = const Value.absent(),
    this.cacheWriteTokens = const Value.absent(),
    this.outputTokens = const Value.absent(),
    this.costUsd = const Value.absent(),
    this.batchId = const Value.absent(),
  });
  AiUsageCompanion.insert({
    this.id = const Value.absent(),
    required int ts,
    this.provider = const Value.absent(),
    this.modelId = const Value.absent(),
    required String kind,
    this.inputTokens = const Value.absent(),
    this.cacheReadTokens = const Value.absent(),
    this.cacheWriteTokens = const Value.absent(),
    this.outputTokens = const Value.absent(),
    required double costUsd,
    this.batchId = const Value.absent(),
  }) : ts = Value(ts),
       kind = Value(kind),
       costUsd = Value(costUsd);
  static Insertable<AiUsageData> custom({
    Expression<int>? id,
    Expression<int>? ts,
    Expression<String>? provider,
    Expression<String>? modelId,
    Expression<String>? kind,
    Expression<int>? inputTokens,
    Expression<int>? cacheReadTokens,
    Expression<int>? cacheWriteTokens,
    Expression<int>? outputTokens,
    Expression<double>? costUsd,
    Expression<String>? batchId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ts != null) 'ts': ts,
      if (provider != null) 'provider': provider,
      if (modelId != null) 'model_id': modelId,
      if (kind != null) 'kind': kind,
      if (inputTokens != null) 'input_tokens': inputTokens,
      if (cacheReadTokens != null) 'cache_read_tokens': cacheReadTokens,
      if (cacheWriteTokens != null) 'cache_write_tokens': cacheWriteTokens,
      if (outputTokens != null) 'output_tokens': outputTokens,
      if (costUsd != null) 'cost_usd': costUsd,
      if (batchId != null) 'batch_id': batchId,
    });
  }

  AiUsageCompanion copyWith({
    Value<int>? id,
    Value<int>? ts,
    Value<String?>? provider,
    Value<String?>? modelId,
    Value<String>? kind,
    Value<int>? inputTokens,
    Value<int>? cacheReadTokens,
    Value<int>? cacheWriteTokens,
    Value<int>? outputTokens,
    Value<double>? costUsd,
    Value<String?>? batchId,
  }) {
    return AiUsageCompanion(
      id: id ?? this.id,
      ts: ts ?? this.ts,
      provider: provider ?? this.provider,
      modelId: modelId ?? this.modelId,
      kind: kind ?? this.kind,
      inputTokens: inputTokens ?? this.inputTokens,
      cacheReadTokens: cacheReadTokens ?? this.cacheReadTokens,
      cacheWriteTokens: cacheWriteTokens ?? this.cacheWriteTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      costUsd: costUsd ?? this.costUsd,
      batchId: batchId ?? this.batchId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ts.present) {
      map['ts'] = Variable<int>(ts.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (modelId.present) {
      map['model_id'] = Variable<String>(modelId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (inputTokens.present) {
      map['input_tokens'] = Variable<int>(inputTokens.value);
    }
    if (cacheReadTokens.present) {
      map['cache_read_tokens'] = Variable<int>(cacheReadTokens.value);
    }
    if (cacheWriteTokens.present) {
      map['cache_write_tokens'] = Variable<int>(cacheWriteTokens.value);
    }
    if (outputTokens.present) {
      map['output_tokens'] = Variable<int>(outputTokens.value);
    }
    if (costUsd.present) {
      map['cost_usd'] = Variable<double>(costUsd.value);
    }
    if (batchId.present) {
      map['batch_id'] = Variable<String>(batchId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiUsageCompanion(')
          ..write('id: $id, ')
          ..write('ts: $ts, ')
          ..write('provider: $provider, ')
          ..write('modelId: $modelId, ')
          ..write('kind: $kind, ')
          ..write('inputTokens: $inputTokens, ')
          ..write('cacheReadTokens: $cacheReadTokens, ')
          ..write('cacheWriteTokens: $cacheWriteTokens, ')
          ..write('outputTokens: $outputTokens, ')
          ..write('costUsd: $costUsd, ')
          ..write('batchId: $batchId')
          ..write(')'))
        .toString();
  }
}

class $JournalEventsTable extends JournalEvents
    with TableInfo<$JournalEventsTable, JournalEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JournalEventsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<int> uid = GeneratedColumn<int>(
    'uid',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _epochMeta = const VerificationMeta('epoch');
  @override
  late final GeneratedColumn<int> epoch = GeneratedColumn<int>(
    'epoch',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _internalDateMeta = const VerificationMeta(
    'internalDate',
  );
  @override
  late final GeneratedColumn<int> internalDate = GeneratedColumn<int>(
    'internal_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyJsonMeta = const VerificationMeta(
    'bodyJson',
  );
  @override
  late final GeneratedColumn<String> bodyJson = GeneratedColumn<String>(
    'body_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    uid,
    type,
    deviceId,
    epoch,
    internalDate,
    bodyJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journal_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<JournalEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('epoch')) {
      context.handle(
        _epochMeta,
        epoch.isAcceptableOrUnknown(data['epoch']!, _epochMeta),
      );
    }
    if (data.containsKey('internal_date')) {
      context.handle(
        _internalDateMeta,
        internalDate.isAcceptableOrUnknown(
          data['internal_date']!,
          _internalDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_internalDateMeta);
    }
    if (data.containsKey('body_json')) {
      context.handle(
        _bodyJsonMeta,
        bodyJson.isAcceptableOrUnknown(data['body_json']!, _bodyJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, uid};
  @override
  JournalEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JournalEvent(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}uid'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      epoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}epoch'],
      ),
      internalDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}internal_date'],
      )!,
      bodyJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body_json'],
      )!,
    );
  }

  @override
  $JournalEventsTable createAlias(String alias) {
    return $JournalEventsTable(attachedDatabase, alias);
  }
}

class JournalEvent extends DataClass implements Insertable<JournalEvent> {
  final String accountId;
  final int uid;
  final String type;
  final String deviceId;
  final int? epoch;
  final int internalDate;
  final String bodyJson;
  const JournalEvent({
    required this.accountId,
    required this.uid,
    required this.type,
    required this.deviceId,
    this.epoch,
    required this.internalDate,
    required this.bodyJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['uid'] = Variable<int>(uid);
    map['type'] = Variable<String>(type);
    map['device_id'] = Variable<String>(deviceId);
    if (!nullToAbsent || epoch != null) {
      map['epoch'] = Variable<int>(epoch);
    }
    map['internal_date'] = Variable<int>(internalDate);
    map['body_json'] = Variable<String>(bodyJson);
    return map;
  }

  JournalEventsCompanion toCompanion(bool nullToAbsent) {
    return JournalEventsCompanion(
      accountId: Value(accountId),
      uid: Value(uid),
      type: Value(type),
      deviceId: Value(deviceId),
      epoch: epoch == null && nullToAbsent
          ? const Value.absent()
          : Value(epoch),
      internalDate: Value(internalDate),
      bodyJson: Value(bodyJson),
    );
  }

  factory JournalEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JournalEvent(
      accountId: serializer.fromJson<String>(json['accountId']),
      uid: serializer.fromJson<int>(json['uid']),
      type: serializer.fromJson<String>(json['type']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      epoch: serializer.fromJson<int?>(json['epoch']),
      internalDate: serializer.fromJson<int>(json['internalDate']),
      bodyJson: serializer.fromJson<String>(json['bodyJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'uid': serializer.toJson<int>(uid),
      'type': serializer.toJson<String>(type),
      'deviceId': serializer.toJson<String>(deviceId),
      'epoch': serializer.toJson<int?>(epoch),
      'internalDate': serializer.toJson<int>(internalDate),
      'bodyJson': serializer.toJson<String>(bodyJson),
    };
  }

  JournalEvent copyWith({
    String? accountId,
    int? uid,
    String? type,
    String? deviceId,
    Value<int?> epoch = const Value.absent(),
    int? internalDate,
    String? bodyJson,
  }) => JournalEvent(
    accountId: accountId ?? this.accountId,
    uid: uid ?? this.uid,
    type: type ?? this.type,
    deviceId: deviceId ?? this.deviceId,
    epoch: epoch.present ? epoch.value : this.epoch,
    internalDate: internalDate ?? this.internalDate,
    bodyJson: bodyJson ?? this.bodyJson,
  );
  JournalEvent copyWithCompanion(JournalEventsCompanion data) {
    return JournalEvent(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      uid: data.uid.present ? data.uid.value : this.uid,
      type: data.type.present ? data.type.value : this.type,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      epoch: data.epoch.present ? data.epoch.value : this.epoch,
      internalDate: data.internalDate.present
          ? data.internalDate.value
          : this.internalDate,
      bodyJson: data.bodyJson.present ? data.bodyJson.value : this.bodyJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JournalEvent(')
          ..write('accountId: $accountId, ')
          ..write('uid: $uid, ')
          ..write('type: $type, ')
          ..write('deviceId: $deviceId, ')
          ..write('epoch: $epoch, ')
          ..write('internalDate: $internalDate, ')
          ..write('bodyJson: $bodyJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    accountId,
    uid,
    type,
    deviceId,
    epoch,
    internalDate,
    bodyJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JournalEvent &&
          other.accountId == this.accountId &&
          other.uid == this.uid &&
          other.type == this.type &&
          other.deviceId == this.deviceId &&
          other.epoch == this.epoch &&
          other.internalDate == this.internalDate &&
          other.bodyJson == this.bodyJson);
}

class JournalEventsCompanion extends UpdateCompanion<JournalEvent> {
  final Value<String> accountId;
  final Value<int> uid;
  final Value<String> type;
  final Value<String> deviceId;
  final Value<int?> epoch;
  final Value<int> internalDate;
  final Value<String> bodyJson;
  final Value<int> rowid;
  const JournalEventsCompanion({
    this.accountId = const Value.absent(),
    this.uid = const Value.absent(),
    this.type = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.epoch = const Value.absent(),
    this.internalDate = const Value.absent(),
    this.bodyJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JournalEventsCompanion.insert({
    required String accountId,
    required int uid,
    required String type,
    required String deviceId,
    this.epoch = const Value.absent(),
    required int internalDate,
    required String bodyJson,
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       uid = Value(uid),
       type = Value(type),
       deviceId = Value(deviceId),
       internalDate = Value(internalDate),
       bodyJson = Value(bodyJson);
  static Insertable<JournalEvent> custom({
    Expression<String>? accountId,
    Expression<int>? uid,
    Expression<String>? type,
    Expression<String>? deviceId,
    Expression<int>? epoch,
    Expression<int>? internalDate,
    Expression<String>? bodyJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (uid != null) 'uid': uid,
      if (type != null) 'type': type,
      if (deviceId != null) 'device_id': deviceId,
      if (epoch != null) 'epoch': epoch,
      if (internalDate != null) 'internal_date': internalDate,
      if (bodyJson != null) 'body_json': bodyJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JournalEventsCompanion copyWith({
    Value<String>? accountId,
    Value<int>? uid,
    Value<String>? type,
    Value<String>? deviceId,
    Value<int?>? epoch,
    Value<int>? internalDate,
    Value<String>? bodyJson,
    Value<int>? rowid,
  }) {
    return JournalEventsCompanion(
      accountId: accountId ?? this.accountId,
      uid: uid ?? this.uid,
      type: type ?? this.type,
      deviceId: deviceId ?? this.deviceId,
      epoch: epoch ?? this.epoch,
      internalDate: internalDate ?? this.internalDate,
      bodyJson: bodyJson ?? this.bodyJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (uid.present) {
      map['uid'] = Variable<int>(uid.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (epoch.present) {
      map['epoch'] = Variable<int>(epoch.value);
    }
    if (internalDate.present) {
      map['internal_date'] = Variable<int>(internalDate.value);
    }
    if (bodyJson.present) {
      map['body_json'] = Variable<String>(bodyJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JournalEventsCompanion(')
          ..write('accountId: $accountId, ')
          ..write('uid: $uid, ')
          ..write('type: $type, ')
          ..write('deviceId: $deviceId, ')
          ..write('epoch: $epoch, ')
          ..write('internalDate: $internalDate, ')
          ..write('bodyJson: $bodyJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JournalCursorsTable extends JournalCursors
    with TableInfo<$JournalCursorsTable, JournalCursor> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JournalCursorsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _uidValidityMeta = const VerificationMeta(
    'uidValidity',
  );
  @override
  late final GeneratedColumn<int> uidValidity = GeneratedColumn<int>(
    'uid_validity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _snapshotUidMeta = const VerificationMeta(
    'snapshotUid',
  );
  @override
  late final GeneratedColumn<int> snapshotUid = GeneratedColumn<int>(
    'snapshot_uid',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastAppliedUidMeta = const VerificationMeta(
    'lastAppliedUid',
  );
  @override
  late final GeneratedColumn<int> lastAppliedUid = GeneratedColumn<int>(
    'last_applied_uid',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastEpochMeta = const VerificationMeta(
    'lastEpoch',
  );
  @override
  late final GeneratedColumn<int> lastEpoch = GeneratedColumn<int>(
    'last_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _writerSeqMeta = const VerificationMeta(
    'writerSeq',
  );
  @override
  late final GeneratedColumn<int> writerSeq = GeneratedColumn<int>(
    'writer_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _controlPathMeta = const VerificationMeta(
    'controlPath',
  );
  @override
  late final GeneratedColumn<String> controlPath = GeneratedColumn<String>(
    'control_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    uidValidity,
    snapshotUid,
    lastAppliedUid,
    lastEpoch,
    writerSeq,
    controlPath,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journal_cursors';
  @override
  VerificationContext validateIntegrity(
    Insertable<JournalCursor> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('uid_validity')) {
      context.handle(
        _uidValidityMeta,
        uidValidity.isAcceptableOrUnknown(
          data['uid_validity']!,
          _uidValidityMeta,
        ),
      );
    }
    if (data.containsKey('snapshot_uid')) {
      context.handle(
        _snapshotUidMeta,
        snapshotUid.isAcceptableOrUnknown(
          data['snapshot_uid']!,
          _snapshotUidMeta,
        ),
      );
    }
    if (data.containsKey('last_applied_uid')) {
      context.handle(
        _lastAppliedUidMeta,
        lastAppliedUid.isAcceptableOrUnknown(
          data['last_applied_uid']!,
          _lastAppliedUidMeta,
        ),
      );
    }
    if (data.containsKey('last_epoch')) {
      context.handle(
        _lastEpochMeta,
        lastEpoch.isAcceptableOrUnknown(data['last_epoch']!, _lastEpochMeta),
      );
    }
    if (data.containsKey('writer_seq')) {
      context.handle(
        _writerSeqMeta,
        writerSeq.isAcceptableOrUnknown(data['writer_seq']!, _writerSeqMeta),
      );
    }
    if (data.containsKey('control_path')) {
      context.handle(
        _controlPathMeta,
        controlPath.isAcceptableOrUnknown(
          data['control_path']!,
          _controlPathMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId};
  @override
  JournalCursor map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JournalCursor(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      uidValidity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}uid_validity'],
      )!,
      snapshotUid: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}snapshot_uid'],
      )!,
      lastAppliedUid: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_applied_uid'],
      )!,
      lastEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_epoch'],
      )!,
      writerSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}writer_seq'],
      )!,
      controlPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}control_path'],
      ),
    );
  }

  @override
  $JournalCursorsTable createAlias(String alias) {
    return $JournalCursorsTable(attachedDatabase, alias);
  }
}

class JournalCursor extends DataClass implements Insertable<JournalCursor> {
  final String accountId;
  final int uidValidity;
  final int snapshotUid;
  final int lastAppliedUid;
  final int lastEpoch;
  final int writerSeq;
  final String? controlPath;
  const JournalCursor({
    required this.accountId,
    required this.uidValidity,
    required this.snapshotUid,
    required this.lastAppliedUid,
    required this.lastEpoch,
    required this.writerSeq,
    this.controlPath,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['uid_validity'] = Variable<int>(uidValidity);
    map['snapshot_uid'] = Variable<int>(snapshotUid);
    map['last_applied_uid'] = Variable<int>(lastAppliedUid);
    map['last_epoch'] = Variable<int>(lastEpoch);
    map['writer_seq'] = Variable<int>(writerSeq);
    if (!nullToAbsent || controlPath != null) {
      map['control_path'] = Variable<String>(controlPath);
    }
    return map;
  }

  JournalCursorsCompanion toCompanion(bool nullToAbsent) {
    return JournalCursorsCompanion(
      accountId: Value(accountId),
      uidValidity: Value(uidValidity),
      snapshotUid: Value(snapshotUid),
      lastAppliedUid: Value(lastAppliedUid),
      lastEpoch: Value(lastEpoch),
      writerSeq: Value(writerSeq),
      controlPath: controlPath == null && nullToAbsent
          ? const Value.absent()
          : Value(controlPath),
    );
  }

  factory JournalCursor.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JournalCursor(
      accountId: serializer.fromJson<String>(json['accountId']),
      uidValidity: serializer.fromJson<int>(json['uidValidity']),
      snapshotUid: serializer.fromJson<int>(json['snapshotUid']),
      lastAppliedUid: serializer.fromJson<int>(json['lastAppliedUid']),
      lastEpoch: serializer.fromJson<int>(json['lastEpoch']),
      writerSeq: serializer.fromJson<int>(json['writerSeq']),
      controlPath: serializer.fromJson<String?>(json['controlPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'uidValidity': serializer.toJson<int>(uidValidity),
      'snapshotUid': serializer.toJson<int>(snapshotUid),
      'lastAppliedUid': serializer.toJson<int>(lastAppliedUid),
      'lastEpoch': serializer.toJson<int>(lastEpoch),
      'writerSeq': serializer.toJson<int>(writerSeq),
      'controlPath': serializer.toJson<String?>(controlPath),
    };
  }

  JournalCursor copyWith({
    String? accountId,
    int? uidValidity,
    int? snapshotUid,
    int? lastAppliedUid,
    int? lastEpoch,
    int? writerSeq,
    Value<String?> controlPath = const Value.absent(),
  }) => JournalCursor(
    accountId: accountId ?? this.accountId,
    uidValidity: uidValidity ?? this.uidValidity,
    snapshotUid: snapshotUid ?? this.snapshotUid,
    lastAppliedUid: lastAppliedUid ?? this.lastAppliedUid,
    lastEpoch: lastEpoch ?? this.lastEpoch,
    writerSeq: writerSeq ?? this.writerSeq,
    controlPath: controlPath.present ? controlPath.value : this.controlPath,
  );
  JournalCursor copyWithCompanion(JournalCursorsCompanion data) {
    return JournalCursor(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      uidValidity: data.uidValidity.present
          ? data.uidValidity.value
          : this.uidValidity,
      snapshotUid: data.snapshotUid.present
          ? data.snapshotUid.value
          : this.snapshotUid,
      lastAppliedUid: data.lastAppliedUid.present
          ? data.lastAppliedUid.value
          : this.lastAppliedUid,
      lastEpoch: data.lastEpoch.present ? data.lastEpoch.value : this.lastEpoch,
      writerSeq: data.writerSeq.present ? data.writerSeq.value : this.writerSeq,
      controlPath: data.controlPath.present
          ? data.controlPath.value
          : this.controlPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JournalCursor(')
          ..write('accountId: $accountId, ')
          ..write('uidValidity: $uidValidity, ')
          ..write('snapshotUid: $snapshotUid, ')
          ..write('lastAppliedUid: $lastAppliedUid, ')
          ..write('lastEpoch: $lastEpoch, ')
          ..write('writerSeq: $writerSeq, ')
          ..write('controlPath: $controlPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    accountId,
    uidValidity,
    snapshotUid,
    lastAppliedUid,
    lastEpoch,
    writerSeq,
    controlPath,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JournalCursor &&
          other.accountId == this.accountId &&
          other.uidValidity == this.uidValidity &&
          other.snapshotUid == this.snapshotUid &&
          other.lastAppliedUid == this.lastAppliedUid &&
          other.lastEpoch == this.lastEpoch &&
          other.writerSeq == this.writerSeq &&
          other.controlPath == this.controlPath);
}

class JournalCursorsCompanion extends UpdateCompanion<JournalCursor> {
  final Value<String> accountId;
  final Value<int> uidValidity;
  final Value<int> snapshotUid;
  final Value<int> lastAppliedUid;
  final Value<int> lastEpoch;
  final Value<int> writerSeq;
  final Value<String?> controlPath;
  final Value<int> rowid;
  const JournalCursorsCompanion({
    this.accountId = const Value.absent(),
    this.uidValidity = const Value.absent(),
    this.snapshotUid = const Value.absent(),
    this.lastAppliedUid = const Value.absent(),
    this.lastEpoch = const Value.absent(),
    this.writerSeq = const Value.absent(),
    this.controlPath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JournalCursorsCompanion.insert({
    required String accountId,
    this.uidValidity = const Value.absent(),
    this.snapshotUid = const Value.absent(),
    this.lastAppliedUid = const Value.absent(),
    this.lastEpoch = const Value.absent(),
    this.writerSeq = const Value.absent(),
    this.controlPath = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId);
  static Insertable<JournalCursor> custom({
    Expression<String>? accountId,
    Expression<int>? uidValidity,
    Expression<int>? snapshotUid,
    Expression<int>? lastAppliedUid,
    Expression<int>? lastEpoch,
    Expression<int>? writerSeq,
    Expression<String>? controlPath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (uidValidity != null) 'uid_validity': uidValidity,
      if (snapshotUid != null) 'snapshot_uid': snapshotUid,
      if (lastAppliedUid != null) 'last_applied_uid': lastAppliedUid,
      if (lastEpoch != null) 'last_epoch': lastEpoch,
      if (writerSeq != null) 'writer_seq': writerSeq,
      if (controlPath != null) 'control_path': controlPath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JournalCursorsCompanion copyWith({
    Value<String>? accountId,
    Value<int>? uidValidity,
    Value<int>? snapshotUid,
    Value<int>? lastAppliedUid,
    Value<int>? lastEpoch,
    Value<int>? writerSeq,
    Value<String?>? controlPath,
    Value<int>? rowid,
  }) {
    return JournalCursorsCompanion(
      accountId: accountId ?? this.accountId,
      uidValidity: uidValidity ?? this.uidValidity,
      snapshotUid: snapshotUid ?? this.snapshotUid,
      lastAppliedUid: lastAppliedUid ?? this.lastAppliedUid,
      lastEpoch: lastEpoch ?? this.lastEpoch,
      writerSeq: writerSeq ?? this.writerSeq,
      controlPath: controlPath ?? this.controlPath,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (uidValidity.present) {
      map['uid_validity'] = Variable<int>(uidValidity.value);
    }
    if (snapshotUid.present) {
      map['snapshot_uid'] = Variable<int>(snapshotUid.value);
    }
    if (lastAppliedUid.present) {
      map['last_applied_uid'] = Variable<int>(lastAppliedUid.value);
    }
    if (lastEpoch.present) {
      map['last_epoch'] = Variable<int>(lastEpoch.value);
    }
    if (writerSeq.present) {
      map['writer_seq'] = Variable<int>(writerSeq.value);
    }
    if (controlPath.present) {
      map['control_path'] = Variable<String>(controlPath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JournalCursorsCompanion(')
          ..write('accountId: $accountId, ')
          ..write('uidValidity: $uidValidity, ')
          ..write('snapshotUid: $snapshotUid, ')
          ..write('lastAppliedUid: $lastAppliedUid, ')
          ..write('lastEpoch: $lastEpoch, ')
          ..write('writerSeq: $writerSeq, ')
          ..write('controlPath: $controlPath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CalendarsTable extends Calendars
    with TableInfo<$CalendarsTable, CalendarRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CalendarsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _readOnlyMeta = const VerificationMeta(
    'readOnly',
  );
  @override
  late final GeneratedColumn<bool> readOnly = GeneratedColumn<bool>(
    'read_only',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("read_only" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _authKindMeta = const VerificationMeta(
    'authKind',
  );
  @override
  late final GeneratedColumn<String> authKind = GeneratedColumn<String>(
    'auth_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _googleEmailMeta = const VerificationMeta(
    'googleEmail',
  );
  @override
  late final GeneratedColumn<String> googleEmail = GeneratedColumn<String>(
    'google_email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncTokenMeta = const VerificationMeta(
    'syncToken',
  );
  @override
  late final GeneratedColumn<String> syncToken = GeneratedColumn<String>(
    'sync_token',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ctagMeta = const VerificationMeta('ctag');
  @override
  late final GeneratedColumn<String> ctag = GeneratedColumn<String>(
    'ctag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
    'etag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncAtMeta = const VerificationMeta(
    'lastSyncAt',
  );
  @override
  late final GeneratedColumn<int> lastSyncAt = GeneratedColumn<int>(
    'last_sync_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    kind,
    url,
    username,
    color,
    enabled,
    readOnly,
    authKind,
    googleEmail,
    syncToken,
    ctag,
    etag,
    lastSyncAt,
    lastError,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calendars';
  @override
  VerificationContext validateIntegrity(
    Insertable<CalendarRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('read_only')) {
      context.handle(
        _readOnlyMeta,
        readOnly.isAcceptableOrUnknown(data['read_only']!, _readOnlyMeta),
      );
    }
    if (data.containsKey('auth_kind')) {
      context.handle(
        _authKindMeta,
        authKind.isAcceptableOrUnknown(data['auth_kind']!, _authKindMeta),
      );
    }
    if (data.containsKey('google_email')) {
      context.handle(
        _googleEmailMeta,
        googleEmail.isAcceptableOrUnknown(
          data['google_email']!,
          _googleEmailMeta,
        ),
      );
    }
    if (data.containsKey('sync_token')) {
      context.handle(
        _syncTokenMeta,
        syncToken.isAcceptableOrUnknown(data['sync_token']!, _syncTokenMeta),
      );
    }
    if (data.containsKey('ctag')) {
      context.handle(
        _ctagMeta,
        ctag.isAcceptableOrUnknown(data['ctag']!, _ctagMeta),
      );
    }
    if (data.containsKey('etag')) {
      context.handle(
        _etagMeta,
        etag.isAcceptableOrUnknown(data['etag']!, _etagMeta),
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
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CalendarRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CalendarRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      readOnly: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}read_only'],
      )!,
      authKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}auth_kind'],
      )!,
      googleEmail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}google_email'],
      ),
      syncToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_token'],
      ),
      ctag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ctag'],
      ),
      etag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etag'],
      ),
      lastSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_sync_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $CalendarsTable createAlias(String alias) {
    return $CalendarsTable(attachedDatabase, alias);
  }
}

class CalendarRow extends DataClass implements Insertable<CalendarRow> {
  final String id;
  final String name;

  /// caldav | ics | local
  final String kind;
  final String url;
  final String? username;
  final int color;
  final bool enabled;
  final bool readOnly;

  /// none | basic | googleOAuth
  final String authKind;
  final String? googleEmail;
  final String? syncToken;
  final String? ctag;
  final String? etag;
  final int? lastSyncAt;
  final String? lastError;
  final int sortOrder;
  const CalendarRow({
    required this.id,
    required this.name,
    required this.kind,
    required this.url,
    this.username,
    required this.color,
    required this.enabled,
    required this.readOnly,
    required this.authKind,
    this.googleEmail,
    this.syncToken,
    this.ctag,
    this.etag,
    this.lastSyncAt,
    this.lastError,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    map['url'] = Variable<String>(url);
    if (!nullToAbsent || username != null) {
      map['username'] = Variable<String>(username);
    }
    map['color'] = Variable<int>(color);
    map['enabled'] = Variable<bool>(enabled);
    map['read_only'] = Variable<bool>(readOnly);
    map['auth_kind'] = Variable<String>(authKind);
    if (!nullToAbsent || googleEmail != null) {
      map['google_email'] = Variable<String>(googleEmail);
    }
    if (!nullToAbsent || syncToken != null) {
      map['sync_token'] = Variable<String>(syncToken);
    }
    if (!nullToAbsent || ctag != null) {
      map['ctag'] = Variable<String>(ctag);
    }
    if (!nullToAbsent || etag != null) {
      map['etag'] = Variable<String>(etag);
    }
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<int>(lastSyncAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  CalendarsCompanion toCompanion(bool nullToAbsent) {
    return CalendarsCompanion(
      id: Value(id),
      name: Value(name),
      kind: Value(kind),
      url: Value(url),
      username: username == null && nullToAbsent
          ? const Value.absent()
          : Value(username),
      color: Value(color),
      enabled: Value(enabled),
      readOnly: Value(readOnly),
      authKind: Value(authKind),
      googleEmail: googleEmail == null && nullToAbsent
          ? const Value.absent()
          : Value(googleEmail),
      syncToken: syncToken == null && nullToAbsent
          ? const Value.absent()
          : Value(syncToken),
      ctag: ctag == null && nullToAbsent ? const Value.absent() : Value(ctag),
      etag: etag == null && nullToAbsent ? const Value.absent() : Value(etag),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      sortOrder: Value(sortOrder),
    );
  }

  factory CalendarRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CalendarRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      url: serializer.fromJson<String>(json['url']),
      username: serializer.fromJson<String?>(json['username']),
      color: serializer.fromJson<int>(json['color']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      readOnly: serializer.fromJson<bool>(json['readOnly']),
      authKind: serializer.fromJson<String>(json['authKind']),
      googleEmail: serializer.fromJson<String?>(json['googleEmail']),
      syncToken: serializer.fromJson<String?>(json['syncToken']),
      ctag: serializer.fromJson<String?>(json['ctag']),
      etag: serializer.fromJson<String?>(json['etag']),
      lastSyncAt: serializer.fromJson<int?>(json['lastSyncAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(kind),
      'url': serializer.toJson<String>(url),
      'username': serializer.toJson<String?>(username),
      'color': serializer.toJson<int>(color),
      'enabled': serializer.toJson<bool>(enabled),
      'readOnly': serializer.toJson<bool>(readOnly),
      'authKind': serializer.toJson<String>(authKind),
      'googleEmail': serializer.toJson<String?>(googleEmail),
      'syncToken': serializer.toJson<String?>(syncToken),
      'ctag': serializer.toJson<String?>(ctag),
      'etag': serializer.toJson<String?>(etag),
      'lastSyncAt': serializer.toJson<int?>(lastSyncAt),
      'lastError': serializer.toJson<String?>(lastError),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  CalendarRow copyWith({
    String? id,
    String? name,
    String? kind,
    String? url,
    Value<String?> username = const Value.absent(),
    int? color,
    bool? enabled,
    bool? readOnly,
    String? authKind,
    Value<String?> googleEmail = const Value.absent(),
    Value<String?> syncToken = const Value.absent(),
    Value<String?> ctag = const Value.absent(),
    Value<String?> etag = const Value.absent(),
    Value<int?> lastSyncAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    int? sortOrder,
  }) => CalendarRow(
    id: id ?? this.id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    url: url ?? this.url,
    username: username.present ? username.value : this.username,
    color: color ?? this.color,
    enabled: enabled ?? this.enabled,
    readOnly: readOnly ?? this.readOnly,
    authKind: authKind ?? this.authKind,
    googleEmail: googleEmail.present ? googleEmail.value : this.googleEmail,
    syncToken: syncToken.present ? syncToken.value : this.syncToken,
    ctag: ctag.present ? ctag.value : this.ctag,
    etag: etag.present ? etag.value : this.etag,
    lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
    lastError: lastError.present ? lastError.value : this.lastError,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  CalendarRow copyWithCompanion(CalendarsCompanion data) {
    return CalendarRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      url: data.url.present ? data.url.value : this.url,
      username: data.username.present ? data.username.value : this.username,
      color: data.color.present ? data.color.value : this.color,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      readOnly: data.readOnly.present ? data.readOnly.value : this.readOnly,
      authKind: data.authKind.present ? data.authKind.value : this.authKind,
      googleEmail: data.googleEmail.present
          ? data.googleEmail.value
          : this.googleEmail,
      syncToken: data.syncToken.present ? data.syncToken.value : this.syncToken,
      ctag: data.ctag.present ? data.ctag.value : this.ctag,
      etag: data.etag.present ? data.etag.value : this.etag,
      lastSyncAt: data.lastSyncAt.present
          ? data.lastSyncAt.value
          : this.lastSyncAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CalendarRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('url: $url, ')
          ..write('username: $username, ')
          ..write('color: $color, ')
          ..write('enabled: $enabled, ')
          ..write('readOnly: $readOnly, ')
          ..write('authKind: $authKind, ')
          ..write('googleEmail: $googleEmail, ')
          ..write('syncToken: $syncToken, ')
          ..write('ctag: $ctag, ')
          ..write('etag: $etag, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('lastError: $lastError, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    kind,
    url,
    username,
    color,
    enabled,
    readOnly,
    authKind,
    googleEmail,
    syncToken,
    ctag,
    etag,
    lastSyncAt,
    lastError,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CalendarRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.url == this.url &&
          other.username == this.username &&
          other.color == this.color &&
          other.enabled == this.enabled &&
          other.readOnly == this.readOnly &&
          other.authKind == this.authKind &&
          other.googleEmail == this.googleEmail &&
          other.syncToken == this.syncToken &&
          other.ctag == this.ctag &&
          other.etag == this.etag &&
          other.lastSyncAt == this.lastSyncAt &&
          other.lastError == this.lastError &&
          other.sortOrder == this.sortOrder);
}

class CalendarsCompanion extends UpdateCompanion<CalendarRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> kind;
  final Value<String> url;
  final Value<String?> username;
  final Value<int> color;
  final Value<bool> enabled;
  final Value<bool> readOnly;
  final Value<String> authKind;
  final Value<String?> googleEmail;
  final Value<String?> syncToken;
  final Value<String?> ctag;
  final Value<String?> etag;
  final Value<int?> lastSyncAt;
  final Value<String?> lastError;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const CalendarsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.url = const Value.absent(),
    this.username = const Value.absent(),
    this.color = const Value.absent(),
    this.enabled = const Value.absent(),
    this.readOnly = const Value.absent(),
    this.authKind = const Value.absent(),
    this.googleEmail = const Value.absent(),
    this.syncToken = const Value.absent(),
    this.ctag = const Value.absent(),
    this.etag = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CalendarsCompanion.insert({
    required String id,
    required String name,
    required String kind,
    this.url = const Value.absent(),
    this.username = const Value.absent(),
    required int color,
    this.enabled = const Value.absent(),
    this.readOnly = const Value.absent(),
    this.authKind = const Value.absent(),
    this.googleEmail = const Value.absent(),
    this.syncToken = const Value.absent(),
    this.ctag = const Value.absent(),
    this.etag = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       kind = Value(kind),
       color = Value(color);
  static Insertable<CalendarRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<String>? url,
    Expression<String>? username,
    Expression<int>? color,
    Expression<bool>? enabled,
    Expression<bool>? readOnly,
    Expression<String>? authKind,
    Expression<String>? googleEmail,
    Expression<String>? syncToken,
    Expression<String>? ctag,
    Expression<String>? etag,
    Expression<int>? lastSyncAt,
    Expression<String>? lastError,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (url != null) 'url': url,
      if (username != null) 'username': username,
      if (color != null) 'color': color,
      if (enabled != null) 'enabled': enabled,
      if (readOnly != null) 'read_only': readOnly,
      if (authKind != null) 'auth_kind': authKind,
      if (googleEmail != null) 'google_email': googleEmail,
      if (syncToken != null) 'sync_token': syncToken,
      if (ctag != null) 'ctag': ctag,
      if (etag != null) 'etag': etag,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (lastError != null) 'last_error': lastError,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CalendarsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? kind,
    Value<String>? url,
    Value<String?>? username,
    Value<int>? color,
    Value<bool>? enabled,
    Value<bool>? readOnly,
    Value<String>? authKind,
    Value<String?>? googleEmail,
    Value<String?>? syncToken,
    Value<String?>? ctag,
    Value<String?>? etag,
    Value<int?>? lastSyncAt,
    Value<String?>? lastError,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return CalendarsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      url: url ?? this.url,
      username: username ?? this.username,
      color: color ?? this.color,
      enabled: enabled ?? this.enabled,
      readOnly: readOnly ?? this.readOnly,
      authKind: authKind ?? this.authKind,
      googleEmail: googleEmail ?? this.googleEmail,
      syncToken: syncToken ?? this.syncToken,
      ctag: ctag ?? this.ctag,
      etag: etag ?? this.etag,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastError: lastError ?? this.lastError,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (readOnly.present) {
      map['read_only'] = Variable<bool>(readOnly.value);
    }
    if (authKind.present) {
      map['auth_kind'] = Variable<String>(authKind.value);
    }
    if (googleEmail.present) {
      map['google_email'] = Variable<String>(googleEmail.value);
    }
    if (syncToken.present) {
      map['sync_token'] = Variable<String>(syncToken.value);
    }
    if (ctag.present) {
      map['ctag'] = Variable<String>(ctag.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<int>(lastSyncAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalendarsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('url: $url, ')
          ..write('username: $username, ')
          ..write('color: $color, ')
          ..write('enabled: $enabled, ')
          ..write('readOnly: $readOnly, ')
          ..write('authKind: $authKind, ')
          ..write('googleEmail: $googleEmail, ')
          ..write('syncToken: $syncToken, ')
          ..write('ctag: $ctag, ')
          ..write('etag: $etag, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('lastError: $lastError, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CalendarEventsTable extends CalendarEvents
    with TableInfo<$CalendarEventsTable, CalendarEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CalendarEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _calendarIdMeta = const VerificationMeta(
    'calendarId',
  );
  @override
  late final GeneratedColumn<String> calendarId = GeneratedColumn<String>(
    'calendar_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES calendars (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hrefMeta = const VerificationMeta('href');
  @override
  late final GeneratedColumn<String> href = GeneratedColumn<String>(
    'href',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
    'etag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startAtMeta = const VerificationMeta(
    'startAt',
  );
  @override
  late final GeneratedColumn<int> startAt = GeneratedColumn<int>(
    'start_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endAtMeta = const VerificationMeta('endAt');
  @override
  late final GeneratedColumn<int> endAt = GeneratedColumn<int>(
    'end_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isAllDayMeta = const VerificationMeta(
    'isAllDay',
  );
  @override
  late final GeneratedColumn<bool> isAllDay = GeneratedColumn<bool>(
    'is_all_day',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_all_day" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _floatingMeta = const VerificationMeta(
    'floating',
  );
  @override
  late final GeneratedColumn<bool> floating = GeneratedColumn<bool>(
    'floating',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("floating" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _tzidMeta = const VerificationMeta('tzid');
  @override
  late final GeneratedColumn<String> tzid = GeneratedColumn<String>(
    'tzid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rruleMeta = const VerificationMeta('rrule');
  @override
  late final GeneratedColumn<String> rrule = GeneratedColumn<String>(
    'rrule',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _exdatesJsonMeta = const VerificationMeta(
    'exdatesJson',
  );
  @override
  late final GeneratedColumn<String> exdatesJson = GeneratedColumn<String>(
    'exdates_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _recurrenceIdMeta = const VerificationMeta(
    'recurrenceId',
  );
  @override
  late final GeneratedColumn<int> recurrenceId = GeneratedColumn<int>(
    'recurrence_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _organizerMeta = const VerificationMeta(
    'organizer',
  );
  @override
  late final GeneratedColumn<String> organizer = GeneratedColumn<String>(
    'organizer',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attendeesJsonMeta = const VerificationMeta(
    'attendeesJson',
  );
  @override
  late final GeneratedColumn<String> attendeesJson = GeneratedColumn<String>(
    'attendees_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _alarmsJsonMeta = const VerificationMeta(
    'alarmsJson',
  );
  @override
  late final GeneratedColumn<String> alarmsJson = GeneratedColumn<String>(
    'alarms_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _rawIcsMeta = const VerificationMeta('rawIcs');
  @override
  late final GeneratedColumn<String> rawIcs = GeneratedColumn<String>(
    'raw_ics',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _conflictedMeta = const VerificationMeta(
    'conflicted',
  );
  @override
  late final GeneratedColumn<bool> conflicted = GeneratedColumn<bool>(
    'conflicted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("conflicted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    calendarId,
    uid,
    href,
    etag,
    summary,
    description,
    location,
    startAt,
    endAt,
    isAllDay,
    floating,
    tzid,
    rrule,
    exdatesJson,
    recurrenceId,
    status,
    organizer,
    attendeesJson,
    alarmsJson,
    rawIcs,
    updatedAt,
    dirty,
    conflicted,
    deleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calendar_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<CalendarEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('calendar_id')) {
      context.handle(
        _calendarIdMeta,
        calendarId.isAcceptableOrUnknown(data['calendar_id']!, _calendarIdMeta),
      );
    } else if (isInserting) {
      context.missing(_calendarIdMeta);
    }
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('href')) {
      context.handle(
        _hrefMeta,
        href.isAcceptableOrUnknown(data['href']!, _hrefMeta),
      );
    }
    if (data.containsKey('etag')) {
      context.handle(
        _etagMeta,
        etag.isAcceptableOrUnknown(data['etag']!, _etagMeta),
      );
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
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
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
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
    if (data.containsKey('is_all_day')) {
      context.handle(
        _isAllDayMeta,
        isAllDay.isAcceptableOrUnknown(data['is_all_day']!, _isAllDayMeta),
      );
    }
    if (data.containsKey('floating')) {
      context.handle(
        _floatingMeta,
        floating.isAcceptableOrUnknown(data['floating']!, _floatingMeta),
      );
    }
    if (data.containsKey('tzid')) {
      context.handle(
        _tzidMeta,
        tzid.isAcceptableOrUnknown(data['tzid']!, _tzidMeta),
      );
    }
    if (data.containsKey('rrule')) {
      context.handle(
        _rruleMeta,
        rrule.isAcceptableOrUnknown(data['rrule']!, _rruleMeta),
      );
    }
    if (data.containsKey('exdates_json')) {
      context.handle(
        _exdatesJsonMeta,
        exdatesJson.isAcceptableOrUnknown(
          data['exdates_json']!,
          _exdatesJsonMeta,
        ),
      );
    }
    if (data.containsKey('recurrence_id')) {
      context.handle(
        _recurrenceIdMeta,
        recurrenceId.isAcceptableOrUnknown(
          data['recurrence_id']!,
          _recurrenceIdMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('organizer')) {
      context.handle(
        _organizerMeta,
        organizer.isAcceptableOrUnknown(data['organizer']!, _organizerMeta),
      );
    }
    if (data.containsKey('attendees_json')) {
      context.handle(
        _attendeesJsonMeta,
        attendeesJson.isAcceptableOrUnknown(
          data['attendees_json']!,
          _attendeesJsonMeta,
        ),
      );
    }
    if (data.containsKey('alarms_json')) {
      context.handle(
        _alarmsJsonMeta,
        alarmsJson.isAcceptableOrUnknown(data['alarms_json']!, _alarmsJsonMeta),
      );
    }
    if (data.containsKey('raw_ics')) {
      context.handle(
        _rawIcsMeta,
        rawIcs.isAcceptableOrUnknown(data['raw_ics']!, _rawIcsMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    }
    if (data.containsKey('conflicted')) {
      context.handle(
        _conflictedMeta,
        conflicted.isAcceptableOrUnknown(data['conflicted']!, _conflictedMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CalendarEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CalendarEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      calendarId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}calendar_id'],
      )!,
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      href: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}href'],
      ),
      etag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etag'],
      ),
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      startAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_at'],
      )!,
      endAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_at'],
      )!,
      isAllDay: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_all_day'],
      )!,
      floating: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}floating'],
      )!,
      tzid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tzid'],
      ),
      rrule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rrule'],
      ),
      exdatesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exdates_json'],
      )!,
      recurrenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recurrence_id'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      ),
      organizer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}organizer'],
      ),
      attendeesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attendees_json'],
      )!,
      alarmsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alarms_json'],
      )!,
      rawIcs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_ics'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dirty'],
      )!,
      conflicted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}conflicted'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
    );
  }

  @override
  $CalendarEventsTable createAlias(String alias) {
    return $CalendarEventsTable(attachedDatabase, alias);
  }
}

class CalendarEventRow extends DataClass
    implements Insertable<CalendarEventRow> {
  final String id;
  final String calendarId;
  final String uid;
  final String? href;
  final String? etag;
  final String summary;
  final String? description;
  final String? location;
  final int startAt;
  final int endAt;
  final bool isAllDay;
  final bool floating;
  final String? tzid;
  final String? rrule;
  final String exdatesJson;
  final int? recurrenceId;
  final String? status;
  final String? organizer;
  final String attendeesJson;
  final String alarmsJson;
  final String? rawIcs;
  final int updatedAt;
  final bool dirty;
  final bool conflicted;
  final bool deleted;
  const CalendarEventRow({
    required this.id,
    required this.calendarId,
    required this.uid,
    this.href,
    this.etag,
    required this.summary,
    this.description,
    this.location,
    required this.startAt,
    required this.endAt,
    required this.isAllDay,
    required this.floating,
    this.tzid,
    this.rrule,
    required this.exdatesJson,
    this.recurrenceId,
    this.status,
    this.organizer,
    required this.attendeesJson,
    required this.alarmsJson,
    this.rawIcs,
    required this.updatedAt,
    required this.dirty,
    required this.conflicted,
    required this.deleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['calendar_id'] = Variable<String>(calendarId);
    map['uid'] = Variable<String>(uid);
    if (!nullToAbsent || href != null) {
      map['href'] = Variable<String>(href);
    }
    if (!nullToAbsent || etag != null) {
      map['etag'] = Variable<String>(etag);
    }
    map['summary'] = Variable<String>(summary);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    map['start_at'] = Variable<int>(startAt);
    map['end_at'] = Variable<int>(endAt);
    map['is_all_day'] = Variable<bool>(isAllDay);
    map['floating'] = Variable<bool>(floating);
    if (!nullToAbsent || tzid != null) {
      map['tzid'] = Variable<String>(tzid);
    }
    if (!nullToAbsent || rrule != null) {
      map['rrule'] = Variable<String>(rrule);
    }
    map['exdates_json'] = Variable<String>(exdatesJson);
    if (!nullToAbsent || recurrenceId != null) {
      map['recurrence_id'] = Variable<int>(recurrenceId);
    }
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(status);
    }
    if (!nullToAbsent || organizer != null) {
      map['organizer'] = Variable<String>(organizer);
    }
    map['attendees_json'] = Variable<String>(attendeesJson);
    map['alarms_json'] = Variable<String>(alarmsJson);
    if (!nullToAbsent || rawIcs != null) {
      map['raw_ics'] = Variable<String>(rawIcs);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    map['dirty'] = Variable<bool>(dirty);
    map['conflicted'] = Variable<bool>(conflicted);
    map['deleted'] = Variable<bool>(deleted);
    return map;
  }

  CalendarEventsCompanion toCompanion(bool nullToAbsent) {
    return CalendarEventsCompanion(
      id: Value(id),
      calendarId: Value(calendarId),
      uid: Value(uid),
      href: href == null && nullToAbsent ? const Value.absent() : Value(href),
      etag: etag == null && nullToAbsent ? const Value.absent() : Value(etag),
      summary: Value(summary),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      startAt: Value(startAt),
      endAt: Value(endAt),
      isAllDay: Value(isAllDay),
      floating: Value(floating),
      tzid: tzid == null && nullToAbsent ? const Value.absent() : Value(tzid),
      rrule: rrule == null && nullToAbsent
          ? const Value.absent()
          : Value(rrule),
      exdatesJson: Value(exdatesJson),
      recurrenceId: recurrenceId == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceId),
      status: status == null && nullToAbsent
          ? const Value.absent()
          : Value(status),
      organizer: organizer == null && nullToAbsent
          ? const Value.absent()
          : Value(organizer),
      attendeesJson: Value(attendeesJson),
      alarmsJson: Value(alarmsJson),
      rawIcs: rawIcs == null && nullToAbsent
          ? const Value.absent()
          : Value(rawIcs),
      updatedAt: Value(updatedAt),
      dirty: Value(dirty),
      conflicted: Value(conflicted),
      deleted: Value(deleted),
    );
  }

  factory CalendarEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CalendarEventRow(
      id: serializer.fromJson<String>(json['id']),
      calendarId: serializer.fromJson<String>(json['calendarId']),
      uid: serializer.fromJson<String>(json['uid']),
      href: serializer.fromJson<String?>(json['href']),
      etag: serializer.fromJson<String?>(json['etag']),
      summary: serializer.fromJson<String>(json['summary']),
      description: serializer.fromJson<String?>(json['description']),
      location: serializer.fromJson<String?>(json['location']),
      startAt: serializer.fromJson<int>(json['startAt']),
      endAt: serializer.fromJson<int>(json['endAt']),
      isAllDay: serializer.fromJson<bool>(json['isAllDay']),
      floating: serializer.fromJson<bool>(json['floating']),
      tzid: serializer.fromJson<String?>(json['tzid']),
      rrule: serializer.fromJson<String?>(json['rrule']),
      exdatesJson: serializer.fromJson<String>(json['exdatesJson']),
      recurrenceId: serializer.fromJson<int?>(json['recurrenceId']),
      status: serializer.fromJson<String?>(json['status']),
      organizer: serializer.fromJson<String?>(json['organizer']),
      attendeesJson: serializer.fromJson<String>(json['attendeesJson']),
      alarmsJson: serializer.fromJson<String>(json['alarmsJson']),
      rawIcs: serializer.fromJson<String?>(json['rawIcs']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      dirty: serializer.fromJson<bool>(json['dirty']),
      conflicted: serializer.fromJson<bool>(json['conflicted']),
      deleted: serializer.fromJson<bool>(json['deleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'calendarId': serializer.toJson<String>(calendarId),
      'uid': serializer.toJson<String>(uid),
      'href': serializer.toJson<String?>(href),
      'etag': serializer.toJson<String?>(etag),
      'summary': serializer.toJson<String>(summary),
      'description': serializer.toJson<String?>(description),
      'location': serializer.toJson<String?>(location),
      'startAt': serializer.toJson<int>(startAt),
      'endAt': serializer.toJson<int>(endAt),
      'isAllDay': serializer.toJson<bool>(isAllDay),
      'floating': serializer.toJson<bool>(floating),
      'tzid': serializer.toJson<String?>(tzid),
      'rrule': serializer.toJson<String?>(rrule),
      'exdatesJson': serializer.toJson<String>(exdatesJson),
      'recurrenceId': serializer.toJson<int?>(recurrenceId),
      'status': serializer.toJson<String?>(status),
      'organizer': serializer.toJson<String?>(organizer),
      'attendeesJson': serializer.toJson<String>(attendeesJson),
      'alarmsJson': serializer.toJson<String>(alarmsJson),
      'rawIcs': serializer.toJson<String?>(rawIcs),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'dirty': serializer.toJson<bool>(dirty),
      'conflicted': serializer.toJson<bool>(conflicted),
      'deleted': serializer.toJson<bool>(deleted),
    };
  }

  CalendarEventRow copyWith({
    String? id,
    String? calendarId,
    String? uid,
    Value<String?> href = const Value.absent(),
    Value<String?> etag = const Value.absent(),
    String? summary,
    Value<String?> description = const Value.absent(),
    Value<String?> location = const Value.absent(),
    int? startAt,
    int? endAt,
    bool? isAllDay,
    bool? floating,
    Value<String?> tzid = const Value.absent(),
    Value<String?> rrule = const Value.absent(),
    String? exdatesJson,
    Value<int?> recurrenceId = const Value.absent(),
    Value<String?> status = const Value.absent(),
    Value<String?> organizer = const Value.absent(),
    String? attendeesJson,
    String? alarmsJson,
    Value<String?> rawIcs = const Value.absent(),
    int? updatedAt,
    bool? dirty,
    bool? conflicted,
    bool? deleted,
  }) => CalendarEventRow(
    id: id ?? this.id,
    calendarId: calendarId ?? this.calendarId,
    uid: uid ?? this.uid,
    href: href.present ? href.value : this.href,
    etag: etag.present ? etag.value : this.etag,
    summary: summary ?? this.summary,
    description: description.present ? description.value : this.description,
    location: location.present ? location.value : this.location,
    startAt: startAt ?? this.startAt,
    endAt: endAt ?? this.endAt,
    isAllDay: isAllDay ?? this.isAllDay,
    floating: floating ?? this.floating,
    tzid: tzid.present ? tzid.value : this.tzid,
    rrule: rrule.present ? rrule.value : this.rrule,
    exdatesJson: exdatesJson ?? this.exdatesJson,
    recurrenceId: recurrenceId.present ? recurrenceId.value : this.recurrenceId,
    status: status.present ? status.value : this.status,
    organizer: organizer.present ? organizer.value : this.organizer,
    attendeesJson: attendeesJson ?? this.attendeesJson,
    alarmsJson: alarmsJson ?? this.alarmsJson,
    rawIcs: rawIcs.present ? rawIcs.value : this.rawIcs,
    updatedAt: updatedAt ?? this.updatedAt,
    dirty: dirty ?? this.dirty,
    conflicted: conflicted ?? this.conflicted,
    deleted: deleted ?? this.deleted,
  );
  CalendarEventRow copyWithCompanion(CalendarEventsCompanion data) {
    return CalendarEventRow(
      id: data.id.present ? data.id.value : this.id,
      calendarId: data.calendarId.present
          ? data.calendarId.value
          : this.calendarId,
      uid: data.uid.present ? data.uid.value : this.uid,
      href: data.href.present ? data.href.value : this.href,
      etag: data.etag.present ? data.etag.value : this.etag,
      summary: data.summary.present ? data.summary.value : this.summary,
      description: data.description.present
          ? data.description.value
          : this.description,
      location: data.location.present ? data.location.value : this.location,
      startAt: data.startAt.present ? data.startAt.value : this.startAt,
      endAt: data.endAt.present ? data.endAt.value : this.endAt,
      isAllDay: data.isAllDay.present ? data.isAllDay.value : this.isAllDay,
      floating: data.floating.present ? data.floating.value : this.floating,
      tzid: data.tzid.present ? data.tzid.value : this.tzid,
      rrule: data.rrule.present ? data.rrule.value : this.rrule,
      exdatesJson: data.exdatesJson.present
          ? data.exdatesJson.value
          : this.exdatesJson,
      recurrenceId: data.recurrenceId.present
          ? data.recurrenceId.value
          : this.recurrenceId,
      status: data.status.present ? data.status.value : this.status,
      organizer: data.organizer.present ? data.organizer.value : this.organizer,
      attendeesJson: data.attendeesJson.present
          ? data.attendeesJson.value
          : this.attendeesJson,
      alarmsJson: data.alarmsJson.present
          ? data.alarmsJson.value
          : this.alarmsJson,
      rawIcs: data.rawIcs.present ? data.rawIcs.value : this.rawIcs,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
      conflicted: data.conflicted.present
          ? data.conflicted.value
          : this.conflicted,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CalendarEventRow(')
          ..write('id: $id, ')
          ..write('calendarId: $calendarId, ')
          ..write('uid: $uid, ')
          ..write('href: $href, ')
          ..write('etag: $etag, ')
          ..write('summary: $summary, ')
          ..write('description: $description, ')
          ..write('location: $location, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('isAllDay: $isAllDay, ')
          ..write('floating: $floating, ')
          ..write('tzid: $tzid, ')
          ..write('rrule: $rrule, ')
          ..write('exdatesJson: $exdatesJson, ')
          ..write('recurrenceId: $recurrenceId, ')
          ..write('status: $status, ')
          ..write('organizer: $organizer, ')
          ..write('attendeesJson: $attendeesJson, ')
          ..write('alarmsJson: $alarmsJson, ')
          ..write('rawIcs: $rawIcs, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('dirty: $dirty, ')
          ..write('conflicted: $conflicted, ')
          ..write('deleted: $deleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    calendarId,
    uid,
    href,
    etag,
    summary,
    description,
    location,
    startAt,
    endAt,
    isAllDay,
    floating,
    tzid,
    rrule,
    exdatesJson,
    recurrenceId,
    status,
    organizer,
    attendeesJson,
    alarmsJson,
    rawIcs,
    updatedAt,
    dirty,
    conflicted,
    deleted,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CalendarEventRow &&
          other.id == this.id &&
          other.calendarId == this.calendarId &&
          other.uid == this.uid &&
          other.href == this.href &&
          other.etag == this.etag &&
          other.summary == this.summary &&
          other.description == this.description &&
          other.location == this.location &&
          other.startAt == this.startAt &&
          other.endAt == this.endAt &&
          other.isAllDay == this.isAllDay &&
          other.floating == this.floating &&
          other.tzid == this.tzid &&
          other.rrule == this.rrule &&
          other.exdatesJson == this.exdatesJson &&
          other.recurrenceId == this.recurrenceId &&
          other.status == this.status &&
          other.organizer == this.organizer &&
          other.attendeesJson == this.attendeesJson &&
          other.alarmsJson == this.alarmsJson &&
          other.rawIcs == this.rawIcs &&
          other.updatedAt == this.updatedAt &&
          other.dirty == this.dirty &&
          other.conflicted == this.conflicted &&
          other.deleted == this.deleted);
}

class CalendarEventsCompanion extends UpdateCompanion<CalendarEventRow> {
  final Value<String> id;
  final Value<String> calendarId;
  final Value<String> uid;
  final Value<String?> href;
  final Value<String?> etag;
  final Value<String> summary;
  final Value<String?> description;
  final Value<String?> location;
  final Value<int> startAt;
  final Value<int> endAt;
  final Value<bool> isAllDay;
  final Value<bool> floating;
  final Value<String?> tzid;
  final Value<String?> rrule;
  final Value<String> exdatesJson;
  final Value<int?> recurrenceId;
  final Value<String?> status;
  final Value<String?> organizer;
  final Value<String> attendeesJson;
  final Value<String> alarmsJson;
  final Value<String?> rawIcs;
  final Value<int> updatedAt;
  final Value<bool> dirty;
  final Value<bool> conflicted;
  final Value<bool> deleted;
  final Value<int> rowid;
  const CalendarEventsCompanion({
    this.id = const Value.absent(),
    this.calendarId = const Value.absent(),
    this.uid = const Value.absent(),
    this.href = const Value.absent(),
    this.etag = const Value.absent(),
    this.summary = const Value.absent(),
    this.description = const Value.absent(),
    this.location = const Value.absent(),
    this.startAt = const Value.absent(),
    this.endAt = const Value.absent(),
    this.isAllDay = const Value.absent(),
    this.floating = const Value.absent(),
    this.tzid = const Value.absent(),
    this.rrule = const Value.absent(),
    this.exdatesJson = const Value.absent(),
    this.recurrenceId = const Value.absent(),
    this.status = const Value.absent(),
    this.organizer = const Value.absent(),
    this.attendeesJson = const Value.absent(),
    this.alarmsJson = const Value.absent(),
    this.rawIcs = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.conflicted = const Value.absent(),
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CalendarEventsCompanion.insert({
    required String id,
    required String calendarId,
    required String uid,
    this.href = const Value.absent(),
    this.etag = const Value.absent(),
    this.summary = const Value.absent(),
    this.description = const Value.absent(),
    this.location = const Value.absent(),
    required int startAt,
    required int endAt,
    this.isAllDay = const Value.absent(),
    this.floating = const Value.absent(),
    this.tzid = const Value.absent(),
    this.rrule = const Value.absent(),
    this.exdatesJson = const Value.absent(),
    this.recurrenceId = const Value.absent(),
    this.status = const Value.absent(),
    this.organizer = const Value.absent(),
    this.attendeesJson = const Value.absent(),
    this.alarmsJson = const Value.absent(),
    this.rawIcs = const Value.absent(),
    required int updatedAt,
    this.dirty = const Value.absent(),
    this.conflicted = const Value.absent(),
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       calendarId = Value(calendarId),
       uid = Value(uid),
       startAt = Value(startAt),
       endAt = Value(endAt),
       updatedAt = Value(updatedAt);
  static Insertable<CalendarEventRow> custom({
    Expression<String>? id,
    Expression<String>? calendarId,
    Expression<String>? uid,
    Expression<String>? href,
    Expression<String>? etag,
    Expression<String>? summary,
    Expression<String>? description,
    Expression<String>? location,
    Expression<int>? startAt,
    Expression<int>? endAt,
    Expression<bool>? isAllDay,
    Expression<bool>? floating,
    Expression<String>? tzid,
    Expression<String>? rrule,
    Expression<String>? exdatesJson,
    Expression<int>? recurrenceId,
    Expression<String>? status,
    Expression<String>? organizer,
    Expression<String>? attendeesJson,
    Expression<String>? alarmsJson,
    Expression<String>? rawIcs,
    Expression<int>? updatedAt,
    Expression<bool>? dirty,
    Expression<bool>? conflicted,
    Expression<bool>? deleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (calendarId != null) 'calendar_id': calendarId,
      if (uid != null) 'uid': uid,
      if (href != null) 'href': href,
      if (etag != null) 'etag': etag,
      if (summary != null) 'summary': summary,
      if (description != null) 'description': description,
      if (location != null) 'location': location,
      if (startAt != null) 'start_at': startAt,
      if (endAt != null) 'end_at': endAt,
      if (isAllDay != null) 'is_all_day': isAllDay,
      if (floating != null) 'floating': floating,
      if (tzid != null) 'tzid': tzid,
      if (rrule != null) 'rrule': rrule,
      if (exdatesJson != null) 'exdates_json': exdatesJson,
      if (recurrenceId != null) 'recurrence_id': recurrenceId,
      if (status != null) 'status': status,
      if (organizer != null) 'organizer': organizer,
      if (attendeesJson != null) 'attendees_json': attendeesJson,
      if (alarmsJson != null) 'alarms_json': alarmsJson,
      if (rawIcs != null) 'raw_ics': rawIcs,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (dirty != null) 'dirty': dirty,
      if (conflicted != null) 'conflicted': conflicted,
      if (deleted != null) 'deleted': deleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CalendarEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? calendarId,
    Value<String>? uid,
    Value<String?>? href,
    Value<String?>? etag,
    Value<String>? summary,
    Value<String?>? description,
    Value<String?>? location,
    Value<int>? startAt,
    Value<int>? endAt,
    Value<bool>? isAllDay,
    Value<bool>? floating,
    Value<String?>? tzid,
    Value<String?>? rrule,
    Value<String>? exdatesJson,
    Value<int?>? recurrenceId,
    Value<String?>? status,
    Value<String?>? organizer,
    Value<String>? attendeesJson,
    Value<String>? alarmsJson,
    Value<String?>? rawIcs,
    Value<int>? updatedAt,
    Value<bool>? dirty,
    Value<bool>? conflicted,
    Value<bool>? deleted,
    Value<int>? rowid,
  }) {
    return CalendarEventsCompanion(
      id: id ?? this.id,
      calendarId: calendarId ?? this.calendarId,
      uid: uid ?? this.uid,
      href: href ?? this.href,
      etag: etag ?? this.etag,
      summary: summary ?? this.summary,
      description: description ?? this.description,
      location: location ?? this.location,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      isAllDay: isAllDay ?? this.isAllDay,
      floating: floating ?? this.floating,
      tzid: tzid ?? this.tzid,
      rrule: rrule ?? this.rrule,
      exdatesJson: exdatesJson ?? this.exdatesJson,
      recurrenceId: recurrenceId ?? this.recurrenceId,
      status: status ?? this.status,
      organizer: organizer ?? this.organizer,
      attendeesJson: attendeesJson ?? this.attendeesJson,
      alarmsJson: alarmsJson ?? this.alarmsJson,
      rawIcs: rawIcs ?? this.rawIcs,
      updatedAt: updatedAt ?? this.updatedAt,
      dirty: dirty ?? this.dirty,
      conflicted: conflicted ?? this.conflicted,
      deleted: deleted ?? this.deleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (calendarId.present) {
      map['calendar_id'] = Variable<String>(calendarId.value);
    }
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (href.present) {
      map['href'] = Variable<String>(href.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (startAt.present) {
      map['start_at'] = Variable<int>(startAt.value);
    }
    if (endAt.present) {
      map['end_at'] = Variable<int>(endAt.value);
    }
    if (isAllDay.present) {
      map['is_all_day'] = Variable<bool>(isAllDay.value);
    }
    if (floating.present) {
      map['floating'] = Variable<bool>(floating.value);
    }
    if (tzid.present) {
      map['tzid'] = Variable<String>(tzid.value);
    }
    if (rrule.present) {
      map['rrule'] = Variable<String>(rrule.value);
    }
    if (exdatesJson.present) {
      map['exdates_json'] = Variable<String>(exdatesJson.value);
    }
    if (recurrenceId.present) {
      map['recurrence_id'] = Variable<int>(recurrenceId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (organizer.present) {
      map['organizer'] = Variable<String>(organizer.value);
    }
    if (attendeesJson.present) {
      map['attendees_json'] = Variable<String>(attendeesJson.value);
    }
    if (alarmsJson.present) {
      map['alarms_json'] = Variable<String>(alarmsJson.value);
    }
    if (rawIcs.present) {
      map['raw_ics'] = Variable<String>(rawIcs.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (conflicted.present) {
      map['conflicted'] = Variable<bool>(conflicted.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalendarEventsCompanion(')
          ..write('id: $id, ')
          ..write('calendarId: $calendarId, ')
          ..write('uid: $uid, ')
          ..write('href: $href, ')
          ..write('etag: $etag, ')
          ..write('summary: $summary, ')
          ..write('description: $description, ')
          ..write('location: $location, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('isAllDay: $isAllDay, ')
          ..write('floating: $floating, ')
          ..write('tzid: $tzid, ')
          ..write('rrule: $rrule, ')
          ..write('exdatesJson: $exdatesJson, ')
          ..write('recurrenceId: $recurrenceId, ')
          ..write('status: $status, ')
          ..write('organizer: $organizer, ')
          ..write('attendeesJson: $attendeesJson, ')
          ..write('alarmsJson: $alarmsJson, ')
          ..write('rawIcs: $rawIcs, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('dirty: $dirty, ')
          ..write('conflicted: $conflicted, ')
          ..write('deleted: $deleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CalendarSyncQueueTable extends CalendarSyncQueue
    with TableInfo<$CalendarSyncQueueTable, CalendarSyncQueueRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CalendarSyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _calendarIdMeta = const VerificationMeta(
    'calendarId',
  );
  @override
  late final GeneratedColumn<String> calendarId = GeneratedColumn<String>(
    'calendar_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES calendars (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hrefMeta = const VerificationMeta('href');
  @override
  late final GeneratedColumn<String> href = GeneratedColumn<String>(
    'href',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
    'etag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    calendarId,
    uid,
    kind,
    href,
    etag,
    createdAt,
    attempts,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calendar_sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<CalendarSyncQueueRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('calendar_id')) {
      context.handle(
        _calendarIdMeta,
        calendarId.isAcceptableOrUnknown(data['calendar_id']!, _calendarIdMeta),
      );
    } else if (isInserting) {
      context.missing(_calendarIdMeta);
    }
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('href')) {
      context.handle(
        _hrefMeta,
        href.isAcceptableOrUnknown(data['href']!, _hrefMeta),
      );
    }
    if (data.containsKey('etag')) {
      context.handle(
        _etagMeta,
        etag.isAcceptableOrUnknown(data['etag']!, _etagMeta),
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
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CalendarSyncQueueRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CalendarSyncQueueRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      calendarId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}calendar_id'],
      )!,
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      href: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}href'],
      ),
      etag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etag'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $CalendarSyncQueueTable createAlias(String alias) {
    return $CalendarSyncQueueTable(attachedDatabase, alias);
  }
}

class CalendarSyncQueueRow extends DataClass
    implements Insertable<CalendarSyncQueueRow> {
  final String id;
  final String calendarId;
  final String uid;

  /// create | update | delete
  final String kind;
  final String? href;
  final String? etag;
  final int createdAt;
  final int attempts;
  final String? lastError;
  const CalendarSyncQueueRow({
    required this.id,
    required this.calendarId,
    required this.uid,
    required this.kind,
    this.href,
    this.etag,
    required this.createdAt,
    required this.attempts,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['calendar_id'] = Variable<String>(calendarId);
    map['uid'] = Variable<String>(uid);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || href != null) {
      map['href'] = Variable<String>(href);
    }
    if (!nullToAbsent || etag != null) {
      map['etag'] = Variable<String>(etag);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  CalendarSyncQueueCompanion toCompanion(bool nullToAbsent) {
    return CalendarSyncQueueCompanion(
      id: Value(id),
      calendarId: Value(calendarId),
      uid: Value(uid),
      kind: Value(kind),
      href: href == null && nullToAbsent ? const Value.absent() : Value(href),
      etag: etag == null && nullToAbsent ? const Value.absent() : Value(etag),
      createdAt: Value(createdAt),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory CalendarSyncQueueRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CalendarSyncQueueRow(
      id: serializer.fromJson<String>(json['id']),
      calendarId: serializer.fromJson<String>(json['calendarId']),
      uid: serializer.fromJson<String>(json['uid']),
      kind: serializer.fromJson<String>(json['kind']),
      href: serializer.fromJson<String?>(json['href']),
      etag: serializer.fromJson<String?>(json['etag']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'calendarId': serializer.toJson<String>(calendarId),
      'uid': serializer.toJson<String>(uid),
      'kind': serializer.toJson<String>(kind),
      'href': serializer.toJson<String?>(href),
      'etag': serializer.toJson<String?>(etag),
      'createdAt': serializer.toJson<int>(createdAt),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  CalendarSyncQueueRow copyWith({
    String? id,
    String? calendarId,
    String? uid,
    String? kind,
    Value<String?> href = const Value.absent(),
    Value<String?> etag = const Value.absent(),
    int? createdAt,
    int? attempts,
    Value<String?> lastError = const Value.absent(),
  }) => CalendarSyncQueueRow(
    id: id ?? this.id,
    calendarId: calendarId ?? this.calendarId,
    uid: uid ?? this.uid,
    kind: kind ?? this.kind,
    href: href.present ? href.value : this.href,
    etag: etag.present ? etag.value : this.etag,
    createdAt: createdAt ?? this.createdAt,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  CalendarSyncQueueRow copyWithCompanion(CalendarSyncQueueCompanion data) {
    return CalendarSyncQueueRow(
      id: data.id.present ? data.id.value : this.id,
      calendarId: data.calendarId.present
          ? data.calendarId.value
          : this.calendarId,
      uid: data.uid.present ? data.uid.value : this.uid,
      kind: data.kind.present ? data.kind.value : this.kind,
      href: data.href.present ? data.href.value : this.href,
      etag: data.etag.present ? data.etag.value : this.etag,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CalendarSyncQueueRow(')
          ..write('id: $id, ')
          ..write('calendarId: $calendarId, ')
          ..write('uid: $uid, ')
          ..write('kind: $kind, ')
          ..write('href: $href, ')
          ..write('etag: $etag, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    calendarId,
    uid,
    kind,
    href,
    etag,
    createdAt,
    attempts,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CalendarSyncQueueRow &&
          other.id == this.id &&
          other.calendarId == this.calendarId &&
          other.uid == this.uid &&
          other.kind == this.kind &&
          other.href == this.href &&
          other.etag == this.etag &&
          other.createdAt == this.createdAt &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError);
}

class CalendarSyncQueueCompanion extends UpdateCompanion<CalendarSyncQueueRow> {
  final Value<String> id;
  final Value<String> calendarId;
  final Value<String> uid;
  final Value<String> kind;
  final Value<String?> href;
  final Value<String?> etag;
  final Value<int> createdAt;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<int> rowid;
  const CalendarSyncQueueCompanion({
    this.id = const Value.absent(),
    this.calendarId = const Value.absent(),
    this.uid = const Value.absent(),
    this.kind = const Value.absent(),
    this.href = const Value.absent(),
    this.etag = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CalendarSyncQueueCompanion.insert({
    required String id,
    required String calendarId,
    required String uid,
    required String kind,
    this.href = const Value.absent(),
    this.etag = const Value.absent(),
    required int createdAt,
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       calendarId = Value(calendarId),
       uid = Value(uid),
       kind = Value(kind),
       createdAt = Value(createdAt);
  static Insertable<CalendarSyncQueueRow> custom({
    Expression<String>? id,
    Expression<String>? calendarId,
    Expression<String>? uid,
    Expression<String>? kind,
    Expression<String>? href,
    Expression<String>? etag,
    Expression<int>? createdAt,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (calendarId != null) 'calendar_id': calendarId,
      if (uid != null) 'uid': uid,
      if (kind != null) 'kind': kind,
      if (href != null) 'href': href,
      if (etag != null) 'etag': etag,
      if (createdAt != null) 'created_at': createdAt,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CalendarSyncQueueCompanion copyWith({
    Value<String>? id,
    Value<String>? calendarId,
    Value<String>? uid,
    Value<String>? kind,
    Value<String?>? href,
    Value<String?>? etag,
    Value<int>? createdAt,
    Value<int>? attempts,
    Value<String?>? lastError,
    Value<int>? rowid,
  }) {
    return CalendarSyncQueueCompanion(
      id: id ?? this.id,
      calendarId: calendarId ?? this.calendarId,
      uid: uid ?? this.uid,
      kind: kind ?? this.kind,
      href: href ?? this.href,
      etag: etag ?? this.etag,
      createdAt: createdAt ?? this.createdAt,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (calendarId.present) {
      map['calendar_id'] = Variable<String>(calendarId.value);
    }
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (href.present) {
      map['href'] = Variable<String>(href.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalendarSyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('calendarId: $calendarId, ')
          ..write('uid: $uid, ')
          ..write('kind: $kind, ')
          ..write('href: $href, ')
          ..write('etag: $etag, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$SortieDatabase extends GeneratedDatabase {
  _$SortieDatabase(QueryExecutor e) : super(e);
  $SortieDatabaseManager get managers => $SortieDatabaseManager(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $IdentitiesTable identities = $IdentitiesTable(this);
  late final $FoldersTable folders = $FoldersTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $MessageBodiesTable messageBodies = $MessageBodiesTable(this);
  late final $PendingOpsTable pendingOps = $PendingOpsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $SortDecisionsTable sortDecisions = $SortDecisionsTable(this);
  late final $CorrectionsTable corrections = $CorrectionsTable(this);
  late final $FolderProfilesTable folderProfiles = $FolderProfilesTable(this);
  late final $FolderProfileHistoryTable folderProfileHistory =
      $FolderProfileHistoryTable(this);
  late final $SenderStatsTable senderStats = $SenderStatsTable(this);
  late final $UserRulesTable userRules = $UserRulesTable(this);
  late final $SortQueueTable sortQueue = $SortQueueTable(this);
  late final $SortEvidenceTable sortEvidence = $SortEvidenceTable(this);
  late final $RuleSuggestionsTable ruleSuggestions = $RuleSuggestionsTable(
    this,
  );
  late final $AiUsageTable aiUsage = $AiUsageTable(this);
  late final $JournalEventsTable journalEvents = $JournalEventsTable(this);
  late final $JournalCursorsTable journalCursors = $JournalCursorsTable(this);
  late final $CalendarsTable calendars = $CalendarsTable(this);
  late final $CalendarEventsTable calendarEvents = $CalendarEventsTable(this);
  late final $CalendarSyncQueueTable calendarSyncQueue =
      $CalendarSyncQueueTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    accounts,
    identities,
    folders,
    messages,
    messageBodies,
    pendingOps,
    settings,
    sortDecisions,
    corrections,
    folderProfiles,
    folderProfileHistory,
    senderStats,
    userRules,
    sortQueue,
    sortEvidence,
    ruleSuggestions,
    aiUsage,
    journalEvents,
    journalCursors,
    calendars,
    calendarEvents,
    calendarSyncQueue,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'accounts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('identities', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'accounts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('folders', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'calendars',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('calendar_events', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'calendars',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('calendar_sync_queue', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$AccountsTableCreateCompanionBuilder = AccountsCompanion Function({
  required String id,
  required String displayName,
  required String email,
  required String username,
  required String imapHost,
  required int imapPort,
  required String imapSecurity,
  required String smtpHost,
  required int smtpPort,
  required String smtpSecurity,
  Value<String?> smtpUsername,
  Value<String> auth,
  Value<bool> enabled,
  Value<int> rowid,
});
typedef $$AccountsTableUpdateCompanionBuilder = AccountsCompanion Function({
  Value<String> id,
  Value<String> displayName,
  Value<String> email,
  Value<String> username,
  Value<String> imapHost,
  Value<int> imapPort,
  Value<String> imapSecurity,
  Value<String> smtpHost,
  Value<int> smtpPort,
  Value<String> smtpSecurity,
  Value<String?> smtpUsername,
  Value<String> auth,
  Value<bool> enabled,
  Value<int> rowid,
});

final class $$AccountsTableReferences
    extends BaseReferences<_$SortieDatabase, $AccountsTable, Account> {
  $$AccountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$IdentitiesTable, List<Identity>>
  _identitiesRefsTable(_$SortieDatabase db) => MultiTypedResultKey.fromTable(
    db.identities,
    aliasName: 'accounts__id__identities__account_id',
  );

  $$IdentitiesTableProcessedTableManager get identitiesRefs {
    final manager = $$IdentitiesTableTableManager(
      $_db,
      $_db.identities,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_identitiesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FoldersTable, List<Folder>> _foldersRefsTable(
    _$SortieDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.folders,
    aliasName: 'accounts__id__folders__account_id',
  );

  $$FoldersTableProcessedTableManager get foldersRefs {
    final manager = $$FoldersTableTableManager(
      $_db,
      $_db.folders,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_foldersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AccountsTableFilterComposer
    extends Composer<_$SortieDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
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

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imapHost => $composableBuilder(
    column: $table.imapHost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get imapPort => $composableBuilder(
    column: $table.imapPort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imapSecurity => $composableBuilder(
    column: $table.imapSecurity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get smtpHost => $composableBuilder(
    column: $table.smtpHost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get smtpPort => $composableBuilder(
    column: $table.smtpPort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get smtpSecurity => $composableBuilder(
    column: $table.smtpSecurity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get smtpUsername => $composableBuilder(
    column: $table.smtpUsername,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get auth => $composableBuilder(
    column: $table.auth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> identitiesRefs(
    Expression<bool> Function($$IdentitiesTableFilterComposer f) f,
  ) {
    final $$IdentitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.identities,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IdentitiesTableFilterComposer(
            $db: $db,
            $table: $db.identities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> foldersRefs(
    Expression<bool> Function($$FoldersTableFilterComposer f) f,
  ) {
    final $$FoldersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoldersTableFilterComposer(
            $db: $db,
            $table: $db.folders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableOrderingComposer
    extends Composer<_$SortieDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
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

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imapHost => $composableBuilder(
    column: $table.imapHost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get imapPort => $composableBuilder(
    column: $table.imapPort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imapSecurity => $composableBuilder(
    column: $table.imapSecurity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get smtpHost => $composableBuilder(
    column: $table.smtpHost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get smtpPort => $composableBuilder(
    column: $table.smtpPort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get smtpSecurity => $composableBuilder(
    column: $table.smtpSecurity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get smtpUsername => $composableBuilder(
    column: $table.smtpUsername,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get auth => $composableBuilder(
    column: $table.auth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$SortieDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get imapHost =>
      $composableBuilder(column: $table.imapHost, builder: (column) => column);

  GeneratedColumn<int> get imapPort =>
      $composableBuilder(column: $table.imapPort, builder: (column) => column);

  GeneratedColumn<String> get imapSecurity => $composableBuilder(
    column: $table.imapSecurity,
    builder: (column) => column,
  );

  GeneratedColumn<String> get smtpHost =>
      $composableBuilder(column: $table.smtpHost, builder: (column) => column);

  GeneratedColumn<int> get smtpPort =>
      $composableBuilder(column: $table.smtpPort, builder: (column) => column);

  GeneratedColumn<String> get smtpSecurity => $composableBuilder(
    column: $table.smtpSecurity,
    builder: (column) => column,
  );

  GeneratedColumn<String> get smtpUsername => $composableBuilder(
    column: $table.smtpUsername,
    builder: (column) => column,
  );

  GeneratedColumn<String> get auth =>
      $composableBuilder(column: $table.auth, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  Expression<T> identitiesRefs<T extends Object>(
    Expression<T> Function($$IdentitiesTableAnnotationComposer a) f,
  ) {
    final $$IdentitiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.identities,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IdentitiesTableAnnotationComposer(
            $db: $db,
            $table: $db.identities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> foldersRefs<T extends Object>(
    Expression<T> Function($$FoldersTableAnnotationComposer a) f,
  ) {
    final $$FoldersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoldersTableAnnotationComposer(
            $db: $db,
            $table: $db.folders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$SortieDatabase,
          $AccountsTable,
          Account,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (Account, $$AccountsTableReferences),
          Account,
          PrefetchHooks Function({bool identitiesRefs, bool foldersRefs})
        > {
  $$AccountsTableTableManager(_$SortieDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String> imapHost = const Value.absent(),
                Value<int> imapPort = const Value.absent(),
                Value<String> imapSecurity = const Value.absent(),
                Value<String> smtpHost = const Value.absent(),
                Value<int> smtpPort = const Value.absent(),
                Value<String> smtpSecurity = const Value.absent(),
                Value<String?> smtpUsername = const Value.absent(),
                Value<String> auth = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion(
                id: id,
                displayName: displayName,
                email: email,
                username: username,
                imapHost: imapHost,
                imapPort: imapPort,
                imapSecurity: imapSecurity,
                smtpHost: smtpHost,
                smtpPort: smtpPort,
                smtpSecurity: smtpSecurity,
                smtpUsername: smtpUsername,
                auth: auth,
                enabled: enabled,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String displayName,
                required String email,
                required String username,
                required String imapHost,
                required int imapPort,
                required String imapSecurity,
                required String smtpHost,
                required int smtpPort,
                required String smtpSecurity,
                Value<String?> smtpUsername = const Value.absent(),
                Value<String> auth = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion.insert(
                id: id,
                displayName: displayName,
                email: email,
                username: username,
                imapHost: imapHost,
                imapPort: imapPort,
                imapSecurity: imapSecurity,
                smtpHost: smtpHost,
                smtpPort: smtpPort,
                smtpSecurity: smtpSecurity,
                smtpUsername: smtpUsername,
                auth: auth,
                enabled: enabled,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AccountsTable, Account>(table),
                  $$AccountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({identitiesRefs = false, foldersRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (identitiesRefs) db.identities,
                    if (foldersRefs) db.folders,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (identitiesRefs)
                        await $_getPrefetchedData<
                          Account,
                          $AccountsTable,
                          Identity
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._identitiesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).identitiesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (foldersRefs)
                        await $_getPrefetchedData<
                          Account,
                          $AccountsTable,
                          Folder
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._foldersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).foldersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
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

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$SortieDatabase,
      $AccountsTable,
      Account,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (Account, $$AccountsTableReferences),
      Account,
      PrefetchHooks Function({bool identitiesRefs, bool foldersRefs})
    >;
typedef $$IdentitiesTableCreateCompanionBuilder = IdentitiesCompanion Function({
  required String id,
  required String accountId,
  required String name,
  required String email,
  Value<String?> replyTo,
  Value<String> signature,
  Value<String?> signatureHtml,
  Value<bool> isDefault,
  Value<int> rowid,
});
typedef $$IdentitiesTableUpdateCompanionBuilder = IdentitiesCompanion Function({
  Value<String> id,
  Value<String> accountId,
  Value<String> name,
  Value<String> email,
  Value<String?> replyTo,
  Value<String> signature,
  Value<String?> signatureHtml,
  Value<bool> isDefault,
  Value<int> rowid,
});

final class $$IdentitiesTableReferences
    extends BaseReferences<_$SortieDatabase, $IdentitiesTable, Identity> {
  $$IdentitiesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AccountsTable _accountIdTable(_$SortieDatabase db) =>
      db.accounts.createAlias('identities__account_id__accounts__id');

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$IdentitiesTableFilterComposer
    extends Composer<_$SortieDatabase, $IdentitiesTable> {
  $$IdentitiesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get replyTo => $composableBuilder(
    column: $table.replyTo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get signature => $composableBuilder(
    column: $table.signature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get signatureHtml => $composableBuilder(
    column: $table.signatureHtml,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IdentitiesTableOrderingComposer
    extends Composer<_$SortieDatabase, $IdentitiesTable> {
  $$IdentitiesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get replyTo => $composableBuilder(
    column: $table.replyTo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get signature => $composableBuilder(
    column: $table.signature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get signatureHtml => $composableBuilder(
    column: $table.signatureHtml,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IdentitiesTableAnnotationComposer
    extends Composer<_$SortieDatabase, $IdentitiesTable> {
  $$IdentitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get replyTo =>
      $composableBuilder(column: $table.replyTo, builder: (column) => column);

  GeneratedColumn<String> get signature =>
      $composableBuilder(column: $table.signature, builder: (column) => column);

  GeneratedColumn<String> get signatureHtml => $composableBuilder(
    column: $table.signatureHtml,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IdentitiesTableTableManager
    extends
        RootTableManager<
          _$SortieDatabase,
          $IdentitiesTable,
          Identity,
          $$IdentitiesTableFilterComposer,
          $$IdentitiesTableOrderingComposer,
          $$IdentitiesTableAnnotationComposer,
          $$IdentitiesTableCreateCompanionBuilder,
          $$IdentitiesTableUpdateCompanionBuilder,
          (Identity, $$IdentitiesTableReferences),
          Identity,
          PrefetchHooks Function({bool accountId})
        > {
  $$IdentitiesTableTableManager(_$SortieDatabase db, $IdentitiesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IdentitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IdentitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IdentitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String?> replyTo = const Value.absent(),
                Value<String> signature = const Value.absent(),
                Value<String?> signatureHtml = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IdentitiesCompanion(
                id: id,
                accountId: accountId,
                name: name,
                email: email,
                replyTo: replyTo,
                signature: signature,
                signatureHtml: signatureHtml,
                isDefault: isDefault,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String accountId,
                required String name,
                required String email,
                Value<String?> replyTo = const Value.absent(),
                Value<String> signature = const Value.absent(),
                Value<String?> signatureHtml = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IdentitiesCompanion.insert(
                id: id,
                accountId: accountId,
                name: name,
                email: email,
                replyTo: replyTo,
                signature: signature,
                signatureHtml: signatureHtml,
                isDefault: isDefault,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$IdentitiesTable, Identity>(table),
                  $$IdentitiesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountId = false}) {
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
                    if (accountId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.accountId,
                        referencedTable: $$IdentitiesTableReferences
                            ._accountIdTable(db),
                        referencedColumn: $$IdentitiesTableReferences
                            ._accountIdTable(db)
                            .id,
                      ) as T;
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

typedef $$IdentitiesTableProcessedTableManager =
    ProcessedTableManager<
      _$SortieDatabase,
      $IdentitiesTable,
      Identity,
      $$IdentitiesTableFilterComposer,
      $$IdentitiesTableOrderingComposer,
      $$IdentitiesTableAnnotationComposer,
      $$IdentitiesTableCreateCompanionBuilder,
      $$IdentitiesTableUpdateCompanionBuilder,
      (Identity, $$IdentitiesTableReferences),
      Identity,
      PrefetchHooks Function({bool accountId})
    >;
typedef $$FoldersTableCreateCompanionBuilder = FoldersCompanion Function({
  required String accountId,
  required String path,
  required String name,
  required String delimiter,
  Value<String> specialUse,
  Value<int?> uidValidity,
  Value<int?> uidNext,
  Value<int?> highestModSeq,
  Value<int> messageCount,
  Value<int> unseenCount,
  Value<bool> subscribed,
  Value<bool> selectable,
  Value<int?> lastSyncedAt,
  Value<int> rowid,
});
typedef $$FoldersTableUpdateCompanionBuilder = FoldersCompanion Function({
  Value<String> accountId,
  Value<String> path,
  Value<String> name,
  Value<String> delimiter,
  Value<String> specialUse,
  Value<int?> uidValidity,
  Value<int?> uidNext,
  Value<int?> highestModSeq,
  Value<int> messageCount,
  Value<int> unseenCount,
  Value<bool> subscribed,
  Value<bool> selectable,
  Value<int?> lastSyncedAt,
  Value<int> rowid,
});

final class $$FoldersTableReferences
    extends BaseReferences<_$SortieDatabase, $FoldersTable, Folder> {
  $$FoldersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AccountsTable _accountIdTable(_$SortieDatabase db) =>
      db.accounts.createAlias('folders__account_id__accounts__id');

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FoldersTableFilterComposer
    extends Composer<_$SortieDatabase, $FoldersTable> {
  $$FoldersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get delimiter => $composableBuilder(
    column: $table.delimiter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get specialUse => $composableBuilder(
    column: $table.specialUse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get uidValidity => $composableBuilder(
    column: $table.uidValidity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get uidNext => $composableBuilder(
    column: $table.uidNext,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get highestModSeq => $composableBuilder(
    column: $table.highestModSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get messageCount => $composableBuilder(
    column: $table.messageCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unseenCount => $composableBuilder(
    column: $table.unseenCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get subscribed => $composableBuilder(
    column: $table.subscribed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get selectable => $composableBuilder(
    column: $table.selectable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FoldersTableOrderingComposer
    extends Composer<_$SortieDatabase, $FoldersTable> {
  $$FoldersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get delimiter => $composableBuilder(
    column: $table.delimiter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get specialUse => $composableBuilder(
    column: $table.specialUse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get uidValidity => $composableBuilder(
    column: $table.uidValidity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get uidNext => $composableBuilder(
    column: $table.uidNext,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get highestModSeq => $composableBuilder(
    column: $table.highestModSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get messageCount => $composableBuilder(
    column: $table.messageCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unseenCount => $composableBuilder(
    column: $table.unseenCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get subscribed => $composableBuilder(
    column: $table.subscribed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get selectable => $composableBuilder(
    column: $table.selectable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FoldersTableAnnotationComposer
    extends Composer<_$SortieDatabase, $FoldersTable> {
  $$FoldersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get delimiter =>
      $composableBuilder(column: $table.delimiter, builder: (column) => column);

  GeneratedColumn<String> get specialUse => $composableBuilder(
    column: $table.specialUse,
    builder: (column) => column,
  );

  GeneratedColumn<int> get uidValidity => $composableBuilder(
    column: $table.uidValidity,
    builder: (column) => column,
  );

  GeneratedColumn<int> get uidNext =>
      $composableBuilder(column: $table.uidNext, builder: (column) => column);

  GeneratedColumn<int> get highestModSeq => $composableBuilder(
    column: $table.highestModSeq,
    builder: (column) => column,
  );

  GeneratedColumn<int> get messageCount => $composableBuilder(
    column: $table.messageCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get unseenCount => $composableBuilder(
    column: $table.unseenCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get subscribed => $composableBuilder(
    column: $table.subscribed,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get selectable => $composableBuilder(
    column: $table.selectable,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FoldersTableTableManager
    extends
        RootTableManager<
          _$SortieDatabase,
          $FoldersTable,
          Folder,
          $$FoldersTableFilterComposer,
          $$FoldersTableOrderingComposer,
          $$FoldersTableAnnotationComposer,
          $$FoldersTableCreateCompanionBuilder,
          $$FoldersTableUpdateCompanionBuilder,
          (Folder, $$FoldersTableReferences),
          Folder,
          PrefetchHooks Function({bool accountId})
        > {
  $$FoldersTableTableManager(_$SortieDatabase db, $FoldersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> delimiter = const Value.absent(),
                Value<String> specialUse = const Value.absent(),
                Value<int?> uidValidity = const Value.absent(),
                Value<int?> uidNext = const Value.absent(),
                Value<int?> highestModSeq = const Value.absent(),
                Value<int> messageCount = const Value.absent(),
                Value<int> unseenCount = const Value.absent(),
                Value<bool> subscribed = const Value.absent(),
                Value<bool> selectable = const Value.absent(),
                Value<int?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoldersCompanion(
                accountId: accountId,
                path: path,
                name: name,
                delimiter: delimiter,
                specialUse: specialUse,
                uidValidity: uidValidity,
                uidNext: uidNext,
                highestModSeq: highestModSeq,
                messageCount: messageCount,
                unseenCount: unseenCount,
                subscribed: subscribed,
                selectable: selectable,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required String path,
                required String name,
                required String delimiter,
                Value<String> specialUse = const Value.absent(),
                Value<int?> uidValidity = const Value.absent(),
                Value<int?> uidNext = const Value.absent(),
                Value<int?> highestModSeq = const Value.absent(),
                Value<int> messageCount = const Value.absent(),
                Value<int> unseenCount = const Value.absent(),
                Value<bool> subscribed = const Value.absent(),
                Value<bool> selectable = const Value.absent(),
                Value<int?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoldersCompanion.insert(
                accountId: accountId,
                path: path,
                name: name,
                delimiter: delimiter,
                specialUse: specialUse,
                uidValidity: uidValidity,
                uidNext: uidNext,
                highestModSeq: highestModSeq,
                messageCount: messageCount,
                unseenCount: unseenCount,
                subscribed: subscribed,
                selectable: selectable,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FoldersTable, Folder>(table),
                  $$FoldersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountId = false}) {
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
                    if (accountId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.accountId,
                        referencedTable: $$FoldersTableReferences
                            ._accountIdTable(db),
                        referencedColumn: $$FoldersTableReferences
                            ._accountIdTable(db)
                            .id,
                      ) as T;
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

typedef $$FoldersTableProcessedTableManager =
    ProcessedTableManager<
      _$SortieDatabase,
      $FoldersTable,
      Folder,
      $$FoldersTableFilterComposer,
      $$FoldersTableOrderingComposer,
      $$FoldersTableAnnotationComposer,
      $$FoldersTableCreateCompanionBuilder,
      $$FoldersTableUpdateCompanionBuilder,
      (Folder, $$FoldersTableReferences),
      Folder,
      PrefetchHooks Function({bool accountId})
    >;
typedef $$MessagesTableCreateCompanionBuilder = MessagesCompanion Function({
  required String accountId,
  required String messageIdHash,
  required String folderPath,
  Value<int?> uid,
  Value<int?> uidValidity,
  Value<String?> messageId,
  Value<String> subject,
  Value<String?> fromEmail,
  Value<String?> fromName,
  Value<String> toAddressesJson,
  Value<String> ccJson,
  Value<String?> replyTo,
  required int date,
  Value<int?> internalDate,
  Value<String?> listId,
  Value<String?> inReplyTo,
  Value<String> referencesJson,
  Value<String?> precedence,
  Value<String?> autoSubmitted,
  Value<bool> hasListUnsubscribe,
  Value<String> flagsJson,
  Value<int> size,
  Value<String> snippet,
  Value<String> attachmentsJson,
  Value<int?> lastOpenedAt,
  Value<int> rowid,
});
typedef $$MessagesTableUpdateCompanionBuilder = MessagesCompanion Function({
  Value<String> accountId,
  Value<String> messageIdHash,
  Value<String> folderPath,
  Value<int?> uid,
  Value<int?> uidValidity,
  Value<String?> messageId,
  Value<String> subject,
  Value<String?> fromEmail,
  Value<String?> fromName,
  Value<String> toAddressesJson,
  Value<String> ccJson,
  Value<String?> replyTo,
  Value<int> date,
  Value<int?> internalDate,
  Value<String?> listId,
  Value<String?> inReplyTo,
  Value<String> referencesJson,
  Value<String?> precedence,
  Value<String?> autoSubmitted,
  Value<bool> hasListUnsubscribe,
  Value<String> flagsJson,
  Value<int> size,
  Value<String> snippet,
  Value<String> attachmentsJson,
  Value<int?> lastOpenedAt,
  Value<int> rowid,
});

class $$MessagesTableFilterComposer
    extends Composer<_$SortieDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get messageIdHash => $composableBuilder(
    column: $table.messageIdHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folderPath => $composableBuilder(
    column: $table.folderPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get uidValidity => $composableBuilder(
    column: $table.uidValidity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromEmail => $composableBuilder(
    column: $table.fromEmail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromName => $composableBuilder(
    column: $table.fromName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toAddressesJson => $composableBuilder(
    column: $table.toAddressesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ccJson => $composableBuilder(
    column: $table.ccJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get replyTo => $composableBuilder(
    column: $table.replyTo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get internalDate => $composableBuilder(
    column: $table.internalDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get listId => $composableBuilder(
    column: $table.listId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inReplyTo => $composableBuilder(
    column: $table.inReplyTo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referencesJson => $composableBuilder(
    column: $table.referencesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get precedence => $composableBuilder(
    column: $table.precedence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get autoSubmitted => $composableBuilder(
    column: $table.autoSubmitted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasListUnsubscribe => $composableBuilder(
    column: $table.hasListUnsubscribe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get flagsJson => $composableBuilder(
    column: $table.flagsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get snippet => $composableBuilder(
    column: $table.snippet,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attachmentsJson => $composableBuilder(
    column: $table.attachmentsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MessagesTableOrderingComposer
    extends Composer<_$SortieDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messageIdHash => $composableBuilder(
    column: $table.messageIdHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folderPath => $composableBuilder(
    column: $table.folderPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get uidValidity => $composableBuilder(
    column: $table.uidValidity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromEmail => $composableBuilder(
    column: $table.fromEmail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromName => $composableBuilder(
    column: $table.fromName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toAddressesJson => $composableBuilder(
    column: $table.toAddressesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ccJson => $composableBuilder(
    column: $table.ccJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get replyTo => $composableBuilder(
    column: $table.replyTo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get internalDate => $composableBuilder(
    column: $table.internalDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get listId => $composableBuilder(
    column: $table.listId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inReplyTo => $composableBuilder(
    column: $table.inReplyTo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referencesJson => $composableBuilder(
    column: $table.referencesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get precedence => $composableBuilder(
    column: $table.precedence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get autoSubmitted => $composableBuilder(
    column: $table.autoSubmitted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasListUnsubscribe => $composableBuilder(
    column: $table.hasListUnsubscribe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get flagsJson => $composableBuilder(
    column: $table.flagsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get snippet => $composableBuilder(
    column: $table.snippet,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attachmentsJson => $composableBuilder(
    column: $table.attachmentsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$SortieDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get messageIdHash => $composableBuilder(
    column: $table.messageIdHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get folderPath => $composableBuilder(
    column: $table.folderPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<int> get uidValidity => $composableBuilder(
    column: $table.uidValidity,
    builder: (column) => column,
  );

  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get fromEmail =>
      $composableBuilder(column: $table.fromEmail, builder: (column) => column);

  GeneratedColumn<String> get fromName =>
      $composableBuilder(column: $table.fromName, builder: (column) => column);

  GeneratedColumn<String> get toAddressesJson => $composableBuilder(
    column: $table.toAddressesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ccJson =>
      $composableBuilder(column: $table.ccJson, builder: (column) => column);

  GeneratedColumn<String> get replyTo =>
      $composableBuilder(column: $table.replyTo, builder: (column) => column);

  GeneratedColumn<int> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get internalDate => $composableBuilder(
    column: $table.internalDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get listId =>
      $composableBuilder(column: $table.listId, builder: (column) => column);

  GeneratedColumn<String> get inReplyTo =>
      $composableBuilder(column: $table.inReplyTo, builder: (column) => column);

  GeneratedColumn<String> get referencesJson => $composableBuilder(
    column: $table.referencesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get precedence => $composableBuilder(
    column: $table.precedence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get autoSubmitted => $composableBuilder(
    column: $table.autoSubmitted,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasListUnsubscribe => $composableBuilder(
    column: $table.hasListUnsubscribe,
    builder: (column) => column,
  );

  GeneratedColumn<String> get flagsJson =>
      $composableBuilder(column: $table.flagsJson, builder: (column) => column);

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<String> get snippet =>
      $composableBuilder(column: $table.snippet, builder: (column) => column);

  GeneratedColumn<String> get attachmentsJson => $composableBuilder(
    column: $table.attachmentsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => column,
  );
}

class $$MessagesTableTableManager
    extends
        RootTableManager<
          _$SortieDatabase,
          $MessagesTable,
          Message,
          $$MessagesTableFilterComposer,
          $$MessagesTableOrderingComposer,
          $$MessagesTableAnnotationComposer,
          $$MessagesTableCreateCompanionBuilder,
          $$MessagesTableUpdateCompanionBuilder,
          (Message, BaseReferences<_$SortieDatabase, $MessagesTable, Message>),
          Message,
          PrefetchHooks Function()
        > {
  $$MessagesTableTableManager(_$SortieDatabase db, $MessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<String> messageIdHash = const Value.absent(),
                Value<String> folderPath = const Value.absent(),
                Value<int?> uid = const Value.absent(),
                Value<int?> uidValidity = const Value.absent(),
                Value<String?> messageId = const Value.absent(),
                Value<String> subject = const Value.absent(),
                Value<String?> fromEmail = const Value.absent(),
                Value<String?> fromName = const Value.absent(),
                Value<String> toAddressesJson = const Value.absent(),
                Value<String> ccJson = const Value.absent(),
                Value<String?> replyTo = const Value.absent(),
                Value<int> date = const Value.absent(),
                Value<int?> internalDate = const Value.absent(),
                Value<String?> listId = const Value.absent(),
                Value<String?> inReplyTo = const Value.absent(),
                Value<String> referencesJson = const Value.absent(),
                Value<String?> precedence = const Value.absent(),
                Value<String?> autoSubmitted = const Value.absent(),
                Value<bool> hasListUnsubscribe = const Value.absent(),
                Value<String> flagsJson = const Value.absent(),
                Value<int> size = const Value.absent(),
                Value<String> snippet = const Value.absent(),
                Value<String> attachmentsJson = const Value.absent(),
                Value<int?> lastOpenedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion(
                accountId: accountId,
                messageIdHash: messageIdHash,
                folderPath: folderPath,
                uid: uid,
                uidValidity: uidValidity,
                messageId: messageId,
                subject: subject,
                fromEmail: fromEmail,
                fromName: fromName,
                toAddressesJson: toAddressesJson,
                ccJson: ccJson,
                replyTo: replyTo,
                date: date,
                internalDate: internalDate,
                listId: listId,
                inReplyTo: inReplyTo,
                referencesJson: referencesJson,
                precedence: precedence,
                autoSubmitted: autoSubmitted,
                hasListUnsubscribe: hasListUnsubscribe,
                flagsJson: flagsJson,
                size: size,
                snippet: snippet,
                attachmentsJson: attachmentsJson,
                lastOpenedAt: lastOpenedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required String messageIdHash,
                required String folderPath,
                Value<int?> uid = const Value.absent(),
                Value<int?> uidValidity = const Value.absent(),
                Value<String?> messageId = const Value.absent(),
                Value<String> subject = const Value.absent(),
                Value<String?> fromEmail = const Value.absent(),
                Value<String?> fromName = const Value.absent(),
                Value<String> toAddressesJson = const Value.absent(),
                Value<String> ccJson = const Value.absent(),
                Value<String?> replyTo = const Value.absent(),
                required int date,
                Value<int?> internalDate = const Value.absent(),
                Value<String?> listId = const Value.absent(),
                Value<String?> inReplyTo = const Value.absent(),
                Value<String> referencesJson = const Value.absent(),
                Value<String?> precedence = const Value.absent(),
                Value<String?> autoSubmitted = const Value.absent(),
                Value<bool> hasListUnsubscribe = const Value.absent(),
                Value<String> flagsJson = const Value.absent(),
                Value<int> size = const Value.absent(),
                Value<String> snippet = const Value.absent(),
                Value<String> attachmentsJson = const Value.absent(),
                Value<int?> lastOpenedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion.insert(
                accountId: accountId,
                messageIdHash: messageIdHash,
                folderPath: folderPath,
                uid: uid,
                uidValidity: uidValidity,
                messageId: messageId,
                subject: subject,
                fromEmail: fromEmail,
                fromName: fromName,
                toAddressesJson: toAddressesJson,
                ccJson: ccJson,
                replyTo: replyTo,
                date: date,
                internalDate: internalDate,
                listId: listId,
                inReplyTo: inReplyTo,
                referencesJson: referencesJson,
                precedence: precedence,
                autoSubmitted: autoSubmitted,
                hasListUnsubscribe: hasListUnsubscribe,
                flagsJson: flagsJson,
                size: size,
                snippet: snippet,
                attachmentsJson: attachmentsJson,
                lastOpenedAt: lastOpenedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MessagesTable, Message>(table),
                  BaseReferences<_$SortieDatabase, $MessagesTable, Message>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$SortieDatabase,
      $MessagesTable,
      Message,
      $$MessagesTableFilterComposer,
      $$MessagesTableOrderingComposer,
      $$MessagesTableAnnotationComposer,
      $$MessagesTableCreateCompanionBuilder,
      $$MessagesTableUpdateCompanionBuilder,
      (Message, BaseReferences<_$SortieDatabase, $MessagesTable, Message>),
      Message,
      PrefetchHooks Function()
    >;
typedef $$MessageBodiesTableCreateCompanionBuilder =
    MessageBodiesCompanion Function({
      required String accountId,
      required String messageIdHash,
      required String bodyText,
      Value<String?> html,
      Value<String> inlineJson,
      Value<String?> calendarText,
      Value<int> sizeBytes,
      required int cachedAt,
      required int lastAccessAt,
      Value<int> rowid,
    });
typedef $$MessageBodiesTableUpdateCompanionBuilder =
    MessageBodiesCompanion Function({
      Value<String> accountId,
      Value<String> messageIdHash,
      Value<String> bodyText,
      Value<String?> html,
      Value<String> inlineJson,
      Value<String?> calendarText,
      Value<int> sizeBytes,
      Value<int> cachedAt,
      Value<int> lastAccessAt,
      Value<int> rowid,
    });

class $$MessageBodiesTableFilterComposer
    extends Composer<_$SortieDatabase, $MessageBodiesTable> {
  $$MessageBodiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get messageIdHash => $composableBuilder(
    column: $table.messageIdHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bodyText => $composableBuilder(
    column: $table.bodyText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get html => $composableBuilder(
    column: $table.html,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inlineJson => $composableBuilder(
    column: $table.inlineJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get calendarText => $composableBuilder(
    column: $table.calendarText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastAccessAt => $composableBuilder(
    column: $table.lastAccessAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MessageBodiesTableOrderingComposer
    extends Composer<_$SortieDatabase, $MessageBodiesTable> {
  $$MessageBodiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messageIdHash => $composableBuilder(
    column: $table.messageIdHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bodyText => $composableBuilder(
    column: $table.bodyText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get html => $composableBuilder(
    column: $table.html,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inlineJson => $composableBuilder(
    column: $table.inlineJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get calendarText => $composableBuilder(
    column: $table.calendarText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastAccessAt => $composableBuilder(
    column: $table.lastAccessAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessageBodiesTableAnnotationComposer
    extends Composer<_$SortieDatabase, $MessageBodiesTable> {
  $$MessageBodiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get messageIdHash => $composableBuilder(
    column: $table.messageIdHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bodyText =>
      $composableBuilder(column: $table.bodyText, builder: (column) => column);

  GeneratedColumn<String> get html =>
      $composableBuilder(column: $table.html, builder: (column) => column);

  GeneratedColumn<String> get inlineJson => $composableBuilder(
    column: $table.inlineJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get calendarText => $composableBuilder(
    column: $table.calendarText,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<int> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  GeneratedColumn<int> get lastAccessAt => $composableBuilder(
    column: $table.lastAccessAt,
    builder: (column) => column,
  );
}

class $$MessageBodiesTableTableManager
    extends
        RootTableManager<
          _$SortieDatabase,
          $MessageBodiesTable,
          MessageBody,
          $$MessageBodiesTableFilterComposer,
          $$MessageBodiesTableOrderingComposer,
          $$MessageBodiesTableAnnotationComposer,
          $$MessageBodiesTableCreateCompanionBuilder,
          $$MessageBodiesTableUpdateCompanionBuilder,
          (
            MessageBody,
            BaseReferences<_$SortieDatabase, $MessageBodiesTable, MessageBody>,
          ),
          MessageBody,
          PrefetchHooks Function()
        > {
  $$MessageBodiesTableTableManager(
    _$SortieDatabase db,
    $MessageBodiesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessageBodiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessageBodiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessageBodiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<String> messageIdHash = const Value.absent(),
                Value<String> bodyText = const Value.absent(),
                Value<String?> html = const Value.absent(),
                Value<String> inlineJson = const Value.absent(),
                Value<String?> calendarText = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<int> cachedAt = const Value.absent(),
                Value<int> lastAccessAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessageBodiesCompanion(
                accountId: accountId,
                messageIdHash: messageIdHash,
                bodyText: bodyText,
                html: html,
                inlineJson: inlineJson,
                calendarText: calendarText,
                sizeBytes: sizeBytes,
                cachedAt: cachedAt,
                lastAccessAt: lastAccessAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required String messageIdHash,
                required String bodyText,
                Value<String?> html = const Value.absent(),
                Value<String> inlineJson = const Value.absent(),
                Value<String?> calendarText = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                required int cachedAt,
                required int lastAccessAt,
                Value<int> rowid = const Value.absent(),
              }) => MessageBodiesCompanion.insert(
                accountId: accountId,
                messageIdHash: messageIdHash,
                bodyText: bodyText,
                html: html,
                inlineJson: inlineJson,
                calendarText: calendarText,
                sizeBytes: sizeBytes,
                cachedAt: cachedAt,
                lastAccessAt: lastAccessAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MessageBodiesTable, MessageBody>(table),
                  BaseReferences<
                    _$SortieDatabase,
                    $MessageBodiesTable,
                    MessageBody
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MessageBodiesTableProcessedTableManager =
    ProcessedTableManager<
      _$SortieDatabase,
      $MessageBodiesTable,
      MessageBody,
      $$MessageBodiesTableFilterComposer,
      $$MessageBodiesTableOrderingComposer,
      $$MessageBodiesTableAnnotationComposer,
      $$MessageBodiesTableCreateCompanionBuilder,
      $$MessageBodiesTableUpdateCompanionBuilder,
      (
        MessageBody,
        BaseReferences<_$SortieDatabase, $MessageBodiesTable, MessageBody>,
      ),
      MessageBody,
      PrefetchHooks Function()
    >;
typedef $$PendingOpsTableCreateCompanionBuilder = PendingOpsCompanion Function({
  required String id,
  required String accountId,
  required String type,
  required String payloadJson,
  required int createdAt,
  Value<int> attempts,
  Value<int?> nextAttemptAt,
  Value<String> status,
  Value<String?> lastError,
  Value<int> rowid,
});
typedef $$PendingOpsTableUpdateCompanionBuilder = PendingOpsCompanion Function({
  Value<String> id,
  Value<String> accountId,
  Value<String> type,
  Value<String> payloadJson,
  Value<int> createdAt,
  Value<int> attempts,
  Value<int?> nextAttemptAt,
  Value<String> status,
  Value<String?> lastError,
  Value<int> rowid,
});

class $$PendingOpsTableFilterComposer
    extends Composer<_$SortieDatabase, $PendingOpsTable> {
  $$PendingOpsTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingOpsTableOrderingComposer
    extends Composer<_$SortieDatabase, $PendingOpsTable> {
  $$PendingOpsTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingOpsTableAnnotationComposer
    extends Composer<_$SortieDatabase, $PendingOpsTable> {
  $$PendingOpsTableAnnotationComposer({
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

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$PendingOpsTableTableManager
    extends
        RootTableManager<
          _$SortieDatabase,
          $PendingOpsTable,
          PendingOp,
          $$PendingOpsTableFilterComposer,
          $$PendingOpsTableOrderingComposer,
          $$PendingOpsTableAnnotationComposer,
          $$PendingOpsTableCreateCompanionBuilder,
          $$PendingOpsTableUpdateCompanionBuilder,
          (
            PendingOp,
            BaseReferences<_$SortieDatabase, $PendingOpsTable, PendingOp>,
          ),
          PendingOp,
          PrefetchHooks Function()
        > {
  $$PendingOpsTableTableManager(_$SortieDatabase db, $PendingOpsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingOpsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingOpsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingOpsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<int?> nextAttemptAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingOpsCompanion(
                id: id,
                accountId: accountId,
                type: type,
                payloadJson: payloadJson,
                createdAt: createdAt,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                status: status,
                lastError: lastError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String accountId,
                required String type,
                required String payloadJson,
                required int createdAt,
                Value<int> attempts = const Value.absent(),
                Value<int?> nextAttemptAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingOpsCompanion.insert(
                id: id,
                accountId: accountId,
                type: type,
                payloadJson: payloadJson,
                createdAt: createdAt,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                status: status,
                lastError: lastError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PendingOpsTable, PendingOp>(table),
                  BaseReferences<_$SortieDatabase, $PendingOpsTable, PendingOp>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingOpsTableProcessedTableManager =
    ProcessedTableManager<
      _$SortieDatabase,
      $PendingOpsTable,
      PendingOp,
      $$PendingOpsTableFilterComposer,
      $$PendingOpsTableOrderingComposer,
      $$PendingOpsTableAnnotationComposer,
      $$PendingOpsTableCreateCompanionBuilder,
      $$PendingOpsTableUpdateCompanionBuilder,
      (
        PendingOp,
        BaseReferences<_$SortieDatabase, $PendingOpsTable, PendingOp>,
      ),
      PendingOp,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  Value<String?> value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String?> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$SortieDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
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

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$SortieDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
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

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$SortieDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$SortieDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$SortieDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$SortieDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String?> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            Value<String?> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, Setting>(table),
                  BaseReferences<_$SortieDatabase, $SettingsTable, Setting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$SortieDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$SortieDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $$SortDecisionsTableCreateCompanionBuilder =
    SortDecisionsCompanion Function({
      required String id,
      required String accountId,
      required String messageIdHash,
      Value<int?> uid,
      Value<int?> uidValidity,
      required String sourceFolder,
      required String destination,
      required String layer,
      Value<String?> matchedKey,
      required double confidence,
      Value<String> reason,
      required String mode,
      required String status,
      Value<String?> modelId,
      Value<int?> folderProfileVersion,
      Value<double?> costUsd,
      Value<String?> deviceId,
      Value<int?> epoch,
      Value<bool> dryRun,
      required int createdAt,
      Value<int?> appliedAt,
      Value<int?> seenObservedAt,
      Value<String?> finalFolder,
      Value<int> rowid,
    });
typedef $$SortDecisionsTableUpdateCompanionBuilder =
    SortDecisionsCompanion Function({
      Value<String> id,
      Value<String> accountId,
      Value<String> messageIdHash,
      Value<int?> uid,
      Value<int?> uidValidity,
      Value<String> sourceFolder,
      Value<String> destination,
      Value<String> layer,
      Value<String?> matchedKey,
      Value<double> confidence,
      Value<String> reason,
      Value<String> mode,
      Value<String> status,
      Value<String?> modelId,
      Value<int?> folderProfileVersion,
      Value<double?> costUsd,
      Value<String?> deviceId,
      Value<int?> epoch,
      Value<bool> dryRun,
      Value<int> createdAt,
      Value<int?> appliedAt,
      Value<int?> seenObservedAt,
      Value<String?> finalFolder,
      Value<int> rowid,
    });

class $$SortDecisionsTableFilterComposer
    extends Composer<_$SortieDatabase, $SortDecisionsTable> {
  $$SortDecisionsTableFilterComposer({
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

  ColumnFilters<String> get messageIdHash => $composableBuilder(
    column: $table.messageIdHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get uidValidity => $composableBuilder(
    column: $table.uidValidity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceFolder => $composableBuilder(
    column: $table.sourceFolder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get layer => $composableBuilder(
    column: $table.layer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get matchedKey => $composableBuilder(
    column: $table.matchedKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get folderProfileVersion => $composableBuilder(
    column: $table.folderProfileVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get costUsd => $composableBuilder(
    column: $table.costUsd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get epoch => $composableBuilder(
    column: $table.epoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dryRun => $composableBuilder(
    column: $table.dryRun,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get appliedAt => $composableBuilder(
    column: $table.appliedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seenObservedAt => $composableBuilder(
    column: $table.seenObservedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get finalFolder => $composableBuilder(
    column: $table.finalFolder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SortDecisionsTableOrderingComposer
    extends Composer<_$SortieDatabase, $SortDecisionsTable> {
  $$SortDecisionsTableOrderingComposer({
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

  ColumnOrderings<String> get messageIdHash => $composableBuilder(
    column: $table.messageIdHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get uidValidity => $composableBuilder(
    column: $table.uidValidity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceFolder => $composableBuilder(
    column: $table.sourceFolder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get layer => $composableBuilder(
    column: $table.layer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matchedKey => $composableBuilder(
    column: $table.matchedKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get folderProfileVersion => $composableBuilder(
    column: $table.folderProfileVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get costUsd => $composableBuilder(
    column: $table.costUsd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get epoch => $composableBuilder(
    column: $table.epoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dryRun => $composableBuilder(
    column: $table.dryRun,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get appliedAt => $composableBuilder(
    column: $table.appliedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seenObservedAt => $composableBuilder(
    column: $table.seenObservedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get finalFolder => $composableBuilder(
    column: $table.finalFolder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SortDecisionsTableAnnotationComposer
    extends Composer<_$SortieDatabase, $SortDecisionsTable> {
  $$SortDecisionsTableAnnotationComposer({
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

  GeneratedColumn<String> get messageIdHash => $composableBuilder(
    column: $table.messageIdHash,
    builder: (column) => column,
  );

  GeneratedColumn<int> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<int> get uidValidity => $composableBuilder(
    column: $table.uidValidity,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceFolder => $composableBuilder(
    column: $table.sourceFolder,
    builder: (column) => column,
  );

  GeneratedColumn<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => column,
  );

  GeneratedColumn<String> get layer =>
      $composableBuilder(column: $table.layer, builder: (column) => column);

  GeneratedColumn<String> get matchedKey => $composableBuilder(
    column: $table.matchedKey,
    builder: (column) => column,
  );

  GeneratedColumn<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get modelId =>
      $composableBuilder(column: $table.modelId, builder: (column) => column);

  GeneratedColumn<int> get folderProfileVersion => $composableBuilder(
    column: $table.folderProfileVersion,
    builder: (column) => column,
  );

  GeneratedColumn<double> get costUsd =>
      $composableBuilder(column: $table.costUsd, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get epoch =>
      $composableBuilder(column: $table.epoch, builder: (column) => column);

  GeneratedColumn<bool> get dryRun =>
      $composableBuilder(column: $table.dryRun, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get appliedAt =>
      $composableBuilder(column: $table.appliedAt, builder: (column) => column);

  GeneratedColumn<int> get seenObservedAt => $composableBuilder(
    column: $table.seenObservedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get finalFolder => $composableBuilder(
    column: $table.finalFolder,
    builder: (column) => column,
  );
}

class $$SortDecisionsTableTableManager
    extends
        RootTableManager<
          _$SortieDatabase,
          $SortDecisionsTable,
          SortDecision,
          $$SortDecisionsTableFilterComposer,
          $$SortDecisionsTableOrderingComposer,
          $$SortDecisionsTableAnnotationComposer,
          $$SortDecisionsTableCreateCompanionBuilder,
          $$SortDecisionsTableUpdateCompanionBuilder,
          (
            SortDecision,
            BaseReferences<_$SortieDatabase, $SortDecisionsTable, SortDecision>,
          ),
          SortDecision,
          PrefetchHooks Function()
        > {
  $$SortDecisionsTableTableManager(
    _$SortieDatabase db,
    $SortDecisionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SortDecisionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SortDecisionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SortDecisionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> messageIdHash = const Value.absent(),
                Value<int?> uid = const Value.absent(),
                Value<int?> uidValidity = const Value.absent(),
                Value<String> sourceFolder = const Value.absent(),
                Value<String> destination = const Value.absent(),
                Value<String> layer = const Value.absent(),
                Value<String?> matchedKey = const Value.absent(),
                Value<double> confidence = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> modelId = const Value.absent(),
                Value<int?> folderProfileVersion = const Value.absent(),
                Value<double?> costUsd = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<int?> epoch = const Value.absent(),
                Value<bool> dryRun = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> appliedAt = const Value.absent(),
                Value<int?> seenObservedAt = const Value.absent(),
                Value<String?> finalFolder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SortDecisionsCompanion(
                id: id,
                accountId: accountId,
                messageIdHash: messageIdHash,
                uid: uid,
                uidValidity: uidValidity,
                sourceFolder: sourceFolder,
                destination: destination,
                layer: layer,
                matchedKey: matchedKey,
                confidence: confidence,
                reason: reason,
                mode: mode,
                status: status,
                modelId: modelId,
                folderProfileVersion: folderProfileVersion,
                costUsd: costUsd,
                deviceId: deviceId,
                epoch: epoch,
                dryRun: dryRun,
                createdAt: createdAt,
                appliedAt: appliedAt,
                seenObservedAt: seenObservedAt,
                finalFolder: finalFolder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String accountId,
                required String messageIdHash,
                Value<int?> uid = const Value.absent(),
                Value<int?> uidValidity = const Value.absent(),
                required String sourceFolder,
                required String destination,
                required String layer,
                Value<String?> matchedKey = const Value.absent(),
                required double confidence,
                Value<String> reason = const Value.absent(),
                required String mode,
                required String status,
                Value<String?> modelId = const Value.absent(),
                Value<int?> folderProfileVersion = const Value.absent(),
                Value<double?> costUsd = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<int?> epoch = const Value.absent(),
                Value<bool> dryRun = const Value.absent(),
                required int createdAt,
                Value<int?> appliedAt = const Value.absent(),
                Value<int?> seenObservedAt = const Value.absent(),
                Value<String?> finalFolder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SortDecisionsCompanion.insert(
                id: id,
                accountId: accountId,
                messageIdHash: messageIdHash,
                uid: uid,
                uidValidity: uidValidity,
                sourceFolder: sourceFolder,
                destination: destination,
                layer: layer,
                matchedKey: matchedKey,
                confidence: confidence,
                reason: reason,
                mode: mode,
                status: status,
                modelId: modelId,
                folderProfileVersion: folderProfileVersion,
                costUsd: costUsd,
                deviceId: deviceId,
                epoch: epoch,
                dryRun: dryRun,
                createdAt: createdAt,
                appliedAt: appliedAt,
                seenObservedAt: seenObservedAt,
                finalFolder: finalFolder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SortDecisionsTable, SortDecision>(table),
                  BaseReferences<
                    _$SortieDatabase,
                    $SortDecisionsTable,
                    SortDecision
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SortDecisionsTableProcessedTableManager =
    ProcessedTableManager<
      _$SortieDatabase,
      $SortDecisionsTable,
      SortDecision,
      $$SortDecisionsTableFilterComposer,
      $$SortDecisionsTableOrderingComposer,
      $$SortDecisionsTableAnnotationComposer,
      $$SortDecisionsTableCreateCompanionBuilder,
      $$SortDecisionsTableUpdateCompanionBuilder,
      (
        SortDecision,
        BaseReferences<_$SortieDatabase, $SortDecisionsTable, SortDecision>,
      ),
      SortDecision,
      PrefetchHooks Function()
    >;
typedef $$CorrectionsTableCreateCompanionBuilder =
    CorrectionsCompanion Function({
      required String id,
      required String accountId,
      required String messageIdHash,
      Value<String?> decisionId,
      required String kind,
      required double weight,
      Value<String?> predictedFolder,
      required String actualFolder,
      Value<String?> fromAddress,
      Value<String?> fromDomain,
      Value<String?> listId,
      Value<String?> subjectNorm,
      Value<bool> superseded,
      Value<String?> deviceId,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$CorrectionsTableUpdateCompanionBuilder =
    CorrectionsCompanion Function({
      Value<String> id,
      Value<String> accountId,
      Value<String> messageIdHash,
      Value<String?> decisionId,
      Value<String> kind,
      Value<double> weight,
      Value<String?> predictedFolder,
      Value<String> actualFolder,
      Value<String?> fromAddress,
      Value<String?> fromDomain,
      Value<String?> listId,
      Value<String?> subjectNorm,
      Value<bool> superseded,
      Value<String?> deviceId,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$CorrectionsTableFilterComposer
    extends Composer<_$SortieDatabase, $CorrectionsTable> {
  $$CorrectionsTableFilterComposer({
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

  ColumnFilters<String> get messageIdHash => $composableBuilder(
    column: $table.messageIdHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get decisionId => $composableBuilder(
    column: $table.decisionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get predictedFolder => $composableBuilder(
    column: $table.predictedFolder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actualFolder => $composableBuilder(
    column: $table.actualFolder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromAddress => $composableBuilder(
    column: $table.fromAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromDomain => $composableBuilder(
    column: $table.fromDomain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get listId => $composableBuilder(
    column: $table.listId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subjectNorm => $composableBuilder(
    column: $table.subjectNorm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get superseded => $composableBuilder(
    column: $table.superseded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CorrectionsTableOrderingComposer
    extends Composer<_$SortieDatabase, $CorrectionsTable> {
  $$CorrectionsTableOrderingComposer({
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

  ColumnOrderings<String> get messageIdHash => $composableBuilder(
    column: $table.messageIdHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get decisionId => $composableBuilder(
    column: $table.decisionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get predictedFolder => $composableBuilder(
    column: $table.predictedFolder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actualFolder => $composableBuilder(
    column: $table.actualFolder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromAddress => $composableBuilder(
    column: $table.fromAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromDomain => $composableBuilder(
    column: $table.fromDomain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get listId => $composableBuilder(
    column: $table.listId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subjectNorm => $composableBuilder(
    column: $table.subjectNorm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get superseded => $composableBuilder(
    column: $table.superseded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CorrectionsTableAnnotationComposer
    extends Composer<_$SortieDatabase, $CorrectionsTable> {
  $$CorrectionsTableAnnotationComposer({
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

  GeneratedColumn<String> get messageIdHash => $composableBuilder(
    column: $table.messageIdHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get decisionId => $composableBuilder(
    column: $table.decisionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<String> get predictedFolder => $composableBuilder(
    column: $table.predictedFolder,
    builder: (column) => column,
  );

  GeneratedColumn<String> get actualFolder => $composableBuilder(
    column: $table.actualFolder,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fromAddress => $composableBuilder(
    column: $table.fromAddress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fromDomain => $composableBuilder(
    column: $table.fromDomain,
    builder: (column) => column,
  );

  GeneratedColumn<String> get listId =>
      $composableBuilder(column: $table.listId, builder: (column) => column);

  GeneratedColumn<String> get subjectNorm => $composableBuilder(
    column: $table.subjectNorm,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get superseded => $composableBuilder(
    column: $table.superseded,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CorrectionsTableTableManager
    extends
        RootTableManager<
          _$SortieDatabase,
          $CorrectionsTable,
          Correction,
          $$CorrectionsTableFilterComposer,
          $$CorrectionsTableOrderingComposer,
          $$CorrectionsTableAnnotationComposer,
          $$CorrectionsTableCreateCompanionBuilder,
          $$CorrectionsTableUpdateCompanionBuilder,
          (
            Correction,
            BaseReferences<_$SortieDatabase, $CorrectionsTable, Correction>,
          ),
          Correction,
          PrefetchHooks Function()
        > {
  $$CorrectionsTableTableManager(_$SortieDatabase db, $CorrectionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CorrectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CorrectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CorrectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> messageIdHash = const Value.absent(),
                Value<String?> decisionId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<double> weight = const Value.absent(),
                Value<String?> predictedFolder = const Value.absent(),
                Value<String> actualFolder = const Value.absent(),
                Value<String?> fromAddress = const Value.absent(),
                Value<String?> fromDomain = const Value.absent(),
                Value<String?> listId = const Value.absent(),
                Value<String?> subjectNorm = const Value.absent(),
                Value<bool> superseded = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CorrectionsCompanion(
                id: id,
                accountId: accountId,
                messageIdHash: messageIdHash,
                decisionId: decisionId,
                kind: kind,
                weight: weight,
                predictedFolder: predictedFolder,
                actualFolder: actualFolder,
                fromAddress: fromAddress,
                fromDomain: fromDomain,
                listId: listId,
                subjectNorm: subjectNorm,
                superseded: superseded,
                deviceId: deviceId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String accountId,
                required String messageIdHash,
                Value<String?> decisionId = const Value.absent(),
                required String kind,
                required double weight,
                Value<String?> predictedFolder = const Value.absent(),
                required String actualFolder,
                Value<String?> fromAddress = const Value.absent(),
                Value<String?> fromDomain = const Value.absent(),
                Value<String?> listId = const Value.absent(),
                Value<String?> subjectNorm = const Value.absent(),
                Value<bool> superseded = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => CorrectionsCompanion.insert(
                id: id,
                accountId: accountId,
                messageIdHash: messageIdHash,
                decisionId: decisionId,
                kind: kind,
                weight: weight,
                predictedFolder: predictedFolder,
                actualFolder: actualFolder,
                fromAddress: fromAddress,
                fromDomain: fromDomain,
                listId: listId,
                subjectNorm: subjectNorm,
                superseded: superseded,
                deviceId: deviceId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CorrectionsTable, Correction>(table),
                  BaseReferences<
                    _$SortieDatabase,
                    $CorrectionsTable,
                    Correction
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CorrectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$SortieDatabase,
      $CorrectionsTable,
      Correction,
      $$CorrectionsTableFilterComposer,
      $$CorrectionsTableOrderingComposer,
      $$CorrectionsTableAnnotationComposer,
      $$CorrectionsTableCreateCompanionBuilder,
      $$CorrectionsTableUpdateCompanionBuilder,
      (
        Correction,
        BaseReferences<_$SortieDatabase, $CorrectionsTable, Correction>,
      ),
      Correction,
      PrefetchHooks Function()
    >;
typedef $$FolderProfilesTableCreateCompanionBuilder =
    FolderProfilesCompanion Function({
      required String accountId,
      required String path,
      required String name,
      Value<String?> specialUse,
      Value<bool> neverSort,
      Value<String> neverSortSource,
      Value<String?> description,
      Value<String> descriptionSource,
      Value<String> topSendersJson,
      Value<String> topListIdsJson,
      Value<String> topDomainsJson,
      Value<String> sampleSubjectsJson,
      Value<int> messageCount,
      Value<int> userFiledCount,
      Value<int?> lastUserFiledAt,
      Value<int> profileVersion,
      Value<String?> renderedText,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$FolderProfilesTableUpdateCompanionBuilder =
    FolderProfilesCompanion Function({
      Value<String> accountId,
      Value<String> path,
      Value<String> name,
      Value<String?> specialUse,
      Value<bool> neverSort,
      Value<String> neverSortSource,
      Value<String?> description,
      Value<String> descriptionSource,
      Value<String> topSendersJson,
      Value<String> topListIdsJson,
      Value<String> topDomainsJson,
      Value<String> sampleSubjectsJson,
      Value<int> messageCount,
      Value<int> userFiledCount,
      Value<int?> lastUserFiledAt,
      Value<int> profileVersion,
      Value<String?> renderedText,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$FolderProfilesTableFilterComposer
    extends Composer<_$SortieDatabase, $FolderProfilesTable> {
  $$FolderProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get specialUse => $composableBuilder(
    column: $table.specialUse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get neverSort => $composableBuilder(
    column: $table.neverSort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get neverSortSource => $composableBuilder(
    column: $table.neverSortSource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descriptionSource => $composableBuilder(
    column: $table.descriptionSource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topSendersJson => $composableBuilder(
    column: $table.topSendersJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topListIdsJson => $composableBuilder(
    column: $table.topListIdsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topDomainsJson => $composableBuilder(
    column: $table.topDomainsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sampleSubjectsJson => $composableBuilder(
    column: $table.sampleSubjectsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get messageCount => $composableBuilder(
    column: $table.messageCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userFiledCount => $composableBuilder(
    column: $table.userFiledCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastUserFiledAt => $composableBuilder(
    column: $table.lastUserFiledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get profileVersion => $composableBuilder(
    column: $table.profileVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get renderedText => $composableBuilder(
    column: $table.renderedText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FolderProfilesTableOrderingComposer
    extends Composer<_$SortieDatabase, $FolderProfilesTable> {
  $$FolderProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get specialUse => $composableBuilder(
    column: $table.specialUse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get neverSort => $composableBuilder(
    column: $table.neverSort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get neverSortSource => $composableBuilder(
    column: $table.neverSortSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descriptionSource => $composableBuilder(
    column: $table.descriptionSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topSendersJson => $composableBuilder(
    column: $table.topSendersJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topListIdsJson => $composableBuilder(
    column: $table.topListIdsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topDomainsJson => $composableBuilder(
    column: $table.topDomainsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sampleSubjectsJson => $composableBuilder(
    column: $table.sampleSubjectsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get messageCount => $composableBuilder(
    column: $table.messageCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userFiledCount => $composableBuilder(
    column: $table.userFiledCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastUserFiledAt => $composableBuilder(
    column: $table.lastUserFiledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get profileVersion => $composableBuilder(
    column: $table.profileVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get renderedText => $composableBuilder(
    column: $table.renderedText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FolderProfilesTableAnnotationComposer
    extends Composer<_$SortieDatabase, $FolderProfilesTable> {
  $$FolderProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get specialUse => $composableBuilder(
    column: $table.specialUse,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get neverSort =>
      $composableBuilder(column: $table.neverSort, builder: (column) => column);

  GeneratedColumn<String> get neverSortSource => $composableBuilder(
    column: $table.neverSortSource,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get descriptionSource => $composableBuilder(
    column: $table.descriptionSource,
    builder: (column) => column,
  );

  GeneratedColumn<String> get topSendersJson => $composableBuilder(
    column: $table.topSendersJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get topListIdsJson => $composableBuilder(
    column: $table.topListIdsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get topDomainsJson => $composableBuilder(
    column: $table.topDomainsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sampleSubjectsJson => $composableBuilder(
    column: $table.sampleSubjectsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get messageCount => $composableBuilder(
    column: $table.messageCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get userFiledCount => $composableBuilder(
    column: $table.userFiledCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastUserFiledAt => $composableBuilder(
    column: $table.lastUserFiledAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get profileVersion => $composableBuilder(
    column: $table.profileVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get renderedText => $composableBuilder(
    column: $table.renderedText,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$FolderProfilesTableTableManager
    extends
        RootTableManager<
          _$SortieDatabase,
          $FolderProfilesTable,
          FolderProfile,
          $$FolderProfilesTableFilterComposer,
          $$FolderProfilesTableOrderingComposer,
          $$FolderProfilesTableAnnotationComposer,
          $$FolderProfilesTableCreateCompanionBuilder,
          $$FolderProfilesTableUpdateCompanionBuilder,
          (
            FolderProfile,
            BaseReferences<
              _$SortieDatabase,
              $FolderProfilesTable,
              FolderProfile
            >,
          ),
          FolderProfile,
          PrefetchHooks Function()
        > {
  $$FolderProfilesTableTableManager(
    _$SortieDatabase db,
    $FolderProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FolderProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FolderProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FolderProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> specialUse = const Value.absent(),
                Value<bool> neverSort = const Value.absent(),
                Value<String> neverSortSource = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> descriptionSource = const Value.absent(),
                Value<String> topSendersJson = const Value.absent(),
                Value<String> topListIdsJson = const Value.absent(),
                Value<String> topDomainsJson = const Value.absent(),
                Value<String> sampleSubjectsJson = const Value.absent(),
                Value<int> messageCount = const Value.absent(),
                Value<int> userFiledCount = const Value.absent(),
                Value<int?> lastUserFiledAt = const Value.absent(),
                Value<int> profileVersion = const Value.absent(),
                Value<String?> renderedText = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FolderProfilesCompanion(
                accountId: accountId,
                path: path,
                name: name,
                specialUse: specialUse,
                neverSort: neverSort,
                neverSortSource: neverSortSource,
                description: description,
                descriptionSource: descriptionSource,
                topSendersJson: topSendersJson,
                topListIdsJson: topListIdsJson,
                topDomainsJson: topDomainsJson,
                sampleSubjectsJson: sampleSubjectsJson,
                messageCount: messageCount,
                userFiledCount: userFiledCount,
                lastUserFiledAt: lastUserFiledAt,
                profileVersion: profileVersion,
                renderedText: renderedText,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required String path,
                required String name,
                Value<String?> specialUse = const Value.absent(),
                Value<bool> neverSort = const Value.absent(),
                Value<String> neverSortSource = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> descriptionSource = const Value.absent(),
                Value<String> topSendersJson = const Value.absent(),
                Value<String> topListIdsJson = const Value.absent(),
                Value<String> topDomainsJson = const Value.absent(),
                Value<String> sampleSubjectsJson = const Value.absent(),
                Value<int> messageCount = const Value.absent(),
                Value<int> userFiledCount = const Value.absent(),
                Value<int?> lastUserFiledAt = const Value.absent(),
                Value<int> profileVersion = const Value.absent(),
                Value<String?> renderedText = const Value.absent(),
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => FolderProfilesCompanion.insert(
                accountId: accountId,
                path: path,
                name: name,
                specialUse: specialUse,
                neverSort: neverSort,
                neverSortSource: neverSortSource,
                description: description,
                descriptionSource: descriptionSource,
                topSendersJson: topSendersJson,
                topListIdsJson: topListIdsJson,
                topDomainsJson: topDomainsJson,
                sampleSubjectsJson: sampleSubjectsJson,
                messageCount: messageCount,
                userFiledCount: userFiledCount,
                lastUserFiledAt: lastUserFiledAt,
                profileVersion: profileVersion,
                renderedText: renderedText,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FolderProfilesTable, FolderProfile>(table),
                  BaseReferences<
                    _$SortieDatabase,
                    $FolderProfilesTable,
                    FolderProfile
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FolderProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$SortieDatabase,
      $FolderProfilesTable,
      FolderProfile,
      $$FolderProfilesTableFilterComposer,
      $$FolderProfilesTableOrderingComposer,
      $$FolderProfilesTableAnnotationComposer,
      $$FolderProfilesTableCreateCompanionBuilder,
      $$FolderProfilesTableUpdateCompanionBuilder,
      (
        FolderProfile,
        BaseReferences<_$SortieDatabase, $FolderProfilesTable, FolderProfile>,
      ),
      FolderProfile,
      PrefetchHooks Function()
    >;
typedef $$FolderProfileHistoryTableCreateCompanionBuilder =
    FolderProfileHistoryCompanion Function({
      required String accountId,
      required String path,
      required int profileVersion,
      required String renderedText,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$FolderProfileHistoryTableUpdateCompanionBuilder =
    FolderProfileHistoryCompanion Function({
      Value<String> accountId,
      Value<String> path,
      Value<int> profileVersion,
      Value<String> renderedText,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$FolderProfileHistoryTableFilterComposer
    extends Composer<_$SortieDatabase, $FolderProfileHistoryTable> {
  $$FolderProfileHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get profileVersion => $composableBuilder(
    column: $table.profileVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get renderedText => $composableBuilder(
    column: $table.renderedText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FolderProfileHistoryTableOrderingComposer
    extends Composer<_$SortieDatabase, $FolderProfileHistoryTable> {
  $$FolderProfileHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get profileVersion => $composableBuilder(
    column: $table.profileVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get renderedText => $composableBuilder(
    column: $table.renderedText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FolderProfileHistoryTableAnnotationComposer
    extends Composer<_$SortieDatabase, $FolderProfileHistoryTable> {
  $$FolderProfileHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<int> get profileVersion => $composableBuilder(
    column: $table.profileVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get renderedText => $composableBuilder(
    column: $table.renderedText,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$FolderProfileHistoryTableTableManager
    extends
        RootTableManager<
          _$SortieDatabase,
          $FolderProfileHistoryTable,
          FolderProfileHistoryData,
          $$FolderProfileHistoryTableFilterComposer,
          $$FolderProfileHistoryTableOrderingComposer,
          $$FolderProfileHistoryTableAnnotationComposer,
          $$FolderProfileHistoryTableCreateCompanionBuilder,
          $$FolderProfileHistoryTableUpdateCompanionBuilder,
          (
            FolderProfileHistoryData,
            BaseReferences<
              _$SortieDatabase,
              $FolderProfileHistoryTable,
              FolderProfileHistoryData
            >,
          ),
          FolderProfileHistoryData,
          PrefetchHooks Function()
        > {
  $$FolderProfileHistoryTableTableManager(
    _$SortieDatabase db,
    $FolderProfileHistoryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FolderProfileHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FolderProfileHistoryTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$FolderProfileHistoryTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<int> profileVersion = const Value.absent(),
                Value<String> renderedText = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FolderProfileHistoryCompanion(
                accountId: accountId,
                path: path,
                profileVersion: profileVersion,
                renderedText: renderedText,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required String path,
                required int profileVersion,
                required String renderedText,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => FolderProfileHistoryCompanion.insert(
                accountId: accountId,
                path: path,
                profileVersion: profileVersion,
                renderedText: renderedText,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $FolderProfileHistoryTable,
                    FolderProfileHistoryData
                  >(table),
                  BaseReferences<
                    _$SortieDatabase,
                    $FolderProfileHistoryTable,
                    FolderProfileHistoryData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FolderProfileHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$SortieDatabase,
      $FolderProfileHistoryTable,
      FolderProfileHistoryData,
      $$FolderProfileHistoryTableFilterComposer,
      $$FolderProfileHistoryTableOrderingComposer,
      $$FolderProfileHistoryTableAnnotationComposer,
      $$FolderProfileHistoryTableCreateCompanionBuilder,
      $$FolderProfileHistoryTableUpdateCompanionBuilder,
      (
        FolderProfileHistoryData,
        BaseReferences<
          _$SortieDatabase,
          $FolderProfileHistoryTable,
          FolderProfileHistoryData
        >,
      ),
      FolderProfileHistoryData,
      PrefetchHooks Function()
    >;
typedef $$SenderStatsTableCreateCompanionBuilder =
    SenderStatsCompanion Function({
      required String accountId,
      required String keyKind,
      required String key,
      required String folderPath,
      Value<double> count,
      Value<double> weightedCount,
      Value<int> countAgainst,
      Value<int?> firstSeenAt,
      Value<int?> lastUserAt,
      Value<int> rowid,
    });
typedef $$SenderStatsTableUpdateCompanionBuilder =
    SenderStatsCompanion Function({
      Value<String> accountId,
      Value<String> keyKind,
      Value<String> key,
      Value<String> folderPath,
      Value<double> count,
      Value<double> weightedCount,
      Value<int> countAgainst,
      Value<int?> firstSeenAt,
      Value<int?> lastUserAt,
      Value<int> rowid,
    });

class $$SenderStatsTableFilterComposer
    extends Composer<_$SortieDatabase, $SenderStatsTable> {
  $$SenderStatsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keyKind => $composableBuilder(
    column: $table.keyKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folderPath => $composableBuilder(
    column: $table.folderPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightedCount => $composableBuilder(
    column: $table.weightedCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get countAgainst => $composableBuilder(
    column: $table.countAgainst,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get firstSeenAt => $composableBuilder(
    column: $table.firstSeenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastUserAt => $composableBuilder(
    column: $table.lastUserAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SenderStatsTableOrderingComposer
    extends Composer<_$SortieDatabase, $SenderStatsTable> {
  $$SenderStatsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keyKind => $composableBuilder(
    column: $table.keyKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folderPath => $composableBuilder(
    column: $table.folderPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightedCount => $composableBuilder(
    column: $table.weightedCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get countAgainst => $composableBuilder(
    column: $table.countAgainst,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get firstSeenAt => $composableBuilder(
    column: $table.firstSeenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastUserAt => $composableBuilder(
    column: $table.lastUserAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SenderStatsTableAnnotationComposer
    extends Composer<_$SortieDatabase, $SenderStatsTable> {
  $$SenderStatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get keyKind =>
      $composableBuilder(column: $table.keyKind, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get folderPath => $composableBuilder(
    column: $table.folderPath,
    builder: (column) => column,
  );

  GeneratedColumn<double> get count =>
      $composableBuilder(column: $table.count, builder: (column) => column);

  GeneratedColumn<double> get weightedCount => $composableBuilder(
    column: $table.weightedCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get countAgainst => $composableBuilder(
    column: $table.countAgainst,
    builder: (column) => column,
  );

  GeneratedColumn<int> get firstSeenAt => $composableBuilder(
    column: $table.firstSeenAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastUserAt => $composableBuilder(
    column: $table.lastUserAt,
    builder: (column) => column,
  );
}

class $$SenderStatsTableTableManager
    extends
        RootTableManager<
          _$SortieDatabase,
          $SenderStatsTable,
          SenderStat,
          $$SenderStatsTableFilterComposer,
          $$SenderStatsTableOrderingComposer,
          $$SenderStatsTableAnnotationComposer,
          $$SenderStatsTableCreateCompanionBuilder,
          $$SenderStatsTableUpdateCompanionBuilder,
          (
            SenderStat,
            BaseReferences<_$SortieDatabase, $SenderStatsTable, SenderStat>,
          ),
          SenderStat,
          PrefetchHooks Function()
        > {
  $$SenderStatsTableTableManager(_$SortieDatabase db, $SenderStatsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SenderStatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SenderStatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SenderStatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<String> keyKind = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> folderPath = const Value.absent(),
                Value<double> count = const Value.absent(),
                Value<double> weightedCount = const Value.absent(),
                Value<int> countAgainst = const Value.absent(),
                Value<int?> firstSeenAt = const Value.absent(),
                Value<int?> lastUserAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SenderStatsCompanion(
                accountId: accountId,
                keyKind: keyKind,
                key: key,
                folderPath: folderPath,
                count: count,
                weightedCount: weightedCount,
                countAgainst: countAgainst,
                firstSeenAt: firstSeenAt,
                lastUserAt: lastUserAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required String keyKind,
                required String key,
                required String folderPath,
                Value<double> count = const Value.absent(),
                Value<double> weightedCount = const Value.absent(),
                Value<int> countAgainst = const Value.absent(),
                Value<int?> firstSeenAt = const Value.absent(),
                Value<int?> lastUserAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SenderStatsCompanion.insert(
                accountId: accountId,
                keyKind: keyKind,
                key: key,
                folderPath: folderPath,
                count: count,
                weightedCount: weightedCount,
                countAgainst: countAgainst,
                firstSeenAt: firstSeenAt,
                lastUserAt: lastUserAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SenderStatsTable, SenderStat>(table),
                  BaseReferences<
                    _$SortieDatabase,
                    $SenderStatsTable,
                    SenderStat
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SenderStatsTableProcessedTableManager =
    ProcessedTableManager<
      _$SortieDatabase,
      $SenderStatsTable,
      SenderStat,
      $$SenderStatsTableFilterComposer,
      $$SenderStatsTableOrderingComposer,
      $$SenderStatsTableAnnotationComposer,
      $$SenderStatsTableCreateCompanionBuilder,
      $$SenderStatsTableUpdateCompanionBuilder,
      (
        SenderStat,
        BaseReferences<_$SortieDatabase, $SenderStatsTable, SenderStat>,
      ),
      SenderStat,
      PrefetchHooks Function()
    >;
typedef $$UserRulesTableCreateCompanionBuilder = UserRulesCompanion Function({
  required String id,
  required String accountId,
  required int priority,
  required String matchJson,
  required String action,
  Value<String?> folderPath,
  Value<int> hits,
  required int createdAt,
  Value<int> rowid,
});
typedef $$UserRulesTableUpdateCompanionBuilder = UserRulesCompanion Function({
  Value<String> id,
  Value<String> accountId,
  Value<int> priority,
  Value<String> matchJson,
  Value<String> action,
  Value<String?> folderPath,
  Value<int> hits,
  Value<int> createdAt,
  Value<int> rowid,
});

class $$UserRulesTableFilterComposer
    extends Composer<_$SortieDatabase, $UserRulesTable> {
  $$UserRulesTableFilterComposer({
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

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get matchJson => $composableBuilder(
    column: $table.matchJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folderPath => $composableBuilder(
    column: $table.folderPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hits => $composableBuilder(
    column: $table.hits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserRulesTableOrderingComposer
    extends Composer<_$SortieDatabase, $UserRulesTable> {
  $$UserRulesTableOrderingComposer({
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

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matchJson => $composableBuilder(
    column: $table.matchJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folderPath => $composableBuilder(
    column: $table.folderPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hits => $composableBuilder(
    column: $table.hits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserRulesTableAnnotationComposer
    extends Composer<_$SortieDatabase, $UserRulesTable> {
  $$UserRulesTableAnnotationComposer({
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

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get matchJson =>
      $composableBuilder(column: $table.matchJson, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get folderPath => $composableBuilder(
    column: $table.folderPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get hits =>
      $composableBuilder(column: $table.hits, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$UserRulesTableTableManager
    extends
        RootTableManager<
          _$SortieDatabase,
          $UserRulesTable,
          UserRule,
          $$UserRulesTableFilterComposer,
          $$UserRulesTableOrderingComposer,
          $$UserRulesTableAnnotationComposer,
          $$UserRulesTableCreateCompanionBuilder,
          $$UserRulesTableUpdateCompanionBuilder,
          (
            UserRule,
            BaseReferences<_$SortieDatabase, $UserRulesTable, UserRule>,
          ),
          UserRule,
          PrefetchHooks Function()
        > {
  $$UserRulesTableTableManager(_$SortieDatabase db, $UserRulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserRulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserRulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<String> matchJson = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String?> folderPath = const Value.absent(),
                Value<int> hits = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserRulesCompanion(
                id: id,
                accountId: accountId,
                priority: priority,
                matchJson: matchJson,
                action: action,
                folderPath: folderPath,
                hits: hits,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String accountId,
                required int priority,
                required String matchJson,
                required String action,
                Value<String?> folderPath = const Value.absent(),
                Value<int> hits = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => UserRulesCompanion.insert(
                id: id,
                accountId: accountId,
                priority: priority,
                matchJson: matchJson,
                action: action,
                folderPath: folderPath,
                hits: hits,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UserRulesTable, UserRule>(table),
                  BaseReferences<_$SortieDatabase, $UserRulesTable, UserRule>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$SortieDatabase,
      $UserRulesTable,
      UserRule,
      $$UserRulesTableFilterComposer,
      $$UserRulesTableOrderingComposer,
      $$UserRulesTableAnnotationComposer,
      $$UserRulesTableCreateCompanionBuilder,
      $$UserRulesTableUpdateCompanionBuilder,
      (UserRule, BaseReferences<_$SortieDatabase, $UserRulesTable, UserRule>),
      UserRule,
      PrefetchHooks Function()
    >;
typedef $$SortQueueTableCreateCompanionBuilder = SortQueueCompanion Function({
  required String accountId,
  required String messageIdHash,
  Value<int?> uid,
  required int enqueuedAt,
  Value<int> attempts,
  Value<int?> nextAttemptAt,
  Value<String?> lastError,
  Value<int> rowid,
});
typedef $$SortQueueTableUpdateCompanionBuilder = SortQueueCompanion Function({
  Value<String> accountId,
  Value<String> messageIdHash,
  Value<int?> uid,
  Value<int> enqueuedAt,
  Value<int> attempts,
  Value<int?> nextAttemptAt,
  Value<String?> lastError,
  Value<int> rowid,
});

class $$SortQueueTableFilterComposer
    extends Composer<_$SortieDatabase, $SortQueueTable> {
  $$SortQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get messageIdHash => $composableBuilder(
    column: $table.messageIdHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get enqueuedAt => $composableBuilder(
    column: $table.enqueuedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SortQueueTableOrderingComposer
    extends Composer<_$SortieDatabase, $SortQueueTable> {
  $$SortQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messageIdHash => $composableBuilder(
    column: $table.messageIdHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get enqueuedAt => $composableBuilder(
    column: $table.enqueuedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SortQueueTableAnnotationComposer
    extends Composer<_$SortieDatabase, $SortQueueTable> {
  $$SortQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get messageIdHash => $composableBuilder(
    column: $table.messageIdHash,
    builder: (column) => column,
  );

  GeneratedColumn<int> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<int> get enqueuedAt => $composableBuilder(
    column: $table.enqueuedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$SortQueueTableTableManager
    extends
        RootTableManager<
          _$SortieDatabase,
          $SortQueueTable,
          SortQueueData,
          $$SortQueueTableFilterComposer,
          $$SortQueueTableOrderingComposer,
          $$SortQueueTableAnnotationComposer,
          $$SortQueueTableCreateCompanionBuilder,
          $$SortQueueTableUpdateCompanionBuilder,
          (
            SortQueueData,
            BaseReferences<_$SortieDatabase, $SortQueueTable, SortQueueData>,
          ),
          SortQueueData,
          PrefetchHooks Function()
        > {
  $$SortQueueTableTableManager(_$SortieDatabase db, $SortQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SortQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SortQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SortQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<String> messageIdHash = const Value.absent(),
                Value<int?> uid = const Value.absent(),
                Value<int> enqueuedAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<int?> nextAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SortQueueCompanion(
                accountId: accountId,
                messageIdHash: messageIdHash,
                uid: uid,
                enqueuedAt: enqueuedAt,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required String messageIdHash,
                Value<int?> uid = const Value.absent(),
                required int enqueuedAt,
                Value<int> attempts = const Value.absent(),
                Value<int?> nextAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SortQueueCompanion.insert(
                accountId: accountId,
                messageIdHash: messageIdHash,
                uid: uid,
                enqueuedAt: enqueuedAt,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SortQueueTable, SortQueueData>(table),
                  BaseReferences<
                    _$SortieDatabase,
                    $SortQueueTable,
                    SortQueueData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SortQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$SortieDatabase,
      $SortQueueTable,
      SortQueueData,
      $$SortQueueTableFilterComposer,
      $$SortQueueTableOrderingComposer,
      $$SortQueueTableAnnotationComposer,
      $$SortQueueTableCreateCompanionBuilder,
      $$SortQueueTableUpdateCompanionBuilder,
      (
        SortQueueData,
        BaseReferences<_$SortieDatabase, $SortQueueTable, SortQueueData>,
      ),
      SortQueueData,
      PrefetchHooks Function()
    >;
typedef $$SortEvidenceTableCreateCompanionBuilder =
    SortEvidenceCompanion Function({
      required String id,
      required String accountId,
      required String kind,
      required String messageIdHash,
      Value<String?> fromAddr,
      Value<String?> fromDomain,
      Value<String?> listId,
      Value<String?> subjectNorm,
      Value<String> examplesJson,
      Value<String?> folder,
      Value<int> seenCount,
      required int firstAt,
      required int lastAt,
      Value<int?> sentAt,
      Value<int?> consumedAt,
      Value<int> rowid,
    });
typedef $$SortEvidenceTableUpdateCompanionBuilder =
    SortEvidenceCompanion Function({
      Value<String> id,
      Value<String> accountId,
      Value<String> kind,
      Value<String> messageIdHash,
      Value<String?> fromAddr,
      Value<String?> fromDomain,
      Value<String?> listId,
      Value<String?> subjectNorm,
      Value<String> examplesJson,
      Value<String?> folder,
      Value<int> seenCount,
      Value<int> firstAt,
      Value<int> lastAt,
      Value<int?> sentAt,
      Value<int?> consumedAt,
      Value<int> rowid,
    });

class $$SortEvidenceTableFilterComposer
    extends Composer<_$SortieDatabase, $SortEvidenceTable> {
  $$SortEvidenceTableFilterComposer({
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

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get messageIdHash => $composableBuilder(
    column: $table.messageIdHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromAddr => $composableBuilder(
    column: $table.fromAddr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromDomain => $composableBuilder(
    column: $table.fromDomain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get listId => $composableBuilder(
    column: $table.listId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subjectNorm => $composableBuilder(
    column: $table.subjectNorm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get examplesJson => $composableBuilder(
    column: $table.examplesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folder => $composableBuilder(
    column: $table.folder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seenCount => $composableBuilder(
    column: $table.seenCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get firstAt => $composableBuilder(
    column: $table.firstAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastAt => $composableBuilder(
    column: $table.lastAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get consumedAt => $composableBuilder(
    column: $table.consumedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SortEvidenceTableOrderingComposer
    extends Composer<_$SortieDatabase, $SortEvidenceTable> {
  $$SortEvidenceTableOrderingComposer({
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

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messageIdHash => $composableBuilder(
    column: $table.messageIdHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromAddr => $composableBuilder(
    column: $table.fromAddr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromDomain => $composableBuilder(
    column: $table.fromDomain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get listId => $composableBuilder(
    column: $table.listId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subjectNorm => $composableBuilder(
    column: $table.subjectNorm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get examplesJson => $composableBuilder(
    column: $table.examplesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folder => $composableBuilder(
    column: $table.folder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seenCount => $composableBuilder(
    column: $table.seenCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get firstAt => $composableBuilder(
    column: $table.firstAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastAt => $composableBuilder(
    column: $table.lastAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get consumedAt => $composableBuilder(
    column: $table.consumedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SortEvidenceTableAnnotationComposer
    extends Composer<_$SortieDatabase, $SortEvidenceTable> {
  $$SortEvidenceTableAnnotationComposer({
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

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get messageIdHash => $composableBuilder(
    column: $table.messageIdHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fromAddr =>
      $composableBuilder(column: $table.fromAddr, builder: (column) => column);

  GeneratedColumn<String> get fromDomain => $composableBuilder(
    column: $table.fromDomain,
    builder: (column) => column,
  );

  GeneratedColumn<String> get listId =>
      $composableBuilder(column: $table.listId, builder: (column) => column);

  GeneratedColumn<String> get subjectNorm => $composableBuilder(
    column: $table.subjectNorm,
    builder: (column) => column,
  );

  GeneratedColumn<String> get examplesJson => $composableBuilder(
    column: $table.examplesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get folder =>
      $composableBuilder(column: $table.folder, builder: (column) => column);

  GeneratedColumn<int> get seenCount =>
      $composableBuilder(column: $table.seenCount, builder: (column) => column);

  GeneratedColumn<int> get firstAt =>
      $composableBuilder(column: $table.firstAt, builder: (column) => column);

  GeneratedColumn<int> get lastAt =>
      $composableBuilder(column: $table.lastAt, builder: (column) => column);

  GeneratedColumn<int> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);

  GeneratedColumn<int> get consumedAt => $composableBuilder(
    column: $table.consumedAt,
    builder: (column) => column,
  );
}

class $$SortEvidenceTableTableManager
    extends
        RootTableManager<
          _$SortieDatabase,
          $SortEvidenceTable,
          SortEvidenceData,
          $$SortEvidenceTableFilterComposer,
          $$SortEvidenceTableOrderingComposer,
          $$SortEvidenceTableAnnotationComposer,
          $$SortEvidenceTableCreateCompanionBuilder,
          $$SortEvidenceTableUpdateCompanionBuilder,
          (
            SortEvidenceData,
            BaseReferences<
              _$SortieDatabase,
              $SortEvidenceTable,
              SortEvidenceData
            >,
          ),
          SortEvidenceData,
          PrefetchHooks Function()
        > {
  $$SortEvidenceTableTableManager(_$SortieDatabase db, $SortEvidenceTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SortEvidenceTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SortEvidenceTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SortEvidenceTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> messageIdHash = const Value.absent(),
                Value<String?> fromAddr = const Value.absent(),
                Value<String?> fromDomain = const Value.absent(),
                Value<String?> listId = const Value.absent(),
                Value<String?> subjectNorm = const Value.absent(),
                Value<String> examplesJson = const Value.absent(),
                Value<String?> folder = const Value.absent(),
                Value<int> seenCount = const Value.absent(),
                Value<int> firstAt = const Value.absent(),
                Value<int> lastAt = const Value.absent(),
                Value<int?> sentAt = const Value.absent(),
                Value<int?> consumedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SortEvidenceCompanion(
                id: id,
                accountId: accountId,
                kind: kind,
                messageIdHash: messageIdHash,
                fromAddr: fromAddr,
                fromDomain: fromDomain,
                listId: listId,
                subjectNorm: subjectNorm,
                examplesJson: examplesJson,
                folder: folder,
                seenCount: seenCount,
                firstAt: firstAt,
                lastAt: lastAt,
                sentAt: sentAt,
                consumedAt: consumedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String accountId,
                required String kind,
                required String messageIdHash,
                Value<String?> fromAddr = const Value.absent(),
                Value<String?> fromDomain = const Value.absent(),
                Value<String?> listId = const Value.absent(),
                Value<String?> subjectNorm = const Value.absent(),
                Value<String> examplesJson = const Value.absent(),
                Value<String?> folder = const Value.absent(),
                Value<int> seenCount = const Value.absent(),
                required int firstAt,
                required int lastAt,
                Value<int?> sentAt = const Value.absent(),
                Value<int?> consumedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SortEvidenceCompanion.insert(
                id: id,
                accountId: accountId,
                kind: kind,
                messageIdHash: messageIdHash,
                fromAddr: fromAddr,
                fromDomain: fromDomain,
                listId: listId,
                subjectNorm: subjectNorm,
                examplesJson: examplesJson,
                folder: folder,
                seenCount: seenCount,
                firstAt: firstAt,
                lastAt: lastAt,
                sentAt: sentAt,
                consumedAt: consumedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SortEvidenceTable, SortEvidenceData>(table),
                  BaseReferences<
                    _$SortieDatabase,
                    $SortEvidenceTable,
                    SortEvidenceData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SortEvidenceTableProcessedTableManager =
    ProcessedTableManager<
      _$SortieDatabase,
      $SortEvidenceTable,
      SortEvidenceData,
      $$SortEvidenceTableFilterComposer,
      $$SortEvidenceTableOrderingComposer,
      $$SortEvidenceTableAnnotationComposer,
      $$SortEvidenceTableCreateCompanionBuilder,
      $$SortEvidenceTableUpdateCompanionBuilder,
      (
        SortEvidenceData,
        BaseReferences<_$SortieDatabase, $SortEvidenceTable, SortEvidenceData>,
      ),
      SortEvidenceData,
      PrefetchHooks Function()
    >;
typedef $$RuleSuggestionsTableCreateCompanionBuilder =
    RuleSuggestionsCompanion Function({
      required String id,
      required String accountId,
      required String matchJson,
      required String folderPath,
      Value<String> rationale,
      required double confidence,
      required String source,
      Value<int> evidenceCount,
      Value<String> examplesJson,
      Value<String> status,
      required int createdAt,
      Value<int?> decidedAt,
      Value<int> rowid,
    });
typedef $$RuleSuggestionsTableUpdateCompanionBuilder =
    RuleSuggestionsCompanion Function({
      Value<String> id,
      Value<String> accountId,
      Value<String> matchJson,
      Value<String> folderPath,
      Value<String> rationale,
      Value<double> confidence,
      Value<String> source,
      Value<int> evidenceCount,
      Value<String> examplesJson,
      Value<String> status,
      Value<int> createdAt,
      Value<int?> decidedAt,
      Value<int> rowid,
    });

class $$RuleSuggestionsTableFilterComposer
    extends Composer<_$SortieDatabase, $RuleSuggestionsTable> {
  $$RuleSuggestionsTableFilterComposer({
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

  ColumnFilters<String> get matchJson => $composableBuilder(
    column: $table.matchJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folderPath => $composableBuilder(
    column: $table.folderPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rationale => $composableBuilder(
    column: $table.rationale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get evidenceCount => $composableBuilder(
    column: $table.evidenceCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get examplesJson => $composableBuilder(
    column: $table.examplesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get decidedAt => $composableBuilder(
    column: $table.decidedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RuleSuggestionsTableOrderingComposer
    extends Composer<_$SortieDatabase, $RuleSuggestionsTable> {
  $$RuleSuggestionsTableOrderingComposer({
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

  ColumnOrderings<String> get matchJson => $composableBuilder(
    column: $table.matchJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folderPath => $composableBuilder(
    column: $table.folderPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rationale => $composableBuilder(
    column: $table.rationale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get evidenceCount => $composableBuilder(
    column: $table.evidenceCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get examplesJson => $composableBuilder(
    column: $table.examplesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get decidedAt => $composableBuilder(
    column: $table.decidedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RuleSuggestionsTableAnnotationComposer
    extends Composer<_$SortieDatabase, $RuleSuggestionsTable> {
  $$RuleSuggestionsTableAnnotationComposer({
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

  GeneratedColumn<String> get matchJson =>
      $composableBuilder(column: $table.matchJson, builder: (column) => column);

  GeneratedColumn<String> get folderPath => $composableBuilder(
    column: $table.folderPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rationale =>
      $composableBuilder(column: $table.rationale, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<int> get evidenceCount => $composableBuilder(
    column: $table.evidenceCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get examplesJson => $composableBuilder(
    column: $table.examplesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get decidedAt =>
      $composableBuilder(column: $table.decidedAt, builder: (column) => column);
}

class $$RuleSuggestionsTableTableManager
    extends
        RootTableManager<
          _$SortieDatabase,
          $RuleSuggestionsTable,
          RuleSuggestion,
          $$RuleSuggestionsTableFilterComposer,
          $$RuleSuggestionsTableOrderingComposer,
          $$RuleSuggestionsTableAnnotationComposer,
          $$RuleSuggestionsTableCreateCompanionBuilder,
          $$RuleSuggestionsTableUpdateCompanionBuilder,
          (
            RuleSuggestion,
            BaseReferences<
              _$SortieDatabase,
              $RuleSuggestionsTable,
              RuleSuggestion
            >,
          ),
          RuleSuggestion,
          PrefetchHooks Function()
        > {
  $$RuleSuggestionsTableTableManager(
    _$SortieDatabase db,
    $RuleSuggestionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RuleSuggestionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RuleSuggestionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RuleSuggestionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> matchJson = const Value.absent(),
                Value<String> folderPath = const Value.absent(),
                Value<String> rationale = const Value.absent(),
                Value<double> confidence = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> evidenceCount = const Value.absent(),
                Value<String> examplesJson = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> decidedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RuleSuggestionsCompanion(
                id: id,
                accountId: accountId,
                matchJson: matchJson,
                folderPath: folderPath,
                rationale: rationale,
                confidence: confidence,
                source: source,
                evidenceCount: evidenceCount,
                examplesJson: examplesJson,
                status: status,
                createdAt: createdAt,
                decidedAt: decidedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String accountId,
                required String matchJson,
                required String folderPath,
                Value<String> rationale = const Value.absent(),
                required double confidence,
                required String source,
                Value<int> evidenceCount = const Value.absent(),
                Value<String> examplesJson = const Value.absent(),
                Value<String> status = const Value.absent(),
                required int createdAt,
                Value<int?> decidedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RuleSuggestionsCompanion.insert(
                id: id,
                accountId: accountId,
                matchJson: matchJson,
                folderPath: folderPath,
                rationale: rationale,
                confidence: confidence,
                source: source,
                evidenceCount: evidenceCount,
                examplesJson: examplesJson,
                status: status,
                createdAt: createdAt,
                decidedAt: decidedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RuleSuggestionsTable, RuleSuggestion>(table),
                  BaseReferences<
                    _$SortieDatabase,
                    $RuleSuggestionsTable,
                    RuleSuggestion
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RuleSuggestionsTableProcessedTableManager =
    ProcessedTableManager<
      _$SortieDatabase,
      $RuleSuggestionsTable,
      RuleSuggestion,
      $$RuleSuggestionsTableFilterComposer,
      $$RuleSuggestionsTableOrderingComposer,
      $$RuleSuggestionsTableAnnotationComposer,
      $$RuleSuggestionsTableCreateCompanionBuilder,
      $$RuleSuggestionsTableUpdateCompanionBuilder,
      (
        RuleSuggestion,
        BaseReferences<_$SortieDatabase, $RuleSuggestionsTable, RuleSuggestion>,
      ),
      RuleSuggestion,
      PrefetchHooks Function()
    >;
typedef $$AiUsageTableCreateCompanionBuilder = AiUsageCompanion Function({
  Value<int> id,
  required int ts,
  Value<String?> provider,
  Value<String?> modelId,
  required String kind,
  Value<int> inputTokens,
  Value<int> cacheReadTokens,
  Value<int> cacheWriteTokens,
  Value<int> outputTokens,
  required double costUsd,
  Value<String?> batchId,
});
typedef $$AiUsageTableUpdateCompanionBuilder = AiUsageCompanion Function({
  Value<int> id,
  Value<int> ts,
  Value<String?> provider,
  Value<String?> modelId,
  Value<String> kind,
  Value<int> inputTokens,
  Value<int> cacheReadTokens,
  Value<int> cacheWriteTokens,
  Value<int> outputTokens,
  Value<double> costUsd,
  Value<String?> batchId,
});

class $$AiUsageTableFilterComposer
    extends Composer<_$SortieDatabase, $AiUsageTable> {
  $$AiUsageTableFilterComposer({
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

  ColumnFilters<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get inputTokens => $composableBuilder(
    column: $table.inputTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cacheReadTokens => $composableBuilder(
    column: $table.cacheReadTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cacheWriteTokens => $composableBuilder(
    column: $table.cacheWriteTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get outputTokens => $composableBuilder(
    column: $table.outputTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get costUsd => $composableBuilder(
    column: $table.costUsd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AiUsageTableOrderingComposer
    extends Composer<_$SortieDatabase, $AiUsageTable> {
  $$AiUsageTableOrderingComposer({
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

  ColumnOrderings<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelId => $composableBuilder(
    column: $table.modelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get inputTokens => $composableBuilder(
    column: $table.inputTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cacheReadTokens => $composableBuilder(
    column: $table.cacheReadTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cacheWriteTokens => $composableBuilder(
    column: $table.cacheWriteTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get outputTokens => $composableBuilder(
    column: $table.outputTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get costUsd => $composableBuilder(
    column: $table.costUsd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AiUsageTableAnnotationComposer
    extends Composer<_$SortieDatabase, $AiUsageTable> {
  $$AiUsageTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get ts =>
      $composableBuilder(column: $table.ts, builder: (column) => column);

  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<String> get modelId =>
      $composableBuilder(column: $table.modelId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get inputTokens => $composableBuilder(
    column: $table.inputTokens,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cacheReadTokens => $composableBuilder(
    column: $table.cacheReadTokens,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cacheWriteTokens => $composableBuilder(
    column: $table.cacheWriteTokens,
    builder: (column) => column,
  );

  GeneratedColumn<int> get outputTokens => $composableBuilder(
    column: $table.outputTokens,
    builder: (column) => column,
  );

  GeneratedColumn<double> get costUsd =>
      $composableBuilder(column: $table.costUsd, builder: (column) => column);

  GeneratedColumn<String> get batchId =>
      $composableBuilder(column: $table.batchId, builder: (column) => column);
}

class $$AiUsageTableTableManager
    extends
        RootTableManager<
          _$SortieDatabase,
          $AiUsageTable,
          AiUsageData,
          $$AiUsageTableFilterComposer,
          $$AiUsageTableOrderingComposer,
          $$AiUsageTableAnnotationComposer,
          $$AiUsageTableCreateCompanionBuilder,
          $$AiUsageTableUpdateCompanionBuilder,
          (
            AiUsageData,
            BaseReferences<_$SortieDatabase, $AiUsageTable, AiUsageData>,
          ),
          AiUsageData,
          PrefetchHooks Function()
        > {
  $$AiUsageTableTableManager(_$SortieDatabase db, $AiUsageTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AiUsageTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AiUsageTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AiUsageTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> ts = const Value.absent(),
                Value<String?> provider = const Value.absent(),
                Value<String?> modelId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> inputTokens = const Value.absent(),
                Value<int> cacheReadTokens = const Value.absent(),
                Value<int> cacheWriteTokens = const Value.absent(),
                Value<int> outputTokens = const Value.absent(),
                Value<double> costUsd = const Value.absent(),
                Value<String?> batchId = const Value.absent(),
              }) => AiUsageCompanion(
                id: id,
                ts: ts,
                provider: provider,
                modelId: modelId,
                kind: kind,
                inputTokens: inputTokens,
                cacheReadTokens: cacheReadTokens,
                cacheWriteTokens: cacheWriteTokens,
                outputTokens: outputTokens,
                costUsd: costUsd,
                batchId: batchId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int ts,
                Value<String?> provider = const Value.absent(),
                Value<String?> modelId = const Value.absent(),
                required String kind,
                Value<int> inputTokens = const Value.absent(),
                Value<int> cacheReadTokens = const Value.absent(),
                Value<int> cacheWriteTokens = const Value.absent(),
                Value<int> outputTokens = const Value.absent(),
                required double costUsd,
                Value<String?> batchId = const Value.absent(),
              }) => AiUsageCompanion.insert(
                id: id,
                ts: ts,
                provider: provider,
                modelId: modelId,
                kind: kind,
                inputTokens: inputTokens,
                cacheReadTokens: cacheReadTokens,
                cacheWriteTokens: cacheWriteTokens,
                outputTokens: outputTokens,
                costUsd: costUsd,
                batchId: batchId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AiUsageTable, AiUsageData>(table),
                  BaseReferences<_$SortieDatabase, $AiUsageTable, AiUsageData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AiUsageTableProcessedTableManager =
    ProcessedTableManager<
      _$SortieDatabase,
      $AiUsageTable,
      AiUsageData,
      $$AiUsageTableFilterComposer,
      $$AiUsageTableOrderingComposer,
      $$AiUsageTableAnnotationComposer,
      $$AiUsageTableCreateCompanionBuilder,
      $$AiUsageTableUpdateCompanionBuilder,
      (
        AiUsageData,
        BaseReferences<_$SortieDatabase, $AiUsageTable, AiUsageData>,
      ),
      AiUsageData,
      PrefetchHooks Function()
    >;
typedef $$JournalEventsTableCreateCompanionBuilder =
    JournalEventsCompanion Function({
      required String accountId,
      required int uid,
      required String type,
      required String deviceId,
      Value<int?> epoch,
      required int internalDate,
      required String bodyJson,
      Value<int> rowid,
    });
typedef $$JournalEventsTableUpdateCompanionBuilder =
    JournalEventsCompanion Function({
      Value<String> accountId,
      Value<int> uid,
      Value<String> type,
      Value<String> deviceId,
      Value<int?> epoch,
      Value<int> internalDate,
      Value<String> bodyJson,
      Value<int> rowid,
    });

class $$JournalEventsTableFilterComposer
    extends Composer<_$SortieDatabase, $JournalEventsTable> {
  $$JournalEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get epoch => $composableBuilder(
    column: $table.epoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get internalDate => $composableBuilder(
    column: $table.internalDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bodyJson => $composableBuilder(
    column: $table.bodyJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JournalEventsTableOrderingComposer
    extends Composer<_$SortieDatabase, $JournalEventsTable> {
  $$JournalEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get epoch => $composableBuilder(
    column: $table.epoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get internalDate => $composableBuilder(
    column: $table.internalDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bodyJson => $composableBuilder(
    column: $table.bodyJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JournalEventsTableAnnotationComposer
    extends Composer<_$SortieDatabase, $JournalEventsTable> {
  $$JournalEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<int> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get epoch =>
      $composableBuilder(column: $table.epoch, builder: (column) => column);

  GeneratedColumn<int> get internalDate => $composableBuilder(
    column: $table.internalDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bodyJson =>
      $composableBuilder(column: $table.bodyJson, builder: (column) => column);
}

class $$JournalEventsTableTableManager
    extends
        RootTableManager<
          _$SortieDatabase,
          $JournalEventsTable,
          JournalEvent,
          $$JournalEventsTableFilterComposer,
          $$JournalEventsTableOrderingComposer,
          $$JournalEventsTableAnnotationComposer,
          $$JournalEventsTableCreateCompanionBuilder,
          $$JournalEventsTableUpdateCompanionBuilder,
          (
            JournalEvent,
            BaseReferences<_$SortieDatabase, $JournalEventsTable, JournalEvent>,
          ),
          JournalEvent,
          PrefetchHooks Function()
        > {
  $$JournalEventsTableTableManager(
    _$SortieDatabase db,
    $JournalEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JournalEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JournalEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JournalEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<int> uid = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int?> epoch = const Value.absent(),
                Value<int> internalDate = const Value.absent(),
                Value<String> bodyJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JournalEventsCompanion(
                accountId: accountId,
                uid: uid,
                type: type,
                deviceId: deviceId,
                epoch: epoch,
                internalDate: internalDate,
                bodyJson: bodyJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required int uid,
                required String type,
                required String deviceId,
                Value<int?> epoch = const Value.absent(),
                required int internalDate,
                required String bodyJson,
                Value<int> rowid = const Value.absent(),
              }) => JournalEventsCompanion.insert(
                accountId: accountId,
                uid: uid,
                type: type,
                deviceId: deviceId,
                epoch: epoch,
                internalDate: internalDate,
                bodyJson: bodyJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$JournalEventsTable, JournalEvent>(table),
                  BaseReferences<
                    _$SortieDatabase,
                    $JournalEventsTable,
                    JournalEvent
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JournalEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$SortieDatabase,
      $JournalEventsTable,
      JournalEvent,
      $$JournalEventsTableFilterComposer,
      $$JournalEventsTableOrderingComposer,
      $$JournalEventsTableAnnotationComposer,
      $$JournalEventsTableCreateCompanionBuilder,
      $$JournalEventsTableUpdateCompanionBuilder,
      (
        JournalEvent,
        BaseReferences<_$SortieDatabase, $JournalEventsTable, JournalEvent>,
      ),
      JournalEvent,
      PrefetchHooks Function()
    >;
typedef $$JournalCursorsTableCreateCompanionBuilder =
    JournalCursorsCompanion Function({
      required String accountId,
      Value<int> uidValidity,
      Value<int> snapshotUid,
      Value<int> lastAppliedUid,
      Value<int> lastEpoch,
      Value<int> writerSeq,
      Value<String?> controlPath,
      Value<int> rowid,
    });
typedef $$JournalCursorsTableUpdateCompanionBuilder =
    JournalCursorsCompanion Function({
      Value<String> accountId,
      Value<int> uidValidity,
      Value<int> snapshotUid,
      Value<int> lastAppliedUid,
      Value<int> lastEpoch,
      Value<int> writerSeq,
      Value<String?> controlPath,
      Value<int> rowid,
    });

class $$JournalCursorsTableFilterComposer
    extends Composer<_$SortieDatabase, $JournalCursorsTable> {
  $$JournalCursorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get uidValidity => $composableBuilder(
    column: $table.uidValidity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get snapshotUid => $composableBuilder(
    column: $table.snapshotUid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastAppliedUid => $composableBuilder(
    column: $table.lastAppliedUid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastEpoch => $composableBuilder(
    column: $table.lastEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get writerSeq => $composableBuilder(
    column: $table.writerSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get controlPath => $composableBuilder(
    column: $table.controlPath,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JournalCursorsTableOrderingComposer
    extends Composer<_$SortieDatabase, $JournalCursorsTable> {
  $$JournalCursorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get uidValidity => $composableBuilder(
    column: $table.uidValidity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get snapshotUid => $composableBuilder(
    column: $table.snapshotUid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastAppliedUid => $composableBuilder(
    column: $table.lastAppliedUid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastEpoch => $composableBuilder(
    column: $table.lastEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get writerSeq => $composableBuilder(
    column: $table.writerSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get controlPath => $composableBuilder(
    column: $table.controlPath,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JournalCursorsTableAnnotationComposer
    extends Composer<_$SortieDatabase, $JournalCursorsTable> {
  $$JournalCursorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<int> get uidValidity => $composableBuilder(
    column: $table.uidValidity,
    builder: (column) => column,
  );

  GeneratedColumn<int> get snapshotUid => $composableBuilder(
    column: $table.snapshotUid,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastAppliedUid => $composableBuilder(
    column: $table.lastAppliedUid,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastEpoch =>
      $composableBuilder(column: $table.lastEpoch, builder: (column) => column);

  GeneratedColumn<int> get writerSeq =>
      $composableBuilder(column: $table.writerSeq, builder: (column) => column);

  GeneratedColumn<String> get controlPath => $composableBuilder(
    column: $table.controlPath,
    builder: (column) => column,
  );
}

class $$JournalCursorsTableTableManager
    extends
        RootTableManager<
          _$SortieDatabase,
          $JournalCursorsTable,
          JournalCursor,
          $$JournalCursorsTableFilterComposer,
          $$JournalCursorsTableOrderingComposer,
          $$JournalCursorsTableAnnotationComposer,
          $$JournalCursorsTableCreateCompanionBuilder,
          $$JournalCursorsTableUpdateCompanionBuilder,
          (
            JournalCursor,
            BaseReferences<
              _$SortieDatabase,
              $JournalCursorsTable,
              JournalCursor
            >,
          ),
          JournalCursor,
          PrefetchHooks Function()
        > {
  $$JournalCursorsTableTableManager(
    _$SortieDatabase db,
    $JournalCursorsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JournalCursorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JournalCursorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JournalCursorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<int> uidValidity = const Value.absent(),
                Value<int> snapshotUid = const Value.absent(),
                Value<int> lastAppliedUid = const Value.absent(),
                Value<int> lastEpoch = const Value.absent(),
                Value<int> writerSeq = const Value.absent(),
                Value<String?> controlPath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JournalCursorsCompanion(
                accountId: accountId,
                uidValidity: uidValidity,
                snapshotUid: snapshotUid,
                lastAppliedUid: lastAppliedUid,
                lastEpoch: lastEpoch,
                writerSeq: writerSeq,
                controlPath: controlPath,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                Value<int> uidValidity = const Value.absent(),
                Value<int> snapshotUid = const Value.absent(),
                Value<int> lastAppliedUid = const Value.absent(),
                Value<int> lastEpoch = const Value.absent(),
                Value<int> writerSeq = const Value.absent(),
                Value<String?> controlPath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JournalCursorsCompanion.insert(
                accountId: accountId,
                uidValidity: uidValidity,
                snapshotUid: snapshotUid,
                lastAppliedUid: lastAppliedUid,
                lastEpoch: lastEpoch,
                writerSeq: writerSeq,
                controlPath: controlPath,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$JournalCursorsTable, JournalCursor>(table),
                  BaseReferences<
                    _$SortieDatabase,
                    $JournalCursorsTable,
                    JournalCursor
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JournalCursorsTableProcessedTableManager =
    ProcessedTableManager<
      _$SortieDatabase,
      $JournalCursorsTable,
      JournalCursor,
      $$JournalCursorsTableFilterComposer,
      $$JournalCursorsTableOrderingComposer,
      $$JournalCursorsTableAnnotationComposer,
      $$JournalCursorsTableCreateCompanionBuilder,
      $$JournalCursorsTableUpdateCompanionBuilder,
      (
        JournalCursor,
        BaseReferences<_$SortieDatabase, $JournalCursorsTable, JournalCursor>,
      ),
      JournalCursor,
      PrefetchHooks Function()
    >;
typedef $$CalendarsTableCreateCompanionBuilder = CalendarsCompanion Function({
  required String id,
  required String name,
  required String kind,
  Value<String> url,
  Value<String?> username,
  required int color,
  Value<bool> enabled,
  Value<bool> readOnly,
  Value<String> authKind,
  Value<String?> googleEmail,
  Value<String?> syncToken,
  Value<String?> ctag,
  Value<String?> etag,
  Value<int?> lastSyncAt,
  Value<String?> lastError,
  Value<int> sortOrder,
  Value<int> rowid,
});
typedef $$CalendarsTableUpdateCompanionBuilder = CalendarsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> kind,
  Value<String> url,
  Value<String?> username,
  Value<int> color,
  Value<bool> enabled,
  Value<bool> readOnly,
  Value<String> authKind,
  Value<String?> googleEmail,
  Value<String?> syncToken,
  Value<String?> ctag,
  Value<String?> etag,
  Value<int?> lastSyncAt,
  Value<String?> lastError,
  Value<int> sortOrder,
  Value<int> rowid,
});

final class $$CalendarsTableReferences
    extends BaseReferences<_$SortieDatabase, $CalendarsTable, CalendarRow> {
  $$CalendarsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CalendarEventsTable, List<CalendarEventRow>>
  _calendarEventsRefsTable(_$SortieDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.calendarEvents,
        aliasName: 'calendars__id__calendar_events__calendar_id',
      );

  $$CalendarEventsTableProcessedTableManager get calendarEventsRefs {
    final manager = $$CalendarEventsTableTableManager(
      $_db,
      $_db.calendarEvents,
    ).filter((f) => f.calendarId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_calendarEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $CalendarSyncQueueTable,
    List<CalendarSyncQueueRow>
  >
  _calendarSyncQueueRefsTable(_$SortieDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.calendarSyncQueue,
        aliasName: 'calendars__id__calendar_sync_queue__calendar_id',
      );

  $$CalendarSyncQueueTableProcessedTableManager get calendarSyncQueueRefs {
    final manager = $$CalendarSyncQueueTableTableManager(
      $_db,
      $_db.calendarSyncQueue,
    ).filter((f) => f.calendarId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _calendarSyncQueueRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CalendarsTableFilterComposer
    extends Composer<_$SortieDatabase, $CalendarsTable> {
  $$CalendarsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get readOnly => $composableBuilder(
    column: $table.readOnly,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authKind => $composableBuilder(
    column: $table.authKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get googleEmail => $composableBuilder(
    column: $table.googleEmail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncToken => $composableBuilder(
    column: $table.syncToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ctag => $composableBuilder(
    column: $table.ctag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> calendarEventsRefs(
    Expression<bool> Function($$CalendarEventsTableFilterComposer f) f,
  ) {
    final $$CalendarEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.calendarEvents,
      getReferencedColumn: (t) => t.calendarId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalendarEventsTableFilterComposer(
            $db: $db,
            $table: $db.calendarEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> calendarSyncQueueRefs(
    Expression<bool> Function($$CalendarSyncQueueTableFilterComposer f) f,
  ) {
    final $$CalendarSyncQueueTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.calendarSyncQueue,
      getReferencedColumn: (t) => t.calendarId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalendarSyncQueueTableFilterComposer(
            $db: $db,
            $table: $db.calendarSyncQueue,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CalendarsTableOrderingComposer
    extends Composer<_$SortieDatabase, $CalendarsTable> {
  $$CalendarsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get readOnly => $composableBuilder(
    column: $table.readOnly,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authKind => $composableBuilder(
    column: $table.authKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get googleEmail => $composableBuilder(
    column: $table.googleEmail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncToken => $composableBuilder(
    column: $table.syncToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ctag => $composableBuilder(
    column: $table.ctag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CalendarsTableAnnotationComposer
    extends Composer<_$SortieDatabase, $CalendarsTable> {
  $$CalendarsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<bool> get readOnly =>
      $composableBuilder(column: $table.readOnly, builder: (column) => column);

  GeneratedColumn<String> get authKind =>
      $composableBuilder(column: $table.authKind, builder: (column) => column);

  GeneratedColumn<String> get googleEmail => $composableBuilder(
    column: $table.googleEmail,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncToken =>
      $composableBuilder(column: $table.syncToken, builder: (column) => column);

  GeneratedColumn<String> get ctag =>
      $composableBuilder(column: $table.ctag, builder: (column) => column);

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);

  GeneratedColumn<int> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  Expression<T> calendarEventsRefs<T extends Object>(
    Expression<T> Function($$CalendarEventsTableAnnotationComposer a) f,
  ) {
    final $$CalendarEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.calendarEvents,
      getReferencedColumn: (t) => t.calendarId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalendarEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.calendarEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> calendarSyncQueueRefs<T extends Object>(
    Expression<T> Function($$CalendarSyncQueueTableAnnotationComposer a) f,
  ) {
    final $$CalendarSyncQueueTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.calendarSyncQueue,
          getReferencedColumn: (t) => t.calendarId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CalendarSyncQueueTableAnnotationComposer(
                $db: $db,
                $table: $db.calendarSyncQueue,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CalendarsTableTableManager
    extends
        RootTableManager<
          _$SortieDatabase,
          $CalendarsTable,
          CalendarRow,
          $$CalendarsTableFilterComposer,
          $$CalendarsTableOrderingComposer,
          $$CalendarsTableAnnotationComposer,
          $$CalendarsTableCreateCompanionBuilder,
          $$CalendarsTableUpdateCompanionBuilder,
          (CalendarRow, $$CalendarsTableReferences),
          CalendarRow,
          PrefetchHooks Function({
            bool calendarEventsRefs,
            bool calendarSyncQueueRefs,
          })
        > {
  $$CalendarsTableTableManager(_$SortieDatabase db, $CalendarsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CalendarsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CalendarsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CalendarsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String?> username = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<bool> readOnly = const Value.absent(),
                Value<String> authKind = const Value.absent(),
                Value<String?> googleEmail = const Value.absent(),
                Value<String?> syncToken = const Value.absent(),
                Value<String?> ctag = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<int?> lastSyncAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CalendarsCompanion(
                id: id,
                name: name,
                kind: kind,
                url: url,
                username: username,
                color: color,
                enabled: enabled,
                readOnly: readOnly,
                authKind: authKind,
                googleEmail: googleEmail,
                syncToken: syncToken,
                ctag: ctag,
                etag: etag,
                lastSyncAt: lastSyncAt,
                lastError: lastError,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String kind,
                Value<String> url = const Value.absent(),
                Value<String?> username = const Value.absent(),
                required int color,
                Value<bool> enabled = const Value.absent(),
                Value<bool> readOnly = const Value.absent(),
                Value<String> authKind = const Value.absent(),
                Value<String?> googleEmail = const Value.absent(),
                Value<String?> syncToken = const Value.absent(),
                Value<String?> ctag = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<int?> lastSyncAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CalendarsCompanion.insert(
                id: id,
                name: name,
                kind: kind,
                url: url,
                username: username,
                color: color,
                enabled: enabled,
                readOnly: readOnly,
                authKind: authKind,
                googleEmail: googleEmail,
                syncToken: syncToken,
                ctag: ctag,
                etag: etag,
                lastSyncAt: lastSyncAt,
                lastError: lastError,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CalendarsTable, CalendarRow>(table),
                  $$CalendarsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({calendarEventsRefs = false, calendarSyncQueueRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (calendarEventsRefs) db.calendarEvents,
                    if (calendarSyncQueueRefs) db.calendarSyncQueue,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (calendarEventsRefs)
                        await $_getPrefetchedData<
                          CalendarRow,
                          $CalendarsTable,
                          CalendarEventRow
                        >(
                          currentTable: table,
                          referencedTable: $$CalendarsTableReferences
                              ._calendarEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CalendarsTableReferences(
                                db,
                                table,
                                p0,
                              ).calendarEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.calendarId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (calendarSyncQueueRefs)
                        await $_getPrefetchedData<
                          CalendarRow,
                          $CalendarsTable,
                          CalendarSyncQueueRow
                        >(
                          currentTable: table,
                          referencedTable: $$CalendarsTableReferences
                              ._calendarSyncQueueRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CalendarsTableReferences(
                                db,
                                table,
                                p0,
                              ).calendarSyncQueueRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.calendarId == item.id,
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

typedef $$CalendarsTableProcessedTableManager =
    ProcessedTableManager<
      _$SortieDatabase,
      $CalendarsTable,
      CalendarRow,
      $$CalendarsTableFilterComposer,
      $$CalendarsTableOrderingComposer,
      $$CalendarsTableAnnotationComposer,
      $$CalendarsTableCreateCompanionBuilder,
      $$CalendarsTableUpdateCompanionBuilder,
      (CalendarRow, $$CalendarsTableReferences),
      CalendarRow,
      PrefetchHooks Function({
        bool calendarEventsRefs,
        bool calendarSyncQueueRefs,
      })
    >;
typedef $$CalendarEventsTableCreateCompanionBuilder =
    CalendarEventsCompanion Function({
      required String id,
      required String calendarId,
      required String uid,
      Value<String?> href,
      Value<String?> etag,
      Value<String> summary,
      Value<String?> description,
      Value<String?> location,
      required int startAt,
      required int endAt,
      Value<bool> isAllDay,
      Value<bool> floating,
      Value<String?> tzid,
      Value<String?> rrule,
      Value<String> exdatesJson,
      Value<int?> recurrenceId,
      Value<String?> status,
      Value<String?> organizer,
      Value<String> attendeesJson,
      Value<String> alarmsJson,
      Value<String?> rawIcs,
      required int updatedAt,
      Value<bool> dirty,
      Value<bool> conflicted,
      Value<bool> deleted,
      Value<int> rowid,
    });
typedef $$CalendarEventsTableUpdateCompanionBuilder =
    CalendarEventsCompanion Function({
      Value<String> id,
      Value<String> calendarId,
      Value<String> uid,
      Value<String?> href,
      Value<String?> etag,
      Value<String> summary,
      Value<String?> description,
      Value<String?> location,
      Value<int> startAt,
      Value<int> endAt,
      Value<bool> isAllDay,
      Value<bool> floating,
      Value<String?> tzid,
      Value<String?> rrule,
      Value<String> exdatesJson,
      Value<int?> recurrenceId,
      Value<String?> status,
      Value<String?> organizer,
      Value<String> attendeesJson,
      Value<String> alarmsJson,
      Value<String?> rawIcs,
      Value<int> updatedAt,
      Value<bool> dirty,
      Value<bool> conflicted,
      Value<bool> deleted,
      Value<int> rowid,
    });

final class $$CalendarEventsTableReferences
    extends
        BaseReferences<
          _$SortieDatabase,
          $CalendarEventsTable,
          CalendarEventRow
        > {
  $$CalendarEventsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CalendarsTable _calendarIdTable(_$SortieDatabase db) =>
      db.calendars.createAlias('calendar_events__calendar_id__calendars__id');

  $$CalendarsTableProcessedTableManager get calendarId {
    final $_column = $_itemColumn<String>('calendar_id')!;

    final manager = $$CalendarsTableTableManager(
      $_db,
      $_db.calendars,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_calendarIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CalendarEventsTableFilterComposer
    extends Composer<_$SortieDatabase, $CalendarEventsTable> {
  $$CalendarEventsTableFilterComposer({
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

  ColumnFilters<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get href => $composableBuilder(
    column: $table.href,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endAt => $composableBuilder(
    column: $table.endAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAllDay => $composableBuilder(
    column: $table.isAllDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get floating => $composableBuilder(
    column: $table.floating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tzid => $composableBuilder(
    column: $table.tzid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rrule => $composableBuilder(
    column: $table.rrule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exdatesJson => $composableBuilder(
    column: $table.exdatesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recurrenceId => $composableBuilder(
    column: $table.recurrenceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get organizer => $composableBuilder(
    column: $table.organizer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attendeesJson => $composableBuilder(
    column: $table.attendeesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alarmsJson => $composableBuilder(
    column: $table.alarmsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawIcs => $composableBuilder(
    column: $table.rawIcs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get conflicted => $composableBuilder(
    column: $table.conflicted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  $$CalendarsTableFilterComposer get calendarId {
    final $$CalendarsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.calendarId,
      referencedTable: $db.calendars,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalendarsTableFilterComposer(
            $db: $db,
            $table: $db.calendars,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CalendarEventsTableOrderingComposer
    extends Composer<_$SortieDatabase, $CalendarEventsTable> {
  $$CalendarEventsTableOrderingComposer({
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

  ColumnOrderings<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get href => $composableBuilder(
    column: $table.href,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endAt => $composableBuilder(
    column: $table.endAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAllDay => $composableBuilder(
    column: $table.isAllDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get floating => $composableBuilder(
    column: $table.floating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tzid => $composableBuilder(
    column: $table.tzid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rrule => $composableBuilder(
    column: $table.rrule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exdatesJson => $composableBuilder(
    column: $table.exdatesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recurrenceId => $composableBuilder(
    column: $table.recurrenceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get organizer => $composableBuilder(
    column: $table.organizer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attendeesJson => $composableBuilder(
    column: $table.attendeesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alarmsJson => $composableBuilder(
    column: $table.alarmsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawIcs => $composableBuilder(
    column: $table.rawIcs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get conflicted => $composableBuilder(
    column: $table.conflicted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  $$CalendarsTableOrderingComposer get calendarId {
    final $$CalendarsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.calendarId,
      referencedTable: $db.calendars,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalendarsTableOrderingComposer(
            $db: $db,
            $table: $db.calendars,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CalendarEventsTableAnnotationComposer
    extends Composer<_$SortieDatabase, $CalendarEventsTable> {
  $$CalendarEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get href =>
      $composableBuilder(column: $table.href, builder: (column) => column);

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<int> get startAt =>
      $composableBuilder(column: $table.startAt, builder: (column) => column);

  GeneratedColumn<int> get endAt =>
      $composableBuilder(column: $table.endAt, builder: (column) => column);

  GeneratedColumn<bool> get isAllDay =>
      $composableBuilder(column: $table.isAllDay, builder: (column) => column);

  GeneratedColumn<bool> get floating =>
      $composableBuilder(column: $table.floating, builder: (column) => column);

  GeneratedColumn<String> get tzid =>
      $composableBuilder(column: $table.tzid, builder: (column) => column);

  GeneratedColumn<String> get rrule =>
      $composableBuilder(column: $table.rrule, builder: (column) => column);

  GeneratedColumn<String> get exdatesJson => $composableBuilder(
    column: $table.exdatesJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recurrenceId => $composableBuilder(
    column: $table.recurrenceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get organizer =>
      $composableBuilder(column: $table.organizer, builder: (column) => column);

  GeneratedColumn<String> get attendeesJson => $composableBuilder(
    column: $table.attendeesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get alarmsJson => $composableBuilder(
    column: $table.alarmsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawIcs =>
      $composableBuilder(column: $table.rawIcs, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);

  GeneratedColumn<bool> get conflicted => $composableBuilder(
    column: $table.conflicted,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  $$CalendarsTableAnnotationComposer get calendarId {
    final $$CalendarsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.calendarId,
      referencedTable: $db.calendars,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalendarsTableAnnotationComposer(
            $db: $db,
            $table: $db.calendars,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CalendarEventsTableTableManager
    extends
        RootTableManager<
          _$SortieDatabase,
          $CalendarEventsTable,
          CalendarEventRow,
          $$CalendarEventsTableFilterComposer,
          $$CalendarEventsTableOrderingComposer,
          $$CalendarEventsTableAnnotationComposer,
          $$CalendarEventsTableCreateCompanionBuilder,
          $$CalendarEventsTableUpdateCompanionBuilder,
          (CalendarEventRow, $$CalendarEventsTableReferences),
          CalendarEventRow,
          PrefetchHooks Function({bool calendarId})
        > {
  $$CalendarEventsTableTableManager(
    _$SortieDatabase db,
    $CalendarEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CalendarEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CalendarEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CalendarEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> calendarId = const Value.absent(),
                Value<String> uid = const Value.absent(),
                Value<String?> href = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<int> startAt = const Value.absent(),
                Value<int> endAt = const Value.absent(),
                Value<bool> isAllDay = const Value.absent(),
                Value<bool> floating = const Value.absent(),
                Value<String?> tzid = const Value.absent(),
                Value<String?> rrule = const Value.absent(),
                Value<String> exdatesJson = const Value.absent(),
                Value<int?> recurrenceId = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<String?> organizer = const Value.absent(),
                Value<String> attendeesJson = const Value.absent(),
                Value<String> alarmsJson = const Value.absent(),
                Value<String?> rawIcs = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<bool> conflicted = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CalendarEventsCompanion(
                id: id,
                calendarId: calendarId,
                uid: uid,
                href: href,
                etag: etag,
                summary: summary,
                description: description,
                location: location,
                startAt: startAt,
                endAt: endAt,
                isAllDay: isAllDay,
                floating: floating,
                tzid: tzid,
                rrule: rrule,
                exdatesJson: exdatesJson,
                recurrenceId: recurrenceId,
                status: status,
                organizer: organizer,
                attendeesJson: attendeesJson,
                alarmsJson: alarmsJson,
                rawIcs: rawIcs,
                updatedAt: updatedAt,
                dirty: dirty,
                conflicted: conflicted,
                deleted: deleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String calendarId,
                required String uid,
                Value<String?> href = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> location = const Value.absent(),
                required int startAt,
                required int endAt,
                Value<bool> isAllDay = const Value.absent(),
                Value<bool> floating = const Value.absent(),
                Value<String?> tzid = const Value.absent(),
                Value<String?> rrule = const Value.absent(),
                Value<String> exdatesJson = const Value.absent(),
                Value<int?> recurrenceId = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<String?> organizer = const Value.absent(),
                Value<String> attendeesJson = const Value.absent(),
                Value<String> alarmsJson = const Value.absent(),
                Value<String?> rawIcs = const Value.absent(),
                required int updatedAt,
                Value<bool> dirty = const Value.absent(),
                Value<bool> conflicted = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CalendarEventsCompanion.insert(
                id: id,
                calendarId: calendarId,
                uid: uid,
                href: href,
                etag: etag,
                summary: summary,
                description: description,
                location: location,
                startAt: startAt,
                endAt: endAt,
                isAllDay: isAllDay,
                floating: floating,
                tzid: tzid,
                rrule: rrule,
                exdatesJson: exdatesJson,
                recurrenceId: recurrenceId,
                status: status,
                organizer: organizer,
                attendeesJson: attendeesJson,
                alarmsJson: alarmsJson,
                rawIcs: rawIcs,
                updatedAt: updatedAt,
                dirty: dirty,
                conflicted: conflicted,
                deleted: deleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CalendarEventsTable, CalendarEventRow>(table),
                  $$CalendarEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({calendarId = false}) {
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
                    if (calendarId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.calendarId,
                        referencedTable: $$CalendarEventsTableReferences
                            ._calendarIdTable(db),
                        referencedColumn: $$CalendarEventsTableReferences
                            ._calendarIdTable(db)
                            .id,
                      ) as T;
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

typedef $$CalendarEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$SortieDatabase,
      $CalendarEventsTable,
      CalendarEventRow,
      $$CalendarEventsTableFilterComposer,
      $$CalendarEventsTableOrderingComposer,
      $$CalendarEventsTableAnnotationComposer,
      $$CalendarEventsTableCreateCompanionBuilder,
      $$CalendarEventsTableUpdateCompanionBuilder,
      (CalendarEventRow, $$CalendarEventsTableReferences),
      CalendarEventRow,
      PrefetchHooks Function({bool calendarId})
    >;
typedef $$CalendarSyncQueueTableCreateCompanionBuilder =
    CalendarSyncQueueCompanion Function({
      required String id,
      required String calendarId,
      required String uid,
      required String kind,
      Value<String?> href,
      Value<String?> etag,
      required int createdAt,
      Value<int> attempts,
      Value<String?> lastError,
      Value<int> rowid,
    });
typedef $$CalendarSyncQueueTableUpdateCompanionBuilder =
    CalendarSyncQueueCompanion Function({
      Value<String> id,
      Value<String> calendarId,
      Value<String> uid,
      Value<String> kind,
      Value<String?> href,
      Value<String?> etag,
      Value<int> createdAt,
      Value<int> attempts,
      Value<String?> lastError,
      Value<int> rowid,
    });

final class $$CalendarSyncQueueTableReferences
    extends
        BaseReferences<
          _$SortieDatabase,
          $CalendarSyncQueueTable,
          CalendarSyncQueueRow
        > {
  $$CalendarSyncQueueTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CalendarsTable _calendarIdTable(_$SortieDatabase db) => db.calendars
      .createAlias('calendar_sync_queue__calendar_id__calendars__id');

  $$CalendarsTableProcessedTableManager get calendarId {
    final $_column = $_itemColumn<String>('calendar_id')!;

    final manager = $$CalendarsTableTableManager(
      $_db,
      $_db.calendars,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_calendarIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CalendarSyncQueueTableFilterComposer
    extends Composer<_$SortieDatabase, $CalendarSyncQueueTable> {
  $$CalendarSyncQueueTableFilterComposer({
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

  ColumnFilters<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get href => $composableBuilder(
    column: $table.href,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  $$CalendarsTableFilterComposer get calendarId {
    final $$CalendarsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.calendarId,
      referencedTable: $db.calendars,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalendarsTableFilterComposer(
            $db: $db,
            $table: $db.calendars,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CalendarSyncQueueTableOrderingComposer
    extends Composer<_$SortieDatabase, $CalendarSyncQueueTable> {
  $$CalendarSyncQueueTableOrderingComposer({
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

  ColumnOrderings<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get href => $composableBuilder(
    column: $table.href,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  $$CalendarsTableOrderingComposer get calendarId {
    final $$CalendarsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.calendarId,
      referencedTable: $db.calendars,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalendarsTableOrderingComposer(
            $db: $db,
            $table: $db.calendars,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CalendarSyncQueueTableAnnotationComposer
    extends Composer<_$SortieDatabase, $CalendarSyncQueueTable> {
  $$CalendarSyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get href =>
      $composableBuilder(column: $table.href, builder: (column) => column);

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  $$CalendarsTableAnnotationComposer get calendarId {
    final $$CalendarsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.calendarId,
      referencedTable: $db.calendars,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalendarsTableAnnotationComposer(
            $db: $db,
            $table: $db.calendars,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CalendarSyncQueueTableTableManager
    extends
        RootTableManager<
          _$SortieDatabase,
          $CalendarSyncQueueTable,
          CalendarSyncQueueRow,
          $$CalendarSyncQueueTableFilterComposer,
          $$CalendarSyncQueueTableOrderingComposer,
          $$CalendarSyncQueueTableAnnotationComposer,
          $$CalendarSyncQueueTableCreateCompanionBuilder,
          $$CalendarSyncQueueTableUpdateCompanionBuilder,
          (CalendarSyncQueueRow, $$CalendarSyncQueueTableReferences),
          CalendarSyncQueueRow,
          PrefetchHooks Function({bool calendarId})
        > {
  $$CalendarSyncQueueTableTableManager(
    _$SortieDatabase db,
    $CalendarSyncQueueTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CalendarSyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CalendarSyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CalendarSyncQueueTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> calendarId = const Value.absent(),
                Value<String> uid = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> href = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CalendarSyncQueueCompanion(
                id: id,
                calendarId: calendarId,
                uid: uid,
                kind: kind,
                href: href,
                etag: etag,
                createdAt: createdAt,
                attempts: attempts,
                lastError: lastError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String calendarId,
                required String uid,
                required String kind,
                Value<String?> href = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                required int createdAt,
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CalendarSyncQueueCompanion.insert(
                id: id,
                calendarId: calendarId,
                uid: uid,
                kind: kind,
                href: href,
                etag: etag,
                createdAt: createdAt,
                attempts: attempts,
                lastError: lastError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CalendarSyncQueueTable, CalendarSyncQueueRow>(
                    table,
                  ),
                  $$CalendarSyncQueueTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({calendarId = false}) {
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
                    if (calendarId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.calendarId,
                        referencedTable: $$CalendarSyncQueueTableReferences
                            ._calendarIdTable(db),
                        referencedColumn: $$CalendarSyncQueueTableReferences
                            ._calendarIdTable(db)
                            .id,
                      ) as T;
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

typedef $$CalendarSyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$SortieDatabase,
      $CalendarSyncQueueTable,
      CalendarSyncQueueRow,
      $$CalendarSyncQueueTableFilterComposer,
      $$CalendarSyncQueueTableOrderingComposer,
      $$CalendarSyncQueueTableAnnotationComposer,
      $$CalendarSyncQueueTableCreateCompanionBuilder,
      $$CalendarSyncQueueTableUpdateCompanionBuilder,
      (CalendarSyncQueueRow, $$CalendarSyncQueueTableReferences),
      CalendarSyncQueueRow,
      PrefetchHooks Function({bool calendarId})
    >;

class $SortieDatabaseManager {
  final _$SortieDatabase _db;
  $SortieDatabaseManager(this._db);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$IdentitiesTableTableManager get identities =>
      $$IdentitiesTableTableManager(_db, _db.identities);
  $$FoldersTableTableManager get folders =>
      $$FoldersTableTableManager(_db, _db.folders);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$MessageBodiesTableTableManager get messageBodies =>
      $$MessageBodiesTableTableManager(_db, _db.messageBodies);
  $$PendingOpsTableTableManager get pendingOps =>
      $$PendingOpsTableTableManager(_db, _db.pendingOps);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$SortDecisionsTableTableManager get sortDecisions =>
      $$SortDecisionsTableTableManager(_db, _db.sortDecisions);
  $$CorrectionsTableTableManager get corrections =>
      $$CorrectionsTableTableManager(_db, _db.corrections);
  $$FolderProfilesTableTableManager get folderProfiles =>
      $$FolderProfilesTableTableManager(_db, _db.folderProfiles);
  $$FolderProfileHistoryTableTableManager get folderProfileHistory =>
      $$FolderProfileHistoryTableTableManager(_db, _db.folderProfileHistory);
  $$SenderStatsTableTableManager get senderStats =>
      $$SenderStatsTableTableManager(_db, _db.senderStats);
  $$UserRulesTableTableManager get userRules =>
      $$UserRulesTableTableManager(_db, _db.userRules);
  $$SortQueueTableTableManager get sortQueue =>
      $$SortQueueTableTableManager(_db, _db.sortQueue);
  $$SortEvidenceTableTableManager get sortEvidence =>
      $$SortEvidenceTableTableManager(_db, _db.sortEvidence);
  $$RuleSuggestionsTableTableManager get ruleSuggestions =>
      $$RuleSuggestionsTableTableManager(_db, _db.ruleSuggestions);
  $$AiUsageTableTableManager get aiUsage =>
      $$AiUsageTableTableManager(_db, _db.aiUsage);
  $$JournalEventsTableTableManager get journalEvents =>
      $$JournalEventsTableTableManager(_db, _db.journalEvents);
  $$JournalCursorsTableTableManager get journalCursors =>
      $$JournalCursorsTableTableManager(_db, _db.journalCursors);
  $$CalendarsTableTableManager get calendars =>
      $$CalendarsTableTableManager(_db, _db.calendars);
  $$CalendarEventsTableTableManager get calendarEvents =>
      $$CalendarEventsTableTableManager(_db, _db.calendarEvents);
  $$CalendarSyncQueueTableTableManager get calendarSyncQueue =>
      $$CalendarSyncQueueTableTableManager(_db, _db.calendarSyncQueue);
}
