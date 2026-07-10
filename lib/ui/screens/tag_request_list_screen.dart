import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/tag_request.dart';
import '../../utils/constants.dart';
import '../state/tag_request_list_controller.dart';
import '../state/truck_list_controller.dart';
import '../widgets/filter_dropdown.dart';
import 'tag_request_form_screen.dart';

class TagRequestListScreen extends StatefulWidget {
  const TagRequestListScreen({super.key});

  @override
  State<TagRequestListScreen> createState() => _TagRequestListScreenState();
}

class _TagRequestListScreenState extends State<TagRequestListScreen> {
  static final _dateFmt = DateFormat.yMMMd();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TagRequestListController>().load();
      context.read<TruckListController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TagRequestListController>();
    final trucks = context.watch<TruckListController>();
    final truckLookup = {
      for (final t in [...trucks.visibleTrucks, ...trucks.archived]) t.id: t,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Tag / Label Requests')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-tag-request-fab',
        icon: const Icon(Icons.add),
        label: const Text('Add Request'),
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TagRequestFormScreen()),
          );
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilterDropdown<String?>(
                  value: controller.statusFilter,
                  hint: 'All statuses',
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All statuses')),
                    for (final s in TagStatus.all)
                      DropdownMenuItem(value: s, child: Text(s)),
                  ],
                  onChanged: controller.setStatusFilter,
                ),
                FilterDropdown<int?>(
                  value: controller.bayFilter,
                  hint: 'All bays',
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All bays')),
                    for (var b = 1; b <= bayCount; b++)
                      DropdownMenuItem(value: b, child: Text('Bay $b')),
                  ],
                  onChanged: controller.setBayFilter,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: controller.loading
                ? const Center(child: CircularProgressIndicator())
                : controller.requests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.label_off_outlined,
                                size: 40,
                                color: Theme.of(context).colorScheme.onSurfaceVariant),
                            const SizedBox(height: 12),
                            Text(
                              'No tag requests match the current filters.',
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                        itemCount: controller.requests.length,
                        itemBuilder: (context, i) {
                          final r = controller.requests[i];
                          final truck = truckLookup[r.truckId];
                          return _TagRequestTile(
                            request: r,
                            truckLabel: truck == null
                                ? 'Unknown truck'
                                : '${truck.hsNumber} — ${truck.truckName}',
                            dateFmt: _dateFmt,
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      TagRequestFormScreen(existing: r),
                                ),
                              );
                            },
                            onToggleStatus: () {
                              if (r.status == TagStatus.needed) {
                                controller.markCompleted(r.id!);
                              } else {
                                controller.markNeeded(r.id!);
                              }
                            },
                            onDelete: () => controller.delete(r.id!),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _TagRequestTile extends StatelessWidget {
  final TagRequest request;
  final String truckLabel;
  final DateFormat dateFmt;
  final VoidCallback onTap;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const _TagRequestTile({
    required this.request,
    required this.truckLabel,
    required this.dateFmt,
    required this.onTap,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = request.status == TagStatus.completed;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: Checkbox(
          value: isCompleted,
          onChanged: (_) => onToggleStatus(),
        ),
        title: Text('${request.tagType} — $truckLabel'),
        subtitle: Text(
          '${request.tagText}\nRequested ${dateFmt.format(request.dateRequested)} · Bay ${request.bayRequestedBy}'
          '${request.dateMade != null ? ' · Made ${dateFmt.format(request.dateMade!)}' : ''}',
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
