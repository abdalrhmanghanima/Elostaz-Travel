import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/presentation/ai_assistant/model/ai_action_option.dart';
import 'package:flutter/material.dart';

class AiActionOptionsList extends StatelessWidget {
  const AiActionOptionsList({
    super.key,
    required this.options,
    required this.onSelect,
  });

  /// UI-only toggle: when false, the Queries (الاستعلام) section is hidden
  /// from the rendered catalog while the source catalog and all query logic
  /// stay intact. Flip to true to restore the Query section.
  static const bool showQuerySection = false;

  final List<AiActionOption> options;
  final ValueChanged<AiActionOption> onSelect;

  @override
  Widget build(BuildContext context) {
    final visibleOptions = showQuerySection
        ? options
        : options.where((o) => o.isCreate).toList();
    final addOptions =
        visibleOptions.where((o) => o.category == AiActionCategory.add).toList();
    final queryOptions =
        visibleOptions.where((o) => o.category == AiActionCategory.query).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (addOptions.isNotEmpty) ...[
          _buildCategoryHeader('إضافة', Icons.add_circle_outline_rounded),
          SizedBox(height: 6.h),
          for (final option in addOptions) _buildOptionCard(option),
        ],

        if (queryOptions.isNotEmpty) ...[
          SizedBox(height: 4.h),
          _buildCategoryHeader('استعلام', Icons.search_rounded),
          SizedBox(height: 6.h),
          for (final option in queryOptions) _buildOptionCard(option),
        ],
      ],
    );
  }

  Widget _buildCategoryHeader(String label, IconData icon) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          Icon(
            icon,
            size: 15.w,
            color: AppColors.primary,
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(AiActionOption option) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: () => onSelect(option),
          child: Ink(
            padding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 8.h,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    option.icon,
                    color: AppColors.primary,
                    size: 18.w,
                  ),
                ),

                SizedBox(width: 8.w),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        option.title,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),

                      if (option.description.isNotEmpty) ...[
                        SizedBox(height: 1.h),
                        Text(
                          option.description,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.primary,
                  size: 20.w,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}