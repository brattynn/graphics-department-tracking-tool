import '../utils/constants.dart';

class Truck {
  final int? id;
  final String hsNumber;
  final String truckName;
  final String? customer;
  final int bayNumber;
  final String currentStage;
  final DateTime dateEnteredStage;
  final bool dealerSuppliedGraphics;
  final String scheduleStatus;
  final DateTime? dueDate;
  final String? notes;
  final String? proofFinalPath1;
  final String? proofFinalPath2;
  final DateTime createdAt;
  final bool isActive;
  final String? stripeColor;
  final String? stripeColorCustom;
  final String? chevronColor;
  final String? chevronColorCustom;
  final String? stripeFeature;
  final String? stripeFeatureCustom;
  final bool stripeOnStainless;

  const Truck({
    this.id,
    required this.hsNumber,
    required this.truckName,
    this.customer,
    required this.bayNumber,
    this.currentStage = Stage.proofing,
    required this.dateEnteredStage,
    this.dealerSuppliedGraphics = false,
    this.scheduleStatus = ScheduleStatus.inBay,
    this.dueDate,
    this.notes,
    this.proofFinalPath1,
    this.proofFinalPath2,
    required this.createdAt,
    this.isActive = true,
    this.stripeColor,
    this.stripeColorCustom,
    this.chevronColor,
    this.chevronColorCustom,
    this.stripeFeature,
    this.stripeFeatureCustom,
    this.stripeOnStainless = false,
  });

  Truck copyWith({
    int? id,
    String? hsNumber,
    String? truckName,
    String? customer,
    int? bayNumber,
    String? currentStage,
    DateTime? dateEnteredStage,
    bool? dealerSuppliedGraphics,
    String? scheduleStatus,
    DateTime? dueDate,
    bool clearDueDate = false,
    String? notes,
    String? proofFinalPath1,
    String? proofFinalPath2,
    DateTime? createdAt,
    bool? isActive,
    String? stripeColor,
    bool clearStripeColor = false,
    String? stripeColorCustom,
    bool clearStripeColorCustom = false,
    String? chevronColor,
    bool clearChevronColor = false,
    String? chevronColorCustom,
    bool clearChevronColorCustom = false,
    String? stripeFeature,
    bool clearStripeFeature = false,
    String? stripeFeatureCustom,
    bool clearStripeFeatureCustom = false,
    bool? stripeOnStainless,
  }) {
    return Truck(
      id: id ?? this.id,
      hsNumber: hsNumber ?? this.hsNumber,
      truckName: truckName ?? this.truckName,
      customer: customer ?? this.customer,
      bayNumber: bayNumber ?? this.bayNumber,
      currentStage: currentStage ?? this.currentStage,
      dateEnteredStage: dateEnteredStage ?? this.dateEnteredStage,
      dealerSuppliedGraphics:
          dealerSuppliedGraphics ?? this.dealerSuppliedGraphics,
      scheduleStatus: scheduleStatus ?? this.scheduleStatus,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      notes: notes ?? this.notes,
      proofFinalPath1: proofFinalPath1 ?? this.proofFinalPath1,
      proofFinalPath2: proofFinalPath2 ?? this.proofFinalPath2,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      stripeColor: clearStripeColor ? null : (stripeColor ?? this.stripeColor),
      stripeColorCustom: clearStripeColorCustom
          ? null
          : (stripeColorCustom ?? this.stripeColorCustom),
      chevronColor:
          clearChevronColor ? null : (chevronColor ?? this.chevronColor),
      chevronColorCustom: clearChevronColorCustom
          ? null
          : (chevronColorCustom ?? this.chevronColorCustom),
      stripeFeature:
          clearStripeFeature ? null : (stripeFeature ?? this.stripeFeature),
      stripeFeatureCustom: clearStripeFeatureCustom
          ? null
          : (stripeFeatureCustom ?? this.stripeFeatureCustom),
      stripeOnStainless: stripeOnStainless ?? this.stripeOnStainless,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'hs_number': hsNumber,
      'truck_name': truckName,
      'customer': customer,
      'bay_number': bayNumber,
      'current_stage': currentStage,
      'date_entered_stage': dateEnteredStage.toIso8601String(),
      'dealer_supplied_graphics': dealerSuppliedGraphics ? 1 : 0,
      'schedule_status': scheduleStatus,
      'due_date': dueDate?.toIso8601String(),
      'notes': notes,
      'proof_final_path_1': proofFinalPath1,
      'proof_final_path_2': proofFinalPath2,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'stripe_color': stripeColor,
      'stripe_color_custom': stripeColorCustom,
      'chevron_color': chevronColor,
      'chevron_color_custom': chevronColorCustom,
      'stripe_feature': stripeFeature,
      'stripe_feature_custom': stripeFeatureCustom,
      'stripe_on_stainless': stripeOnStainless ? 1 : 0,
    };
  }

  factory Truck.fromMap(Map<String, Object?> map) {
    return Truck(
      id: map['id'] as int?,
      hsNumber: map['hs_number'] as String,
      truckName: map['truck_name'] as String,
      customer: map['customer'] as String?,
      bayNumber: map['bay_number'] as int,
      currentStage: map['current_stage'] as String,
      dateEnteredStage: DateTime.parse(map['date_entered_stage'] as String),
      dealerSuppliedGraphics: (map['dealer_supplied_graphics'] as int) == 1,
      scheduleStatus: map['schedule_status'] as String,
      dueDate: map['due_date'] == null
          ? null
          : DateTime.parse(map['due_date'] as String),
      notes: map['notes'] as String?,
      proofFinalPath1: map['proof_final_path_1'] as String?,
      proofFinalPath2: map['proof_final_path_2'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      isActive: (map['is_active'] as int) == 1,
      stripeColor: map['stripe_color'] as String?,
      stripeColorCustom: map['stripe_color_custom'] as String?,
      chevronColor: map['chevron_color'] as String?,
      chevronColorCustom: map['chevron_color_custom'] as String?,
      stripeFeature: map['stripe_feature'] as String?,
      stripeFeatureCustom: map['stripe_feature_custom'] as String?,
      stripeOnStainless: (map['stripe_on_stainless'] as int? ?? 0) == 1,
    );
  }

  bool get hasBothProofs =>
      proofFinalPath1 != null && proofFinalPath2 != null;

  /// The value to show/use for a "pick one, or Custom" field: the custom
  /// text when the option is Custom, otherwise the option itself.
  static String? _resolve(String? option, String? custom) {
    if (option == null) return null;
    return option == customOption ? custom : option;
  }

  String? get stripeColorDisplay => _resolve(stripeColor, stripeColorCustom);
  String? get chevronColorDisplay =>
      _resolve(chevronColor, chevronColorCustom);
  String? get stripeFeatureDisplay =>
      _resolve(stripeFeature, stripeFeatureCustom);
}
