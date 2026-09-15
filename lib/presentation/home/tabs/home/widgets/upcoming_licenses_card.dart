import 'package:elostaz_travel/core/dimens/dimens.dart';
import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/home/provider/bottom_nav_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UpcomingLicensesCard extends ConsumerWidget {
  const UpcomingLicensesCard({
    super.key,
    required this.expiringSoon,
    required this.expired,
  });

  final List<BusEntity> expiringSoon;
  final List<BusEntity> expired;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final allItems = [
      ...expired.map(
            (b) => LicenseItem(
          bus: b,
          isExpired: true,
          daysLeft: 0,
        ),
      ),
      ...expiringSoon.map((b) {
        final expiry = DateTime(
          b.licenseExpiryDate.year,
          b.licenseExpiryDate.month,
          b.licenseExpiryDate.day,
        );

        final diff = expiry.difference(today).inDays;

        return LicenseItem(
          bus: b,
          isExpired: false,
          daysLeft: diff,
        );
      }),
    ];

    return Container(
      width: Dimens.width,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 12.w,
          right: 12.w,
          top: 16.h,
          bottom: 4.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    ref.read(bottomNavProvider.notifier).state = 4;
                  },
                  child: CustomText(
                    title: "عرض الكل",
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    fontColor: AppColors.primary,
                  ),
                ),
                CustomText(
                  title: "يحتاج إجراء",
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),

            SizedBox(height: 12.h),

            // Empty state
            if (allItems.isEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: CustomText(
                  title: "لا توجد تراخيص تحتاج إجراء",
                  fontColor: Colors.grey,
                ),
              )
            else
            // No ListView / No Scroll
              Column(
                mainAxisSize: MainAxisSize.min,
                children: allItems.map((item) {
                  final color = item.isExpired
                      ? AppColors.red
                      : AppColors.warning;

                  final subtitle = item.isExpired
                      ? 'انتهت الرخصة'
                      : 'تنتهي خلال ${item.daysLeft} '
                      '${item.daysLeft == 1 ? 'يوم' : 'أيام'}';

                  return Container(
                    margin: EdgeInsets.only(bottom: 12.h),
                    width: Dimens.width,
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 14.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                          ),
                        ),

                        SizedBox(width: 12.w),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.end,
                            children: [
                              Text(
                                'رخصة السيارة • ${item.bus.busName}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),

                              SizedBox(height: 4.h),

                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class LicenseItem {
  final BusEntity bus;
  final bool isExpired;
  final int daysLeft;
  const LicenseItem({
    required this.bus,
    required this.isExpired,
    required this.daysLeft,
  });
}
