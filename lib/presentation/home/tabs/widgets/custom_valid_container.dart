import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/presentation/components/custom_svg/custom_svg_icon.dart';
import 'package:flutter/material.dart';

class CustomValidContainer extends StatelessWidget {
  final String icon;
  final Color iconBackgroundColor;

  const CustomValidContainer({
    super.key,
    required this.icon,
    required this.iconBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        color: iconBackgroundColor,
        borderRadius: BorderRadius.circular(24.r),
      ),
      alignment: Alignment.center,
      child: CustomSvgIcon(assetName: icon,),
    );
  }
}
