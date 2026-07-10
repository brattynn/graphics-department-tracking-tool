// Pure unit tests for truckCompletionPercent — no database, no widgets.
import 'package:flutter_test/flutter_test.dart';
import 'package:graphics_bay_tracker/models/substep_progress.dart';
import 'package:graphics_bay_tracker/models/truck.dart';
import 'package:graphics_bay_tracker/utils/constants.dart';
import 'package:graphics_bay_tracker/utils/truck_progress.dart';

Truck _truck({
  required String stage,
  bool dealerSupplied = false,
}) {
  final now = DateTime.now();
  return Truck(
    hsNumber: 'HS-1',
    truckName: 'Test Truck',
    bayNumber: 1,
    currentStage: stage,
    dateEnteredStage: now,
    createdAt: now,
    dealerSuppliedGraphics: dealerSupplied,
  );
}

SubstepProgress _substep({required bool complete}) {
  return SubstepProgress(
    truckId: 1,
    substepName: 'Cab Striping',
    sortOrder: 0,
    isComplete: complete,
  );
}

void main() {
  test('Proofing is always 0%, regardless of substeps or dealer-supplied', () {
    expect(truckCompletionPercent(_truck(stage: Stage.proofing), []), 0);
    expect(
      truckCompletionPercent(
        _truck(stage: Stage.proofing, dealerSupplied: true),
        [_substep(complete: true)],
      ),
      0,
    );
  });

  test('Complete is always 100%, even with incomplete substeps', () {
    final substeps = [
      _substep(complete: true),
      _substep(complete: false),
      _substep(complete: false),
    ];
    expect(truckCompletionPercent(_truck(stage: Stage.complete), substeps), 100);
  });

  test(
      'dealer-supplied trucks past Proofing are 100% since there is nothing to check off',
      () {
    final truck = _truck(
        stage: Stage.productionInstallation, dealerSupplied: true);
    expect(truckCompletionPercent(truck, []), 100);
  });

  test('non-dealer truck with no substep rows past Proofing is 100%', () {
    // e.g. every substep was manually removed via the checklist UI.
    final truck = _truck(stage: Stage.productionInstallation);
    expect(truckCompletionPercent(truck, []), 100);
  });

  test('Production/Installation with 0/9 complete is exactly 20%', () {
    final truck = _truck(stage: Stage.productionInstallation);
    final substeps = List.generate(9, (_) => _substep(complete: false));
    expect(truckCompletionPercent(truck, substeps), 20);
  });

  test('Production/Installation with 9/9 complete is exactly 100%', () {
    final truck = _truck(stage: Stage.productionInstallation);
    final substeps = List.generate(9, (_) => _substep(complete: true));
    expect(truckCompletionPercent(truck, substeps), 100);
  });

  test('Production/Installation with partial completion scales linearly', () {
    final truck = _truck(stage: Stage.productionInstallation);
    final substeps = [
      ...List.generate(3, (_) => _substep(complete: true)),
      ...List.generate(6, (_) => _substep(complete: false)),
    ];
    // 20 + (3/9)*80 = 20 + 26.666... = 46.666...
    expect(truckCompletionPercent(truck, substeps), closeTo(46.67, 0.01));
  });

  test(
      'a custom sub-step widens the denominator, so each item is worth less',
      () {
    final truck = _truck(stage: Stage.productionInstallation);
    // 9 defaults + 1 custom = 10 total; 5 complete.
    final substeps = [
      ...List.generate(5, (_) => _substep(complete: true)),
      ...List.generate(5, (_) => _substep(complete: false)),
    ];
    expect(truckCompletionPercent(truck, substeps), 60); // 20 + (5/10)*80
  });

  test('QC has no effect of its own — it just preserves the substep-earned percentage',
      () {
    final substeps = [
      ...List.generate(5, (_) => _substep(complete: true)),
      ...List.generate(4, (_) => _substep(complete: false)),
    ];
    final inProduction = truckCompletionPercent(
        _truck(stage: Stage.productionInstallation), substeps);
    final inQc = truckCompletionPercent(_truck(stage: Stage.qc), substeps);
    expect(inQc, inProduction);
  });
}
