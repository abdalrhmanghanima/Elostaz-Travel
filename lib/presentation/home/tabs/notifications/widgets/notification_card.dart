import 'package:elostaz_travel/core/dimens/dimens.dart';
import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/navigator/navigator.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/core/utils/app_icons.dart';
import 'package:elostaz_travel/presentation/components/custom_svg/custom_svg_icon.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/bus_details_screen.dart';
import 'package:elostaz_travel/presentation/home/tabs/notifications/provider/notifications_provider.dart';
import 'package:flutter/material.dart';

class NotificationCard extends StatelessWidget {
  final BusNotificationItem item;

  const NotificationCard({
    super.key,
    required this.item,
  });

  String _formatDate(DateTime date) {
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');

    return '$d/$m/$y';
  }

  @override
  Widget build(BuildContext context) {
    final bus = item.bus;
    final status = item.status;
    final daysLeft = item.daysLeft;

    // Status colors and strings
    final Color statusColor;
    final Color statusBgColor;
    final String statusBadgeText;
    final String remainingText;
    final IconData statusIcon;

    switch (status) {
      case BusNotificationFilter.expired:
        statusColor = AppColors.red;
        statusBgColor = AppColors.lightRed;
        statusBadgeText = 'منتهي';
        remainingText = 'انتهت الرخصة';
        statusIcon = Icons.cancel_outlined;
        break;

      case BusNotificationFilter.expiringSoon:
        statusColor = AppColors.warning;
        statusBgColor = AppColors.lightYellow;
        statusBadgeText = 'ينتهي قريبًا';

        final daysStr = daysLeft == 1
            ? 'يوم واحد'
            : daysLeft == 2
            ? 'يومان'
            : daysLeft <= 10
            ? '$daysLeft أيام'
            : '$daysLeft يوم';

        remainingText = 'متبقي $daysStr';
        statusIcon = Icons.warning_amber_rounded;
        break;

      case BusNotificationFilter.valid:
        statusColor = AppColors.green;
        statusBgColor = AppColors.lightGreen;
        statusBadgeText = 'ساري';
        remainingText = 'الرخصة سارية (متبقي $daysLeft يوم)';
        statusIcon = Icons.check_circle_outline;
        break;

      case BusNotificationFilter.all:
        statusColor = AppColors.primary;
        statusBgColor = AppColors.lightGray;
        statusBadgeText = 'الكل';
        remainingText = '';
        statusIcon = Icons.info_outline;
        break;
    }

    return GestureDetector(
      onTap: () {
        NavigatorHandler.push(
          BusDetailsScreen(bus: bus),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        width: Dimens.width,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Arrow
              CustomSvgIcon(
                assetName: AppIcons.arrowBack,
                height: 14.h,
                width: 14.w,
                color: AppColors.darkGray,
              ),

              SizedBox(width: 10.w),

              // Main Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // ─────────────────────────────────────────
                    // Header
                    // ─────────────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: statusBgColor,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                statusIcon,
                                size: 13.sp,
                                color: statusColor,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                statusBadgeText,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(width: 8.w),

                        // License title + Bus name
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'رخصة الأتوبيس',
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkGray,
                                ),
                              ),

                              SizedBox(height: 2.h),

                              Text(
                                bus.busName,
                                textAlign: TextAlign.end,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 8.h),

                    // ─────────────────────────────────────────
                    // Plate & Brand
                    // ─────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            '${bus.brand} (${bus.modelYear})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: AppColors.darkGray,
                            ),
                          ),
                        ),

                        Text(
                          ' • ',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: AppColors.gray,
                          ),
                        ),

                        Flexible(
                          child: Text(
                            'لوحة: ${bus.plateNumber}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 8.h),

                    // ─────────────────────────────────────────
                    // Remaining Status
                    // ─────────────────────────────────────────
                    if (remainingText.isNotEmpty)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          remainingText,
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),

                    SizedBox(height: 5.h),

                    // ─────────────────────────────────────────
                    // Expiry Date
                    // ─────────────────────────────────────────
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'الانتهاء: ${_formatDate(bus.licenseExpiryDate)}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.darkGray,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: 10.w),

              // Status Indicator
              Container(
                width: 5.w,
                height: 70.h,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
