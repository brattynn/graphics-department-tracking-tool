import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/truck.dart';
import '../state/truck_list_controller.dart';
import 'stage_badge.dart';

class TruckTable extends StatelessWidget {
  final List<Truck> trucks;
  final ValueChanged<Truck> onTap;

  /// Sorting is optional — pass both to enable tappable column headers.
  final TruckSortField? sortField;
  final bool sortAscending;
  final ValueChanged<TruckSortField>? onSort;

  const TruckTable({
    super.key,
    required this.trucks,
    required this.onTap,
    this.sortField,
    this.sortAscending = true,
    this.onSort,
  });

  static final _dateFmt = DateFormat.yMMMd();

  @override
  Widget build(BuildContext context) {
    if (trucks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No trucks match the current filters.'),
        ),
      );
    }

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          sortColumnIndex: sortField == null
              ? null
              : TruckSortField.values.indexOf(sortField!) + 2,
          sortAscending: sortAscending,
          columns: [
            const DataColumn(label: Text('HS #')),
            const DataColumn(label: Text('Truck / Job')),
            DataColumn(
              label: const Text('Bay'),
              onSort: onSort == null
                  ? null
                  : (_, _) => onSort!(TruckSortField.bay),
            ),
            DataColumn(
              label: const Text('Stage'),
              onSort: onSort == null
                  ? null
                  : (_, _) => onSort!(TruckSortField.stage),
            ),
            DataColumn(
              label: const Text('Schedule'),
              onSort: onSort == null
                  ? null
                  : (_, _) => onSort!(TruckSortField.scheduleStatus),
            ),
            DataColumn(
              label: const Text('Due Date'),
              onSort: onSort == null
                  ? null
                  : (_, _) => onSort!(TruckSortField.dueDate),
            ),
          ],
          rows: trucks.map((t) {
            return DataRow(
              onSelectChanged: (_) => onTap(t),
              cells: [
                DataCell(Text(t.hsNumber)),
                DataCell(Text(t.truckName)),
                DataCell(Text(t.bayNumber.toString())),
                DataCell(StageBadge(stage: t.currentStage)),
                DataCell(Text(t.scheduleStatus)),
                DataCell(Text(t.dueDate == null
                    ? '—'
                    : _dateFmt.format(t.dueDate!))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
