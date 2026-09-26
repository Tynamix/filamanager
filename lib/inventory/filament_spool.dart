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
    final id = FilamentSpoolId.parse(json['id'] as String);
    final remainingGrams = json['remainingGrams'];
    final assignmentId = json['assignmentId'];
    if (remainingGrams is! int || remainingGrams <= 0) {
      throw const FormatException(
        'Active filament spool must have a positive quantity.',
      );
    }
    if (assignmentId != null) {
      throw const FormatException(
        'Unlocated filament spool cannot have an assignment.',
      );
    }
    final historyJson = json['history'];
    if (historyJson is! List || historyJson.isEmpty) {
      throw const FormatException(
        'Filament spool must have registration history.',
      );
    }
    final history = List<SpoolHistoryEntry>.unmodifiable([
      for (final entry in historyJson)
        SpoolHistoryEntry.fromJson(entry as Map<String, dynamic>),
    ]);
    final registration = history.first;
    if (registration.action != 'Registered' ||
        registration.beforeState != null ||
        registration.beforeRemainingGrams != null ||
        !registration.affectedSpoolIds.contains(id) ||
        history.last.afterRemainingGrams != remainingGrams) {
      throw const FormatException('Invalid filament-spool history.');
    }
    for (final entry in history) {
      if (entry.action.trim().isEmpty ||
          !entry.affectedSpoolIds.contains(id) ||
          entry.afterRemainingGrams <= 0) {
        throw const FormatException('Invalid filament-spool history entry.');
      }
    }
    for (var index = 1; index < history.length; index++) {
      if (history[index].occurredAt.isBefore(history[index - 1].occurredAt)) {
        throw const FormatException('Filament-spool history is out of order.');
      }
    }
    return FilamentSpool(
      id: id,
      description: SpoolDescription.fromJson(
        json['description'] as Map<String, dynamic>,
      ),
      remainingGrams: remainingGrams,
      state: FilamentSpoolState.values.byName(json['state'] as String),
      assignmentId: null,
      history: history,
    );
  }
}
