import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_wage_balance.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:flutter/material.dart';

class WageSummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool emphasize;

  const WageSummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(
          title: '${value.toStringAsFixed(0)} ج.م',
          fontSize: emphasize ? 16.sp : 14.sp,
          fontWeight: FontWeight.w800,
          fontColor: const Color(0xFFB45309),
        ),
        CustomText(
          title: label,
          fontSize: 13.sp,
          fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
          fontColor: const Color(0xFF92400E),
        ),
      ],
    );
  }
}

class WageActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const WageActionButton({
    super.key,
    required this.title,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 15.sp),
            SizedBox(width: 4.w),
            Flexible(
              child: CustomText(
                title: title,
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                fontColor: Colors.white,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DriverWageSummary extends StatelessWidget {
  final DriverWageBalance balance;
  final VoidCallback onAddWage;
  final VoidCallback onPayWage;

  const DriverWageSummary({
    super.key,
    required this.balance,
    required this.onAddWage,
    required this.onPayWage,
  });

  @override
  Widget build(BuildContext context) {
    final canPay = balance.remaining > 0;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        children: [
          WageSummaryRow(
            label: 'إجمالي الأجر المستحق',
            value: balance.totalAccrued,
          ),
          SizedBox(height: 8.h),
          WageSummaryRow(
            label: 'تم تسديده',
            value: balance.totalPaid,
          ),
          SizedBox(height: 8.h),
          WageSummaryRow(
            label: 'المتبقي للسائق',
            value: balance.remaining,
            emphasize: true,
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: WageActionButton(
                  title: 'إضافة أجر',
                  icon: Icons.add,
                  enabled: true,
                  onTap: onAddWage,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: WageActionButton(
                  title: 'تسديد أجر السائق',
                  icon: Icons.payments_outlined,
                  enabled: canPay,
                  onTap: onPayWage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
