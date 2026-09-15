import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:flutter/material.dart';

class TripFinancialItem extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const TripFinancialItem({
    super.key,
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
