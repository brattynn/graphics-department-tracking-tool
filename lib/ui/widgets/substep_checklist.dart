import 'package:flutter/material.dart';

import '../../models/substep_progress.dart';

class SubstepChecklist extends StatefulWidget {
  final List<SubstepProgress> substeps;
  final bool readOnly;
  final void Function(SubstepProgress substep, bool complete) onToggle;
  final void Function(String name) onAddCustom;
  final void Function(SubstepProgress substep) onRemove;

  const SubstepChecklist({
    super.key,
    required this.substeps,
    required this.onToggle,
    required this.onAddCustom,
    required this.onRemove,
    this.readOnly = false,
  });

  @override
  State<SubstepChecklist> createState() => _SubstepChecklistState();
}

class _SubstepChecklistState extends State<SubstepChecklist> {
  final _customController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _submitCustom() {
    final name = _customController.text.trim();
    if (name.isEmpty) return;
    widget.onAddCustom(name);
    _customController.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.substeps.isEmpty && widget.readOnly) {
      return const Text('No sub-steps (dealer-supplied graphics).');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.substeps.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No sub-steps yet.'),
          ),
        ...widget.substeps.map((s) {
          return CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: s.isComplete,
            onChanged: widget.readOnly
                ? null
                : (v) => widget.onToggle(s, v ?? false),
            title: Text(
              s.substepName,
              style: s.isComplete
                  ? const TextStyle(decoration: TextDecoration.lineThrough)
                  : null,
            ),
            secondary: widget.readOnly
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Remove sub-step',
                    onPressed: () => widget.onRemove(s),
                  ),
          );
        }),
        if (!widget.readOnly) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customController,
                  decoration: const InputDecoration(
                    labelText: 'Add custom sub-step',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _submitCustom(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _submitCustom,
                child: const Text('Add'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
