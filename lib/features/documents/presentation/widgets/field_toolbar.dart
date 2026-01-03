import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/entities/field_entity.dart';
import '../../../../core/theme/app_colors.dart';

/// Bottom toolbar for selecting field types to add
class FieldToolbar extends StatelessWidget {
  final Function(FieldType) onFieldSelected;
  final bool isEnabled;

  const FieldToolbar({super.key, required this.onFieldSelected, this.isEnabled = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _FieldButton(
              type: FieldType.signature,
              icon: Icons.draw,
              label: 'Signature',
              color: Colors.blue,
              onTap: isEnabled ? () => onFieldSelected(FieldType.signature) : null,
            ),
            _FieldButton(
              type: FieldType.text,
              icon: Icons.text_fields,
              label: 'Text',
              color: Colors.green,
              onTap: isEnabled ? () => onFieldSelected(FieldType.text) : null,
            ),
            _FieldButton(
              type: FieldType.checkbox,
              icon: Icons.check_box,
              label: 'Checkbox',
              color: Colors.orange,
              onTap: isEnabled ? () => onFieldSelected(FieldType.checkbox) : null,
            ),
            _FieldButton(
              type: FieldType.date,
              icon: Icons.calendar_today,
              label: 'Date',
              color: Colors.purple,
              onTap: isEnabled ? () => onFieldSelected(FieldType.date) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldButton extends StatelessWidget {
  final FieldType type;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _FieldButton({required this.type, required this.icon, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isDisabled ? 0.5 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
              ),
              child: Icon(icon, size: 24.sp, color: color),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: isDisabled ? AppColors.textDisabled : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
