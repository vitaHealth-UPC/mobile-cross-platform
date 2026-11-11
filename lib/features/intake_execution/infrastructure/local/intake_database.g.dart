// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'intake_database.dart';

// ignore_for_file: type=lint
class $CachedIntakesTable extends CachedIntakes
    with TableInfo<$CachedIntakesTable, CachedIntakeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedIntakesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _careLinkIdMeta = const VerificationMeta(
    'careLinkId',
  );
  @override
  late final GeneratedColumn<String> careLinkId = GeneratedColumn<String>(
    'care_link_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intakeIdMeta = const VerificationMeta(
    'intakeId',
  );
  @override
  late final GeneratedColumn<String> intakeId = GeneratedColumn<String>(
    'intake_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _medicationNameMeta = const VerificationMeta(
    'medicationName',
  );
  @override
  late final GeneratedColumn<String> medicationName = GeneratedColumn<String>(
    'medication_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _doseMeta = const VerificationMeta('dose');
  @override
  late final GeneratedColumn<String> dose = GeneratedColumn<String>(
    'dose',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _instructionsMeta = const VerificationMeta(
    'instructions',
  );
  @override
  late final GeneratedColumn<String> instructions = GeneratedColumn<String>(
    'instructions',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scheduledAtMicrosMeta = const VerificationMeta(
    'scheduledAtMicros',
  );
  @override
  late final GeneratedColumn<int> scheduledAtMicros = GeneratedColumn<int>(
    'scheduled_at_micros',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<IntakeStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<IntakeStatus>($CachedIntakesTable.$converterstatus);
  static const VerificationMeta _confirmedAtMicrosMeta = const VerificationMeta(
    'confirmedAtMicros',
  );
  @override
  late final GeneratedColumn<int> confirmedAtMicros = GeneratedColumn<int>(
    'confirmed_at_micros',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    ownerId,
    careLinkId,
    intakeId,
    medicationName,
    dose,
    instructions,
    scheduledAtMicros,
    status,
    confirmedAtMicros,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_intakes';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedIntakeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('care_link_id')) {
      context.handle(
        _careLinkIdMeta,
        careLinkId.isAcceptableOrUnknown(
          data['care_link_id']!,
          _careLinkIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_careLinkIdMeta);
    }
    if (data.containsKey('intake_id')) {
      context.handle(
        _intakeIdMeta,
        intakeId.isAcceptableOrUnknown(data['intake_id']!, _intakeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_intakeIdMeta);
    }
    if (data.containsKey('medication_name')) {
      context.handle(
        _medicationNameMeta,
        medicationName.isAcceptableOrUnknown(
          data['medication_name']!,
          _medicationNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_medicationNameMeta);
    }
    if (data.containsKey('dose')) {
      context.handle(
        _doseMeta,
        dose.isAcceptableOrUnknown(data['dose']!, _doseMeta),
      );
    } else if (isInserting) {
      context.missing(_doseMeta);
    }
    if (data.containsKey('instructions')) {
      context.handle(
        _instructionsMeta,
        instructions.isAcceptableOrUnknown(
          data['instructions']!,
          _instructionsMeta,
        ),
      );
    }
    if (data.containsKey('scheduled_at_micros')) {
      context.handle(
        _scheduledAtMicrosMeta,
        scheduledAtMicros.isAcceptableOrUnknown(
          data['scheduled_at_micros']!,
          _scheduledAtMicrosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledAtMicrosMeta);
    }
    if (data.containsKey('confirmed_at_micros')) {
      context.handle(
        _confirmedAtMicrosMeta,
        confirmedAtMicros.isAcceptableOrUnknown(
          data['confirmed_at_micros']!,
          _confirmedAtMicrosMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ownerId, careLinkId, intakeId};
  @override
  CachedIntakeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedIntakeRow(
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      careLinkId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}care_link_id'],
      )!,
      intakeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}intake_id'],
      )!,
      medicationName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medication_name'],
      )!,
      dose: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dose'],
      )!,
      instructions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instructions'],
      ),
      scheduledAtMicros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scheduled_at_micros'],
      )!,
      status: $CachedIntakesTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      confirmedAtMicros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}confirmed_at_micros'],
      ),
    );
  }

  @override
  $CachedIntakesTable createAlias(String alias) {
    return $CachedIntakesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<IntakeStatus, String, String> $converterstatus =
      const EnumNameConverter<IntakeStatus>(IntakeStatus.values);
}

class CachedIntakeRow extends DataClass implements Insertable<CachedIntakeRow> {
  final String ownerId;
  final String careLinkId;
  final String intakeId;
  final String medicationName;
  final String dose;
  final String? instructions;
  final int scheduledAtMicros;
  final IntakeStatus status;
  final int? confirmedAtMicros;
  const CachedIntakeRow({
    required this.ownerId,
    required this.careLinkId,
    required this.intakeId,
    required this.medicationName,
    required this.dose,
    this.instructions,
    required this.scheduledAtMicros,
    required this.status,
    this.confirmedAtMicros,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['owner_id'] = Variable<String>(ownerId);
    map['care_link_id'] = Variable<String>(careLinkId);
    map['intake_id'] = Variable<String>(intakeId);
    map['medication_name'] = Variable<String>(medicationName);
    map['dose'] = Variable<String>(dose);
    if (!nullToAbsent || instructions != null) {
      map['instructions'] = Variable<String>(instructions);
    }
    map['scheduled_at_micros'] = Variable<int>(scheduledAtMicros);
    {
      map['status'] = Variable<String>(
        $CachedIntakesTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || confirmedAtMicros != null) {
      map['confirmed_at_micros'] = Variable<int>(confirmedAtMicros);
    }
    return map;
  }

  CachedIntakesCompanion toCompanion(bool nullToAbsent) {
    return CachedIntakesCompanion(
      ownerId: Value(ownerId),
      careLinkId: Value(careLinkId),
      intakeId: Value(intakeId),
      medicationName: Value(medicationName),
      dose: Value(dose),
      instructions: instructions == null && nullToAbsent
          ? const Value.absent()
          : Value(instructions),
      scheduledAtMicros: Value(scheduledAtMicros),
      status: Value(status),
      confirmedAtMicros: confirmedAtMicros == null && nullToAbsent
          ? const Value.absent()
          : Value(confirmedAtMicros),
    );
  }

  factory CachedIntakeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedIntakeRow(
      ownerId: serializer.fromJson<String>(json['ownerId']),
      careLinkId: serializer.fromJson<String>(json['careLinkId']),
      intakeId: serializer.fromJson<String>(json['intakeId']),
      medicationName: serializer.fromJson<String>(json['medicationName']),
      dose: serializer.fromJson<String>(json['dose']),
      instructions: serializer.fromJson<String?>(json['instructions']),
      scheduledAtMicros: serializer.fromJson<int>(json['scheduledAtMicros']),
      status: $CachedIntakesTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      confirmedAtMicros: serializer.fromJson<int?>(json['confirmedAtMicros']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ownerId': serializer.toJson<String>(ownerId),
      'careLinkId': serializer.toJson<String>(careLinkId),
      'intakeId': serializer.toJson<String>(intakeId),
      'medicationName': serializer.toJson<String>(medicationName),
      'dose': serializer.toJson<String>(dose),
      'instructions': serializer.toJson<String?>(instructions),
      'scheduledAtMicros': serializer.toJson<int>(scheduledAtMicros),
      'status': serializer.toJson<String>(
        $CachedIntakesTable.$converterstatus.toJson(status),
      ),
      'confirmedAtMicros': serializer.toJson<int?>(confirmedAtMicros),
    };
  }

  CachedIntakeRow copyWith({
    String? ownerId,
    String? careLinkId,
    String? intakeId,
    String? medicationName,
    String? dose,
    Value<String?> instructions = const Value.absent(),
    int? scheduledAtMicros,
    IntakeStatus? status,
    Value<int?> confirmedAtMicros = const Value.absent(),
  }) => CachedIntakeRow(
    ownerId: ownerId ?? this.ownerId,
    careLinkId: careLinkId ?? this.careLinkId,
    intakeId: intakeId ?? this.intakeId,
    medicationName: medicationName ?? this.medicationName,
    dose: dose ?? this.dose,
    instructions: instructions.present ? instructions.value : this.instructions,
    scheduledAtMicros: scheduledAtMicros ?? this.scheduledAtMicros,
    status: status ?? this.status,
    confirmedAtMicros: confirmedAtMicros.present
        ? confirmedAtMicros.value
        : this.confirmedAtMicros,
  );
  CachedIntakeRow copyWithCompanion(CachedIntakesCompanion data) {
    return CachedIntakeRow(
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      careLinkId: data.careLinkId.present
          ? data.careLinkId.value
          : this.careLinkId,
      intakeId: data.intakeId.present ? data.intakeId.value : this.intakeId,
      medicationName: data.medicationName.present
          ? data.medicationName.value
          : this.medicationName,
      dose: data.dose.present ? data.dose.value : this.dose,
      instructions: data.instructions.present
          ? data.instructions.value
          : this.instructions,
      scheduledAtMicros: data.scheduledAtMicros.present
          ? data.scheduledAtMicros.value
          : this.scheduledAtMicros,
      status: data.status.present ? data.status.value : this.status,
      confirmedAtMicros: data.confirmedAtMicros.present
          ? data.confirmedAtMicros.value
          : this.confirmedAtMicros,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedIntakeRow(')
          ..write('ownerId: $ownerId, ')
          ..write('careLinkId: $careLinkId, ')
          ..write('intakeId: $intakeId, ')
          ..write('medicationName: $medicationName, ')
          ..write('dose: $dose, ')
          ..write('instructions: $instructions, ')
          ..write('scheduledAtMicros: $scheduledAtMicros, ')
          ..write('status: $status, ')
          ..write('confirmedAtMicros: $confirmedAtMicros')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    ownerId,
    careLinkId,
    intakeId,
    medicationName,
    dose,
    instructions,
    scheduledAtMicros,
    status,
    confirmedAtMicros,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedIntakeRow &&
          other.ownerId == this.ownerId &&
          other.careLinkId == this.careLinkId &&
          other.intakeId == this.intakeId &&
          other.medicationName == this.medicationName &&
          other.dose == this.dose &&
          other.instructions == this.instructions &&
          other.scheduledAtMicros == this.scheduledAtMicros &&
          other.status == this.status &&
          other.confirmedAtMicros == this.confirmedAtMicros);
}

class CachedIntakesCompanion extends UpdateCompanion<CachedIntakeRow> {
  final Value<String> ownerId;
  final Value<String> careLinkId;
  final Value<String> intakeId;
  final Value<String> medicationName;
  final Value<String> dose;
  final Value<String?> instructions;
  final Value<int> scheduledAtMicros;
  final Value<IntakeStatus> status;
  final Value<int?> confirmedAtMicros;
  final Value<int> rowid;
  const CachedIntakesCompanion({
    this.ownerId = const Value.absent(),
    this.careLinkId = const Value.absent(),
    this.intakeId = const Value.absent(),
    this.medicationName = const Value.absent(),
    this.dose = const Value.absent(),
    this.instructions = const Value.absent(),
    this.scheduledAtMicros = const Value.absent(),
    this.status = const Value.absent(),
    this.confirmedAtMicros = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedIntakesCompanion.insert({
    required String ownerId,
    required String careLinkId,
    required String intakeId,
    required String medicationName,
    required String dose,
    this.instructions = const Value.absent(),
    required int scheduledAtMicros,
    required IntakeStatus status,
    this.confirmedAtMicros = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : ownerId = Value(ownerId),
       careLinkId = Value(careLinkId),
       intakeId = Value(intakeId),
       medicationName = Value(medicationName),
       dose = Value(dose),
       scheduledAtMicros = Value(scheduledAtMicros),
       status = Value(status);
  static Insertable<CachedIntakeRow> custom({
    Expression<String>? ownerId,
    Expression<String>? careLinkId,
    Expression<String>? intakeId,
    Expression<String>? medicationName,
    Expression<String>? dose,
    Expression<String>? instructions,
    Expression<int>? scheduledAtMicros,
    Expression<String>? status,
    Expression<int>? confirmedAtMicros,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ownerId != null) 'owner_id': ownerId,
      if (careLinkId != null) 'care_link_id': careLinkId,
      if (intakeId != null) 'intake_id': intakeId,
      if (medicationName != null) 'medication_name': medicationName,
      if (dose != null) 'dose': dose,
      if (instructions != null) 'instructions': instructions,
      if (scheduledAtMicros != null) 'scheduled_at_micros': scheduledAtMicros,
      if (status != null) 'status': status,
      if (confirmedAtMicros != null) 'confirmed_at_micros': confirmedAtMicros,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedIntakesCompanion copyWith({
    Value<String>? ownerId,
    Value<String>? careLinkId,
    Value<String>? intakeId,
    Value<String>? medicationName,
    Value<String>? dose,
    Value<String?>? instructions,
    Value<int>? scheduledAtMicros,
    Value<IntakeStatus>? status,
    Value<int?>? confirmedAtMicros,
    Value<int>? rowid,
  }) {
    return CachedIntakesCompanion(
      ownerId: ownerId ?? this.ownerId,
      careLinkId: careLinkId ?? this.careLinkId,
      intakeId: intakeId ?? this.intakeId,
      medicationName: medicationName ?? this.medicationName,
      dose: dose ?? this.dose,
      instructions: instructions ?? this.instructions,
      scheduledAtMicros: scheduledAtMicros ?? this.scheduledAtMicros,
      status: status ?? this.status,
      confirmedAtMicros: confirmedAtMicros ?? this.confirmedAtMicros,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (careLinkId.present) {
      map['care_link_id'] = Variable<String>(careLinkId.value);
    }
    if (intakeId.present) {
      map['intake_id'] = Variable<String>(intakeId.value);
    }
    if (medicationName.present) {
      map['medication_name'] = Variable<String>(medicationName.value);
    }
    if (dose.present) {
      map['dose'] = Variable<String>(dose.value);
    }
    if (instructions.present) {
      map['instructions'] = Variable<String>(instructions.value);
    }
    if (scheduledAtMicros.present) {
      map['scheduled_at_micros'] = Variable<int>(scheduledAtMicros.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $CachedIntakesTable.$converterstatus.toSql(status.value),
      );
    }
    if (confirmedAtMicros.present) {
      map['confirmed_at_micros'] = Variable<int>(confirmedAtMicros.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedIntakesCompanion(')
          ..write('ownerId: $ownerId, ')
          ..write('careLinkId: $careLinkId, ')
          ..write('intakeId: $intakeId, ')
          ..write('medicationName: $medicationName, ')
          ..write('dose: $dose, ')
          ..write('instructions: $instructions, ')
          ..write('scheduledAtMicros: $scheduledAtMicros, ')
          ..write('status: $status, ')
          ..write('confirmedAtMicros: $confirmedAtMicros, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingConfirmationsTable extends PendingConfirmations
    with TableInfo<$PendingConfirmationsTable, PendingConfirmationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingConfirmationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _careLinkIdMeta = const VerificationMeta(
    'careLinkId',
  );
  @override
  late final GeneratedColumn<String> careLinkId = GeneratedColumn<String>(
    'care_link_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intakeIdMeta = const VerificationMeta(
    'intakeId',
  );
  @override
  late final GeneratedColumn<String> intakeId = GeneratedColumn<String>(
    'intake_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _queuedAtMicrosMeta = const VerificationMeta(
    'queuedAtMicros',
  );
  @override
  late final GeneratedColumn<int> queuedAtMicros = GeneratedColumn<int>(
    'queued_at_micros',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _failureCodeMeta = const VerificationMeta(
    'failureCode',
  );
  @override
  late final GeneratedColumn<String> failureCode = GeneratedColumn<String>(
    'failure_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    ownerId,
    careLinkId,
    intakeId,
    queuedAtMicros,
    failureCode,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_confirmations';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingConfirmationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('care_link_id')) {
      context.handle(
        _careLinkIdMeta,
        careLinkId.isAcceptableOrUnknown(
          data['care_link_id']!,
          _careLinkIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_careLinkIdMeta);
    }
    if (data.containsKey('intake_id')) {
      context.handle(
        _intakeIdMeta,
        intakeId.isAcceptableOrUnknown(data['intake_id']!, _intakeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_intakeIdMeta);
    }
    if (data.containsKey('queued_at_micros')) {
      context.handle(
        _queuedAtMicrosMeta,
        queuedAtMicros.isAcceptableOrUnknown(
          data['queued_at_micros']!,
          _queuedAtMicrosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_queuedAtMicrosMeta);
    }
    if (data.containsKey('failure_code')) {
      context.handle(
        _failureCodeMeta,
        failureCode.isAcceptableOrUnknown(
          data['failure_code']!,
          _failureCodeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ownerId, careLinkId, intakeId};
  @override
  PendingConfirmationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingConfirmationRow(
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      careLinkId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}care_link_id'],
      )!,
      intakeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}intake_id'],
      )!,
      queuedAtMicros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}queued_at_micros'],
      )!,
      failureCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}failure_code'],
      ),
    );
  }

  @override
  $PendingConfirmationsTable createAlias(String alias) {
    return $PendingConfirmationsTable(attachedDatabase, alias);
  }
}

class PendingConfirmationRow extends DataClass
    implements Insertable<PendingConfirmationRow> {
  final String ownerId;
  final String careLinkId;
  final String intakeId;
  final int queuedAtMicros;
  final String? failureCode;
  const PendingConfirmationRow({
    required this.ownerId,
    required this.careLinkId,
    required this.intakeId,
    required this.queuedAtMicros,
    this.failureCode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['owner_id'] = Variable<String>(ownerId);
    map['care_link_id'] = Variable<String>(careLinkId);
    map['intake_id'] = Variable<String>(intakeId);
    map['queued_at_micros'] = Variable<int>(queuedAtMicros);
    if (!nullToAbsent || failureCode != null) {
      map['failure_code'] = Variable<String>(failureCode);
    }
    return map;
  }

  PendingConfirmationsCompanion toCompanion(bool nullToAbsent) {
    return PendingConfirmationsCompanion(
      ownerId: Value(ownerId),
      careLinkId: Value(careLinkId),
      intakeId: Value(intakeId),
      queuedAtMicros: Value(queuedAtMicros),
      failureCode: failureCode == null && nullToAbsent
          ? const Value.absent()
          : Value(failureCode),
    );
  }

  factory PendingConfirmationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingConfirmationRow(
      ownerId: serializer.fromJson<String>(json['ownerId']),
      careLinkId: serializer.fromJson<String>(json['careLinkId']),
      intakeId: serializer.fromJson<String>(json['intakeId']),
      queuedAtMicros: serializer.fromJson<int>(json['queuedAtMicros']),
      failureCode: serializer.fromJson<String?>(json['failureCode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ownerId': serializer.toJson<String>(ownerId),
      'careLinkId': serializer.toJson<String>(careLinkId),
      'intakeId': serializer.toJson<String>(intakeId),
      'queuedAtMicros': serializer.toJson<int>(queuedAtMicros),
      'failureCode': serializer.toJson<String?>(failureCode),
    };
  }

  PendingConfirmationRow copyWith({
    String? ownerId,
    String? careLinkId,
    String? intakeId,
    int? queuedAtMicros,
    Value<String?> failureCode = const Value.absent(),
  }) => PendingConfirmationRow(
    ownerId: ownerId ?? this.ownerId,
    careLinkId: careLinkId ?? this.careLinkId,
    intakeId: intakeId ?? this.intakeId,
    queuedAtMicros: queuedAtMicros ?? this.queuedAtMicros,
    failureCode: failureCode.present ? failureCode.value : this.failureCode,
  );
  PendingConfirmationRow copyWithCompanion(PendingConfirmationsCompanion data) {
    return PendingConfirmationRow(
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      careLinkId: data.careLinkId.present
          ? data.careLinkId.value
          : this.careLinkId,
      intakeId: data.intakeId.present ? data.intakeId.value : this.intakeId,
      queuedAtMicros: data.queuedAtMicros.present
          ? data.queuedAtMicros.value
          : this.queuedAtMicros,
      failureCode: data.failureCode.present
          ? data.failureCode.value
          : this.failureCode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingConfirmationRow(')
          ..write('ownerId: $ownerId, ')
          ..write('careLinkId: $careLinkId, ')
          ..write('intakeId: $intakeId, ')
          ..write('queuedAtMicros: $queuedAtMicros, ')
          ..write('failureCode: $failureCode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(ownerId, careLinkId, intakeId, queuedAtMicros, failureCode);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingConfirmationRow &&
          other.ownerId == this.ownerId &&
          other.careLinkId == this.careLinkId &&
          other.intakeId == this.intakeId &&
          other.queuedAtMicros == this.queuedAtMicros &&
          other.failureCode == this.failureCode);
}

class PendingConfirmationsCompanion
    extends UpdateCompanion<PendingConfirmationRow> {
  final Value<String> ownerId;
  final Value<String> careLinkId;
  final Value<String> intakeId;
  final Value<int> queuedAtMicros;
  final Value<String?> failureCode;
  final Value<int> rowid;
  const PendingConfirmationsCompanion({
    this.ownerId = const Value.absent(),
    this.careLinkId = const Value.absent(),
    this.intakeId = const Value.absent(),
    this.queuedAtMicros = const Value.absent(),
    this.failureCode = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingConfirmationsCompanion.insert({
    required String ownerId,
    required String careLinkId,
    required String intakeId,
    required int queuedAtMicros,
    this.failureCode = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : ownerId = Value(ownerId),
       careLinkId = Value(careLinkId),
       intakeId = Value(intakeId),
       queuedAtMicros = Value(queuedAtMicros);
  static Insertable<PendingConfirmationRow> custom({
    Expression<String>? ownerId,
    Expression<String>? careLinkId,
    Expression<String>? intakeId,
    Expression<int>? queuedAtMicros,
    Expression<String>? failureCode,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ownerId != null) 'owner_id': ownerId,
      if (careLinkId != null) 'care_link_id': careLinkId,
      if (intakeId != null) 'intake_id': intakeId,
      if (queuedAtMicros != null) 'queued_at_micros': queuedAtMicros,
      if (failureCode != null) 'failure_code': failureCode,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingConfirmationsCompanion copyWith({
    Value<String>? ownerId,
    Value<String>? careLinkId,
    Value<String>? intakeId,
    Value<int>? queuedAtMicros,
    Value<String?>? failureCode,
    Value<int>? rowid,
  }) {
    return PendingConfirmationsCompanion(
      ownerId: ownerId ?? this.ownerId,
      careLinkId: careLinkId ?? this.careLinkId,
      intakeId: intakeId ?? this.intakeId,
      queuedAtMicros: queuedAtMicros ?? this.queuedAtMicros,
      failureCode: failureCode ?? this.failureCode,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (careLinkId.present) {
      map['care_link_id'] = Variable<String>(careLinkId.value);
    }
    if (intakeId.present) {
      map['intake_id'] = Variable<String>(intakeId.value);
    }
    if (queuedAtMicros.present) {
      map['queued_at_micros'] = Variable<int>(queuedAtMicros.value);
    }
    if (failureCode.present) {
      map['failure_code'] = Variable<String>(failureCode.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingConfirmationsCompanion(')
          ..write('ownerId: $ownerId, ')
          ..write('careLinkId: $careLinkId, ')
          ..write('intakeId: $intakeId, ')
          ..write('queuedAtMicros: $queuedAtMicros, ')
          ..write('failureCode: $failureCode, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$IntakeDatabase extends GeneratedDatabase {
  _$IntakeDatabase(QueryExecutor e) : super(e);
  $IntakeDatabaseManager get managers => $IntakeDatabaseManager(this);
  late final $CachedIntakesTable cachedIntakes = $CachedIntakesTable(this);
  late final $PendingConfirmationsTable pendingConfirmations =
      $PendingConfirmationsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedIntakes,
    pendingConfirmations,
  ];
}

typedef $$CachedIntakesTableCreateCompanionBuilder =
    CachedIntakesCompanion Function({
      required String ownerId,
      required String careLinkId,
      required String intakeId,
      required String medicationName,
      required String dose,
      Value<String?> instructions,
      required int scheduledAtMicros,
      required IntakeStatus status,
      Value<int?> confirmedAtMicros,
      Value<int> rowid,
    });
typedef $$CachedIntakesTableUpdateCompanionBuilder =
    CachedIntakesCompanion Function({
      Value<String> ownerId,
      Value<String> careLinkId,
      Value<String> intakeId,
      Value<String> medicationName,
      Value<String> dose,
      Value<String?> instructions,
      Value<int> scheduledAtMicros,
      Value<IntakeStatus> status,
      Value<int?> confirmedAtMicros,
      Value<int> rowid,
    });

class $$CachedIntakesTableFilterComposer
    extends Composer<_$IntakeDatabase, $CachedIntakesTable> {
  $$CachedIntakesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get careLinkId => $composableBuilder(
    column: $table.careLinkId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get intakeId => $composableBuilder(
    column: $table.intakeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medicationName => $composableBuilder(
    column: $table.medicationName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dose => $composableBuilder(
    column: $table.dose,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get instructions => $composableBuilder(
    column: $table.instructions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scheduledAtMicros => $composableBuilder(
    column: $table.scheduledAtMicros,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<IntakeStatus, IntakeStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get confirmedAtMicros => $composableBuilder(
    column: $table.confirmedAtMicros,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedIntakesTableOrderingComposer
    extends Composer<_$IntakeDatabase, $CachedIntakesTable> {
  $$CachedIntakesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get careLinkId => $composableBuilder(
    column: $table.careLinkId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get intakeId => $composableBuilder(
    column: $table.intakeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medicationName => $composableBuilder(
    column: $table.medicationName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dose => $composableBuilder(
    column: $table.dose,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get instructions => $composableBuilder(
    column: $table.instructions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scheduledAtMicros => $composableBuilder(
    column: $table.scheduledAtMicros,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get confirmedAtMicros => $composableBuilder(
    column: $table.confirmedAtMicros,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedIntakesTableAnnotationComposer
    extends Composer<_$IntakeDatabase, $CachedIntakesTable> {
  $$CachedIntakesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get careLinkId => $composableBuilder(
    column: $table.careLinkId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get intakeId =>
      $composableBuilder(column: $table.intakeId, builder: (column) => column);

  GeneratedColumn<String> get medicationName => $composableBuilder(
    column: $table.medicationName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dose =>
      $composableBuilder(column: $table.dose, builder: (column) => column);

  GeneratedColumn<String> get instructions => $composableBuilder(
    column: $table.instructions,
    builder: (column) => column,
  );

  GeneratedColumn<int> get scheduledAtMicros => $composableBuilder(
    column: $table.scheduledAtMicros,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<IntakeStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get confirmedAtMicros => $composableBuilder(
    column: $table.confirmedAtMicros,
    builder: (column) => column,
  );
}

class $$CachedIntakesTableTableManager
    extends
        RootTableManager<
          _$IntakeDatabase,
          $CachedIntakesTable,
          CachedIntakeRow,
          $$CachedIntakesTableFilterComposer,
          $$CachedIntakesTableOrderingComposer,
          $$CachedIntakesTableAnnotationComposer,
          $$CachedIntakesTableCreateCompanionBuilder,
          $$CachedIntakesTableUpdateCompanionBuilder,
          (
            CachedIntakeRow,
            BaseReferences<
              _$IntakeDatabase,
              $CachedIntakesTable,
              CachedIntakeRow
            >,
          ),
          CachedIntakeRow,
          PrefetchHooks Function()
        > {
  $$CachedIntakesTableTableManager(
    _$IntakeDatabase db,
    $CachedIntakesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedIntakesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedIntakesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedIntakesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> ownerId = const Value.absent(),
                Value<String> careLinkId = const Value.absent(),
                Value<String> intakeId = const Value.absent(),
                Value<String> medicationName = const Value.absent(),
                Value<String> dose = const Value.absent(),
                Value<String?> instructions = const Value.absent(),
                Value<int> scheduledAtMicros = const Value.absent(),
                Value<IntakeStatus> status = const Value.absent(),
                Value<int?> confirmedAtMicros = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedIntakesCompanion(
                ownerId: ownerId,
                careLinkId: careLinkId,
                intakeId: intakeId,
                medicationName: medicationName,
                dose: dose,
                instructions: instructions,
                scheduledAtMicros: scheduledAtMicros,
                status: status,
                confirmedAtMicros: confirmedAtMicros,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String ownerId,
                required String careLinkId,
                required String intakeId,
                required String medicationName,
                required String dose,
                Value<String?> instructions = const Value.absent(),
                required int scheduledAtMicros,
                required IntakeStatus status,
                Value<int?> confirmedAtMicros = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedIntakesCompanion.insert(
                ownerId: ownerId,
                careLinkId: careLinkId,
                intakeId: intakeId,
                medicationName: medicationName,
                dose: dose,
                instructions: instructions,
                scheduledAtMicros: scheduledAtMicros,
                status: status,
                confirmedAtMicros: confirmedAtMicros,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedIntakesTable, CachedIntakeRow>(table),
                  BaseReferences<
                    _$IntakeDatabase,
                    $CachedIntakesTable,
                    CachedIntakeRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedIntakesTableProcessedTableManager =
    ProcessedTableManager<
      _$IntakeDatabase,
      $CachedIntakesTable,
      CachedIntakeRow,
      $$CachedIntakesTableFilterComposer,
      $$CachedIntakesTableOrderingComposer,
      $$CachedIntakesTableAnnotationComposer,
      $$CachedIntakesTableCreateCompanionBuilder,
      $$CachedIntakesTableUpdateCompanionBuilder,
      (
        CachedIntakeRow,
        BaseReferences<_$IntakeDatabase, $CachedIntakesTable, CachedIntakeRow>,
      ),
      CachedIntakeRow,
      PrefetchHooks Function()
    >;
typedef $$PendingConfirmationsTableCreateCompanionBuilder =
    PendingConfirmationsCompanion Function({
      required String ownerId,
      required String careLinkId,
      required String intakeId,
      required int queuedAtMicros,
      Value<String?> failureCode,
      Value<int> rowid,
    });
typedef $$PendingConfirmationsTableUpdateCompanionBuilder =
    PendingConfirmationsCompanion Function({
      Value<String> ownerId,
      Value<String> careLinkId,
      Value<String> intakeId,
      Value<int> queuedAtMicros,
      Value<String?> failureCode,
      Value<int> rowid,
    });

class $$PendingConfirmationsTableFilterComposer
    extends Composer<_$IntakeDatabase, $PendingConfirmationsTable> {
  $$PendingConfirmationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get careLinkId => $composableBuilder(
    column: $table.careLinkId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get intakeId => $composableBuilder(
    column: $table.intakeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get queuedAtMicros => $composableBuilder(
    column: $table.queuedAtMicros,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get failureCode => $composableBuilder(
    column: $table.failureCode,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingConfirmationsTableOrderingComposer
    extends Composer<_$IntakeDatabase, $PendingConfirmationsTable> {
  $$PendingConfirmationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get careLinkId => $composableBuilder(
    column: $table.careLinkId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get intakeId => $composableBuilder(
    column: $table.intakeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get queuedAtMicros => $composableBuilder(
    column: $table.queuedAtMicros,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get failureCode => $composableBuilder(
    column: $table.failureCode,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingConfirmationsTableAnnotationComposer
    extends Composer<_$IntakeDatabase, $PendingConfirmationsTable> {
  $$PendingConfirmationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get careLinkId => $composableBuilder(
    column: $table.careLinkId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get intakeId =>
      $composableBuilder(column: $table.intakeId, builder: (column) => column);

  GeneratedColumn<int> get queuedAtMicros => $composableBuilder(
    column: $table.queuedAtMicros,
    builder: (column) => column,
  );

  GeneratedColumn<String> get failureCode => $composableBuilder(
    column: $table.failureCode,
    builder: (column) => column,
  );
}

class $$PendingConfirmationsTableTableManager
    extends
        RootTableManager<
          _$IntakeDatabase,
          $PendingConfirmationsTable,
          PendingConfirmationRow,
          $$PendingConfirmationsTableFilterComposer,
          $$PendingConfirmationsTableOrderingComposer,
          $$PendingConfirmationsTableAnnotationComposer,
          $$PendingConfirmationsTableCreateCompanionBuilder,
          $$PendingConfirmationsTableUpdateCompanionBuilder,
          (
            PendingConfirmationRow,
            BaseReferences<
              _$IntakeDatabase,
              $PendingConfirmationsTable,
              PendingConfirmationRow
            >,
          ),
          PendingConfirmationRow,
          PrefetchHooks Function()
        > {
  $$PendingConfirmationsTableTableManager(
    _$IntakeDatabase db,
    $PendingConfirmationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingConfirmationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingConfirmationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PendingConfirmationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> ownerId = const Value.absent(),
                Value<String> careLinkId = const Value.absent(),
                Value<String> intakeId = const Value.absent(),
                Value<int> queuedAtMicros = const Value.absent(),
                Value<String?> failureCode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingConfirmationsCompanion(
                ownerId: ownerId,
                careLinkId: careLinkId,
                intakeId: intakeId,
                queuedAtMicros: queuedAtMicros,
                failureCode: failureCode,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String ownerId,
                required String careLinkId,
                required String intakeId,
                required int queuedAtMicros,
                Value<String?> failureCode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingConfirmationsCompanion.insert(
                ownerId: ownerId,
                careLinkId: careLinkId,
                intakeId: intakeId,
                queuedAtMicros: queuedAtMicros,
                failureCode: failureCode,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $PendingConfirmationsTable,
                    PendingConfirmationRow
                  >(table),
                  BaseReferences<
                    _$IntakeDatabase,
                    $PendingConfirmationsTable,
                    PendingConfirmationRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingConfirmationsTableProcessedTableManager =
    ProcessedTableManager<
      _$IntakeDatabase,
      $PendingConfirmationsTable,
      PendingConfirmationRow,
      $$PendingConfirmationsTableFilterComposer,
      $$PendingConfirmationsTableOrderingComposer,
      $$PendingConfirmationsTableAnnotationComposer,
      $$PendingConfirmationsTableCreateCompanionBuilder,
      $$PendingConfirmationsTableUpdateCompanionBuilder,
      (
        PendingConfirmationRow,
        BaseReferences<
          _$IntakeDatabase,
          $PendingConfirmationsTable,
          PendingConfirmationRow
        >,
      ),
      PendingConfirmationRow,
      PrefetchHooks Function()
    >;

class $IntakeDatabaseManager {
  final _$IntakeDatabase _db;
  $IntakeDatabaseManager(this._db);
  $$CachedIntakesTableTableManager get cachedIntakes =>
      $$CachedIntakesTableTableManager(_db, _db.cachedIntakes);
  $$PendingConfirmationsTableTableManager get pendingConfirmations =>
      $$PendingConfirmationsTableTableManager(_db, _db.pendingConfirmations);
}
