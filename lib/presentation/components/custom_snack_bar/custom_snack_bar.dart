import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:flutter/material.dart';

class CustomSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    bool success = false,
    double? aboveBottomSheetHeight,
  }) {
    var bottomMargin = 20.h;
    if (aboveBottomSheetHeight != null && aboveBottomSheetHeight > 0) {
      final aboveSheet = aboveBottomSheetHeight + 12;
      if (aboveSheet < MediaQuery.of(context).size.height) {
        bottomMargin = aboveSheet;
      }
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: success ? AppColors.green : Colors.red,
          elevation: 0,
          margin: EdgeInsetsDirectional.only(
            start: 24.w,
            end: 24.w,
            bottom: bottomMargin,
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
  }
}
