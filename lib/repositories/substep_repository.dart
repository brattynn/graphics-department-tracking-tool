import '../db/database_helper.dart';
import '../models/substep_progress.dart';
import '../utils/constants.dart';
import 'stage_history_repository.dart';

/// Manages the per-truck Production/Installation checklist.
///
/// Default sub-step rows are seeded as real data (not hardcoded into the UI)
/// so custom one-off sub-steps can be inserted alongside them uniformly.
class SubstepRepository {
  final StageHistoryRepository _stageHistoryRepo = StageHistoryRepository();

  Future<void> seedDefaults(int truckId) async {
    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();
    for (var i = 0; i < defaultSubsteps.length; i++) {
      batch.insert(
        'substep_progress',
        SubstepProgress(
          truckId: truckId,
          substepName: defaultSubsteps[i],
          sortOrder: i,
        ).toMap()
          ..remove('id'),
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<SubstepProgress>> getForTruck(int truckId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'substep_progress',
      where: 'truck_id = ?',
      whereArgs: [truckId],
      orderBy: 'sort_order ASC',
    );
    return rows.map(SubstepProgress.fromMap).toList();
  }

  Future<int> addCustom(int truckId, String name) async {
    final db = await DatabaseHelper.instance.database;
    final existing = await getForTruck(truckId);
    final nextOrder = existing.isEmpty
        ? 0
        : existing.map((s) => s.sortOrder).reduce((a, b) => a > b ? a : b) +
            1;
    return db.insert(
      'substep_progress',
      SubstepProgress(
        truckId: truckId,
        substepName: name,
        sortOrder: nextOrder,
        isCustom: true,
      ).toMap()
        ..remove('id'),
    );
  }

  Future<void> setComplete(int substepId, int truckId, String substepName,
      bool complete) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'substep_progress',
      {
        'is_complete': complete ? 1 : 0,
        'completed_at': complete ? DateTime.now().toIso8601String() : null,
      },
      where: 'id = ?',
      whereArgs: [substepId],
    );
    if (complete) {
      // Per spec: sub-step progress is captured in stage_history the same
      // way as top-level stage changes, without altering truck.current_stage.
      await _stageHistoryRepo.log(truckId, substepName);
    }
  }

  Future<void> removeSubstep(int substepId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('substep_progress', where: 'id = ?', whereArgs: [substepId]);
  }

  Future<void> deleteAllForTruck(int truckId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('substep_progress', where: 'truck_id = ?', whereArgs: [truckId]);
  }

  /// Called when dealer_supplied_graphics is toggled on an existing truck.
  Future<void> handleDealerSuppliedToggle(
      int truckId, bool dealerSupplied) async {
    if (dealerSupplied) {
      // Sub-steps are skipped entirely when dealer-supplied.
      await deleteAllForTruck(truckId);
    } else {
      final existing = await getForTruck(truckId);
      if (existing.isEmpty) {
        await seedDefaults(truckId);
      }
    }
  }
}
