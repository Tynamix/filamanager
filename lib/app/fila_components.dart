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
