import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../../models/substep_progress.dart';
import '../../models/tag_request.dart';
import '../../models/truck.dart';
import '../../repositories/substep_repository.dart';
import '../../repositories/tag_request_repository.dart';
import '../../repositories/truck_repository.dart';
import '../../utils/constants.dart';
import '../../utils/open_file.dart';
import '../state/truck_list_controller.dart';
import '../widgets/stage_badge.dart';
import '../widgets/substep_checklist.dart';
import 'tag_request_form_screen.dart';
import 'truck_form_screen.dart';

class TruckDetailScreen extends StatefulWidget {
  final int truckId;
  final bool readOnly;

  const TruckDetailScreen({
    super.key,
    required this.truckId,
    this.readOnly = false,
  });

  @override
  State<TruckDetailScreen> createState() => _TruckDetailScreenState();
}

class _TruckDetailScreenState extends State<TruckDetailScreen> {
  final _truckRepo = TruckRepository();
  final _substepRepo = SubstepRepository();
  final _tagRepo = TagRequestRepository();

  Truck? _truck;
  List<SubstepProgress> _substeps = [];
  List<TagRequest> _tagRequests = [];
  bool _loading = true;

  static final _dateFmt = DateFormat.yMMMd();
  // A distinct instance, not built by chaining .add_jm() off _dateFmt at
  // call time: intl's add_jm() mutates the formatter in place and returns
  // it, so calling it on a shared static instance inside build() would
  // permanently accumulate another time pattern onto _dateFmt every rebuild.
  static final _dateTimeFmt = DateFormat.yMMMd().add_jm();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final truck = await _truckRepo.getById(widget.truckId);
    final substeps = await _substepRepo.getForTruck(widget.truckId);
    final tags = await _tagRepo.getForTruck(widget.truckId);
    setState(() {
      _truck = truck;
      _substeps = substeps;
      _tagRequests = tags;
      _loading = false;
    });
  }

  Future<void> _changeStage(String newStage) async {
    final truck = _truck!;
    if (newStage == truck.currentStage) return;
    final truckController = context.read<TruckListController>();

    if (newStage == Stage.complete) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Mark Complete'),
          content: const Text(
              'This archives the truck and frees its bay. If more than '
              '8 trucks are archived, the oldest archived truck will be '
              'permanently deleted. Continue?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Mark Complete')),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    await truckController.changeStage(truck.id!, newStage);
    await _load();
  }

  Future<void> _setScheduleStatus(String status) async {
    await context.read<TruckListController>().setScheduleStatus(
        _truck!.id!, status);
    await _load();
  }

  Future<void> _deleteTruck() async {
    final truckController = context.read<TruckListController>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Truck'),
        content: Text(
            'Delete ${_truck!.hsNumber} — ${_truck!.truckName}? This also deletes its tag requests. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await truckController.deleteTruck(_truck!.id!);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _truck == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final truck = _truck!;

    return Scaffold(
      appBar: AppBar(
        title: Text('${truck.hsNumber} — ${truck.truckName}'),
        actions: [
          if (!widget.readOnly) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit',
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => TruckFormScreen(existing: truck),
                ));
                await _load();
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              onPressed: _deleteTruck,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _section(children: [
                Row(
                  children: [
                    StageBadge(stage: truck.currentStage),
                    const SizedBox(width: 12),
                    Text('Bay ${truck.bayNumber}',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(width: 12),
                    Chip(label: Text(truck.scheduleStatus)),
                  ],
                ),
                if (!widget.readOnly) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Stage:'),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: truck.currentStage,
                        items: [
                          for (final s in Stage.all)
                            DropdownMenuItem(value: s, child: Text(s)),
                        ],
                        onChanged: (v) {
                          if (v != null) _changeStage(v);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Schedule status:'),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: truck.scheduleStatus,
                        items: [
                          for (final s in ScheduleStatus.all)
                            DropdownMenuItem(value: s, child: Text(s)),
                        ],
                        onChanged: (v) {
                          if (v != null) _setScheduleStatus(v);
                        },
                      ),
                    ],
                  ),
                ],
              ]),
              _section(children: [
                _infoRow('Customer', truck.customer ?? '—'),
                _infoRow('Due Date',
                    truck.dueDate == null ? '—' : _dateFmt.format(truck.dueDate!)),
                _infoRow('Dealer-supplied graphics',
                    truck.dealerSuppliedGraphics ? 'Yes' : 'No'),
                _infoRow('Entered current stage',
                    _dateTimeFmt.format(truck.dateEnteredStage)),
                _infoRow('Created', _dateFmt.format(truck.createdAt)),
                if (truck.notes != null && truck.notes!.isNotEmpty)
                  _infoRow('Notes', truck.notes!),
              ]),
              _section(title: 'Graphics Specification', children: [
                _infoRow('Stripe Color', truck.stripeColorDisplay ?? '—'),
                _infoRow('Chevron Color', truck.chevronColorDisplay ?? '—'),
                _infoRow('Stripe Feature', truck.stripeFeatureDisplay ?? '—'),
                _infoRow('Stripe on Stainless',
                    truck.stripeOnStainless ? 'Yes' : 'No'),
              ]),
              _section(title: 'Final Approved Proofs', children: [
                _proofRow('Proof 1', truck.proofFinalPath1),
                _proofRow('Proof 2', truck.proofFinalPath2),
              ]),
              _section(title: 'Production/Installation Sub-steps', children: [
                if (truck.dealerSuppliedGraphics)
                  const Text('Skipped — dealer-supplied graphics.')
                else if (truck.currentStage != Stage.productionInstallation &&
                    _substeps.isEmpty)
                  const Text('Not yet applicable for the current stage.')
                else
                  SubstepChecklist(
                    substeps: _substeps,
                    readOnly: widget.readOnly,
                    onToggle: (s, complete) async {
                      await _substepRepo.setComplete(
                          s.id!, truck.id!, s.substepName, complete);
                      await _load();
                    },
                    onAddCustom: (name) async {
                      await _substepRepo.addCustom(truck.id!, name);
                      await _load();
                    },
                    onRemove: (s) async {
                      await _substepRepo.removeSubstep(s.id!);
                      await _load();
                    },
                  ),
              ]),
              _section(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tag / Label Requests',
                        style: Theme.of(context).textTheme.titleSmall),
                    if (!widget.readOnly)
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add'),
                        onPressed: () async {
                          await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) =>
                                TagRequestFormScreen(presetTruckId: truck.id),
                          ));
                          await _load();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_tagRequests.isEmpty)
                  const Text('No tag requests for this truck.')
                else
                  ..._tagRequests.map((tr) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(tr.tagType),
                        subtitle: Text(tr.tagText),
                        trailing: Chip(label: Text(tr.status)),
                      )),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section({String? title, required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 12),
            ],
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 200,
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _proofRow(String label, String? path) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 70, child: Text(label)),
          Expanded(
            child: Text(
              path == null ? 'Not attached' : p.basename(path),
              style: path == null
                  ? TextStyle(color: Theme.of(context).hintColor)
                  : null,
            ),
          ),
          if (path != null)
            TextButton.icon(
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('View'),
              onPressed: () => openLocalFile(context, path),
            ),
        ],
      ),
    );
  }
}
