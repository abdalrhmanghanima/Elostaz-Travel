import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppDateFormatter {
  static String format(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  static String formatArabicReadable(DateTime date) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class AppDatePicker {
  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    String helpText = 'اختر التاريخ',
    String cancelText = 'إلغاء',
    String confirmText = 'اختيار',
  }) async {
    // We use showDialog + DatePickerDialog directly instead of showDatePicker.
    //
    // Reason: showDatePicker pushes the dialog as a separate Navigator route.
    // MaterialApp in this project has no localizationsDelegates, so
    // MaterialLocalizations is never available in the route's context tree.
    // The builder parameter of showDatePicker only wraps the child widget
    // visually; it does NOT inject localizations into the route's own context
    // because the route is resolved before builder runs.
    //
    // By using showDialog we fully own the dialog widget tree, and we can
    // wrap DatePickerDialog inside a Localizations widget that provides all
    // required delegates. This scope is strictly local to the dialog — the
    // rest of the application is unaffected.
    return showDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Localizations(
          locale: const Locale('ar', 'EG'),
          delegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: AppColors.primary,
                ),
                dialogTheme: const DialogThemeData(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(16),
                    ),
                  ),
                ),
              ),
              child: DatePickerDialog(
                initialDate: initialDate,
                firstDate: firstDate,
                lastDate: lastDate,
                helpText: helpText,
                cancelText: cancelText,
                confirmText: confirmText,
                initialCalendarMode: DatePickerMode.day,
              ),
            ),
          ),
        );
      },
    );
  }
}