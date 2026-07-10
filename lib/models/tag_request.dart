import '../utils/constants.dart';

class TagRequest {
  final int? id;
  final DateTime dateRequested;
  final int bayRequestedBy;
  final int truckId;
  final String tagType;
  final String tagText;
  final DateTime? dateMade;
  final String status;

  const TagRequest({
    this.id,
    required this.dateRequested,
    required this.bayRequestedBy,
    required this.truckId,
    required this.tagType,
    required this.tagText,
    this.dateMade,
    this.status = TagStatus.needed,
  });

  TagRequest copyWith({
    int? id,
    DateTime? dateRequested,
    int? bayRequestedBy,
    int? truckId,
    String? tagType,
    String? tagText,
    DateTime? dateMade,
    bool clearDateMade = false,
    String? status,
  }) {
    return TagRequest(
      id: id ?? this.id,
      dateRequested: dateRequested ?? this.dateRequested,
      bayRequestedBy: bayRequestedBy ?? this.bayRequestedBy,
      truckId: truckId ?? this.truckId,
      tagType: tagType ?? this.tagType,
      tagText: tagText ?? this.tagText,
      dateMade: clearDateMade ? null : (dateMade ?? this.dateMade),
      status: status ?? this.status,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'date_requested': dateRequested.toIso8601String(),
      'bay_requested_by': bayRequestedBy,
      'truck_id': truckId,
      'tag_type': tagType,
      'tag_text': tagText,
      'date_made': dateMade?.toIso8601String(),
      'status': status,
    };
  }

  factory TagRequest.fromMap(Map<String, Object?> map) {
    return TagRequest(
      id: map['id'] as int?,
      dateRequested: DateTime.parse(map['date_requested'] as String),
      bayRequestedBy: map['bay_requested_by'] as int,
      truckId: map['truck_id'] as int,
      tagType: map['tag_type'] as String,
      tagText: map['tag_text'] as String,
      dateMade: map['date_made'] == null
          ? null
          : DateTime.parse(map['date_made'] as String),
      status: map['status'] as String,
    );
  }
}
