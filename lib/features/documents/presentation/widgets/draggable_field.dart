import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/entities/field_entity.dart';
import '../../../../core/theme/app_colors.dart';

/// Draggable field widget that can be positioned on the PDF
class DraggableField extends StatelessWidget {
  final FieldEntity field;
  final bool isSelected;
  final bool isDraggable;
  final double pageWidth;
  final double pageHeight;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Function(double xPercent, double yPercent) onDragEnd;

  const DraggableField({
    super.key,
    required this.field,
    required this.isSelected,
    required this.isDraggable,
    required this.pageWidth,
    required this.pageHeight,
    required this.onTap,
    required this.onDelete,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate actual position and size from percentages
    final left = field.xPercent * pageWidth;
    final top = field.yPercent * pageHeight;
    final width = field.widthPercent * pageWidth;
    final height = field.heightPercent * pageHeight;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: onTap,
        child: isDraggable
            ? Draggable<FieldEntity>(
                data: field,
                feedback: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(8.r),
                  child: _buildFieldContent(width, height, isDragging: true),
                ),
                childWhenDragging: Opacity(opacity: 0.3, child: _buildFieldContent(width, height)),
                onDragEnd: (details) {
                  // This is handled by the parent DragTarget
                },
                child: _buildFieldContent(width, height),
              )
            : _buildFieldContent(width, height),
      ),
    );
  }

  Widget _buildFieldContent(double width, double height, {bool isDragging = false}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _getFieldColor().withValues(alpha: 0.2),
        border: Border.all(color: isSelected ? AppColors.primary : _getFieldColor(), width: isSelected ? 2 : 1),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Stack(
        children: [
          // Field content
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getFieldIcon(), size: 16.sp, color: _getFieldColor()),
                SizedBox(width: 4.w),
                Flexible(
                  child: Text(
                    _getFieldLabel(),
                    style: TextStyle(fontSize: 10.sp, color: _getFieldColor(), fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Delete button (only when selected and in edit mode)
          if (isSelected && isDraggable)
            Positioned(
              right: -8.w,
              top: -8.h,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: EdgeInsets.all(4.r),
                  decoration: BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                  child: Icon(Icons.close, size: 12.sp, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getFieldIcon() {
    switch (field.type) {
      case FieldType.signature:
        return Icons.draw;
      case FieldType.text:
        return Icons.text_fields;
      case FieldType.checkbox:
        return Icons.check_box_outline_blank;
      case FieldType.date:
        return Icons.calendar_today;
    }
  }

  String _getFieldLabel() {
    if (field.label != null && field.label!.isNotEmpty) {
      return field.label!;
    }
    return FieldEntity.getDisplayName(field.type);
  }

  Color _getFieldColor() {
    switch (field.type) {
      case FieldType.signature:
        return Colors.blue;
      case FieldType.text:
        return Colors.green;
      case FieldType.checkbox:
        return Colors.orange;
      case FieldType.date:
        return Colors.purple;
    }
  }
}
