import 'package:flutter/material.dart';

import '../../models/substep_progress.dart';
import '../../models/truck.dart';
import '../../repositories/substep_repository.dart';
import '../../utils/constants.dart';
import '../../utils/truck_progress.dart';

/// A ring showing how far along a truck is toward completion — green for
/// the completed portion, red for what's left. Fetches sub-step data itself
/// (only when the truck's stage actually needs it) so callers can drop it
/// in without pre-loading anything.
class TruckProgressRing extends StatefulWidget {
  final Truck truck;
  final double size;
  final bool showLabel;

  const TruckProgressRing({
    super.key,
    required this.truck,
    this.size = 28,
    this.showLabel = false,
  });

  @override
  State<TruckProgressRing> createState() => _TruckProgressRingState();
}

class _TruckProgressRingState extends State<TruckProgressRing> {
  final _substepRepo = SubstepRepository();
  double? _percent;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant TruckProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    _load();
  }

  Future<void> _load() async {
    final truck = widget.truck;
    final needsSubsteps = !truck.dealerSuppliedGraphics &&
        (truck.currentStage == Stage.productionInstallation ||
            truck.currentStage == Stage.qc);
    final substeps = needsSubsteps
        ? await _substepRepo.getForTruck(truck.id!)
        : const <SubstepProgress>[];
    if (!mounted) return;
    setState(() {
      _percent = truckCompletionPercent(truck, substeps);
    });
  }

  @override
  Widget build(BuildContext context) {
    final percent = _percent;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (percent == null)
            SizedBox(
              width: widget.size * 0.5,
              height: widget.size * 0.5,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          else ...[
            SizedBox(
              width: widget.size,
              height: widget.size,
              child: CircularProgressIndicator(
                value: percent / 100,
                strokeWidth: widget.size * 0.14,
                color: Colors.green.shade500,
                backgroundColor: Colors.red.shade400,
              ),
            ),
            if (widget.showLabel)
              Text(
                '${percent.round()}%',
                style: TextStyle(
                  fontSize: widget.size * 0.22,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ],
      ),
    );
  }
}
