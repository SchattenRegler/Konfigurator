import 'package:flutter/material.dart';

class DividerWithText extends StatelessWidget {
  const DividerWithText({
    super.key,
    required this.text,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
    this.lineThickness = 1,
  });

  final String text;
  final EdgeInsetsGeometry padding;
  final double lineThickness;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dividerColor = colorScheme.outlineVariant.withOpacity(0.6);
    final textStyle = Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600) ??
        Theme.of(context).textTheme.titleMedium;

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Divider(
              thickness: lineThickness,
              height: lineThickness,
              color: dividerColor,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(text, style: textStyle),
          ),
          Expanded(
            child: Divider(
              thickness: lineThickness,
              height: lineThickness,
              color: dividerColor,
            ),
          ),
        ],
      ),
    );
  }
}
