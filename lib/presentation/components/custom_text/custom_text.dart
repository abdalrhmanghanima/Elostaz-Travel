import 'package:elostaz_travel/core/utils/text_styles.dart';
import 'package:flutter/material.dart';
class CustomText extends StatelessWidget {
  final String? title;
  final Color fontColor;
  final double fontSize;
  final FontWeight fontWeight;
  final int? maxLines;
  final TextAlign? textAlign;
  final TextDecoration decoration;

  const CustomText({
    super.key,
    required this.title,
    this.fontColor = Colors.black,
    this.fontSize = 14,
    this.fontWeight = FontWeight.normal,
    this.maxLines,
    this.textAlign,
    this.decoration = TextDecoration.none,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title ?? '',
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      textAlign: textAlign,
      style: AppTextStyles()
          .normalText(
        fontSize: fontSize,
        decoration: decoration,
      )
          .copyWith(
        color: fontColor,
        fontWeight: fontWeight,
      ),
    );
  }
}