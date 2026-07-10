/// App-wide constants: workflow stages, default sub-steps, and enum-like values.
///
/// These are stored as plain strings (not Dart enums) because they're persisted
/// directly as TEXT in SQLite and compared against seed data.
library;

class Stage {
  static const proofing = 'Proofing';
  static const productionInstallation = 'Production/Installation';
  static const qc = 'QC';
  static const complete = 'Complete';

  static const all = [proofing, productionInstallation, qc, complete];

  /// The stage a truck enters immediately after [current].
  static String? next(String current) {
    final i = all.indexOf(current);
    if (i == -1 || i == all.length - 1) return null;
    return all[i + 1];
  }
}

class ScheduleStatus {
  static const inBay = 'In Bay';
  static const outForTesting = 'Out for Testing';

  static const all = [inBay, outForTesting];
}

class TagStatus {
  static const needed = 'Needed';
  static const completed = 'Completed';

  static const all = [needed, completed];
}

/// Sentinel value shared by the stripe/chevron spec fields below: selecting
/// it reveals a free-text field on the Truck for a one-off value that isn't
/// one of the standard options.
const String customOption = 'Custom';

class StripeColor {
  static const black = 'Black';
  static const white = 'White';
  static const goldRef = 'Gold Ref.';
  static const goldLeaf = 'Gold Leaf';
  static const yellow = 'Yellow';
  static const blue = 'Blue';
  static const orange = 'Orange';

  static const all = [
    black,
    white,
    goldRef,
    goldLeaf,
    yellow,
    blue,
    orange,
    customOption,
  ];
}

class ChevronColor {
  static const limeRed = 'Lime/Red';
  static const blackRed = 'Black/Red';
  static const yellowRed = 'Yellow/Red';

  static const all = [limeRed, blackRed, yellowRed, customOption];
}

class StripeFeature {
  static const straight = 'Straight';
  static const zStripe = 'Z-Stripe';
  static const bodyBreakStripe = 'Body Break Stripe';
  static const cabBreakStripe = 'Cab Break Stripe';

  static const all = [
    straight,
    zStripe,
    bodyBreakStripe,
    cabBreakStripe,
    customOption,
  ];
}

/// Default Production/Installation sub-steps, in display order.
/// Seeded as real rows per-truck (not hardcoded into the UI) so that
/// custom one-off sub-steps can sit alongside them in the same list.
const List<String> defaultSubsteps = [
  'Cab Striping',
  'Cab Lettering',
  'Bumper Chevron',
  'Hydraulic Area Striping',
  'Passenger Body Striping/Lettering',
  'Driver Body Striping/Lettering',
  'Rear Body Graphics and Chevron',
  'Ladder Signs',
  'Ladder Tip',
];

const int bayCount = 8;
const int activeWindowSize = 8;
const int archiveWindowSize = 8;
