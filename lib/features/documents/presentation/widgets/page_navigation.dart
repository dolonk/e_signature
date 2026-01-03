import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';

/// Page navigation controls for multi-page PDF documents
class PageNavigation extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onFirstPage;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;
  final VoidCallback onLastPage;

  const PageNavigation({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onFirstPage,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.onLastPage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.greyLight, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // First page button
          _NavButton(icon: Icons.first_page, onTap: currentPage > 1 ? onFirstPage : null),
          SizedBox(width: 8.w),
          // Previous page button
          _NavButton(icon: Icons.chevron_left, onTap: currentPage > 1 ? onPreviousPage : null),
          SizedBox(width: 16.w),
          // Page indicator
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(color: AppColors.greyLight, borderRadius: BorderRadius.circular(8.r)),
            child: Text(
              'Page $currentPage / $totalPages',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
            ),
          ),
          SizedBox(width: 16.w),
          // Next page button
          _NavButton(icon: Icons.chevron_right, onTap: currentPage < totalPages ? onNextPage : null),
          SizedBox(width: 8.w),
          // Last page button
          _NavButton(icon: Icons.last_page, onTap: currentPage < totalPages ? onLastPage : null),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _NavButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: isDisabled ? AppColors.greyLight : AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(icon, size: 24.sp, color: isDisabled ? AppColors.textDisabled : AppColors.primary),
      ),
    );
  }
}
