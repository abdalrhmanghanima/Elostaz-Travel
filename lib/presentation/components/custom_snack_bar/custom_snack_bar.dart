import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:flutter/material.dart';
class CustomSnackBar {
  static void show(
      BuildContext context, {
        required String message,
      }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          elevation: 0,
          margin: EdgeInsetsDirectional.only(
            start: 24.w,
            end: 24.w,
            bottom: 20.h,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 12.h,
          ),
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