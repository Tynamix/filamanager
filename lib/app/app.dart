import 'dart:async';

import 'package:filamanager/app/app_dependencies.dart';
import 'package:filamanager/app/fila_theme.dart';
import 'package:filamanager/inventory/material_unit.dart';
import 'package:filamanager/inventory/storage_slot.dart';
import 'package:filamanager/inventory/storage_slot_reference.dart';
import 'package:filamanager/services/nfc_service.dart';
import 'package:flutter/material.dart';

final class FilaManagerApp extends StatelessWidget {
  const FilaManagerApp({required this.dependencies, super.key});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FilaManager',
      theme: FilaTheme.light,
      home: _InventoryShell(dependencies: dependencies),
    );
  }
}

final class _InventoryShell extends StatefulWidget {
  const _InventoryShell({required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<_InventoryShell> createState() => _InventoryShellState();
}

final class _InventoryShellState extends State<_InventoryShell> {
  var _selectedIndex = 0;
  StorageSlot? _selectedStorageSlot;
  MaterialUnit? _selectedMaterialUnit;
  String? _referenceError;
  late final StreamSubscription<NfcEvent> _nfcEvents;
  late final StreamSubscription<Uri> _incomingLinks;

  @override
  void initState() {
    super.initState();
    _nfcEvents = widget.dependencies.nfcService.events.listen((event) {
      switch (event) {
        case NfcUriPayloadRead():
          _openStorageSlotReference(
            event.payload,
            receivedMessage: 'NFC input received',
            invalidReferenceTitle: 'Unknown tag',
          );
        case NfcContentRead():
          _openStorageSlotReference(
            Uri.tryParse(event.content),
            receivedMessage: 'NFC input received',
            invalidReferenceTitle: 'Unknown tag',
          );
        case NfcTagRejected():
          _showScanFailure(
            event.kind == NfcTagFailureKind.unformatted
                ? 'Tag is not NDEF-formatted'
                : 'Incompatible NFC tag',
          );
        case NfcScanUnavailable():
          _showInventoryUnchangedResult(
            _nfcAvailabilityMessage(event.availability),
          );
        case NfcScanCancelled():
          _showInventoryUnchangedResult('Scan cancelled');
        case NfcScanFailed():
          _showInventoryUnchangedResult('NFC scan failed');
      }
    });
    _incomingLinks = widget.dependencies.incomingLinkService.links.listen((
      uri,
    ) {
      _openStorageSlotReference(
        uri,
        receivedMessage: 'Incoming link received',
        invalidReferenceTitle: 'Invalid storage-slot link',
      );
    });
    final initialIncomingLink = widget.dependencies.initialIncomingLink;
    if (initialIncomingLink != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _openStorageSlotReference(
            initialIncomingLink,
            receivedMessage: 'Incoming link received',
            invalidReferenceTitle: 'Invalid storage-slot link',
          );
        }
      });
    }
  }

  @override
  void dispose() {
    unawaited(_nfcEvents.cancel());
    unawaited(_incomingLinks.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final destinations = [
      _InventoryDestination(
        icon: Icons.nfc,
        label: 'Home',
        content: _HomeView(
          onScan: widget.dependencies.nfcService.scan,
          onShowAll: () => _selectDestination(1),
        ),
      ),
      const _InventoryDestination(
        icon: Icons.album_outlined,
        label: 'Spools',
        content: _EmptyArea(
          icon: Icons.album_outlined,
          title: 'Spools',
          message: 'No active filament spools yet',
        ),
      ),
      _InventoryDestination(
        icon: Icons.shelves,
        label: 'Places',
        content: _selectedStorageSlot != null
            ? _StorageSlotContextView(
                storageSlot: _selectedStorageSlot!,
                onRegisterTag: () => _registerTag(_selectedStorageSlot!),
                onEdit: _editStorageSlot,
              )
            : _selectedMaterialUnit != null
            ? _MaterialUnitContextView(
                materialUnit: _selectedMaterialUnit!,
                onEdit: _editMaterialUnit,
              )
            : _referenceError != null
            ? _ReferenceErrorView(title: _referenceError!)
            : _PlacesView(
                storageSlots: widget.dependencies.inventory.storageSlots
                    .where((slot) => !slot.archived)
                    .toList(),
                materialUnits: widget.dependencies.inventory.materialUnits
                    .where((unit) => !unit.archived)
                    .toList(),
                onAddStorageSlot: _createStorageSlot,
                onAddMaterialUnit: _createMaterialUnit,
                onOpenStorageSlot: _openStorageSlot,
                onOpenMaterialUnit: _openMaterialUnit,
              ),
      ),
      const _InventoryDestination(
        icon: Icons.archive_outlined,
        label: 'Archive',
        content: _EmptyArea(
          icon: Icons.archive_outlined,
          title: 'Archive',
          message: 'No consumed or retired filament spools',
        ),
      ),
    ];

    return PopScope(
      canPop:
          _selectedIndex == 0 &&
          _selectedStorageSlot == null &&
          _selectedMaterialUnit == null &&
          _referenceError == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        if (_selectedStorageSlot != null ||
            _selectedMaterialUnit != null ||
            _referenceError != null) {
          setState(() {
            _selectedStorageSlot = null;
            _selectedMaterialUnit = null;
            _referenceError = null;
          });
        } else if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: FilaColors.canvas,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final content = destinations[_selectedIndex].content;
              final page = ColoredBox(
                color: FilaColors.surface,
                child: Column(
                  children: [
                    const _AppHeader(),
                    Expanded(child: content),
                  ],
                ),
              );
              if (constraints.maxWidth >= 600) {
                return Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: _selectDestination,
                      labelType: NavigationRailLabelType.all,
                      destinations: [
                        for (final destination in destinations)
                          NavigationRailDestination(
                            icon: Icon(destination.icon),
                            label: Text(destination.label),
                          ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: page),
                  ],
                );
              }

              return page;
            },
          ),
        ),
        bottomNavigationBar: MediaQuery.sizeOf(context).width < 600
            ? SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: _CompactNavigation(
                  destinations: destinations,
                  selectedIndex: _selectedIndex,
                  onSelected: _selectDestination,
                ),
              )
            : null,
      ),
    );
  }

  void _selectDestination(int index) {
    setState(() {
      _selectedIndex = index;
      if (index != 2) {
        _selectedStorageSlot = null;
        _selectedMaterialUnit = null;
        _referenceError = null;
      }
    });
  }

  Future<void> _createStorageSlot() async {
    final storageSlot = await showModalBottomSheet<StorageSlot>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _StorageSlotSheet(
        onSave: (name, area) =>
            widget.dependencies.createStorageSlot(name, area: area),
      ),
    );
    if (storageSlot == null || !mounted) {
      return;
    }
    setState(() => _selectedStorageSlot = storageSlot);
    _showPlaceSaved('Storage slot created');
  }

  Future<void> _editStorageSlot() async {
    final current = _selectedStorageSlot!;
    final renamed = await showModalBottomSheet<StorageSlot>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _StorageSlotSheet(
        initial: current,
        onSave: (name, area) =>
            widget.dependencies.renameStorageSlot(current.id, name, area: area),
      ),
    );
    if (renamed != null && mounted) {
      setState(() => _selectedStorageSlot = renamed);
      _showPlaceSaved('Storage slot saved');
    }
  }

  Future<void> _createMaterialUnit() async {
    final unit = await showModalBottomSheet<MaterialUnit>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _MaterialUnitSheet(
        onSave: (name, slots) =>
            widget.dependencies.createMaterialUnit(name, slots),
      ),
    );
    if (unit != null && mounted) {
      setState(() => _selectedMaterialUnit = unit);
      _showPlaceSaved('Material unit created');
    }
  }

  Future<void> _editMaterialUnit() async {
    final current = _selectedMaterialUnit!;
    final renamed = await showModalBottomSheet<MaterialUnit>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _MaterialUnitSheet(
        initial: current,
        onSave: (name, slots) => widget.dependencies.renameMaterialUnit(
          current.id,
          name,
          slotNames: {
            for (var i = 0; i < current.slots.length; i++)
              current.slots[i].id: slots[i],
          },
        ),
      ),
    );
    if (renamed != null && mounted) {
      setState(() => _selectedMaterialUnit = renamed);
      _showPlaceSaved('Material unit saved');
    }
  }

  void _showPlaceSaved(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Semantics(liveRegion: true, child: Text(message))),
      );
  }

  void _openStorageSlot(StorageSlot storageSlot) {
    setState(() {
      _selectedStorageSlot = storageSlot;
      _selectedMaterialUnit = null;
      _referenceError = null;
    });
  }

  void _openMaterialUnit(MaterialUnit unit) {
    setState(() {
      _selectedMaterialUnit = unit;
      _selectedStorageSlot = null;
      _referenceError = null;
    });
  }

  void _openStorageSlotReference(
    Uri? uri, {
    required String receivedMessage,
    required String invalidReferenceTitle,
  }) {
    final storageSlotId = uri == null ? null : StorageSlotReference.parse(uri);
    StorageSlot? storageSlot;
    if (storageSlotId != null) {
      for (final candidate in widget.dependencies.inventory.storageSlots) {
        if (candidate.id == storageSlotId) {
          storageSlot = candidate;
          break;
        }
      }
    }

    setState(() {
      _selectedIndex = 2;
      _selectedStorageSlot = storageSlot;
      _selectedMaterialUnit = null;
      _referenceError = storageSlotId == null
          ? invalidReferenceTitle
          : storageSlot == null
          ? 'Unknown storage slot'
          : null;
    });
    if (_referenceError != null) {
      _showInventoryUnchangedResult(receivedMessage);
    }
  }

  void _showScanFailure(String title) {
    setState(() {
      _selectedIndex = 2;
      _selectedStorageSlot = null;
      _selectedMaterialUnit = null;
      _referenceError = title;
    });
    _showInventoryUnchangedResult(title);
  }

  Future<void> _registerTag(StorageSlot storageSlot) async {
    final availability = await widget.dependencies.nfcService.availability();
    if (!mounted) {
      return;
    }
    if (availability != NfcAvailability.available) {
      _showInventoryUnchangedResult(_nfcAvailabilityMessage(availability));
      return;
    }

    final reference = StorageSlotReference.forStorageSlot(storageSlot.id);
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _RegisterTagSheet(reference: reference),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    final resultFuture = widget.dependencies.nfcService
        .writeStorageSlotReference(reference);
    final result = await showModalBottomSheet<NfcWriteResult>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => _WriteTagProgressSheet(
        result: resultFuture,
        onCancel: widget.dependencies.nfcService.cancelSession,
      ),
    );
    if (!mounted) {
      return;
    }
    _showInventoryUnchangedResult(
      _writeResultMessage(
        result ?? const NfcWriteFailed(NfcWriteFailureKind.unexpected),
      ),
    );
  }

  String _writeResultMessage(NfcWriteResult result) {
    return switch (result) {
      NfcWriteSucceeded() => 'Tag registered',
      NfcWriteCancelled() => 'Tag registration cancelled',
      NfcWriteFailed(:final kind) => switch (kind) {
        NfcWriteFailureKind.disabled => 'NFC is disabled',
        NfcWriteFailureKind.unavailable => 'NFC is unavailable',
        NfcWriteFailureKind.incompatible => 'Incompatible NFC tag',
        NfcWriteFailureKind.unformatted => 'Tag is not NDEF-formatted',
        NfcWriteFailureKind.readOnly => 'Tag is read-only',
        NfcWriteFailureKind.insufficientCapacity =>
          'Tag does not have enough capacity',
        NfcWriteFailureKind.interrupted => 'Tag write was interrupted',
        NfcWriteFailureKind.unexpected => 'Tag registration failed',
      },
    };
  }

  String _nfcAvailabilityMessage(NfcAvailability availability) {
    return switch (availability) {
      NfcAvailability.disabled => 'NFC is disabled',
      NfcAvailability.unavailable => 'NFC is unavailable',
      NfcAvailability.available => 'NFC is available',
    };
  }

  void _showInventoryUnchangedResult(String message) {
    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Semantics(
            container: true,
            liveRegion: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message),
                const Text('No inventory changes were made.'),
              ],
            ),
          ),
        ),
      );
  }
}

final class _ReferenceErrorView extends StatelessWidget {
  const _ReferenceErrorView({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Eyebrow('Nothing changed'),
              const SizedBox(height: 4),
              Text(title, style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 20),
              const _PrototypeCard(
                child: _EmptyCardContent(
                  icon: Icons.nfc_outlined,
                  title: 'No inventory changes were made.',
                  message: 'Try scanning again or choose a place manually.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _PlacesView extends StatelessWidget {
  const _PlacesView({
    required this.storageSlots,
    required this.materialUnits,
    required this.onAddStorageSlot,
    required this.onAddMaterialUnit,
    required this.onOpenStorageSlot,
    required this.onOpenMaterialUnit,
  });

  final List<StorageSlot> storageSlots;
  final List<MaterialUnit> materialUnits;
  final Future<void> Function() onAddStorageSlot;
  final Future<void> Function() onAddMaterialUnit;
  final ValueChanged<StorageSlot> onOpenStorageSlot;
  final ValueChanged<MaterialUnit> onOpenMaterialUnit;

  @override
  Widget build(BuildContext context) {
    final areas = <String, String?>{};
    for (final slot in storageSlots) {
      areas.putIfAbsent(
        (slot.area ?? '').trim().toLowerCase(),
        () => slot.area,
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Eyebrow('Local inventory'),
              const SizedBox(height: 4),
              Text('Places', style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: onAddStorageSlot,
                    icon: const Icon(Icons.add),
                    label: const Text('Add storage slot'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onAddMaterialUnit,
                    icon: const Icon(Icons.add),
                    label: const Text('Add material unit'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (storageSlots.isEmpty && materialUnits.isEmpty)
                const _PrototypeCard(
                  child: _EmptyCardContent(
                    icon: Icons.shelves,
                    title: 'No storage slots or material units yet',
                    message: 'Create a storage slot or material unit to get started.',
                  ),
                )
              else ...[
                if (storageSlots.isNotEmpty) const _Eyebrow('Storage slots'),
                for (final area in areas.entries) ...[
                  const SizedBox(height: 12),
                  Text(
                    area.value ?? 'No storage area',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  for (final storageSlot in storageSlots.where(
                    (slot) =>
                        (slot.area ?? '').trim().toLowerCase() == area.key,
                  )) ...[
                    _PrototypeCard(
                      child: Material(
                        color: Colors.transparent,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.shelves),
                          title: Text(storageSlot.name),
                          subtitle: Text(
                            'Storage slot · ${storageSlot.archived
                                ? 'Archived'
                                : storageSlot.occupantId == null
                                ? 'Empty'
                                : 'Occupied'}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => onOpenStorageSlot(storageSlot),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
                if (materialUnits.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const _Eyebrow('Material units'),
                  const SizedBox(height: 12),
                  for (final unit in materialUnits) ...[
                    _PrototypeCard(
                      child: Material(
                        color: Colors.transparent,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.view_module_outlined),
                          title: Text(unit.name),
                          subtitle: Text(
                            '${unit.slots.length} material ${unit.slots.length == 1 ? 'slot' : 'slots'} · ${unit.archived ? 'Archived' : 'Active'}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => onOpenMaterialUnit(unit),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

final class _StorageSlotContextView extends StatelessWidget {
  const _StorageSlotContextView({
    required this.storageSlot,
    required this.onRegisterTag,
    required this.onEdit,
  });

  final StorageSlot storageSlot;
  final Future<void> Function() onRegisterTag;
  final Future<void> Function() onEdit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Eyebrow('Read-only storage-slot context'),
              const SizedBox(height: 4),
              Text(
                storageSlot.name,
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 10),
              _PlaceStatusPill(archived: storageSlot.archived),
              if (storageSlot.area != null) Text(storageSlot.area!),
              const SizedBox(height: 20),
              _PrototypeCard(
                child: _EmptyCardContent(
                  icon: Icons.inventory_2_outlined,
                  title: storageSlot.occupantId == null ? 'Empty' : 'Occupied',
                  message: storageSlot.occupantId == null
                      ? 'No filament spool occupies this storage slot.'
                      : 'A filament spool occupies this storage slot.',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit storage slot'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onRegisterTag,
                  icon: const Icon(Icons.nfc),
                  label: const Text('Register NFC tag'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _MaterialUnitContextView extends StatelessWidget {
  const _MaterialUnitContextView({
    required this.materialUnit,
    required this.onEdit,
  });

  final MaterialUnit materialUnit;
  final Future<void> Function() onEdit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Eyebrow('Material unit'),
              const SizedBox(height: 4),
              Text(
                materialUnit.name,
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 10),
              _PlaceStatusPill(archived: materialUnit.archived),
              const SizedBox(height: 20),
              for (final slot in materialUnit.slots.where(
                (slot) => !slot.archived,
              )) ...[
                _PrototypeCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.view_module_outlined),
                    title: Text(slot.name),
                    subtitle: Text(
                      'Material slot · Active · ${slot.occupantId == null ? 'Empty' : 'Occupied'}',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit material unit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _RegisterTagSheet extends StatelessWidget {
  const _RegisterTagSheet({required this.reference});

  final Uri reference;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Eyebrow('Confirm tag write'),
            const SizedBox(height: 6),
            Text(
              'Replace tag contents?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            const Text('The complete NDEF message will be replaced.'),
            const SizedBox(height: 10),
            SelectableText(reference.toString()),
            const SizedBox(height: 8),
            const Text('Registering this tag will not change inventory.'),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Replace and register'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

final class _WriteTagProgressSheet extends StatefulWidget {
  const _WriteTagProgressSheet({required this.result, required this.onCancel});

  final Future<NfcWriteResult> result;
  final Future<void> Function() onCancel;

  @override
  State<_WriteTagProgressSheet> createState() => _WriteTagProgressSheetState();
}

final class _WriteTagProgressSheetState extends State<_WriteTagProgressSheet> {
  var _cancelling = false;

  @override
  void initState() {
    super.initState();
    unawaited(_closeWithResult());
  }

  Future<void> _closeWithResult() async {
    final result = await widget.result;
    if (mounted) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Eyebrow('NFC tag registration'),
            const SizedBox(height: 6),
            Text(
              _cancelling ? 'Cancelling…' : 'Ready to write',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
            const SizedBox(height: 12),
            const Text('Hold your phone near the writable NDEF tag.'),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _cancelling
                  ? null
                  : () async {
                      setState(() => _cancelling = true);
                      await widget.onCancel();
                    },
              child: const Text('Cancel tag registration'),
            ),
          ],
        ),
      ),
    );
  }
}

final class _PlaceReview extends StatelessWidget {
  const _PlaceReview({
    required this.kind,
    required this.nameLabel,
    required this.name,
    required this.creating,
    required this.saving,
    required this.details,
    required this.onConfirm,
    required this.onBack,
  });

  final String kind;
  final String nameLabel;
  final String name;
  final bool creating;
  final bool saving;
  final List<Widget> details;
  final VoidCallback onConfirm;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final action = creating ? 'Create' : 'Save';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Eyebrow('Review $kind'),
        const SizedBox(height: 6),
        Text(
          '$action this $kind?',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 18),
        _PrototypeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Eyebrow(nameLabel),
              const SizedBox(height: 4),
              Text(name, style: Theme.of(context).textTheme.titleMedium),
              ...details,
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text('No inventory changes have been made.'),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: saving ? null : onConfirm,
          child: Text('$action $kind'),
        ),
        TextButton(onPressed: onBack, child: const Text('Back to edit')),
      ],
    );
  }
}

final class _PlaceSheetError extends StatelessWidget {
  const _PlaceSheetError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 12),
      Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
      const Text('No inventory changes were made.'),
    ],
  );
}

Future<void> _submitPlace<T>({
  required BuildContext context,
  required Future<T> Function() save,
  required void Function(String) onError,
  required String kind,
}) async {
  try {
    final result = await save();
    if (context.mounted) Navigator.of(context).pop(result);
  } on PlaceValidationException catch (error) {
    if (context.mounted) onError(error.message);
  } catch (_) {
    if (context.mounted) onError('Could not save $kind. Try again.');
  }
}

final class _StorageSlotSheet extends StatefulWidget {
  const _StorageSlotSheet({this.initial, required this.onSave});

  final StorageSlot? initial;
  final Future<StorageSlot> Function(String name, String? area) onSave;

  @override
  State<_StorageSlotSheet> createState() => _StorageSlotSheetState();
}

final class _StorageSlotSheetState extends State<_StorageSlotSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _areaController;
  var _reviewing = false;
  var _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name);
    _areaController = TextEditingController(text: widget.initial?.area);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = _nameController.text.trim();
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _reviewing
                ? [
                    _PlaceReview(
                      kind: 'storage slot',
                      nameLabel: 'Storage-slot name',
                      name: name,
                      creating: widget.initial == null,
                      saving: _saving,
                      onConfirm: _submit,
                      onBack: () => setState(() => _reviewing = false),
                      details: [
                        if (_areaController.text.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const _Eyebrow('Storage area'),
                          const SizedBox(height: 4),
                          Text(_areaController.text.trim()),
                        ],
                      ],
                    ),
                  ]
                : [
                    const _Eyebrow('New place'),
                    const SizedBox(height: 6),
                    Text(
                      widget.initial == null
                          ? 'Create storage slot'
                          : 'Edit storage slot',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _nameController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Storage-slot name',
                      ),
                      onChanged: (_) => setState(() => _error = null),
                      onSubmitted: name.isEmpty ? null : (_) => _review(),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _areaController,
                      decoration: const InputDecoration(
                        labelText: 'Storage area (optional)',
                      ),
                      onChanged: (_) => setState(() => _error = null),
                    ),
                    if (_error != null) ...[_PlaceSheetError(_error!)],
                    const SizedBox(height: 18),
                    OutlinedButton(
                      onPressed: _review,
                      child: const Text('Review storage slot'),
                    ),
                  ],
          ),
        ),
      ),
    );
  }

  void _review() {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = 'Storage-slot name is required.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _reviewing = true);
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    await _submitPlace(
      context: context,
      kind: 'storage slot',
      save: () => widget.onSave(_nameController.text, _areaController.text),
      onError: (message) => setState(() {
        _error = message;
        _reviewing = false;
        _saving = false;
      }),
    );
  }
}

final class _MaterialUnitSheet extends StatefulWidget {
  const _MaterialUnitSheet({this.initial, required this.onSave});

  final MaterialUnit? initial;
  final Future<MaterialUnit> Function(String name, List<String> slots) onSave;

  @override
  State<_MaterialUnitSheet> createState() => _MaterialUnitSheetState();
}

final class _MaterialUnitSheetState extends State<_MaterialUnitSheet> {
  late final TextEditingController _nameController;
  late final List<TextEditingController> _slotControllers;
  var _reviewing = false;
  var _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name);
    _slotControllers = widget.initial == null
        ? [TextEditingController()]
        : [
            for (final slot in widget.initial!.slots)
              TextEditingController(text: slot.name),
          ];
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final controller in _slotControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _reviewing
              ? [
                  _PlaceReview(
                    kind: 'material unit',
                    nameLabel: 'Material-unit name',
                    name: _nameController.text.trim(),
                    creating: widget.initial == null,
                    saving: _saving,
                    onConfirm: _submit,
                    onBack: () => setState(() => _reviewing = false),
                    details: [
                      const SizedBox(height: 12),
                      const _Eyebrow('Material slots'),
                      for (final controller in _slotControllers) ...[
                        const SizedBox(height: 4),
                        Text(controller.text.trim()),
                      ],
                    ],
                  ),
                ]
              : [
                  const _Eyebrow('Places'),
                  const SizedBox(height: 6),
                  Text(
                    widget.initial == null
                        ? 'Create material unit'
                        : 'Edit material unit',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Material-unit name',
                    ),
                    onChanged: (_) => setState(() => _error = null),
                  ),
                  const SizedBox(height: 16),
                  const _Eyebrow('Material slots'),
                  const SizedBox(height: 8),
                  for (
                    var index = 0;
                    index < _slotControllers.length;
                    index++
                  ) ...[
                    TextField(
                      controller: _slotControllers[index],
                      decoration: InputDecoration(
                        labelText: 'Material-slot name ${index + 1}',
                      ),
                      onChanged: (_) => setState(() => _error = null),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (widget.initial == null) ...[
                    TextButton.icon(
                      onPressed: () => setState(
                        () => _slotControllers.add(TextEditingController()),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Add material slot'),
                    ),
                    if (_slotControllers.length > 1)
                      TextButton(
                        onPressed: () => setState(
                          () => _slotControllers.removeLast().dispose(),
                        ),
                        child: const Text('Remove last slot'),
                      ),
                  ],
                  if (_error != null) ...[_PlaceSheetError(_error!)],
                  const SizedBox(height: 18),
                  OutlinedButton(
                    onPressed: _review,
                    child: const Text('Review material unit'),
                  ),
                ],
        ),
      ),
    );
  }

  void _review() {
    if (_nameController.text.trim().isEmpty ||
        _slotControllers.any((controller) => controller.text.trim().isEmpty)) {
      setState(
        () => _error = 'Name the material unit and every material slot.',
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _reviewing = true);
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    await _submitPlace(
      context: context,
      kind: 'material unit',
      save: () => widget.onSave(_nameController.text, [
        for (final controller in _slotControllers) controller.text,
      ]),
      onError: (message) => setState(() {
        _error = message;
        _reviewing = false;
        _saving = false;
      }),
    );
  }
}

final class _CompactNavigation extends StatelessWidget {
  const _CompactNavigation({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_InventoryDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        border: Border.all(color: FilaColors.line),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2118281E),
            blurRadius: 35,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var index = 0; index < destinations.length; index++)
            Expanded(
              child: _CompactDestinationButton(
                destination: destinations[index],
                selectedIndex: selectedIndex,
                index: index,
                onSelected: onSelected,
              ),
            ),
        ],
      ),
    );
  }
}

final class _CompactDestinationButton extends StatelessWidget {
  const _CompactDestinationButton({
    required this.destination,
    required this.selectedIndex,
    required this.index,
    required this.onSelected,
  });

  final _InventoryDestination destination;
  final int selectedIndex;
  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = selectedIndex == index;
    final color = selected ? Colors.white : FilaColors.muted;

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: ExcludeSemantics(
        child: Material(
          color: selected ? FilaColors.green : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () => onSelected(index),
            borderRadius: BorderRadius.circular(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(destination.icon, size: 20, color: color),
                const SizedBox(height: 3),
                Text(
                  destination.label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _AppHeader extends StatelessWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: FilaColors.green,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Text(
              'F',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.4,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FilaManager',
                  style: TextStyle(
                    color: FilaColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Scan-led context',
                  style: TextStyle(color: FilaColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: FilaColors.greenLight,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 9, color: FilaColors.green),
                SizedBox(width: 6),
                Text(
                  'Local',
                  style: TextStyle(
                    color: FilaColors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _InventoryDestination {
  const _InventoryDestination({
    required this.icon,
    required this.label,
    required this.content,
  });

  final IconData icon;
  final String label;
  final Widget content;
}

final class _HomeView extends StatelessWidget {
  const _HomeView({required this.onScan, required this.onShowAll});

  final Future<void> Function() onScan;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Eyebrow('Ready when you are'),
              const SizedBox(height: 8),
              Text(
                'Find the slot.\nMove the spool.',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 10),
              Text(
                'Scanning is the fastest way in. Every action also works manually.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 22),
              _ScanHero(onScan: onScan),
              const SizedBox(height: 30),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Eyebrow('Manual lookup'),
                        const SizedBox(height: 3),
                        Text(
                          'Find a spool',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: onShowAll,
                    child: const Text('See all'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const _PrototypeCard(
                child: _EmptyCardContent(
                  icon: Icons.album_outlined,
                  title: 'No active filament spools yet',
                  message: 'Registered filament spools will appear here.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _ScanHero extends StatelessWidget {
  const _ScanHero({required this.onScan});

  final Future<void> Function() onScan;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Scan a storage-slot tag',
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [FilaColors.greenDark, Color(0xFF28654B)],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x24312027),
                  blurRadius: 55,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            child: InkWell(
              onTap: onScan,
              borderRadius: BorderRadius.circular(28),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.75),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.nfc,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 17),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scan a storage-slot tag',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Hold the top of your phone near a tag.',
                            style: TextStyle(
                              color: Color(0xFFC9DBD1),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _EmptyArea extends StatelessWidget {
  const _EmptyArea({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Eyebrow('Local inventory'),
              const SizedBox(height: 4),
              Text(title, style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 20),
              _PrototypeCard(
                child: _EmptyCardContent(
                  icon: icon,
                  title: message,
                  message: 'This area is ready for your inventory.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: FilaColors.muted,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
      ),
    );
  }
}

final class _PlaceStatusPill extends StatelessWidget {
  const _PlaceStatusPill({required this.archived});

  final bool archived;

  @override
  Widget build(BuildContext context) {
    final label = archived ? 'Archived' : 'Active';
    return Semantics(
      label: 'Place status: $label',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: archived ? FilaColors.canvas : FilaColors.greenLight,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: FilaColors.line),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: archived ? FilaColors.muted : FilaColors.green,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

final class _PrototypeCard extends StatelessWidget {
  const _PrototypeCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: FilaColors.line),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D1D3024),
            blurRadius: 20,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

final class _EmptyCardContent extends StatelessWidget {
  const _EmptyCardContent({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFEDF3ED),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: FilaColors.green),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(message),
            ],
          ),
        ),
      ],
    );
  }
}
