import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:flutter/material.dart';

class AiEntityChoiceItem {
  final String id;
  final String title;
  final String? subtitle;
  final IconData icon;

  const AiEntityChoiceItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.icon = Icons.check_circle_outline_rounded,
  });
}

class AiEntityChoiceList extends StatelessWidget {
  const AiEntityChoiceList({
    super.key,
    required this.question,
    required this.options,
    required this.onSelect,
  });

  final String question;
  final List<AiEntityChoiceItem> options;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Text(
            question,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),

        SizedBox(height: 8.h),

        for (final option in options)
          Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14.r),
                onTap: () => onSelect(option.id),
                child: Ink(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          option.icon,
                          color: AppColors.primary,
                          size: 21.w,
                        ),
                      ),

                      SizedBox(width: 10.w),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              option.title,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.black,
                              ),
                            ),

                            if (option.subtitle != null &&
                                option.subtitle!.isNotEmpty) ...[
                              SizedBox(height: 2.h),
                              Text(
                                option.subtitle!,
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 12.sp,
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
                        size: 22.w,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}