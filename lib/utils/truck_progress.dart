import '../models/substep_progress.dart';
import '../models/truck.dart';
import 'constants.dart';

/// Truck completion percentage: Proofing is worth a flat 20%, and the
/// remaining 80% is earned by checking off Production/Installation
/// sub-steps. QC deliberately has no formula of its own — it just carries
/// forward whatever percentage the sub-steps already earned, since this
/// only depends on stage-passed-proofing plus sub-step completion state,
/// not on which of Production/Installation or QC the truck is currently in.
double truckCompletionPercent(Truck truck, List<SubstepProgress> substeps) {
  if (truck.currentStage == Stage.complete) return 100;
  if (truck.currentStage == Stage.proofing) return 0;

  // Production/Installation or QC. Nothing left to check off (dealer-supplied
  // graphics, or a truck whose sub-steps were all removed) earns full credit
  // for the remaining 80% rather than getting stuck below 100%.
  if (substeps.isEmpty) return 100;

  final completed = substeps.where((s) => s.isComplete).length;
  return 20 + (completed / substeps.length) * 80;
}
