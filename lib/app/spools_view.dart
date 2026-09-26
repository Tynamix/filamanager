import 'package:filamanager/app/fila_theme.dart';
import 'package:filamanager/inventory/filament_spool.dart';
import 'package:flutter/material.dart';

final class SpoolsView extends StatefulWidget {
  const SpoolsView({
    required this.spools,
    required this.onAddSpool,
    required this.onOpenSpool,
    super.key,
  });

  final List<FilamentSpool> spools;
  final VoidCallback onAddSpool;
  final ValueChanged<FilamentSpool> onOpenSpool;

  @override
  State<SpoolsView> createState() => _SpoolsViewState();
}

final class _SpoolsViewState extends State<SpoolsView> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final matchingSpools = widget.spools.where((spool) {
      final description = spool.description;
      return [
        description.spoolLabel,
        description.materialType,
        description.manufacturer,
        description.productName,
        description.notes,
        description.filamentColor,
      ].whereType<String>().any((value) => value.toLowerCase().contains(query));
    }).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SpoolEyebrow('Local inventory'),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Spools',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: widget.onAddSpool,
                    icon: const Icon(Icons.add),
                    label: const Text('Add filament spool'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Search filament spools',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 16),
              if (widget.spools.isEmpty)
                const SpoolCard(child: Text('No active filament spools yet'))
              else if (matchingSpools.isEmpty)
                const SpoolCard(child: Text('No matching filament spools'))
              else
                for (final spool in matchingSpools) ...[
                  SpoolCard(
                    child: Material(
                      color: Colors.transparent,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: SpoolSwatch(
                          color: spool.description.filamentColor,
                        ),
                        title: Text(
                          spool.description.spoolLabel ??
                              spool.description.materialType,
                        ),
                        subtitle: Text(
                          '${spool.description.materialType} · Unlocated · ${spool.remainingGrams} g',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => widget.onOpenSpool(spool),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

final class SpoolDetailsView extends StatelessWidget {
  const SpoolDetailsView({
    required this.spool,
    required this.onBack,
    required this.onEdit,
    super.key,
  });

  final FilamentSpool spool;
  final VoidCallback onBack;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final description = spool.description;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to spools'),
              ),
              const SpoolEyebrow('Filament spool'),
              const SizedBox(height: 4),
              Text(
                description.spoolLabel ?? description.materialType,
                style: Theme.of(context).textTheme.displayMedium,
              ),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit details'),
              ),
              const SizedBox(height: 20),
              SpoolCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SpoolSwatch(color: description.filamentColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            description.materialType,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Unlocated'),
                    const Text('No assignment'),
                    Text('${spool.remainingGrams} g'),
                    Text(description.filamentColor),
                    if (description.manufacturer != null)
                      Text(description.manufacturer!),
                    if (description.productName != null)
                      Text(description.productName!),
                    if (description.originalNominalGrams != null)
                      Text('Original: ${description.originalNominalGrams} g'),
                    if (description.notes != null) Text(description.notes!),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'History',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              for (final entry in spool.history)
                SpoolCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.action),
                      Text(entry.occurredAt.toLocal().toString()),
                      Text(
                        'Affected: ${entry.affectedSpoolIds.length == 1 && entry.affectedSpoolIds.single == spool.id ? 'this filament spool' : '${entry.affectedSpoolIds.length} filament spools'}',
                      ),
                      Text(
                        entry.beforeState == null
                            ? 'Before: not registered'
                            : 'Before: ${entry.beforeState!.name} · ${entry.beforeRemainingGrams} g',
                      ),
                      Text(
                        'After: Unlocated · ${entry.afterRemainingGrams} g · no assignment',
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

final class RegisterSpoolSheet extends StatefulWidget {
  const RegisterSpoolSheet({this.editingSpool, super.key});

  final FilamentSpool? editingSpool;

  @override
  State<RegisterSpoolSheet> createState() => _RegisterSpoolSheetState();
}

final class _RegisterSpoolSheetState extends State<RegisterSpoolSheet> {
  final _material = TextEditingController();
  final _color = TextEditingController();
  final _remaining = TextEditingController();
  final _label = TextEditingController();
  final _manufacturer = TextEditingController();
  final _product = TextEditingController();
  final _nominal = TextEditingController();
  final _notes = TextEditingController();
  SpoolRegistration? _review;
  String? _error;

  Future<void> _pickColor() async {
    FocusScope.of(context).unfocus();
    final color = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choose one representative color'),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Text(
              'For transparent or multicolored material, choose the color that helps you recognize this spool.',
            ),
          ),
          for (final (name, hex) in const [
            ('White', '#F4F2E9'),
            ('Black', '#18211B'),
            ('Gray', '#8A918B'),
            ('Red', '#C54B43'),
            ('Orange', '#D8813C'),
            ('Yellow', '#DFBE4A'),
            ('Green', '#369568'),
            ('Blue', '#3468C0'),
            ('Purple', '#8553A3'),
            ('Pink', '#D87CA3'),
          ])
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(hex),
              child: Row(
                children: [
                  SpoolSwatch(color: hex),
                  const SizedBox(width: 12),
                  Text(name),
                  const Spacer(),
                  Text(hex),
                ],
              ),
            ),
        ],
      ),
    );
    if (color != null && mounted) {
      setState(() => _color.text = color);
    }
  }

  @override
  void initState() {
    super.initState();
    final spool = widget.editingSpool;
    if (spool != null) {
      final description = spool.description;
      _material.text = description.materialType;
      _color.text = description.filamentColor;
      _remaining.text = spool.remainingGrams.toString();
      _label.text = description.spoolLabel ?? '';
      _manufacturer.text = description.manufacturer ?? '';
      _product.text = description.productName ?? '';
      _nominal.text = description.originalNominalGrams?.toString() ?? '';
      _notes.text = description.notes ?? '';
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _material,
      _color,
      _remaining,
      _label,
      _manufacturer,
      _product,
      _nominal,
      _notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _showReview() {
    try {
      final remaining = int.tryParse(_remaining.text.trim());
      if (remaining == null || remaining <= 0) {
        throw const FormatException(
          'Enter a positive whole-gram remaining quantity.',
        );
      }
      final nominalText = _nominal.text.trim();
      final nominal = nominalText.isEmpty ? null : int.tryParse(nominalText);
      if (nominalText.isNotEmpty && (nominal == null || nominal <= 0)) {
        throw const FormatException(
          'Enter a positive whole-gram original quantity.',
        );
      }
      final description = SpoolDescription(
        materialType: _material.text,
        filamentColor: _color.text,
        spoolLabel: _label.text,
        manufacturer: _manufacturer.text,
        productName: _product.text,
        originalNominalGrams: nominal,
        notes: _notes.text,
      );
      FocusScope.of(context).unfocus();
      setState(() {
        _review = SpoolRegistration(
          description: description,
          remainingGrams: remaining,
        );
        _error = null;
      });
    } on FormatException catch (error) {
      setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final review = _review;
    final editing = widget.editingSpool != null;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .78,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SpoolEyebrow(
                review == null
                    ? editing
                          ? 'Edit filament spool'
                          : 'New filament spool'
                    : editing
                    ? 'Review changes'
                    : 'Review filament spool',
              ),
              const SizedBox(height: 6),
              Text(
                review == null
                    ? editing
                          ? 'Edit descriptive details'
                          : 'Register as Unlocated'
                    : editing
                    ? 'Save these details?'
                    : 'Register this filament spool?',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 14),
              Expanded(
                child: SingleChildScrollView(
                  child: review == null ? _form() : _reviewContents(review),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (review == null)
                FilledButton(
                  onPressed: _showReview,
                  child: Text(
                    editing ? 'Review changes' : 'Review filament spool',
                  ),
                )
              else ...[
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(review),
                  child: Text(
                    editing ? 'Save details' : 'Register filament spool',
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _review = null),
                  child: const Text('Back to edit'),
                ),
              ],
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _form() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text('Choose a material type or enter your own.'),
      Wrap(
        spacing: 8,
        children: [
          for (final suggestion in ['PLA', 'PETG', 'ABS', 'TPU'])
            ChoiceChip(
              label: Text(suggestion),
              selected: _material.text == suggestion,
              onSelected: (_) => setState(() => _material.text = suggestion),
            ),
        ],
      ),
      TextField(
        controller: _material,
        decoration: const InputDecoration(labelText: 'Material type'),
        onChanged: (_) => setState(() {}),
      ),
      TextField(
        controller: _color,
        decoration: const InputDecoration(
          labelText: 'Filament color (#RRGGBB)',
        ),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: _pickColor,
          icon: const Icon(Icons.palette_outlined),
          label: const Text('Pick filament color'),
        ),
      ),
      if (widget.editingSpool == null)
        TextField(
          controller: _remaining,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Remaining quantity (g)',
          ),
        ),
      const SizedBox(height: 12),
      const SpoolEyebrow('Optional details'),
      TextField(
        controller: _label,
        decoration: const InputDecoration(labelText: 'Spool label'),
      ),
      TextField(
        controller: _manufacturer,
        decoration: const InputDecoration(labelText: 'Manufacturer'),
      ),
      TextField(
        controller: _product,
        decoration: const InputDecoration(labelText: 'Product name'),
      ),
      TextField(
        controller: _nominal,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Original nominal quantity (g)',
        ),
      ),
      TextField(
        controller: _notes,
        decoration: const InputDecoration(labelText: 'Notes'),
      ),
    ],
  );

  Widget _reviewContents(SpoolRegistration registration) {
    final description = registration.description;
    return SpoolCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(description.spoolLabel ?? description.materialType),
          Text('Material type: ${description.materialType}'),
          Text('Filament color: ${description.filamentColor}'),
          Text('Remaining quantity: ${registration.remainingGrams} g'),
          if (widget.editingSpool == null) ...[
            const Text('Unlocated'),
            const Text('No assignment'),
          ] else
            const Text('No change to quantity, state, assignment, or history.'),
          if (description.manufacturer != null)
            Text('Manufacturer: ${description.manufacturer}'),
          if (description.productName != null)
            Text('Product name: ${description.productName}'),
          if (description.originalNominalGrams != null)
            Text(
              'Original nominal quantity: ${description.originalNominalGrams} g',
            ),
          if (description.notes != null) Text('Notes: ${description.notes}'),
        ],
      ),
    );
  }
}

final class SpoolEyebrow extends StatelessWidget {
  const SpoolEyebrow(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      color: FilaColors.muted,
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.1,
    ),
  );
}

final class SpoolCard extends StatelessWidget {
  const SpoolCard({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
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

final class SpoolSwatch extends StatelessWidget {
  const SpoolSwatch({required this.color, super.key});
  final String color;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Filament color $color',
    child: Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Color(int.parse(color.substring(1), radix: 16) | 0xFF000000),
        border: Border.all(color: FilaColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
    ),
  );
}
