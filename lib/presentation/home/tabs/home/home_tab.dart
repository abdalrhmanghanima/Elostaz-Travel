import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/navigator/navigator.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/core/utils/app_icons.dart';
import 'package:elostaz_travel/core/utils/text_styles.dart';
import 'package:elostaz_travel/presentation/ai_assistant/widgets/ai_assistant_fab.dart';
import 'package:elostaz_travel/presentation/auth/provider/logout_provider.dart';
import 'package:elostaz_travel/presentation/auth/screen/login_screen.dart';
import 'package:elostaz_travel/presentation/components/custom_app_bar/custom_app_bar.dart';
import 'package:elostaz_travel/presentation/components/custom_svg/custom_svg_icon.dart';
import 'package:elostaz_travel/presentation/home/provider/bottom_nav_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/provider/bus_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/provider/driver_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/home/financial_summary/provider/company_financial_summary_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/home/financial_summary/financial_summary_screen.dart';
import 'package:elostaz_travel/presentation/home/tabs/home/provider/home_stats_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/home/widgets/financial_summary_card.dart';
import 'package:elostaz_travel/presentation/home/tabs/home/widgets/stat_card.dart';
import 'package:elostaz_travel/presentation/home/tabs/home/widgets/upcoming_licenses_card.dart';
import 'package:elostaz_travel/presentation/home/tabs/notifications/provider/notifications_provider.dart';
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
                        child: StatCard(
                          value: stats.validLicenseCount.toString(),
                          label: "رخص سارية",
                          iconAsset: AppIcons.valid,
                          iconBgColor: AppColors.lightGreen,
                          onTap: () {
                            ref
                                .read(selectedNotificationFilterProvider.notifier)
                                .state = BusNotificationFilter.valid;
                            ref.read(bottomNavProvider.notifier).state = 4;
                          },
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: StatCard(
                          value: stats.totalBuses.toString(),
                          label: "العربيات",
                          iconAsset: AppIcons.bus,
                          iconBgColor: AppColors.lightGray,
                          onTap: () {
                            ref.read(bottomNavProvider.notifier).state = 1;
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),

                  // ── Row 2: Expired  |  Expiring soon ───────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          value: stats.expiredBuses.length.toString(),
                          label: "رخص منتهية",
                          iconAsset: AppIcons.unValid,
                          iconBgColor: AppColors.lightRed,
                          onTap: () {
                            ref
                                .read(selectedNotificationFilterProvider.notifier)
                                .state = BusNotificationFilter.expired;
                            ref.read(bottomNavProvider.notifier).state = 4;
                          },
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: StatCard(
                          value: stats.busesExpiringWithin30Days.length
                              .toString(),
                          label: "تنتهي قريبًا",
                          iconAsset: AppIcons.warning,
                          iconBgColor: AppColors.lightYellow,
                          onTap: () {
                            ref
                                .read(selectedNotificationFilterProvider.notifier)
                                .state = BusNotificationFilter.expiringSoon;
                            ref.read(bottomNavProvider.notifier).state = 4;
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),

                  // ── Row 3: Current-month trips  |  Total drivers ────────────
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          value: stats.currentMonthTripCount.toString(),
                          label: "رحلات الشهر",
                          iconAsset: AppIcons.trip,
                          iconBgColor: AppColors.lightGray,
                          onTap: () {
                            ref.read(selectedFinancialPeriodProvider.notifier).state =
                                FinancialPeriod.currentMonth;

                            NavigatorHandler.push(
                              const FinancialSummaryScreen(),
                            );
                          },
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: StatCard(
                          value: stats.totalDrivers.toString(),
                          label: "السائقين",
                          iconAsset: AppIcons.person,
                          iconBgColor: AppColors.lightGray,
                          onTap: () {
                            ref.read(bottomNavProvider.notifier).state = 2;
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 18.h),

                  // ── Upcoming / action list ──────────────────────────────────
UpcomingLicensesCard(
                    expiringSoon: stats.busesExpiringWithin30Days,
                    expired: stats.expiredBuses,
                  ),
                  SizedBox(height: 18.h),

                  // ── Financial summary ───────────────────────────────────────
                  GestureDetector(
                    onTap: () =>
                        NavigatorHandler.push(const FinancialSummaryScreen()),
                    child: FinancialSummaryCard(stats: stats),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 20.h),
        child: const AiAssistantFab(),
      ),

      floatingActionButtonLocation:
      FloatingActionButtonLocation.endFloat,
    );
  }
}

