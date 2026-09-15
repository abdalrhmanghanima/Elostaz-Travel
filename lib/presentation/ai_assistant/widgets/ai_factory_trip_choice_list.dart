import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:flutter/material.dart';

class AiFactoryTripChoiceItem {
  final String type;
  final String title;
  final String? subtitle;
  final IconData icon;

  const AiFactoryTripChoiceItem({
    required this.type,
    required this.title,
    this.subtitle,
    required this.icon,
  });
}

const List<AiFactoryTripChoiceItem> availableFactoryTripTypes = [
  AiFactoryTripChoiceItem(
    type: 'trip',
    title: 'رحلة',
    subtitle: 'تسجيل رحلة للمصنع',
    icon: Icons.directions_bus_outlined,
  ),
  AiFactoryTripChoiceItem(
    type: 'night_outing',
    title: 'سهرة',
    subtitle: 'تسجيل سهرة للمصنع',
    icon: Icons.nightlight_round,
  ),
];

class AiFactoryTripChoiceList extends StatelessWidget {
  const AiFactoryTripChoiceList({
    super.key,
    required this.factoryName,
    required this.onSelect,
  });

  final String factoryName;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Text(
            'المصنع "$factoryName" عنده أكتر من نوع رحلة.\nاختار أنهي نوع:',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ),

        SizedBox(height: 8.h),

        for (final option in availableFactoryTripTypes)
          Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14.r),
                onTap: () => onSelect(option.type),
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
