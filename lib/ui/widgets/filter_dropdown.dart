import 'package:flutter/material.dart';

/// Pill-shaped dropdown used for the list-screen filter bars. Visually
/// distinguishes an active filter (something other than "All ...") from an
/// inactive one via fill/border color.
class FilterDropdown<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const FilterDropdown({
    super.key,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = value != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: active
            ? scheme.primaryContainer.withValues(alpha: 0.55)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active
              ? scheme.primary.withValues(alpha: 0.45)
              : scheme.outlineVariant,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
          icon: Icon(Icons.expand_more_rounded,
              size: 18, color: scheme.onSurfaceVariant),
          borderRadius: BorderRadius.circular(10),
          style: TextStyle(
            color: active ? scheme.onPrimaryContainer : scheme.onSurface,
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
