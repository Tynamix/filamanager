import 'package:filamanager/app/fila_components.dart';
import 'package:filamanager/app/fila_theme.dart';
import 'package:filamanager/inventory/filament_spool.dart';
import 'package:flutter/material.dart';

final class FilamentColorPickerDialog extends StatefulWidget {
  const FilamentColorPickerDialog({required this.initialHex, super.key});

  final String initialHex;

  @override
  State<FilamentColorPickerDialog> createState() =>
      _FilamentColorPickerDialogState();
}

final class _FilamentColorPickerDialogState
    extends State<FilamentColorPickerDialog> {
  static const _presets = <(String, String)>[
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
  ];

  late final TextEditingController _hex;
  late HSVColor _hsv;
  var _validHex = true;

  @override
  void initState() {
    super.initState();
    final initial = _normalizedOrNull(widget.initialHex) ?? _presets.first.$2;
    _hex = TextEditingController(text: initial);
    _hsv = HSVColor.fromColor(_colorOf(initial));
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  static String? _normalizedOrNull(String value) {
    try {
      return SpoolDescription.normalizeFilamentColor(value);
    } on FormatException {
      return null;
    }
  }

  static Color _colorOf(String hex) =>
      Color(0xFF000000 | int.parse(hex.substring(1), radix: 16));

  static String _hexOf(Color color) {
    final rgb = color.toARGB32() & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  void _setHsv(HSVColor value) {
    setState(() {
      _hsv = value;
      _hex.text = _hexOf(value.toColor());
      _validHex = true;
    });
  }

  void _onHexChanged(String value) {
    final normalized = _normalizedOrNull(value);
    setState(() {
      _validHex = normalized != null;
      if (normalized != null) {
        _hsv = HSVColor.fromColor(_colorOf(normalized));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedHex = _normalizedOrNull(_hex.text);
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 440,
          maxHeight: MediaQuery.sizeOf(context).height * .86,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose one representative color',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'For transparent or multicolored filament, choose the color that helps you recognize this spool.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const FilaEyebrow('Presets'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final (name, hex) in _presets)
                            ChoiceChip(
                              label: Text(name),
                              avatar: _ColorDot(color: _colorOf(hex)),
                              selected: selectedHex == hex,
                              onSelected: (_) =>
                                  _setHsv(HSVColor.fromColor(_colorOf(hex))),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const FilaEyebrow('Custom color'),
                      const SizedBox(height: 8),
                      Text(
                        'Drag in the color area or adjust hue, saturation, and brightness.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      _ColorPlane(hsv: _hsv, onChanged: _setHsv),
                      const SizedBox(height: 12),
                      _colorSlider(
                        'Hue',
                        _hsv.hue,
                        360,
                        (value) => _setHsv(
                          HSVColor.fromAHSV(
                            1,
                            value,
                            _hsv.saturation,
                            _hsv.value,
                          ),
                        ),
                      ),
                      _colorSlider(
                        'Saturation',
                        _hsv.saturation,
                        1,
                        (value) => _setHsv(
                          HSVColor.fromAHSV(1, _hsv.hue, value, _hsv.value),
                        ),
                      ),
                      _colorSlider(
                        'Brightness',
                        _hsv.value,
                        1,
                        (value) => _setHsv(
                          HSVColor.fromAHSV(
                            1,
                            _hsv.hue,
                            _hsv.saturation,
                            value,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilaFormField(
                        controller: _hex,
                        label: 'Hex color (#RRGGBB)',
                        isRequired: true,
                        onChanged: _onHexChanged,
                      ),
                      if (!_validHex)
                        Semantics(
                          liveRegion: true,
                          child: const Text(
                            'Enter six hexadecimal color digits.',
                            style: TextStyle(color: FilaColors.error),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _ColorDot(color: _hsv.toColor(), size: 38),
                  const SizedBox(width: 10),
                  Text(
                    selectedHex ?? 'Invalid color',
                    style: const TextStyle(
                      color: FilaColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: selectedHex == null
                          ? null
                          : () =>
                                Navigator.of(context)
                                    .pop(_normalizedOrNull(_hex.text)),
                      child: const Text('Apply color'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _colorSlider(
    String label,
    double value,
    double max,
    ValueChanged<double> onChanged,
  ) => Column(
    children: [
      Row(
        children: [
          SizedBox(width: 90, child: Text(label)),
          Expanded(
            child: Semantics(
              label: label,
              child: Slider(value: value, max: max, onChanged: onChanged),
            ),
          ),
        ],
      ),
      if (label == 'Hue')
        Padding(
          padding: const EdgeInsets.fromLTRB(90, 0, 22, 12),
          child: Semantics(
            label: 'Hue spectrum',
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: const LinearGradient(
                  colors: [
                    Colors.red,
                    Colors.yellow,
                    Colors.green,
                    Colors.cyan,
                    Colors.blue,
                    Colors.purple,
                    Colors.red,
                  ],
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

final class _ColorPlane extends StatelessWidget {
  const _ColorPlane({required this.hsv, required this.onChanged});

  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;

  @override
  Widget build(BuildContext context) {
    final hue = HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const height = 176.0;

        void select(Offset point) {
          final saturation = (point.dx / width).clamp(0.0, 1.0);
          final brightness = (1 - point.dy / height).clamp(0.0, 1.0);
          onChanged(HSVColor.fromAHSV(1, hsv.hue, saturation, brightness));
        }

        return Semantics(
          label: 'Color saturation and brightness area',
          child: GestureDetector(
            onTapDown: (details) => select(details.localPosition),
            onPanUpdate: (details) => select(details.localPosition),
            child: SizedBox(
              height: height,
              child: Stack(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(colors: [Colors.white, hue]),
                    ),
                    child: const SizedBox.expand(),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black],
                      ),
                    ),
                    child: const SizedBox.expand(),
                  ),
                  Positioned(
                    left: (hsv.saturation * width - 10).clamp(0, width - 20),
                    top: ((1 - hsv.value) * height - 10).clamp(0, height - 20),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black54, blurRadius: 3),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

final class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color, this.size = 18});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: FilaColors.line),
    ),
  );
}
