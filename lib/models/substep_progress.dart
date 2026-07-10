class SubstepProgress {
  final int? id;
  final int truckId;
  final String substepName;
  final int sortOrder;
  final bool isCustom;
  final bool isComplete;
  final DateTime? completedAt;

  const SubstepProgress({
    this.id,
    required this.truckId,
    required this.substepName,
    required this.sortOrder,
    this.isCustom = false,
    this.isComplete = false,
    this.completedAt,
  });

  SubstepProgress copyWith({
    int? id,
    int? truckId,
    String? substepName,
    int? sortOrder,
    bool? isCustom,
    bool? isComplete,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return SubstepProgress(
      id: id ?? this.id,
      truckId: truckId ?? this.truckId,
      substepName: substepName ?? this.substepName,
      sortOrder: sortOrder ?? this.sortOrder,
      isCustom: isCustom ?? this.isCustom,
      isComplete: isComplete ?? this.isComplete,
      completedAt:
          clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'truck_id': truckId,
      'substep_name': substepName,
      'sort_order': sortOrder,
      'is_custom': isCustom ? 1 : 0,
      'is_complete': isComplete ? 1 : 0,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  factory SubstepProgress.fromMap(Map<String, Object?> map) {
    return SubstepProgress(
      id: map['id'] as int?,
      truckId: map['truck_id'] as int,
      substepName: map['substep_name'] as String,
      sortOrder: map['sort_order'] as int,
      isCustom: (map['is_custom'] as int) == 1,
      isComplete: (map['is_complete'] as int) == 1,
      completedAt: map['completed_at'] == null
          ? null
          : DateTime.parse(map['completed_at'] as String),
    );
  }
}
