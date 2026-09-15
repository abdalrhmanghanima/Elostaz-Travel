import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return CustomText(
      title: title,
      fontSize: 19.sp,
      fontWeight: FontWeight.w700,
      fontColor: AppColors.primary,
      textAlign: TextAlign.right,
    );
  }
}
