import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../../models/truck.dart';
import '../../repositories/truck_repository.dart';
import '../../utils/constants.dart';
import '../../utils/file_paths.dart';
import '../../utils/open_file.dart';
import '../state/truck_list_controller.dart';

/// Add/Edit form. Pass [existing] to edit; omit to create a new truck.
class TruckFormScreen extends StatefulWidget {
  final Truck? existing;

  const TruckFormScreen({super.key, this.existing});

  @override
  State<TruckFormScreen> createState() => _TruckFormScreenState();
}

class _TruckFormScreenState extends State<TruckFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _hsNumberCtrl;
  late final TextEditingController _truckNameCtrl;
  late final TextEditingController _customerCtrl;
  late final TextEditingController _notesCtrl;

  int? _bayNumber;
  bool _dealerSupplied = false;
  String _scheduleStatus = ScheduleStatus.inBay;
  DateTime? _dueDate;
  String? _proofPath1;
  String? _proofPath2;

  String? _stripeColor;
  late final TextEditingController _stripeColorCustomCtrl;
  String? _chevronColor;
  late final TextEditingController _chevronColorCustomCtrl;
  String? _stripeFeature;
  late final TextEditingController _stripeFeatureCustomCtrl;
  bool _stripeOnStainless = false;

  List<int> _availableBays = [];
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    _hsNumberCtrl = TextEditingController(text: t?.hsNumber ?? '');
    _truckNameCtrl = TextEditingController(text: t?.truckName ?? '');
    _customerCtrl = TextEditingController(text: t?.customer ?? '');
    _notesCtrl = TextEditingController(text: t?.notes ?? '');
    _bayNumber = t?.bayNumber;
    _dealerSupplied = t?.dealerSuppliedGraphics ?? false;
    _scheduleStatus = t?.scheduleStatus ?? ScheduleStatus.inBay;
    _dueDate = t?.dueDate;
    _proofPath1 = t?.proofFinalPath1;
    _proofPath2 = t?.proofFinalPath2;
    _stripeColor = t?.stripeColor;
    _stripeColorCustomCtrl =
        TextEditingController(text: t?.stripeColorCustom ?? '');
    _chevronColor = t?.chevronColor;
    _chevronColorCustomCtrl =
        TextEditingController(text: t?.chevronColorCustom ?? '');
    _stripeFeature = t?.stripeFeature;
    _stripeFeatureCustomCtrl =
        TextEditingController(text: t?.stripeFeatureCustom ?? '');
    _stripeOnStainless = t?.stripeOnStainless ?? false;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = context.read<TruckListController>();
      final bays = await controller.availableBays(
          excludingTruckId: widget.existing?.id);
      setState(() {
        _availableBays = bays;
        _bayNumber ??= bays.isNotEmpty ? bays.first : null;
      });
    });
  }

  @override
  void dispose() {
    _hsNumberCtrl.dispose();
    _truckNameCtrl.dispose();
    _customerCtrl.dispose();
    _notesCtrl.dispose();
    _stripeColorCustomCtrl.dispose();
    _chevronColorCustomCtrl.dispose();
    _stripeFeatureCustomCtrl.dispose();
    super.dispose();
  }

  static const _pdfTypeGroup = XTypeGroup(label: 'PDF', extensions: ['pdf']);

  Future<void> _pickProof(int slot) async {
    final XFile? picked = await openFile(acceptedTypeGroups: [_pdfTypeGroup]);
    if (picked == null) return;

    final sourcePath = picked.path;
    // Copy into app-data so the record survives the source file moving/deleting.
    // Uses a temp truck id (0) for new trucks; re-homed under the real id
    // isn't necessary since the folder is keyed by id only for organization.
    final dir = await AppPaths.proofsDirectoryForTruck(
        widget.existing?.id ?? 0);
    final destName =
        'proof_${slot}_${DateTime.now().millisecondsSinceEpoch}${p.extension(sourcePath)}';
    final destPath = p.join(dir.path, destName);
    await File(sourcePath).copy(destPath);

    if (!mounted) return;
    setState(() {
      if (slot == 1) {
        _proofPath1 = destPath;
      } else {
        _proofPath2 = destPath;
      }
    });
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_bayNumber == null) {
      setState(() => _error = 'Select a bay.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final controller = context.read<TruckListController>();
    final truck = Truck(
      id: widget.existing?.id,
      hsNumber: _hsNumberCtrl.text.trim(),
      truckName: _truckNameCtrl.text.trim(),
      customer:
          _customerCtrl.text.trim().isEmpty ? null : _customerCtrl.text.trim(),
      bayNumber: _bayNumber!,
      currentStage: widget.existing?.currentStage ?? Stage.proofing,
      dateEnteredStage: widget.existing?.dateEnteredStage ?? DateTime.now(),
      dealerSuppliedGraphics: _dealerSupplied,
      scheduleStatus: _scheduleStatus,
      dueDate: _dueDate,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      proofFinalPath1: _proofPath1,
      proofFinalPath2: _proofPath2,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
      isActive: widget.existing?.isActive ?? true,
      stripeColor: _stripeColor,
      stripeColorCustom:
          _stripeColor == customOption ? _stripeColorCustomCtrl.text.trim() : null,
      chevronColor: _chevronColor,
      chevronColorCustom: _chevronColor == customOption
          ? _chevronColorCustomCtrl.text.trim()
          : null,
      stripeFeature: _stripeFeature,
      stripeFeatureCustom: _stripeFeature == customOption
          ? _stripeFeatureCustomCtrl.text.trim()
          : null,
      stripeOnStainless: _stripeOnStainless,
    );

    try {
      if (_isEdit) {
        await controller.updateTruckDetails(truck);
      } else {
        await controller.createTruck(truck);
      }
      if (mounted) Navigator.of(context).pop();
    } on DuplicateHsNumberException catch (e) {
      setState(() => _error = e.toString());
    } on BayTakenException catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Truck' : 'Add Truck')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  ),
                TextFormField(
                  controller: _hsNumberCtrl,
                  decoration: const InputDecoration(labelText: 'HS Number *'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _truckNameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Truck Name / Job Identifier *'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customerCtrl,
                  decoration: const InputDecoration(labelText: 'Customer'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _availableBays.contains(_bayNumber)
                      ? _bayNumber
                      : null,
                  decoration: const InputDecoration(labelText: 'Bay *'),
                  items: [
                    for (final b in _availableBays)
                      DropdownMenuItem(value: b, child: Text('Bay $b')),
                  ],
                  onChanged: (v) => setState(() => _bayNumber = v),
                  validator: (v) => v == null ? 'Select an open bay' : null,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Dealer-supplied graphics'),
                  subtitle: const Text(
                      'Skips Production/Installation sub-steps for this truck'),
                  value: _dealerSupplied,
                  onChanged: (v) => setState(() => _dealerSupplied = v),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: _scheduleStatus,
                  decoration:
                      const InputDecoration(labelText: 'Schedule Status'),
                  items: [
                    for (final s in ScheduleStatus.all)
                      DropdownMenuItem(value: s, child: Text(s)),
                  ],
                  onChanged: (v) =>
                      setState(() => _scheduleStatus = v ?? _scheduleStatus),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_dueDate == null
                      ? 'No due date set'
                      : 'Due: ${_dueDate!.toLocal().toString().split(' ').first}'),
                  trailing: Wrap(
                    children: [
                      TextButton(
                          onPressed: _pickDueDate, child: const Text('Pick')),
                      if (_dueDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _dueDate = null),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                Text('Graphics Specification',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                _PickOneOrCustomField(
                  label: 'Stripe Color',
                  options: StripeColor.all,
                  value: _stripeColor,
                  customController: _stripeColorCustomCtrl,
                  onChanged: (v) => setState(() => _stripeColor = v),
                ),
                const SizedBox(height: 12),
                _PickOneOrCustomField(
                  label: 'Chevron Color',
                  options: ChevronColor.all,
                  value: _chevronColor,
                  customController: _chevronColorCustomCtrl,
                  onChanged: (v) => setState(() => _chevronColor = v),
                ),
                const SizedBox(height: 12),
                _PickOneOrCustomField(
                  label: 'Stripe Feature',
                  options: StripeFeature.all,
                  value: _stripeFeature,
                  customController: _stripeFeatureCustomCtrl,
                  onChanged: (v) => setState(() => _stripeFeature = v),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Stripe on Stainless'),
                  value: _stripeOnStainless,
                  onChanged: (v) => setState(() => _stripeOnStainless = v),
                ),
                const SizedBox(height: 20),
                Text('Final Approved Proofs (2 required once approved)',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                _ProofPicker(
                  label: 'Proof 1',
                  path: _proofPath1,
                  onPick: () => _pickProof(1),
                  onClear: () => setState(() => _proofPath1 = null),
                ),
                const SizedBox(height: 8),
                _ProofPicker(
                  label: 'Proof 2',
                  path: _proofPath2,
                  onPick: () => _pickProof(2),
                  onClear: () => setState(() => _proofPath2 = null),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_isEdit ? 'Save Changes' : 'Add Truck'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A dropdown of fixed options plus a "Custom" choice that reveals a
/// free-text field. Shared by the stripe color / chevron color / stripe
/// feature pickers, which all follow this exact shape.
class _PickOneOrCustomField extends StatelessWidget {
  final String label;
  final List<String> options;
  final String? value;
  final TextEditingController customController;
  final ValueChanged<String?> onChanged;

  const _PickOneOrCustomField({
    required this.label,
    required this.options,
    required this.value,
    required this.customController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isCustom = value == customOption;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: options.contains(value) ? value : null,
          decoration: InputDecoration(labelText: label),
          items: [
            for (final o in options) DropdownMenuItem(value: o, child: Text(o)),
          ],
          onChanged: onChanged,
        ),
        if (isCustom) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: customController,
            decoration: InputDecoration(labelText: '$label (Custom)'),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Enter a value for Custom $label'
                : null,
          ),
        ],
      ],
    );
  }
}

class _ProofPicker extends StatelessWidget {
  final String label;
  final String? path;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _ProofPicker({
    required this.label,
    required this.path,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 70, child: Text(label)),
        Expanded(
          child: Text(
            path == null ? 'No file attached' : p.basename(path!),
            overflow: TextOverflow.ellipsis,
            style: path == null
                ? TextStyle(color: Theme.of(context).hintColor)
                : null,
          ),
        ),
        if (path != null)
          TextButton(
            onPressed: () => openLocalFile(context, path!),
            child: const Text('View'),
          ),
        TextButton(onPressed: onPick, child: const Text('Attach PDF')),
        if (path != null)
          IconButton(icon: const Icon(Icons.clear), onPressed: onClear),
      ],
    );
  }
}
