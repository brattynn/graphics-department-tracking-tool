import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/constants.dart';
import '../state/truck_list_controller.dart';
import '../widgets/filter_dropdown.dart';
import '../widgets/truck_table.dart';
import 'truck_detail_screen.dart';
import 'truck_form_screen.dart';

class TruckListScreen extends StatefulWidget {
  const TruckListScreen({super.key});

  @override
  State<TruckListScreen> createState() => _TruckListScreenState();
}

class _TruckListScreenState extends State<TruckListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TruckListController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TruckListController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Active Trucks (${controller.visibleTrucks.length}/8)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.load(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Truck'),
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TruckFormScreen()),
          );
        },
      ),
      body: controller.loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilterDropdown<int?>(
                        value: controller.bayFilter,
                        hint: 'All bays',
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All bays')),
                          for (var b = 1; b <= bayCount; b++)
                            DropdownMenuItem(value: b, child: Text('Bay $b')),
                        ],
                        onChanged: (v) => controller.setBayFilter(v),
                      ),
                      FilterDropdown<String?>(
                        value: controller.stageFilter,
                        hint: 'All stages',
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All stages')),
                          for (final s in Stage.all)
                            DropdownMenuItem(value: s, child: Text(s)),
                        ],
                        onChanged: (v) => controller.setStageFilter(v),
                      ),
                      FilterDropdown<String?>(
                        value: controller.scheduleStatusFilter,
                        hint: 'All schedule statuses',
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('All schedule statuses')),
                          for (final s in ScheduleStatus.all)
                            DropdownMenuItem(value: s, child: Text(s)),
                        ],
                        onChanged: (v) => controller.setScheduleStatusFilter(v),
                      ),
                      if (controller.bayFilter != null ||
                          controller.stageFilter != null ||
                          controller.scheduleStatusFilter != null)
                        TextButton.icon(
                          onPressed: controller.clearFilters,
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('Clear filters'),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: TruckTable(
                    trucks: controller.visibleTrucks,
                    sortField: controller.sortField,
                    sortAscending: controller.sortAscending,
                    onSort: controller.setSort,
                    onTap: (truck) async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              TruckDetailScreen(truckId: truck.id!),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
