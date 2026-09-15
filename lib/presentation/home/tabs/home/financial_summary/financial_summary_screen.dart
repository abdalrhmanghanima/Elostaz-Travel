import 'package:elostaz_travel/core/dimens/dimens.dart';
import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/navigator/navigator.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/core/utils/app_icons.dart';
import 'package:elostaz_travel/presentation/components/custom_app_bar/custom_app_bar.dart';
import 'package:elostaz_travel/presentation/components/custom_svg/custom_svg_icon.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/provider/driver_wage_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/home/financial_summary/provider/company_financial_summary_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/home/financial_summary/services/company_financial_report_service.dart';
import 'package:elostaz_travel/presentation/home/tabs/home/financial_summary/widgets/bus_group_card.dart';
import 'package:elostaz_travel/presentation/home/tabs/home/financial_summary/widgets/company_totals_card.dart';
import 'package:elostaz_travel/presentation/home/tabs/home/financial_summary/widgets/period_tab_item.dart';
import 'package:elostaz_travel/presentation/home/tabs/trip/provider/trip_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FinancialSummaryScreen extends ConsumerWidget {
  const FinancialSummaryScreen({super.key});

  String _fmt(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatCustomMonthLabel(DateTime date) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  void _showMonthPicker(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    int selectedMonth = now.month;
    int selectedYear = now.year;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final years = List.generate(
              now.year - 2020 + 1,
              (i) => 2020 + i,
            ).reversed.toList();

            const monthNames = [
              'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
              'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
            ];

            return Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    title: 'اختر الشهر والسنة',
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    fontColor: AppColors.primary,
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: selectedMonth,
                          decoration: InputDecoration(
                            labelText: 'الشهر',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          items: List.generate(12, (i) {
                            return DropdownMenuItem(
                              value: i + 1,
                              child: Text(monthNames[i]),
                            );
                          }),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedMonth = val);
                            }
                          },
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: selectedYear,
                          decoration: InputDecoration(
                            labelText: 'السنة',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          items: years.map((y) {
                            return DropdownMenuItem(
                              value: y,
                              child: Text('$y'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedYear = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: CustomText(
                            title: 'إلغاء',
                            fontColor: AppColors.gray,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          onPressed: () {
                            final picked = DateTime(selectedYear, selectedMonth);
                            if (picked.isAfter(now)) return;
                            ref.read(selectedCustomMonthProvider.notifier).state =
                                picked;
                            ref.read(selectedFinancialPeriodProvider.notifier).state =
                                FinancialPeriod.customMonth;
                            Navigator.pop(ctx);
                          },
                          child: CustomText(
                            title: 'تأكيد',
                            fontColor: AppColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(selectedFinancialPeriodProvider);
    final selectedCustomMonth = ref.watch(selectedCustomMonthProvider);
    final summaryAsync = ref.watch(companyFinancialSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: CustomAppBar(
        showToolBar: true,
        bgColor: AppColors.primary,
        centerTitle: true,
        title: "الملخص المالي للشركة",
        fontColor: AppColors.white,
        fontSize: 20.sp,
        iconPath: AppIcons.arrowLeft,
        onPressed: () => NavigatorHandler.pop(),
        actions: [
          IconButton(
            tooltip: 'مشاركة التقرير PDF',
            onPressed: summaryAsync.valueOrNull == null
                ? null
                : () async {
                    final summary = summaryAsync.valueOrNull;
                    if (summary != null) {
                      String periodTitle;
                      switch (summary.period) {
                        case FinancialPeriod.currentMonth:
                          periodTitle = 'الشهر الحالي';
                          break;
                        case FinancialPeriod.previousMonth:
                          periodTitle = 'الشهر السابق';
                          break;
                        case FinancialPeriod.customMonth:
                          periodTitle = summary.periodLabel;
                          break;
                        case FinancialPeriod.all:
                          periodTitle = 'الكل';
                          break;
                      }
                      await CompanyFinancialReportService.shareCompanyReport(
                        summary: summary,
                        periodTitle: periodTitle,
                      );
                    }
                  },
            icon: const Icon(
              Icons.print_outlined,
              color: AppColors.white,
            ),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: Column(
        children: [
          // ── 1. Period Filter Tabs ───────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(bottomRight: Radius.circular(16.r),bottomLeft: Radius.circular(16.r)),
              color: AppColors.white,
            ),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                PeriodTabItem(
                  title: FinancialPeriod.all.title,
                  isSelected: selectedPeriod == FinancialPeriod.all,
                  onTap: () {
                    ref.read(selectedFinancialPeriodProvider.notifier).state =
                        FinancialPeriod.all;
                  },
                ),
                SizedBox(width: 8.w),
                PeriodTabItem(
                  title: FinancialPeriod.previousMonth.title,
                  isSelected: selectedPeriod == FinancialPeriod.previousMonth,
                  onTap: () {
                    ref.read(selectedFinancialPeriodProvider.notifier).state =
                        FinancialPeriod.previousMonth;
                  },
                ),
                SizedBox(width: 8.w),
                PeriodTabItem(
                  title: FinancialPeriod.currentMonth.title,
                  isSelected: selectedPeriod == FinancialPeriod.currentMonth,
                  onTap: () {
                    ref.read(selectedFinancialPeriodProvider.notifier).state =
                        FinancialPeriod.currentMonth;
                  },
                ),
                SizedBox(width: 8.w),
                PeriodTabItem(
                  title: selectedPeriod == FinancialPeriod.customMonth &&
                          selectedCustomMonth != null
                      ? _formatCustomMonthLabel(selectedCustomMonth)
                      : FinancialPeriod.customMonth.title,
                  isSelected: selectedPeriod == FinancialPeriod.customMonth,
                  onTap: () {
                    if (selectedPeriod == FinancialPeriod.customMonth &&
                        selectedCustomMonth != null) {
                      return;
                    }
                    _showMonthPicker(context, ref);
                  },
                ),
              ],
            ),
          ),

          // ── 2. Summary Body & Bus Groups ────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.white,
              onRefresh: () async {
                ref.invalidate(monthlyTripsProvider);
                ref.invalidate(allTripsProvider);
                ref.invalidate(allDriverWagePaymentsProvider);
                ref.invalidate(companyFinancialSummaryProvider);
                await ref.read(companyFinancialSummaryProvider.future);
              },
              child: summaryAsync.when(
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
                          Icon(Icons.error_outline, color: AppColors.red, size: 48.sp),
                          SizedBox(height: 12.h),
                          CustomText(
                            title: 'حدث خطأ أثناء تحميل البيانات المالية',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
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
                data: (summary) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(14.w),
                    child: Column(
                      children: [
                        // ── Top Summary Card ────────────────────────────────
                        CompanyTotalsCard(summary: summary, fmt: _fmt),

                        SizedBox(height: 14.h),

                        // ── Trips grouped by bus ────────────────────────────
                        if (summary.busGroups.isEmpty)
                          Container(
                            width: Dimens.width,
                            margin: EdgeInsets.only(top: 40.h),
                            padding: EdgeInsets.all(32.w),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Column(
                              children: [
                                CustomSvgIcon(
                                  assetName: AppIcons.trip,
                                  height: 56.h,
                                  width: 56.w,
                                  color: AppColors.darkGray,
                                ),
                                SizedBox(height: 16.h),
                                CustomText(
                                  title: "لا توجد رحلات في هذه الفترة",
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  fontColor: AppColors.black,
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: summary.busGroups.length,
                            itemBuilder: (context, index) {
                              final group = summary.busGroups[index];
                              return BusGroupCard(
                                group: group,
                                fmt: _fmt,
                                formatDate: _formatDate,
                              );
                            },
                          ),
                      ],
                    ),
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
