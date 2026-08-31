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
                _PeriodTabItem(
                  title: FinancialPeriod.all.title,
                  isSelected: selectedPeriod == FinancialPeriod.all,
                  onTap: () {
                    ref.read(selectedFinancialPeriodProvider.notifier).state =
                        FinancialPeriod.all;
                  },
                ),
                SizedBox(width: 8.w),
                _PeriodTabItem(
                  title: FinancialPeriod.previousMonth.title,
                  isSelected: selectedPeriod == FinancialPeriod.previousMonth,
                  onTap: () {
                    ref.read(selectedFinancialPeriodProvider.notifier).state =
                        FinancialPeriod.previousMonth;
                  },
                ),
                SizedBox(width: 8.w),
                _PeriodTabItem(
                  title: FinancialPeriod.currentMonth.title,
                  isSelected: selectedPeriod == FinancialPeriod.currentMonth,
                  onTap: () {
                    ref.read(selectedFinancialPeriodProvider.notifier).state =
                        FinancialPeriod.currentMonth;
                  },
                ),
                SizedBox(width: 8.w),
                _PeriodTabItem(
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
                        _CompanyTotalsCard(summary: summary, fmt: _fmt),

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
                              return _BusGroupCard(
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

// ────────────────────────────────────────────────────────────────────────────
// Period Filter Tab Item
// ────────────────────────────────────────────────────────────────────────────

class _PeriodTabItem extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodTabItem({
    required this.title,
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
          padding: EdgeInsets.symmetric(vertical: 8.h),
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
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? AppColors.white : AppColors.black,
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Top Company Totals Card
// ────────────────────────────────────────────────────────────────────────────

class _CompanyTotalsCard extends StatelessWidget {
  final CompanyFinancialSummary summary;
  final String Function(double) fmt;

  const _CompanyTotalsCard({
    required this.summary,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Dimens.width,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 14.w, right: 14.w, top: 14.h, bottom: 10.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    'رحلة ${summary.totalTrips}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.green,
                    ),
                  ),
                ),
                Row(
                  children: [
                    CustomText(
                      title: "إجمالي أداء الشركة",
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    SizedBox(width: 8.w),
                    const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary),
                  ],
                ),
              ],
            ),
          ),
          Divider(color: AppColors.backgroundGray, height: 2, thickness: 1.5),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Row(
              children: [
                // Total Expenses
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomText(title: "المصروفات", fontSize: 13.sp, fontColor: AppColors.gray),
                          SizedBox(width: 4.w),
                          CustomSvgIcon(assetName: AppIcons.down, height: 10.h, width: 10.w),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomText(title: "ج.م", fontSize: 14.sp),
                          SizedBox(width: 4.w),
                          CustomText(
                            title: fmt(summary.totalExpenses),
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            fontColor: AppColors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(height: 40.h, width: 1, color: AppColors.borderGray),
                // Total Revenue
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomText(title: "الإيرادات", fontSize: 13.sp, fontColor: AppColors.gray),
                          SizedBox(width: 4.w),
                          CustomSvgIcon(assetName: AppIcons.up, height: 10.h, width: 10.w),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomText(title: "ج.م", fontSize: 14.sp),
                          SizedBox(width: 4.w),
                          CustomText(
                            title: fmt(summary.totalRevenue),
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            fontColor: AppColors.black,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (summary.totalDriverWages > 0) ...[
            Divider(color: AppColors.backgroundGray, height: 2, thickness: 1.5),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CustomText(title: "ج.م", fontSize: 13.sp, fontColor: const Color(0xFFB45309)),
                      SizedBox(width: 4.w),
                      CustomText(
                        title: fmt(summary.totalDriverWages),
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        fontColor: const Color(0xFFB45309),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      CustomText(
                        title: "إجمالي أجور السائقين المستحقة",
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        fontColor: const Color(0xFF92400E),
                      ),
                      SizedBox(width: 6.w),
                      Icon(
                        Icons.badge_outlined,
                        size: 16.sp,
                        color: const Color(0xFFD97706),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (summary.totalDriverWagesPaid > 0) ...[
            Divider(color: AppColors.backgroundGray, height: 2, thickness: 1.5),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CustomText(title: "ج.م", fontSize: 13.sp, fontColor: AppColors.red),
                      SizedBox(width: 4.w),
                      CustomText(
                        title: fmt(summary.totalDriverWagesPaid),
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        fontColor: AppColors.red,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      CustomText(
                        title: "أجور السائقين المسددة (المدفوعة)",
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        fontColor: AppColors.red,
                      ),
                      SizedBox(width: 6.w),
                      Icon(
                        Icons.payments_outlined,
                        size: 16.sp,
                        color: AppColors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          Divider(color: AppColors.backgroundGray, height: 2, thickness: 1.5),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CustomText(title: "ج.م", fontSize: 14.sp),
                    SizedBox(width: 4.w),
                    CustomText(
                      title: fmt(summary.totalNetRevenue),
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      fontColor: summary.totalNetRevenue >= 0 ? AppColors.green : AppColors.red,
                    ),
                  ],
                ),
                CustomText(
                  title: "صافي أرباح الشركة",
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Bus Group Card with Subtotals and Trip Items
// ────────────────────────────────────────────────────────────────────────────

class _BusGroupCard extends StatelessWidget {
  final BusFinancialGroup group;
  final String Function(double) fmt;
  final String Function(DateTime) formatDate;

  const _BusGroupCard({
    required this.group,
    required this.fmt,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Bus Header ──────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'لوحة: ${group.plateNumber}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      group.busName,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    CustomSvgIcon(
                      assetName: AppIcons.bus,
                      height: 18.h,
                      width: 18.w,
                      color: AppColors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Trips List for this Bus ─────────────────────────────────────
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: group.trips.length,
            separatorBuilder: (_, __) => Divider(
              color: AppColors.backgroundGray,
              height: 1,
              thickness: 1,
            ),
            itemBuilder: (context, idx) {
              final trip = group.trips[idx];
              final tripNet = trip.revenue - trip.expenses;

              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 10.h,
                ),
                child: Column(
                  children: [
                    // Driver + Date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText(
                          title: formatDate(trip.createdAt),
                          fontSize: 12.sp,
                          fontColor: AppColors.darkGray,
                        ),

                        Row(
                          children: [
                            CustomText(
                              title: trip.driverName,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              fontColor: AppColors.black,
                            ),
                            SizedBox(width: 6.w),
                            Icon(
                              Icons.person_outline,
                              size: 16.sp,
                              color: AppColors.gray,
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Trip Details
                    if (trip.details.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Align(
                        alignment: Alignment.centerRight,
                        child: CustomText(
                          title: trip.details,
                          fontSize: 12.sp,
                          fontColor: AppColors.gray,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],

                    SizedBox(height: 8.h),

                    // Financial Information
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        children: [
                          // الإيراد - ناحية اليمين
                          Expanded(
                            child: _TripFinancialItem(
                              label: ':الإيراد',
                              value: fmt(trip.revenue),
                              valueColor: AppColors.black,
                            ),
                          ),

                          // المصروف - في المنتصف
                          Expanded(
                            child: _TripFinancialItem(
                              label: 'المصروف',
                              value: fmt(trip.expenses),
                              valueColor: AppColors.red,
                            ),
                          ),

                          SizedBox(width: 8.w),

                          // الصافي - ناحية الشمال
                          Expanded(
                            child: _TripFinancialItem(
                              label: ':الصافي',
                              value: fmt(tripNet),
                              valueColor: tripNet >= 0
                                  ? AppColors.green
                                  : AppColors.red,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Driver Wage if entered
                    if (trip.driverWage != null && trip.driverWage! > 0) ...[
                      SizedBox(height: 6.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(color: const Color(0xFFFDE68A), width: 0.8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${fmt(trip.driverWage!)} ج.م',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFB45309),
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  'أجر السائق (مستحق)',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF92400E),
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Icon(
                                  Icons.badge_outlined,
                                  size: 13.sp,
                                  color: const Color(0xFFD97706),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),

          // ── Bus Subtotals Bar ───────────────────────────────────────────
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 10.h,
            ),
            decoration: BoxDecoration(
              color: AppColors.backgroundGray,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16.r),
                bottomRight: Radius.circular(16.r),
              ),
              border: Border(
                top: BorderSide(
                  color: AppColors.borderGray,
                  width: 0.8,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    // صافي الأتوبيس
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'صافي الأتوبيس',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkGray,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '${fmt(group.busNet)} ج.م',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: group.busNet >= 0
                                  ? AppColors.green
                                  : AppColors.red,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: 8.w),

                    // المصروف
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'المصروف',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppColors.darkGray,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '${fmt(group.busExpenses)} ج.م',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.red,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: 8.w),

                    // الإيراد
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'الإيراد',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppColors.darkGray,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '${fmt(group.busRevenue)} ج.م',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (group.busDriverWages > 0) ...[
                  SizedBox(height: 6.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${fmt(group.busDriverWages)} ج.م',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFB45309),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'أجور السائقين للأتوبيس:',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          )
        ],
      ),
    );
  }
}
class _TripFinancialItem extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _TripFinancialItem({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // الفلوس - على الشمال
        Flexible(
          child: CustomText(
            title: value,
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
            fontColor: valueColor,
            textAlign: TextAlign.left,
            maxLines: 1,
          ),
        ),

        SizedBox(width: 4.w),

        // الكلمة - على اليمين
        Flexible(
          child: CustomText(
            title: label,
            fontSize: 12.sp,
            fontColor: AppColors.darkGray,
            textAlign: TextAlign.right,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
