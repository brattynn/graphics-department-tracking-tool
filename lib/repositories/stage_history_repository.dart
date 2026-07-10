import '../db/database_helper.dart';
import '../models/stage_history.dart';

class StageHistoryRepository {
  Future<int> log(int truckId, String stage, {DateTime? enteredAt}) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert(
      'stage_history',
      StageHistory(
        truckId: truckId,
        stage: stage,
        enteredAt: enteredAt ?? DateTime.now(),
      ).toMap()
        ..remove('id'),
    );
  }

  Future<List<StageHistory>> getForTruck(int truckId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'stage_history',
      where: 'truck_id = ?',
      whereArgs: [truckId],
      orderBy: 'entered_at ASC',
    );
    return rows.map(StageHistory.fromMap).toList();
  }
}
