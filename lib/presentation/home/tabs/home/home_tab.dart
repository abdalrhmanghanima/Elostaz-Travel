import 'package:elostaz_travel/core/dimens/dimens.dart';
import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/navigator/navigator.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/core/utils/app_icons.dart';
import 'package:elostaz_travel/core/utils/text_styles.dart';
import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/presentation/auth/provider/logout_provider.dart';
import 'package:elostaz_travel/presentation/auth/screen/login_screen.dart';
import 'package:elostaz_travel/presentation/components/custom_app_bar/custom_app_bar.dart';
import 'package:elostaz_travel/presentation/components/custom_svg/custom_svg_icon.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/home/provider/bottom_nav_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/provider/bus_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/provider/driver_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/home/financial_summary/financial_summary_screen.dart';
import 'package:elostaz_travel/presentation/home/tabs/home/provider/home_stats_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/widgets/custom_valid_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(homeStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: CustomAppBar(
        bgColor: AppColors.primary,
        showToolBar: true,
        title: "Elostaz Travel",
        titlePadding: 13.w,
        fontColor: AppColors.white,
        actions: [
          GestureDetector(
            onTap: () {
              ref.read(bottomNavProvider.notifier).state = 4;
            },
            child: SizedBox(
              width: 44.w,
              height: 44.h,
              child: Center(
                child: CustomSvgIcon(assetName: AppIcons.notificationWhite),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (dialogContext) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    title: Text(
                      "تسجيل الخروج",
                      textAlign: TextAlign.right,
                      style: AppTextStyles().normalText().textColorNormal(
                        AppColors.black,
                      ),
                    ),
                    content: Text(
                      "هل أنت متأكد أنك تريد تسجيل الخروج؟",
                      textAlign: TextAlign.right,
                      style: AppTextStyles().normalText().textColorNormal(
                        AppColors.black,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        child: Text(
                          "إلغاء",
                          style: AppTextStyles().normalText().textColorNormal(
                            AppColors.black,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(dialogContext);

                          await ref.read(logoutProvider.notifier).logout();

                          if (!context.mounted) return;

                          final logoutState = ref.read(logoutProvider);

                          if (logoutState.hasError) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "حدث خطأ أثناء تسجيل الخروج",
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            );
                            return;
                          }

                          // بعد نجاح Logout
                          NavigatorHandler.pushAndRemoveUntil(LoginScreen());
                        },
                        child: Text(
                          "تسجيل الخروج",
                          style: AppTextStyles().normalText().textColorNormal(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            child: SizedBox(
              width: 44.w,
              height: 44.h,
              child: Center(
                child: Icon(
                  Icons.logout_rounded,
                  color: AppColors.white,
                  size: 24.w,
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.white,
        onRefresh: () async {
          await Future.wait([
            ref.read(busProvider.notifier).refreshBuses(),
            ref.read(driversProvider.notifier).getDrivers(),
            ref.refresh(homeStatsProvider.future),
          ]);
        },
        child: statsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          error: (e, _) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Center(
                child: Text(
                  'حدث خطأ في تحميل البيانات',
                  style: TextStyle(color: Colors.white, fontSize: 16.sp),
                ),
              ),
            ),
          ),
          data: (stats) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.only(
                left: 12.w,
                right: 12.w,
                top: 20.h,
                bottom: 10.h,
              ),
              child: Column(
                children: [
                  // ── Row 1: Valid licenses  |  Total buses ──────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: stats.validLicenseCount.toString(),
                          label: "رخص سارية",
                          iconAsset: AppIcons.valid,
                          iconBgColor: AppColors.lightGreen,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _StatCard(
                          value: stats.totalBuses.toString(),
                          label: "العربيات",
                          iconAsset: AppIcons.bus,
                          iconBgColor: AppColors.lightGray,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),

                  // ── Row 2: Expired  |  Expiring soon ───────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: stats.expiredBuses.length.toString(),
                          label: "رخص منتهية",
                          iconAsset: AppIcons.unValid,
                          iconBgColor: AppColors.lightRed,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _StatCard(
                          value: stats.busesExpiringWithin30Days.length
                              .toString(),
                          label: "تنتهي قريبًا",
                          iconAsset: AppIcons.warning,
                          iconBgColor: AppColors.lightYellow,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),

                  // ── Row 3: Current-month trips  |  Total drivers ────────────
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: stats.currentMonthTripCount.toString(),
                          label: "رحلات الشهر",
                          iconAsset: AppIcons.trip,
                          iconBgColor: AppColors.lightGray,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _StatCard(
                          value: stats.totalDrivers.toString(),
                          label: "السائقين",
                          iconAsset: AppIcons.person,
                          iconBgColor: AppColors.lightGray,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 18.h),

                  // ── Upcoming / action list ──────────────────────────────────
                  _UpcomingLicensesCard(
                    expiringSoon: stats.busesExpiringWithin30Days,
                    expired: stats.expiredBuses,
                  ),
                  SizedBox(height: 18.h),

                  // ── Financial summary ───────────────────────────────────────
                  GestureDetector(
                    onTap: () =>
                        NavigatorHandler.push(const FinancialSummaryScreen()),
                    child: _FinancialSummaryCard(stats: stats),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Small reusable stat card
// ────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.iconAsset,
    required this.iconBgColor,
  });

  final String value;
  final String label;
  final String iconAsset;
  final Color iconBgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: CustomText(
                  title: value,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w700,
                  maxLines: 1,
                ),
              ),

              SizedBox(width: 8.w),

              CustomValidContainer(
                icon: iconAsset,
                iconBackgroundColor: iconBgColor,
              ),
            ],
          ),

          SizedBox(height: 10.h),

          Align(
            alignment: Alignment.center,
            child: CustomText(
              title: label,
              fontWeight: FontWeight.w700,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Upcoming licenses card – shows expiring + expired buses
// ────────────────────────────────────────────────────────────────────────────

class _UpcomingLicensesCard extends ConsumerWidget {
  const _UpcomingLicensesCard({
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
            (b) => _LicenseItem(
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

        return _LicenseItem(
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

class _LicenseItem {
  final BusEntity bus;
  final bool isExpired;
  final int daysLeft;
  const _LicenseItem({
    required this.bus,
    required this.isExpired,
    required this.daysLeft,
  });
}

// ────────────────────────────────────────────────────────────────────────────
// Financial summary card
// ────────────────────────────────────────────────────────────────────────────

class _FinancialSummaryCard extends StatelessWidget {
  const _FinancialSummaryCard({required this.stats});

  final HomeStats stats;

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Dimens.width,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─────────────────────────────────────────────
          // Header
          // ─────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.only(
              left: 12.w,
              right: 12.w,
              top: 16.h,
              bottom: 12.h,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(
                  Icons.chevron_left,
                  color: AppColors.darkGray,
                  size: 22,
                ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: CustomText(
                        title: "الملخص المالي (الشهر الحالي)",
                        fontSize: 16.sp,
                        maxLines: 1,
                        textAlign: TextAlign.right,
                      ),
                    ),

                    SizedBox(width: 8.w),

                    const Icon(Icons.wallet),
                  ],
                ),
              ],
            ),
          ),

          Divider(color: AppColors.backgroundGray, height: 3, thickness: 2),

          // ─────────────────────────────────────────────
          // Expenses + Revenue
          // ─────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.only(left: 12.w, right: 12.w, top: 16.h),
            child: Row(
              children: [
                // Expenses
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: CustomText(
                              title: "إجمالي المصروفات",
                              fontSize: 13.sp,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                            ),
                          ),

                          SizedBox(width: 4.w),

                          CustomSvgIcon(
                            assetName: AppIcons.down,
                            height: 10.h,
                            width: 13.w,
                          ),
                        ],
                      ),

                      SizedBox(height: 4.h),

                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomText(title: "ج.م", fontSize: 18.sp),

                          SizedBox(width: 4.w),

                          Flexible(
                            child: CustomText(
                              title: _fmt(stats.currentMonthExpenses),
                              fontSize: 18.sp,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 12.w),

                // Revenue
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: CustomText(
                              title: "إجمالي الإيرادات",
                              fontSize: 13.sp,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                            ),
                          ),

                          SizedBox(width: 4.w),

                          CustomSvgIcon(
                            assetName: AppIcons.up,
                            height: 10.h,
                            width: 13.w,
                          ),
                        ],
                      ),

                      SizedBox(height: 4.h),

                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomText(title: "ج.م", fontSize: 18.sp),

                          SizedBox(width: 4.w),

                          Flexible(
                            child: CustomText(
                              title: _fmt(stats.currentMonthRevenue),
                              fontSize: 18.sp,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          Divider(color: AppColors.backgroundGray, height: 3, thickness: 2),

          // ─────────────────────────────────────────────
          // Net Revenue + Trips
          // ─────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.only(left: 12.w, right: 12.w, top: 16.h),
            child: Row(
              children: [
                // Net Revenue
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomText(
                        title: "صافي الإيرادات",
                        fontSize: 13.sp,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 4.h),

                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomText(title: "ج.م", fontSize: 18.sp),

                          SizedBox(width: 4.w),

                          Flexible(
                            child: CustomText(
                              title: _fmt(stats.currentMonthNetRevenue),
                              fontSize: 18.sp,
                              fontColor: stats.currentMonthNetRevenue >= 0
                                  ? AppColors.green
                                  : AppColors.red,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 12.w),

                // Month Trips
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomText(
                        title: "رحلات الشهر",
                        fontSize: 13.sp,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 4.h),

                      CustomText(
                        title: stats.currentMonthTripCount.toString(),
                        fontSize: 18.sp,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20.h),
        ],
      ),
    );
  }
}
