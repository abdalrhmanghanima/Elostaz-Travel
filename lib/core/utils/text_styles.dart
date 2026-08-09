import 'package:easy_localization/easy_localization.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:flutter/material.dart';

import '../../main.dart';

String get currentLang =>
    navigatorKey.currentContext?.locale.languageCode ?? 'ar';

class AppTextStyles {
  TextStyle normalText({
    double fontSize = 14,
    TextDecoration decoration = TextDecoration.none,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontFamily:
      'font_regular',
      decoration: decoration,
      decorationColor: AppColors.gray,
    );
  }
}

extension TextStyleExtension on TextStyle {
  TextStyle textColorNormal(Color color) => copyWith(
      color: color,
      fontFamily:
      'font_regular'
  );

  TextStyle textColorBold(Color color) => copyWith(
    color: color,
    fontFamily:
    'font_bold',
    fontWeight: FontWeight.bold,
  );

  TextStyle textColorNormalDecoration(
      Color color,
      Color decoration,
      ) =>
      copyWith(
        color: color,
        fontFamily:
        'font_regular' ,
        fontWeight: FontWeight.normal,
        decorationColor: decoration,
        decoration: TextDecoration.underline,
      );

  TextStyle textColorBoldDecoration(
      Color color,
      Color decoration,
      ) =>
      copyWith(
        color: color,
        fontFamily: 'font_bold' ,
        fontWeight: FontWeight.bold,
        decorationColor: decoration,
        decoration: TextDecoration.underline,
      );
}