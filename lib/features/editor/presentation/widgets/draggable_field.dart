import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/entities/field_entity.dart';
import '../../../../core/theme/app_colors.dart';

// Minimum sizes as percentage of page
const double kMinWidthPercent = 0.12;
const double kMinHeightPercent = 0.04;

class DraggableField extends StatefulWidget {
  final FieldEntity field;
  final bool isSelected;
  final bool isDraggable;
  final double pageWidth;
  final double pageHeight;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Function(double xPercent, double yPercent) onPositionChanged;
  final Function(double widthPercent, double heightPercent) onSizeChanged;

  const DraggableField({
    super.key,
    required this.field,
    required this.isSelected,
    required this.isDraggable,
    required this.pageWidth,
    required this.pageHeight,
    required this.onTap,
    required this.onDelete,
    required this.onPositionChanged,
    required this.onSizeChanged,
  });

  @override
  State<DraggableField> createState() => _DraggableFieldState();
}

class _DraggableFieldState extends State<DraggableField> {
  late double _xPercent;
  late double _yPercent;
  late double _widthPercent;
  late double _heightPercent;

  @override
  void initState() {
    super.initState();
    _xPercent = widget.field.xPercent;
    _yPercent = widget.field.yPercent;
    _widthPercent = widget.field.widthPercent;
    _heightPercent = widget.field.heightPercent;
  }

  @override
  void didUpdateWidget(covariant DraggableField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.field.xPercent != widget.field.xPercent || oldWidget.field.yPercent != widget.field.yPercent) {
      _xPercent = widget.field.xPercent;
      _yPercent = widget.field.yPercent;
    }
    if (oldWidget.field.widthPercent != widget.field.widthPercent ||
        oldWidget.field.heightPercent != widget.field.heightPercent) {
      _widthPercent = widget.field.widthPercent;
      _heightPercent = widget.field.heightPercent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final left = _xPercent * widget.pageWidth;
    final top = _yPercent * widget.pageHeight;
    final width = _widthPercent * widget.pageWidth;
    final height = _heightPercent * widget.pageHeight;

    return Positioned(left: left, top: top, child: _buildFieldContent(width, height));
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _xPercent += details.delta.dx / widget.pageWidth;
      _yPercent += details.delta.dy / widget.pageHeight;
      _xPercent = _xPercent.clamp(0.0, 1.0 - _widthPercent);
      _yPercent = _yPercent.clamp(0.0, 1.0 - _heightPercent);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    widget.onPositionChanged(_xPercent, _yPercent);
  }

  void _onResizeUpdate(DragUpdateDetails details) {
    setState(() {
      _widthPercent += details.delta.dx / widget.pageWidth;
      _heightPercent += details.delta.dy / widget.pageHeight;
      // Enforce minimum size
      _widthPercent = _widthPercent.clamp(kMinWidthPercent, 1.0 - _xPercent);
      _heightPercent = _heightPercent.clamp(kMinHeightPercent, 1.0 - _yPercent);
    });
  }

  void _onResizeEnd(DragEndDetails details) {
    widget.onSizeChanged(_widthPercent, _heightPercent);
  }

  Widget _buildFieldContent(double width, double height) {
    final hasValue = widget.field.value != null && widget.field.value.toString().isNotEmpty;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onPanUpdate: widget.isDraggable ? _onDragUpdate : null,
      onPanEnd: widget.isDraggable ? _onDragEnd : null,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: _getFieldColor().withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: CustomPaint(
          painter: DashedBorderPainter(
            color: widget.isSelected ? AppColors.primary : _getFieldColor(),
            strokeWidth: widget.isSelected ? 2 : 1,
            dashWidth: 5,
            dashSpace: 3,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Field content
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                child: Center(child: hasValue ? _buildFilledContent() : _buildPlaceholderContent()),
              ),

              // Delete button (top-right, only when selected)
              if (widget.isSelected && widget.isDraggable)
                Positioned(
                  right: -10.w,
                  top: -10.h,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        debugPrint('Delete tapped for field: ${widget.field.id}');
                        widget.onDelete();
                      },
                      borderRadius: BorderRadius.circular(12.r),
                      child: Container(
                        width: 24.w,
                        height: 24.w,
                        decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                        child: Icon(Icons.close, size: 14.sp, color: Colors.white),
                      ),
                    ),
                  ),
                ),

              // Resize handle (bottom-right, only when selected and draggable)
              if (widget.isSelected && widget.isDraggable)
                Positioned(
                  right: -2.w,
                  bottom: -6.h,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: _onResizeUpdate,
                    onPanEnd: _onResizeEnd,
                    child: Container(
                      width: 20.w,
                      height: 20.w,
                      decoration: BoxDecoration(
                        color: _getFieldColor(),
                        borderRadius: BorderRadius.circular(4.r),
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2, offset: const Offset(1, 1))],
                      ),
                      child: Icon(Icons.open_in_full, size: 12.sp, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_getFieldIcon(), size: 14.sp, color: _getFieldColor()),
        SizedBox(width: 4.w),
        Flexible(
          child: Text(
            _getFieldLabel(),
            style: TextStyle(fontSize: 11.sp, color: _getFieldColor(), fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildFilledContent() {
    final value = widget.field.value;

    switch (widget.field.type) {
      case FieldType.checkbox:
        return FittedBox(
          fit: BoxFit.contain,
          child: Icon(value == true ? Icons.check_box : Icons.check_box_outline_blank, color: _getFieldColor()),
        );
      case FieldType.signature:
        if (value is Uint8List) {
          return Image.memory(
            value,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                Icon(Icons.error_outline, size: 20.sp, color: AppColors.error),
          );
        }
        return Text(
          value.toString(),
          style: TextStyle(fontSize: 14, fontFamily: 'Cursive', color: Colors.black87),
          overflow: TextOverflow.ellipsis,
        );
      case FieldType.text:
      case FieldType.date:
        return Text(
          value.toString(),
          style: TextStyle(fontSize: 12.sp, color: Colors.black87, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        );
    }
  }

  IconData _getFieldIcon() {
    switch (widget.field.type) {
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
    if (widget.field.label != null && widget.field.label!.isNotEmpty) {
      return widget.field.label!;
    }
    return FieldEntity.getDisplayName(widget.field.type);
  }

  Color _getFieldColor() {
    switch (widget.field.type) {
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

/// Custom painter for dashed border
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DashedBorderPainter({required this.color, this.strokeWidth = 1, this.dashWidth = 5, this.dashSpace = 3});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(4)));

    final dashPath = Path();
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final start = distance;
        final end = (distance + dashWidth).clamp(0.0, metric.length);
        dashPath.addPath(metric.extractPath(start, end), Offset.zero);
        distance += dashWidth + dashSpace;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace;
  }
}
