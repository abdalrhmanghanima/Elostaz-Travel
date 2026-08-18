import 'package:elostaz_travel/core/dimens/dimens.dart';
import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/navigator/navigator.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/core/utils/app_icons.dart';
import 'package:elostaz_travel/presentation/components/custom_app_bar/custom_app_bar.dart';
import 'package:elostaz_travel/presentation/components/custom_svg/custom_svg_icon.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/bus_details_screen.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/provider/bus_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/notifications/provider/notifications_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationsTab extends ConsumerWidget {
  const NotificationsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(selectedNotificationFilterProvider);
    final counts = ref.watch(notificationCountsProvider);
    final notificationsAsync = ref.watch(busNotificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: CustomAppBar(
        showToolBar: true,
        bgColor: AppColors.primary,
        centerTitle: true,
        title: "التنبيهات",
        fontColor: AppColors.white,
        fontSize: 24.sp,
      ),
      body: Column(
        children: [
          // ── Horizontal Filter Row (4 items in one row) ───────────────────
          Container(
            color: AppColors.white,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                _FilterTabItem(
                  title: BusNotificationFilter.all.title,
                  count: counts.all,
                  isSelected: selectedFilter == BusNotificationFilter.all,
                  onTap: () {
                    ref.read(selectedNotificationFilterProvider.notifier).state =
                        BusNotificationFilter.all;
                  },
                ),
                SizedBox(width: 6.w),
                _FilterTabItem(
                  title: BusNotificationFilter.valid.title,
                  count: counts.valid,
                  isSelected: selectedFilter == BusNotificationFilter.valid,
                  onTap: () {
                    ref.read(selectedNotificationFilterProvider.notifier).state =
                        BusNotificationFilter.valid;
                  },
                ),
                SizedBox(width: 6.w),
                _FilterTabItem(
                  title: BusNotificationFilter.expiringSoon.title,
                  count: counts.expiringSoon,
                  isSelected: selectedFilter == BusNotificationFilter.expiringSoon,
                  onTap: () {
                    ref.read(selectedNotificationFilterProvider.notifier).state =
                        BusNotificationFilter.expiringSoon;
                  },
                ),
                SizedBox(width: 6.w),
                _FilterTabItem(
                  title: BusNotificationFilter.expired.title,
                  count: counts.expired,
                  isSelected: selectedFilter == BusNotificationFilter.expired,
                  onTap: () {
                    ref.read(selectedNotificationFilterProvider.notifier).state =
                        BusNotificationFilter.expired;
                  },
                ),
              ],
            ),
          ),

          // ── Notification Items List / State Handler ─────────────────────
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.white,
              onRefresh: () async {
                await ref.read(busProvider.notifier).refreshBuses();
              },
              child: notificationsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: 100.h),
                    Padding(
                      padding: EdgeInsets.all(24.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: AppColors.red,
                            size: 48.sp,
                          ),
                          SizedBox(height: 12.h),
                          CustomText(
                            title: 'حدث خطأ أثناء تحميل التنبيهات',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          SizedBox(height: 6.h),
                          CustomText(
                            title: error.toString(),
                            fontSize: 13.sp,
                            fontColor: AppColors.gray,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: 100.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32.w),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(20.w),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: CustomSvgIcon(
                                  assetName: AppIcons.notification,
                                  height: 48.h,
                                  width: 48.w,
                                  color: AppColors.darkGray,
                                ),
                              ),
                              SizedBox(height: 16.h),
                              CustomText(
                                title: selectedFilter.emptyMessage,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                fontColor: AppColors.black,
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8.h),
                              CustomText(
                                title: 'سيتم عرض إشعارات رخص الأتوبيسات هنا فور توفرها',
                                fontSize: 14.sp,
                                fontColor: AppColors.gray,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _NotificationCard(item: item);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Filter Tab Item Widget (compact, fits in 1 row of 4 items)
// ────────────────────────────────────────────────────────────────────────────

class _FilterTabItem extends StatelessWidget {
  final String title;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterTabItem({
    required this.title,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 2.w),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.borderGray,
              width: 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? AppColors.white : AppColors.black,
                ),
              ),
              SizedBox(height: 3.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.white.withValues(alpha: 0.2)
                      : AppColors.grayLight,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.white : AppColors.darkGray,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Bus License Notification Card Widget
// ────────────────────────────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  final BusNotificationItem item;

  const _NotificationCard({
    required this.item,
  });

  String _formatDate(DateTime date) {
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');

    return '$y/$m/$d';
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