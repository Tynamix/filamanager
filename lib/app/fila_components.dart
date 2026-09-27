import 'package:filamanager/app/fila_theme.dart';
import 'package:flutter/material.dart';

final class FilaEyebrow extends StatelessWidget {
  const FilaEyebrow(this.text, {super.key});

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

final class FilaCard extends StatelessWidget {
  const FilaCard({required this.child, super.key});

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

final class FilaDetailRow extends StatelessWidget {
  const FilaDetailRow({required this.label, required this.child, super.key});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [FilaEyebrow(label), const SizedBox(height: 4), child],
    ),
  );
}

final class FilaFormField extends StatelessWidget {
  const FilaFormField({
    required this.controller,
    required this.label,
    required this.isRequired,
    this.focusNode,
    this.autofocus = false,
    this.keyboardType,
    this.maxLines = 1,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final bool isRequired;
  final FocusNode? focusNode;
  final bool autofocus;
  final TextInputType? keyboardType;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    const outline = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide(color: FilaColors.line),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: const TextStyle(
          color: FilaColors.ink,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.25,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: FilaColors.muted,
            fontWeight: FontWeight.w600,
          ),
          floatingLabelStyle: const TextStyle(
            color: FilaColors.muted,
            fontWeight: FontWeight.w600,
          ),
          helperText: isRequired ? 'Required' : 'Optional',
          helperStyle: const TextStyle(color: FilaColors.muted, fontSize: 11),
          filled: true,
          fillColor: Colors.white,
          border: outline,
          enabledBorder: outline,
          focusedBorder: outline.copyWith(
            borderSide: const BorderSide(color: FilaColors.green, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}

final class FilaAppHeader extends StatelessWidget {
  const FilaAppHeader({super.key});

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
