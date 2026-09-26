final class FilamentSpoolId {
  FilamentSpoolId.parse(this.value) {
    if (!RegExp(r'^[A-Za-z0-9_-]{22}$').hasMatch(value)) {
      throw const FormatException('Invalid filament-spool identity.');
    }
  }

  final String value;

  @override
  bool operator ==(Object other) =>
      other is FilamentSpoolId && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

enum FilamentSpoolState { unlocated }

final class SpoolDescription {
  SpoolDescription({
    required String materialType,
    required String filamentColor,
    String? spoolLabel,
    String? manufacturer,
    String? productName,
    int? originalNominalGrams,
    String? notes,
  }) : materialType = materialType.trim(),
       filamentColor = normalizeFilamentColor(filamentColor),
       spoolLabel = _optional(spoolLabel),
       manufacturer = _optional(manufacturer),
       productName = _optional(productName),
       originalNominalGrams = originalNominalGrams,
       notes = _optional(notes) {
    if (this.materialType.isEmpty) {
      throw const FormatException('Material type is required.');
    }
    if (originalNominalGrams != null && originalNominalGrams <= 0) {
      throw const FormatException(
        'Original nominal quantity must be positive.',
      );
    }
  }

  final String materialType;
  final String filamentColor;
  final String? spoolLabel;
  final String? manufacturer;
  final String? productName;
  final int? originalNominalGrams;
  final String? notes;

  static String? _optional(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static String normalizeFilamentColor(String value) {
    final color = value.trim().toUpperCase();
    final hex = color.startsWith('#') ? color.substring(1) : color;
    if (!RegExp(r'^[0-9A-F]{6}$').hasMatch(hex)) {
      throw const FormatException('Choose a color in #RRGGBB format.');
    }
    return '#$hex';
  }

  Map<String, Object?> toJson() => {
    'materialType': materialType,
    'filamentColor': filamentColor,
    'spoolLabel': spoolLabel,
    'manufacturer': manufacturer,
    'productName': productName,
    'originalNominalGrams': originalNominalGrams,
    'notes': notes,
  };

  factory SpoolDescription.fromJson(Map<String, dynamic> json) {
    return SpoolDescription(
      materialType: json['materialType'] as String,
      filamentColor: json['filamentColor'] as String,
      spoolLabel: json['spoolLabel'] as String?,
      manufacturer: json['manufacturer'] as String?,
      productName: json['productName'] as String?,
      originalNominalGrams: json['originalNominalGrams'] as int?,
      notes: json['notes'] as String?,
    );
  }
}

final class SpoolRegistration {
  const SpoolRegistration({
    required this.description,
    required this.remainingGrams,
  });

  final SpoolDescription description;
  final int remainingGrams;
}

final class SpoolHistoryEntry {
  const SpoolHistoryEntry({
    required this.occurredAt,
    required this.action,
    required this.affectedSpoolIds,
    required this.beforeState,
    required this.afterState,
    required this.beforeRemainingGrams,
    required this.afterRemainingGrams,
  });

  final DateTime occurredAt;
  final String action;
  final List<FilamentSpoolId> affectedSpoolIds;
  final FilamentSpoolState? beforeState;
  final FilamentSpoolState afterState;
  final int? beforeRemainingGrams;
  final int afterRemainingGrams;

  Map<String, Object?> toJson() => {
    'occurredAt': occurredAt.toUtc().toIso8601String(),
    'action': action,
    'affectedSpoolIds': [for (final id in affectedSpoolIds) id.value],
    'beforeState': beforeState?.name,
    'afterState': afterState.name,
    'beforeRemainingGrams': beforeRemainingGrams,
    'afterRemainingGrams': afterRemainingGrams,
  };

  factory SpoolHistoryEntry.fromJson(Map<String, dynamic> json) {
    return SpoolHistoryEntry(
      occurredAt: DateTime.parse(json['occurredAt'] as String),
      action: json['action'] as String,
      affectedSpoolIds: List.unmodifiable(
        (json['affectedSpoolIds'] as List).map(
          (id) => FilamentSpoolId.parse(id as String),
        ),
      ),
      beforeState: json['beforeState'] == null
          ? null
          : FilamentSpoolState.values.byName(json['beforeState'] as String),
      afterState: FilamentSpoolState.values.byName(
        json['afterState'] as String,
      ),
      beforeRemainingGrams: json['beforeRemainingGrams'] as int?,
      afterRemainingGrams: json['afterRemainingGrams'] as int,
    );
  }
}

final class FilamentSpool {
  const FilamentSpool({
    required this.id,
    required this.description,
    required this.remainingGrams,
    required this.state,
    required this.assignmentId,
    required this.history,
  });

  final FilamentSpoolId id;
  final SpoolDescription description;
  final int remainingGrams;
  final FilamentSpoolState state;
  final String? assignmentId;
  final List<SpoolHistoryEntry> history;

  factory FilamentSpool.registerUnlocated({
    required FilamentSpoolId id,
    required SpoolRegistration registration,
    required DateTime occurredAt,
  }) {
    if (registration.remainingGrams <= 0) {
      throw const FormatException('Remaining quantity must be positive.');
    }
    return FilamentSpool(
      id: id,
      description: registration.description,
      remainingGrams: registration.remainingGrams,
      state: FilamentSpoolState.unlocated,
      assignmentId: null,
      history: List.unmodifiable([
        SpoolHistoryEntry(
          occurredAt: occurredAt.toUtc(),
          action: 'Registered',
          affectedSpoolIds: List.unmodifiable([id]),
          beforeState: null,
          afterState: FilamentSpoolState.unlocated,
          beforeRemainingGrams: null,
          afterRemainingGrams: registration.remainingGrams,
        ),
      ]),
    );
  }

  FilamentSpool withDescription(SpoolDescription description) => FilamentSpool(
    id: id,
    description: description,
    remainingGrams: remainingGrams,
    state: state,
    assignmentId: assignmentId,
    history: history,
  );

  Map<String, Object?> toJson() => {
    'id': id.value,
    'description': description.toJson(),
    'remainingGrams': remainingGrams,
    'state': state.name,
    'assignmentId': assignmentId,
    'history': [for (final entry in history) entry.toJson()],
  };

  factory FilamentSpool.fromJson(Map<String, dynamic> json) {
    final historyJson = json['history'] as List;
    return FilamentSpool(
      id: FilamentSpoolId.parse(json['id'] as String),
      description: SpoolDescription.fromJson(
        json['description'] as Map<String, dynamic>,
      ),
      remainingGrams: json['remainingGrams'] as int,
      state: FilamentSpoolState.values.byName(json['state'] as String),
      assignmentId: json['assignmentId'] as String?,
      history: List.unmodifiable([
        for (final entry in historyJson)
          SpoolHistoryEntry.fromJson(entry as Map<String, dynamic>),
      ]),
    );
  }
}
