import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../db/database_helper.dart';
import '../models/truck.dart';
import '../utils/constants.dart';
import 'stage_history_repository.dart';
import 'substep_repository.dart';

class BayTakenException implements Exception {
  final int bayNumber;
  BayTakenException(this.bayNumber);
  @override
  String toString() =>
      'Bay $bayNumber is already occupied by another active truck.';
}

class DuplicateHsNumberException implements Exception {
  final String hsNumber;
  DuplicateHsNumberException(this.hsNumber);
  @override
  String toString() => 'HS number "$hsNumber" is already in use.';
}

/// Owns truck CRUD plus the workflow rules that depend on it: automatic
/// stage-change logging, sub-step seeding, and the rolling 8-active/8-archived
/// retention window.
class TruckRepository {
  final StageHistoryRepository _stageHistoryRepo = StageHistoryRepository();
  final SubstepRepository _substepRepo = SubstepRepository();

  Future<Truck> create(Truck truck) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final toInsert = truck.copyWith(dateEnteredStage: now, createdAt: now);

    late int id;
    try {
      id = await db.insert(
        'truck',
        toInsert.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError('truck.hs_number')) {
        throw DuplicateHsNumberException(truck.hsNumber);
      }
      if (e.isUniqueConstraintError('truck.bay_number') ||
          (e.toString().contains('truck.bay_number'))) {
        throw BayTakenException(truck.bayNumber);
      }
      rethrow;
    }

    await _stageHistoryRepo.log(id, toInsert.currentStage, enteredAt: now);

    if (!toInsert.dealerSuppliedGraphics &&
        toInsert.currentStage == Stage.productionInstallation) {
      await _substepRepo.seedDefaults(id);
    }

    return toInsert.copyWith(id: id);
  }

  /// Updates non-stage fields (name, customer, bay, notes, due date, proofs,
  /// schedule status, dealer-supplied toggle). Does not change current_stage —
  /// use [changeStage] for that so stage_history stays accurate.
  Future<void> updateDetails(Truck truck) async {
    if (truck.id == null) {
      throw ArgumentError('Cannot update a truck without an id');
    }
    final db = await DatabaseHelper.instance.database;

    final before = await getById(truck.id!);

    // Deliberately excludes current_stage / date_entered_stage / is_active /
    // created_at: those are owned by changeStage (and creation) so that a
    // stale Truck object passed in here can never silently revert a stage
    // change made elsewhere.
    final detailFields = truck.toMap()
      ..remove('id')
      ..remove('current_stage')
      ..remove('date_entered_stage')
      ..remove('is_active')
      ..remove('created_at');

    try {
      await db.update(
        'truck',
        detailFields,
        where: 'id = ?',
        whereArgs: [truck.id],
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError('truck.hs_number')) {
        throw DuplicateHsNumberException(truck.hsNumber);
      }
      if (e.isUniqueConstraintError('truck.bay_number') ||
          (e.toString().contains('truck.bay_number'))) {
        throw BayTakenException(truck.bayNumber);
      }
      rethrow;
    }

    if (before != null &&
        before.dealerSuppliedGraphics != truck.dealerSuppliedGraphics) {
      await _substepRepo.handleDealerSuppliedToggle(
          truck.id!, truck.dealerSuppliedGraphics);
    }
  }

  /// Moves a truck to [newStage]: stamps date_entered_stage, logs a
  /// stage_history row, and — if the new stage is Complete — archives the
  /// truck and enforces the rolling retention window.
  Future<Truck> changeStage(int truckId, String newStage) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final truck = await getById(truckId);
    if (truck == null) {
      throw ArgumentError('Truck $truckId not found');
    }

    final isComplete = newStage == Stage.complete;
    // Moving a truck back out of Complete un-archives it. Guarded by the
    // same bay-uniqueness constraint as everywhere else, in case another
    // truck has since taken over its bay while it was archived.
    final reactivating = !isComplete && !truck.isActive;

    try {
      await db.update(
        'truck',
        {
          'current_stage': newStage,
          'date_entered_stage': now.toIso8601String(),
          if (isComplete) 'is_active': 0,
          if (reactivating) 'is_active': 1,
        },
        where: 'id = ?',
        whereArgs: [truckId],
      );
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError('truck.bay_number') ||
          e.toString().contains('truck.bay_number')) {
        throw BayTakenException(truck.bayNumber);
      }
      rethrow;
    }

    await _stageHistoryRepo.log(truckId, newStage, enteredAt: now);

    if (!truck.dealerSuppliedGraphics &&
        newStage == Stage.productionInstallation) {
      final existing = await _substepRepo.getForTruck(truckId);
      if (existing.isEmpty) {
        await _substepRepo.seedDefaults(truckId);
      }
    }

    if (isComplete) {
      await _enforceRetention();
    }

    return (await getById(truckId))!;
  }

  Future<void> setScheduleStatus(int truckId, String status) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'truck',
      {'schedule_status': status},
      where: 'id = ?',
      whereArgs: [truckId],
    );
  }

  Future<void> delete(int truckId) async {
    final db = await DatabaseHelper.instance.database;
    // tag_request, stage_history, and substep_progress rows cascade via FK.
    await db.delete('truck', where: 'id = ?', whereArgs: [truckId]);
  }

  Future<Truck?> getById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('truck', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Truck.fromMap(rows.first);
  }

  Future<List<Truck>> getActive() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('truck',
        where: 'is_active = 1', orderBy: 'bay_number ASC');
    return rows.map(Truck.fromMap).toList();
  }

  Future<List<Truck>> getArchived() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('truck',
        where: 'is_active = 0', orderBy: 'date_entered_stage DESC');
    return rows.map(Truck.fromMap).toList();
  }

  /// Bay numbers (1-8) not currently held by an active truck.
  Future<List<int>> availableBays({int? excludingTruckId}) async {
    final active = await getActive();
    final taken = active
        .where((t) => t.id != excludingTruckId)
        .map((t) => t.bayNumber)
        .toSet();
    return [
      for (var b = 1; b <= bayCount; b++)
        if (!taken.contains(b)) b,
    ];
  }

  /// Keeps only the [archiveWindowSize] most-recently-completed archived
  /// trucks; anything older is hard-deleted (cascades to its child rows),
  /// per the spec's "deleted, not exported" retention rule.
  Future<void> _enforceRetention() async {
    final archived = await getArchived(); // already DESC by date_entered_stage
    if (archived.length <= archiveWindowSize) return;
    final toDelete = archived.skip(archiveWindowSize);
    for (final truck in toDelete) {
      await delete(truck.id!);
    }
  }
}
