class StageHistory {
  final int? id;
  final int truckId;
  final String stage;
  final DateTime enteredAt;

  const StageHistory({
    this.id,
    required this.truckId,
    required this.stage,
    required this.enteredAt,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'truck_id': truckId,
      'stage': stage,
      'entered_at': enteredAt.toIso8601String(),
    };
  }

  factory StageHistory.fromMap(Map<String, Object?> map) {
    return StageHistory(
      id: map['id'] as int?,
      truckId: map['truck_id'] as int,
      stage: map['stage'] as String,
      enteredAt: DateTime.parse(map['entered_at'] as String),
    );
  }
}
