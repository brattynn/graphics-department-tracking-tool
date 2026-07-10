import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/truck_list_controller.dart';
import '../widgets/truck_table.dart';
import 'truck_detail_screen.dart';

/// Read-only view of the 8 most recently completed trucks.
class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
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
        title: Text('Archive (${controller.archived.length}/8 most recent)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.load(),
          ),
        ],
      ),
      body: controller.loading
          ? const Center(child: CircularProgressIndicator())
          : TruckTable(
              trucks: controller.archived,
              onTap: (truck) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TruckDetailScreen(
                      truckId: truck.id!,
                      readOnly: true,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
