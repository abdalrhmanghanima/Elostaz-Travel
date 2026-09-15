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
import 'package:elostaz_travel/presentation/home/tabs/notifications/widgets/filter_tab_item.dart';
import 'package:elostaz_travel/presentation/home/tabs/notifications/widgets/notification_card.dart';

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
          Container(
            color: AppColors.white,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                FilterTabItem(
                  title: BusNotificationFilter.all.title,
                  count: counts.all,
                  isSelected: selectedFilter == BusNotificationFilter.all,
                  onTap: () {
                    ref.read(selectedNotificationFilterProvider.notifier).state =
                        BusNotificationFilter.all;
                  },
                ),
                SizedBox(width: 6.w),
                FilterTabItem(
                  title: BusNotificationFilter.valid.title,
                  count: counts.valid,
                  isSelected: selectedFilter == BusNotificationFilter.valid,
                  onTap: () {
                    ref.read(selectedNotificationFilterProvider.notifier).state =
                        BusNotificationFilter.valid;
                  },
                ),
                SizedBox(width: 6.w),
                FilterTabItem(
                  title: BusNotificationFilter.expiringSoon.title,
                  count: counts.expiringSoon,
                  isSelected: selectedFilter == BusNotificationFilter.expiringSoon,
                  onTap: () {
                    ref.read(selectedNotificationFilterProvider.notifier).state =
                        BusNotificationFilter.expiringSoon;
                  },
                ),
                SizedBox(width: 6.w),
                FilterTabItem(
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
                      return NotificationCard(item: item);
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
