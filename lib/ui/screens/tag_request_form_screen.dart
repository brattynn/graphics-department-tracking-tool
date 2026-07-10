import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/tag_request.dart';
import '../../utils/constants.dart';
import '../state/tag_request_list_controller.dart';
import '../state/truck_list_controller.dart';

/// Quick-add/edit form for ad-hoc installer tag/label requests.
/// Pass [existing] to edit, or [presetTruckId] to preselect a truck
/// (e.g. when adding from a truck's detail screen).
class TagRequestFormScreen extends StatefulWidget {
  final TagRequest? existing;
  final int? presetTruckId;

  const TagRequestFormScreen({super.key, this.existing, this.presetTruckId});

  @override
  State<TagRequestFormScreen> createState() => _TagRequestFormScreenState();
}

class _TagRequestFormScreenState extends State<TagRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tagTypeCtrl;
  late final TextEditingController _tagTextCtrl;

  DateTime _dateRequested = DateTime.now();
  int? _bayRequestedBy;
  int? _truckId;
  bool _completed = false;
  DateTime? _dateMade;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final r = widget.existing;
    _tagTypeCtrl = TextEditingController(text: r?.tagType ?? '');
    _tagTextCtrl = TextEditingController(text: r?.tagText ?? '');
    _dateRequested = r?.dateRequested ?? DateTime.now();
    _bayRequestedBy = r?.bayRequestedBy;
    _truckId = r?.truckId ?? widget.presetTruckId;
    _completed = r?.status == TagStatus.completed;
    _dateMade = r?.dateMade;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TruckListController>().load();
    });
  }

  @override
  void dispose() {
    _tagTypeCtrl.dispose();
    _tagTextCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateRequested,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _dateRequested = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_bayRequestedBy == null || _truckId == null) {
      setState(() {});
      return;
    }
    setState(() => _saving = true);

    final controller = context.read<TagRequestListController>();
    final request = TagRequest(
      id: widget.existing?.id,
      dateRequested: _dateRequested,
      bayRequestedBy: _bayRequestedBy!,
      truckId: _truckId!,
      tagType: _tagTypeCtrl.text.trim(),
      tagText: _tagTextCtrl.text.trim(),
      dateMade: _completed ? (_dateMade ?? DateTime.now()) : null,
      status: _completed ? TagStatus.completed : TagStatus.needed,
    );

    if (_isEdit) {
      await controller.update(request);
    } else {
      await controller.create(request);
    }

    if (mounted) {
      setState(() => _saving = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final trucks = context.watch<TruckListController>();
    final allTrucks = [...trucks.visibleTrucks, ...trucks.archived];

    return Scaffold(
      appBar: AppBar(
          title: Text(_isEdit ? 'Edit Tag Request' : 'Add Tag Request')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Date requested: '
                      '${_dateRequested.toLocal().toString().split(' ').first}'),
                  trailing: TextButton(
                      onPressed: _pickDate, child: const Text('Pick')),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: _bayRequestedBy,
                  decoration:
                      const InputDecoration(labelText: 'Requesting Bay *'),
                  items: [
                    for (var b = 1; b <= bayCount; b++)
                      DropdownMenuItem(value: b, child: Text('Bay $b')),
                  ],
                  onChanged: (v) => setState(() => _bayRequestedBy = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: allTrucks.any((t) => t.id == _truckId)
                      ? _truckId
                      : null,
                  decoration: const InputDecoration(labelText: 'Truck (HS #) *'),
                  items: [
                    for (final t in allTrucks)
                      DropdownMenuItem(
                        value: t.id,
                        child: Text('${t.hsNumber} — ${t.truckName}'),
                      ),
                  ],
                  onChanged: (v) => setState(() => _truckId = v),
                  validator: (v) => v == null ? 'Select a truck' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tagTypeCtrl,
                  decoration: const InputDecoration(labelText: 'Tag Type *'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tagTextCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Tag Text *'),
                  maxLines: 3,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Completed'),
                  subtitle: _completed && _dateMade != null
                      ? Text('Made: ${_dateMade!.toLocal().toString().split(' ').first}')
                      : null,
                  value: _completed,
                  onChanged: (v) => setState(() {
                    _completed = v ?? false;
                    if (_completed) _dateMade ??= DateTime.now();
                  }),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_isEdit ? 'Save Changes' : 'Add Request'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
