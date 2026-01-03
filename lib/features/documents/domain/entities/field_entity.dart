/// Field entity for document editor
/// Represents a draggable field on the PDF document
library;

enum FieldType { signature, text, checkbox, date }

class FieldEntity {
  final String id;
  final FieldType type;
  final int page;

  /// Position as percentage (0.0 - 1.0) for cross-device accuracy
  double xPercent;
  double yPercent;

  /// Size as percentage of page dimensions
  double widthPercent;
  double heightPercent;

  /// Field value (filled during signing mode)
  dynamic value;

  /// Whether this field is required
  bool isRequired;

  /// Label for the field
  String? label;

  FieldEntity({
    required this.id,
    required this.type,
    required this.page,
    required this.xPercent,
    required this.yPercent,
    required this.widthPercent,
    required this.heightPercent,
    this.value,
    this.isRequired = false,
    this.label,
  });

  /// Generate unique ID
  static String generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${1000 + (DateTime.now().microsecond % 9000)}';
  }

  /// Create a new field with default size
  factory FieldEntity.create({
    required FieldType type,
    required int page,
    required double xPercent,
    required double yPercent,
  }) {
    // Default sizes based on field type
    double width;
    double height;

    switch (type) {
      case FieldType.signature:
        width = 0.25; // 25% of page width
        height = 0.08; // 8% of page height
        break;
      case FieldType.text:
        width = 0.3;
        height = 0.04;
        break;
      case FieldType.checkbox:
        width = 0.05;
        height = 0.03;
        break;
      case FieldType.date:
        width = 0.2;
        height = 0.04;
        break;
    }

    return FieldEntity(
      id: generateId(),
      type: type,
      page: page,
      xPercent: xPercent,
      yPercent: yPercent,
      widthPercent: width,
      heightPercent: height,
    );
  }

  /// Copy with new position
  FieldEntity copyWith({
    String? id,
    FieldType? type,
    int? page,
    double? xPercent,
    double? yPercent,
    double? widthPercent,
    double? heightPercent,
    dynamic value,
    bool? isRequired,
    String? label,
  }) {
    return FieldEntity(
      id: id ?? this.id,
      type: type ?? this.type,
      page: page ?? this.page,
      xPercent: xPercent ?? this.xPercent,
      yPercent: yPercent ?? this.yPercent,
      widthPercent: widthPercent ?? this.widthPercent,
      heightPercent: heightPercent ?? this.heightPercent,
      value: value ?? this.value,
      isRequired: isRequired ?? this.isRequired,
      label: label ?? this.label,
    );
  }

  /// Get icon for field type
  static String getIconName(FieldType type) {
    switch (type) {
      case FieldType.signature:
        return 'draw';
      case FieldType.text:
        return 'text_fields';
      case FieldType.checkbox:
        return 'check_box';
      case FieldType.date:
        return 'calendar_today';
    }
  }

  /// Get display name for field type
  static String getDisplayName(FieldType type) {
    switch (type) {
      case FieldType.signature:
        return 'Signature';
      case FieldType.text:
        return 'Text';
      case FieldType.checkbox:
        return 'Checkbox';
      case FieldType.date:
        return 'Date';
    }
  }

  /// Convert to JSON for export
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'page': page,
      'xPercent': xPercent,
      'yPercent': yPercent,
      'widthPercent': widthPercent,
      'heightPercent': heightPercent,
      'value': value,
      'isRequired': isRequired,
      'label': label,
    };
  }

  /// Create from JSON
  factory FieldEntity.fromJson(Map<String, dynamic> json) {
    return FieldEntity(
      id: json['id'] as String,
      type: FieldType.values.firstWhere((e) => e.name == json['type']),
      page: json['page'] as int,
      xPercent: (json['xPercent'] as num).toDouble(),
      yPercent: (json['yPercent'] as num).toDouble(),
      widthPercent: (json['widthPercent'] as num).toDouble(),
      heightPercent: (json['heightPercent'] as num).toDouble(),
      value: json['value'],
      isRequired: json['isRequired'] as bool? ?? false,
      label: json['label'] as String?,
    );
  }

  @override
  String toString() {
    return 'FieldEntity(id: $id, type: $type, page: $page, x: $xPercent, y: $yPercent)';
  }
}
