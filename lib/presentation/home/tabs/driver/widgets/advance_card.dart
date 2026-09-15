import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_advance_entity.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/provider/driver_advance_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdvanceCard extends ConsumerWidget {
  final DriverAdvanceEntity advance;
  final String driverId;

  const AdvanceCard({super.key, required this.advance, required this.driverId});

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFE7E8EC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Mark as paid button
              TextButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text(
                        'تأكيد السداد',
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                      ),
                      content: Text(
                        'هل تم سداد هذه السلفة (${advance.amount.toStringAsFixed(0)} ج.م)؟',
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('إلغاء'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.green,
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            'تم السداد',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await ref
                        .read(driverAdvanceNotifierProvider.notifier)
                        .markAdvancePaid(
                      driverId: driverId,
                      advanceId: advance.id,
                    );
                  }
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  backgroundColor: AppColors.lightGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: CustomText(
                  title: 'تم السداد ✓',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  fontColor: AppColors.green,
                ),
              ),

              // Amount
              CustomText(
                title: '${advance.amount.toStringAsFixed(0)} ج.م',
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                fontColor: AppColors.primary,
              ),
            ],
          ),

          SizedBox(height: 6.h),

          // Date
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomText(
                title: _formatDate(advance.date),
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                fontColor: const Color(0xFF666A73),
              ),
              SizedBox(width: 4.w),
              Icon(
                Icons.calendar_today_outlined,
                size: 13.sp,
                color: const Color(0xFF666A73),
              ),
            ],
          ),

          if (advance.note.isNotEmpty) ...[
            SizedBox(height: 6.h),
            CustomText(
              title: advance.note,
              fontSize: 13.sp,
              fontColor: const Color(0xFF777B85),
              textAlign: TextAlign.right,
            ),
          ],
        ],
      ),
    );
  }
}
