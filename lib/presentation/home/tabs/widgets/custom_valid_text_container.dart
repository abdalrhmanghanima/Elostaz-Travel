import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:flutter/material.dart';
class CustomValidTextContainer extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color fontColor;

  const CustomValidTextContainer({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.fontColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 8.h,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: CustomText(
        title: text,
        fontColor: fontColor,
        maxLines: 1,
      ),
    );
  }
}