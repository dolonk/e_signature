library;

import 'dart:convert';
import 'package:flutter/foundation.dart';

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
        width = 0.25;
        height = 0.08;
        break;
      case FieldType.text:
        width = 0.3;
        height = 0.04;
        break;
      case FieldType.checkbox:
        width = 0.08;
        height = 0.05;
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
    dynamic jsonValue = value;

    debugPrint('toJson - Field: $id, Type: ${type.name}');
    debugPrint('Value type: ${value?.runtimeType}');
    debugPrint('Is Uint8List: ${value is Uint8List}');

    if (value is Uint8List) {
      final bytes = value as Uint8List;
      debugPrint('Converting Uint8List (${bytes.length} bytes) to base64');
      jsonValue = {'type': 'bytes', 'data': base64Encode(bytes)};
      debugPrint('Converted to map format');
    }

    return {
      'id': id,
      'type': type.name,
      'page': page,
      'xPercent': xPercent,
      'yPercent': yPercent,
      'widthPercent': widthPercent,
      'heightPercent': heightPercent,
      'value': jsonValue,
      'isRequired': isRequired,
      'label': label,
    };
  }

  /// Create from JSON
  factory FieldEntity.fromJson(Map<String, dynamic> json) {
    dynamic fieldValue = json['value'];

    debugPrint('fromJson - Field: ${json['id']}, Type: ${json['type']}');
    debugPrint('Raw value type: ${fieldValue?.runtimeType}');
    debugPrint(
      '   Raw value: ${fieldValue.toString().substring(0, fieldValue.toString().length > 100 ? 100 : fieldValue.toString().length)}...',
    );

    // Handle different formats for byte data (signature)
    if (fieldValue != null && json['type'] == 'signature') {
      try {
        // Format 1: TYPE
        if (fieldValue is Map && fieldValue['type'] == 'bytes' && fieldValue['data'] != null) {
          debugPrint('Format: Map with base64 data');
          final decoded = base64Decode(fieldValue['data'] as String);
          debugPrint('Decoded to Uint8List (${decoded.length} bytes)');
          fieldValue = decoded;
        }
        // Format 2: DRAW
        else if (fieldValue is List) {
          debugPrint('Format: List of integers');
          if (fieldValue.isNotEmpty && fieldValue.first is int) {
            final converted = Uint8List.fromList(fieldValue.cast<int>());
            debugPrint('Converted to Uint8List (${converted.length} bytes)');
            fieldValue = converted;
          }
        }
        // Format 3:IMAGE SIGNATURE
        else if (fieldValue is String) {
          debugPrint('   Format: String (length: ${fieldValue.length})');
          if (fieldValue.length > 50 && !fieldValue.contains(' ')) {
            try {
              final decoded = base64Decode(fieldValue);
              debugPrint(' Decoded base64 string to Uint8List (${decoded.length} bytes)');
              fieldValue = decoded;
            } catch (_) {
              debugPrint(' Not base64, keeping as text signature');
            }
          } else {
            debugPrint('Short string, treating as text signature');
          }
        }

        debugPrint('Final value type: ${fieldValue.runtimeType}');
        debugPrint('Is Uint8List: ${fieldValue is Uint8List}');
      } catch (e) {
        debugPrint('Error decoding signature data: $e');
      }
    }

    return FieldEntity(
      id: json['id'] as String,
      type: FieldType.values.firstWhere((e) => e.name == json['type']),
      page: json['page'] as int,
      xPercent: (json['xPercent'] as num).toDouble(),
      yPercent: (json['yPercent'] as num).toDouble(),
      widthPercent: (json['widthPercent'] as num).toDouble(),
      heightPercent: (json['heightPercent'] as num).toDouble(),
      value: fieldValue,
      isRequired: json['isRequired'] as bool? ?? false,
      label: json['label'] as String?,
    );
  }

  @override
  String toString() {
    return 'FieldEntity(id: $id, type: $type, page: $page, x: $xPercent, y: $yPercent)';
  }
}
