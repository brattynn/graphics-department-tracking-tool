import '../db/database_helper.dart';
import '../models/tag_request.dart';
import '../utils/constants.dart';

class TagRequestRepository {
  Future<int> create(TagRequest request) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('tag_request', request.toMap()..remove('id'));
  }

  Future<void> update(TagRequest request) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'tag_request',
      request.toMap(),
      where: 'id = ?',
      whereArgs: [request.id],
    );
  }

  Future<void> markCompleted(int id, {DateTime? dateMade}) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'tag_request',
      {
        'status': TagStatus.completed,
        'date_made': (dateMade ?? DateTime.now()).toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markNeeded(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'tag_request',
      {'status': TagStatus.needed, 'date_made': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('tag_request', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TagRequest>> getAll({String? status, int? bay}) async {
    final db = await DatabaseHelper.instance.database;
    final conditions = <String>[];
    final args = <Object?>[];
    if (status != null) {
      conditions.add('status = ?');
      args.add(status);
    }
    if (bay != null) {
      conditions.add('bay_requested_by = ?');
      args.add(bay);
    }
    final rows = await db.query(
      'tag_request',
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'date_requested DESC',
    );
    return rows.map(TagRequest.fromMap).toList();
  }

  Future<List<TagRequest>> getForTruck(int truckId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'tag_request',
      where: 'truck_id = ?',
      whereArgs: [truckId],
      orderBy: 'date_requested DESC',
    );
    return rows.map(TagRequest.fromMap).toList();
  }
}
