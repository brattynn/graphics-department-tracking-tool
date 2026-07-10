// Repository-level smoke tests exercising the core business rules against
// a real (temp-file) SQLite database via sqflite_common_ffi — no UI involved.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphics_bay_tracker/db/database_helper.dart';
import 'package:graphics_bay_tracker/models/tag_request.dart';
import 'package:graphics_bay_tracker/models/truck.dart';
import 'package:graphics_bay_tracker/repositories/stage_history_repository.dart';
import 'package:graphics_bay_tracker/repositories/substep_repository.dart';
import 'package:graphics_bay_tracker/repositories/tag_request_repository.dart';
import 'package:graphics_bay_tracker/repositories/truck_repository.dart';
import 'package:graphics_bay_tracker/utils/constants.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The truck table exactly as it shipped in schema v1, before the
/// stripe/chevron graphics-spec columns were added in v2. Used to simulate
/// an existing user's database file and verify the v1->v2 migration.
const String _legacyV1TruckTable = '''
CREATE TABLE truck (
  id                        INTEGER PRIMARY KEY AUTOINCREMENT,
  hs_number                 TEXT NOT NULL UNIQUE,
  truck_name                TEXT NOT NULL,
  customer                  TEXT,
  bay_number                INTEGER NOT NULL CHECK (bay_number BETWEEN 1 AND 8),
  current_stage             TEXT NOT NULL DEFAULT 'Proofing',
  date_entered_stage        TEXT NOT NULL,
  dealer_supplied_graphics  INTEGER NOT NULL DEFAULT 0,
  schedule_status           TEXT NOT NULL DEFAULT 'In Bay',
  due_date                  TEXT,
  notes                     TEXT,
  proof_final_path_1        TEXT,
  proof_final_path_2        TEXT,
  created_at                TEXT NOT NULL,
  is_active                 INTEGER NOT NULL DEFAULT 1
)
''';

Truck _newTruck({
  required String hsNumber,
  required int bayNumber,
  bool dealerSupplied = false,
}) {
  final now = DateTime.now();
  return Truck(
    hsNumber: hsNumber,
    truckName: 'Truck $hsNumber',
    bayNumber: bayNumber,
    dateEnteredStage: now,
    createdAt: now,
    dealerSuppliedGraphics: dealerSupplied,
  );
}

void main() {
  late Directory tempDir;
  late TruckRepository truckRepo;
  late SubstepRepository substepRepo;
  late TagRequestRepository tagRepo;
  late StageHistoryRepository stageHistoryRepo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('baytracker_test_');
    await DatabaseHelper.instance
        .resetForTesting(p.join(tempDir.path, 'test.db'));
    truckRepo = TruckRepository();
    substepRepo = SubstepRepository();
    tagRepo = TagRequestRepository();
    stageHistoryRepo = StageHistoryRepository();
  });

  tearDown(() async {
    await DatabaseHelper.instance.closeForTesting();
    await tempDir.delete(recursive: true);
  });

  test(
      'opening an existing v1 database migrates to v2, adding the graphics-spec columns without losing data',
      () async {
    final legacyPath = p.join(tempDir.path, 'legacy.db');

    // Hand-build a v1-shaped database, as an existing user's install would
    // have on disk, and seed it with a row using only the original columns.
    sqfliteFfiInit();
    final legacyDb = await databaseFactoryFfi.openDatabase(
      legacyPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute(_legacyV1TruckTable);
        },
      ),
    );
    final now = DateTime.now().toIso8601String();
    await legacyDb.insert('truck', {
      'hs_number': 'LEGACY-1',
      'truck_name': 'Pre-migration Truck',
      'bay_number': 2,
      'current_stage': Stage.qc,
      'date_entered_stage': now,
      'dealer_supplied_graphics': 0,
      'schedule_status': ScheduleStatus.inBay,
      'created_at': now,
      'is_active': 1,
    });
    await legacyDb.close();

    // Now hand that same file to the real DatabaseHelper (targeting the
    // current schemaVersion) — this must trigger onUpgrade, not onCreate.
    await DatabaseHelper.instance.resetForTesting(legacyPath);

    final trucks = await truckRepo.getActive();
    expect(trucks, hasLength(1));
    final migrated = trucks.single;
    expect(migrated.hsNumber, 'LEGACY-1');
    expect(migrated.currentStage, Stage.qc);
    // New v2 columns default to null/false for pre-existing rows.
    expect(migrated.stripeColor, isNull);
    expect(migrated.chevronColor, isNull);
    expect(migrated.stripeFeature, isNull);
    expect(migrated.stripeOnStainless, isFalse);

    // And the new columns are fully usable going forward.
    await truckRepo.updateDetails(migrated.copyWith(
      stripeColor: StripeColor.blue,
      stripeOnStainless: true,
    ));
    final updated = (await truckRepo.getById(migrated.id!))!;
    expect(updated.stripeColor, StripeColor.blue);
    expect(updated.stripeOnStainless, isTrue);
  });

  test('creating a truck defaults to Proofing and logs one stage_history row',
      () async {
    final truck = await truckRepo.create(_newTruck(hsNumber: 'HS-1', bayNumber: 1));

    expect(truck.currentStage, Stage.proofing);
    expect(truck.isActive, isTrue);

    final history = await stageHistoryRepo.getForTruck(truck.id!);
    expect(history, hasLength(1));
    expect(history.first.stage, Stage.proofing);

    // Substeps are not seeded until the truck actually reaches
    // Production/Installation.
    expect(await substepRepo.getForTruck(truck.id!), isEmpty);
  });

  test(
      'advancing a non-dealer-supplied truck into Production/Installation seeds the 9 default substeps in order',
      () async {
    final truck = await truckRepo.create(_newTruck(hsNumber: 'HS-2', bayNumber: 1));
    await truckRepo.changeStage(truck.id!, Stage.productionInstallation);

    final substeps = await substepRepo.getForTruck(truck.id!);
    expect(substeps, hasLength(defaultSubsteps.length));
    expect(substeps.map((s) => s.substepName).toList(), defaultSubsteps);
    expect(substeps.every((s) => !s.isComplete), isTrue);
    expect(substeps.every((s) => !s.isCustom), isTrue);
  });

  test(
      'dealer-supplied truck gets zero substeps in Production/Installation, but stage still advances',
      () async {
    final truck = await truckRepo
        .create(_newTruck(hsNumber: 'HS-3', bayNumber: 1, dealerSupplied: true));
    final updated =
        await truckRepo.changeStage(truck.id!, Stage.productionInstallation);

    expect(updated.currentStage, Stage.productionInstallation);
    expect(await substepRepo.getForTruck(truck.id!), isEmpty);
  });

  test('toggling dealer_supplied_graphics on mid-stream adds/removes substeps',
      () async {
    final truck = await truckRepo.create(_newTruck(hsNumber: 'HS-4', bayNumber: 1));
    await truckRepo.changeStage(truck.id!, Stage.productionInstallation);
    expect(await substepRepo.getForTruck(truck.id!), hasLength(9));

    // Flip to dealer-supplied: existing substeps should be wiped.
    await truckRepo.updateDetails(
        truck.copyWith(id: truck.id, dealerSuppliedGraphics: true));
    expect(await substepRepo.getForTruck(truck.id!), isEmpty);

    // Flip back off: defaults should be reseeded since the truck is still
    // in Production/Installation.
    await truckRepo.updateDetails(
        truck.copyWith(id: truck.id, dealerSuppliedGraphics: false));
    expect(await substepRepo.getForTruck(truck.id!), hasLength(9));
  });

  test(
      'completing a substep logs it to stage_history without changing truck.currentStage',
      () async {
    final truck = await truckRepo.create(_newTruck(hsNumber: 'HS-5', bayNumber: 1));
    await truckRepo.changeStage(truck.id!, Stage.productionInstallation);
    final substeps = await substepRepo.getForTruck(truck.id!);
    final first = substeps.first;

    await substepRepo.setComplete(first.id!, truck.id!, first.substepName, true);

    final updatedTruck = await truckRepo.getById(truck.id!);
    expect(updatedTruck!.currentStage, Stage.productionInstallation);

    final history = await stageHistoryRepo.getForTruck(truck.id!);
    expect(history.map((h) => h.stage), contains(first.substepName));

    final updatedSubsteps = await substepRepo.getForTruck(truck.id!);
    final updatedFirst = updatedSubsteps.firstWhere((s) => s.id == first.id);
    expect(updatedFirst.isComplete, isTrue);
    expect(updatedFirst.completedAt, isNotNull);
  });

  test('custom one-off substeps can be added and removed per truck', () async {
    final truck = await truckRepo.create(_newTruck(hsNumber: 'HS-6', bayNumber: 1));
    await truckRepo.changeStage(truck.id!, Stage.productionInstallation);

    await substepRepo.addCustom(truck.id!, 'Special Reflective Decal');
    final substeps = await substepRepo.getForTruck(truck.id!);
    expect(substeps, hasLength(10));
    final custom = substeps.firstWhere((s) => s.isCustom);
    expect(custom.substepName, 'Special Reflective Decal');
    expect(custom.sortOrder, 9); // appended after the 9 defaults (0-8)

    await substepRepo.removeSubstep(custom.id!);
    expect(await substepRepo.getForTruck(truck.id!), hasLength(9));
  });

  test('bay uniqueness is enforced among active trucks', () async {
    await truckRepo.create(_newTruck(hsNumber: 'HS-7A', bayNumber: 1));
    expect(
      () => truckRepo.create(_newTruck(hsNumber: 'HS-7B', bayNumber: 1)),
      throwsA(isA<BayTakenException>()),
    );
  });

  test('a freed bay (from an archived truck) can be reused', () async {
    final t1 = await truckRepo.create(_newTruck(hsNumber: 'HS-8A', bayNumber: 1));
    await truckRepo.changeStage(t1.id!, Stage.complete); // archives it

    // Bay 1 should be available again.
    final t2 = await truckRepo.create(_newTruck(hsNumber: 'HS-8B', bayNumber: 1));
    expect(t2.bayNumber, 1);
  });

  test(
      'moving a truck backward from Production/Installation to Proofing preserves substep progress',
      () async {
    final truck = await truckRepo.create(_newTruck(hsNumber: 'HS-BACK-1', bayNumber: 1));
    await truckRepo.changeStage(truck.id!, Stage.productionInstallation);
    final substeps = await substepRepo.getForTruck(truck.id!);
    await substepRepo.setComplete(
        substeps.first.id!, truck.id!, substeps.first.substepName, true);

    // Move backward.
    final backTruck = await truckRepo.changeStage(truck.id!, Stage.proofing);
    expect(backTruck.currentStage, Stage.proofing);
    // Progress isn't wiped just because the truck stepped back.
    expect(await substepRepo.getForTruck(truck.id!), hasLength(9));

    // Moving forward again must not re-seed a duplicate set of substeps.
    await truckRepo.changeStage(truck.id!, Stage.productionInstallation);
    final againSubsteps = await substepRepo.getForTruck(truck.id!);
    expect(againSubsteps, hasLength(9));
    expect(againSubsteps.firstWhere((s) => s.id == substeps.first.id).isComplete,
        isTrue);
  });

  test('moving a truck back out of Complete restores is_active', () async {
    final truck = await truckRepo.create(_newTruck(hsNumber: 'HS-BACK-2', bayNumber: 1));
    await truckRepo.changeStage(truck.id!, Stage.complete);
    expect((await truckRepo.getById(truck.id!))!.isActive, isFalse);
    expect(await truckRepo.getArchived(), hasLength(1));

    final reopened = await truckRepo.changeStage(truck.id!, Stage.qc);
    expect(reopened.isActive, isTrue);
    expect(reopened.currentStage, Stage.qc);
    expect(await truckRepo.getArchived(), isEmpty);
    expect(await truckRepo.getActive(), hasLength(1));
  });

  test(
      'un-completing a truck whose bay was taken over by another active truck is rejected',
      () async {
    final t1 = await truckRepo.create(_newTruck(hsNumber: 'HS-BACK-3A', bayNumber: 1));
    await truckRepo.changeStage(t1.id!, Stage.complete); // frees bay 1
    await truckRepo.create(_newTruck(hsNumber: 'HS-BACK-3B', bayNumber: 1));

    expect(
      () => truckRepo.changeStage(t1.id!, Stage.qc),
      throwsA(isA<BayTakenException>()),
    );
  });

  test('duplicate HS numbers are rejected', () async {
    await truckRepo.create(_newTruck(hsNumber: 'DUP-1', bayNumber: 1));
    expect(
      () => truckRepo.create(_newTruck(hsNumber: 'DUP-1', bayNumber: 2)),
      throwsA(isA<DuplicateHsNumberException>()),
    );
  });

  test(
      'deleting a truck cascades to delete its tag requests, stage history, and substep progress',
      () async {
    final truck = await truckRepo.create(_newTruck(hsNumber: 'HS-9', bayNumber: 1));
    await truckRepo.changeStage(truck.id!, Stage.productionInstallation);
    await tagRepo.create(TagRequest(
      dateRequested: DateTime.now(),
      bayRequestedBy: 2,
      truckId: truck.id!,
      tagType: 'Door tag',
      tagText: 'REAR STEP – WATCH YOUR HEAD',
    ));

    expect(await tagRepo.getForTruck(truck.id!), hasLength(1));
    expect(await substepRepo.getForTruck(truck.id!), hasLength(9));

    await truckRepo.delete(truck.id!);

    expect(await truckRepo.getById(truck.id!), isNull);
    expect(await tagRepo.getForTruck(truck.id!), isEmpty);
    expect(await substepRepo.getForTruck(truck.id!), isEmpty);
    expect(await stageHistoryRepo.getForTruck(truck.id!), isEmpty);
  });

  test(
      'retention: completing a 9th truck auto-deletes the oldest archived truck, keeping 8',
      () async {
    final hsNumbers = List.generate(9, (i) => 'RET-$i');
    for (final hs in hsNumbers) {
      final truck = await truckRepo.create(_newTruck(hsNumber: hs, bayNumber: 1));
      await truckRepo.changeStage(truck.id!, Stage.complete);
      // Give each completion a distinct timestamp so ordering is unambiguous.
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }

    final archived = await truckRepo.getArchived();
    expect(archived, hasLength(archiveWindowSize));
    // The very first truck completed (RET-0) should have been purged.
    expect(archived.any((t) => t.hsNumber == 'RET-0'), isFalse);
    // The most recent 8 should all still be present.
    for (final hs in hsNumbers.skip(1)) {
      expect(archived.any((t) => t.hsNumber == hs), isTrue,
          reason: '$hs should still be archived');
    }
  });

  test('tag request status filtering and markCompleted/markNeeded round-trip',
      () async {
    final truck = await truckRepo.create(_newTruck(hsNumber: 'HS-10', bayNumber: 1));
    final id = await tagRepo.create(TagRequest(
      dateRequested: DateTime.now(),
      bayRequestedBy: 3,
      truckId: truck.id!,
      tagType: 'Compartment label',
      tagText: 'HOSE — 2.5"',
    ));

    var needed = await tagRepo.getAll(status: TagStatus.needed);
    expect(needed, hasLength(1));
    var completed = await tagRepo.getAll(status: TagStatus.completed);
    expect(completed, isEmpty);

    await tagRepo.markCompleted(id);
    completed = await tagRepo.getAll(status: TagStatus.completed);
    expect(completed, hasLength(1));
    expect(completed.first.dateMade, isNotNull);

    await tagRepo.markNeeded(id);
    needed = await tagRepo.getAll(status: TagStatus.needed);
    expect(needed, hasLength(1));
    expect(needed.first.dateMade, isNull);
  });

  test('bay filter on availableBays excludes both active and just-freed correctly',
      () async {
    await truckRepo.create(_newTruck(hsNumber: 'HS-11', bayNumber: 3));
    await truckRepo.create(_newTruck(hsNumber: 'HS-12', bayNumber: 5));

    final available = await truckRepo.availableBays();
    expect(available, containsAll([1, 2, 4, 6, 7, 8]));
    expect(available, isNot(contains(3)));
    expect(available, isNot(contains(5)));
    expect(available, hasLength(6));
  });
}
