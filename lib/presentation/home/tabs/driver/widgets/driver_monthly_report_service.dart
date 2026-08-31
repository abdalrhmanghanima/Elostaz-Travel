import 'package:elostaz_travel/domain/driver/entity/driver_advance_entity.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_entity.dart';
import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class DriverMonthlyReportService {
  static Future<void> shareCurrentMonthReport({
    required DriverEntity driver,
    required List<TripEntity> trips,
    List<DriverAdvanceEntity> advances = const [],
    String? periodLabel,
    String? typeFilterLabel,
  }) async {
    final now = DateTime.now();

    // Apply the selected operation type filter.
    List<TripEntity> filteredTrips = trips;

    if (typeFilterLabel != null && typeFilterLabel.isNotEmpty) {
      if (typeFilterLabel == 'الرحلات') {
        filteredTrips = trips.where((trip) => trip.isTrip).toList();
      } else if (typeFilterLabel == 'السهرات') {
        filteredTrips = trips.where((trip) => trip.isNightOuting).toList();
      }
    }

    // If a period is explicitly supplied, use the supplied trips as-is.
    // Otherwise keep the existing backward-compatible current-month behavior.
    final reportTrips = periodLabel != null
        ? [...filteredTrips]
        : filteredTrips.where((trip) {
            final date = trip.effectiveDate;
            return date.year == now.year && date.month == now.month;
          }).toList()
      ..sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));

    // The driver's total wage is calculated ONLY from the wages assigned
    // to the individual trips in this report.
    final totalDriverWages = reportTrips.fold<double>(
      0,
      (sum, trip) => sum + (trip.driverWage ?? 0),
    );

    final totalRevenue = reportTrips.fold<double>(
      0,
      (sum, trip) => sum + trip.revenue,
    );

    final totalExpenses = reportTrips.fold<double>(
      0,
      (sum, trip) => sum + trip.expenses,
    );

    final totalNetRevenue = totalRevenue - totalExpenses;

    final tripCount = reportTrips.length;

    // Fonts
    final regularFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Cairo-Regular.ttf'),
    );

    final boldFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Cairo-Bold.ttf'),
    );

    final pdf = pw.Document();

    final theme = pw.ThemeData.withFont(
      base: regularFont,
      bold: boldFont,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        footer: (context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 8),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'صفحة ${context.pageNumber} من ${context.pagesCount}',
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  'تقرير رحلات السائق',
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          );
        },
        build: (context) {
          final widgets = <pw.Widget>[];

          // Simple header.
          widgets.add(
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'تقرير رحلات السائق',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 17,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'الفترة: ${_resolvePeriodLabel(periodLabel, now)}',
                      style: pw.TextStyle(
                        font: regularFont,
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      driver.name,
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 15,
                      ),
                    ),
                    if (driver.phone.isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'هاتف: ${driver.phone}',
                        style: pw.TextStyle(
                          font: regularFont,
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );

          widgets.add(pw.SizedBox(height: 12));

          // Compact financial summary: all essential figures in one row.
          widgets.add(
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 7,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: _smallSummary(
                      title: 'الرحلات',
                      value: '$tripCount',
                      regularFont: regularFont,
                      boldFont: boldFont,
                    ),
                  ),
                  pw.Expanded(
                    child: _smallSummary(
                      title: 'الإيراد',
                      value: '${totalRevenue.toStringAsFixed(0)} ج.م',
                      regularFont: regularFont,
                      boldFont: boldFont,
                    ),
                  ),
                  pw.Expanded(
                    child: _smallSummary(
                      title: 'المصروف',
                      value: '${totalExpenses.toStringAsFixed(0)} ج.م',
                      regularFont: regularFont,
                      boldFont: boldFont,
                    ),
                  ),
                  pw.Expanded(
                    child: _smallSummary(
                      title: 'صافي الإيراد',
                      value: '${totalNetRevenue.toStringAsFixed(0)} ج.م',
                      regularFont: regularFont,
                      boldFont: boldFont,
                    ),
                  ),
                  pw.Expanded(
                    child: _smallSummary(
                      title: 'أجر السائق',
                      value: '${totalDriverWages.toStringAsFixed(0)} ج.م',
                      regularFont: regularFont,
                      boldFont: boldFont,
                    ),
                  ),
                ],
              ),
            ),
          );

          widgets.add(pw.SizedBox(height: 14));

          widgets.add(
            _sectionTitle('تفاصيل الرحلات والمصروفات', boldFont),
          );

          if (reportTrips.isEmpty) {
            widgets.add(
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(18),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'لا توجد رحلات أو سهرات مسجلة لهذا السائق${periodLabel != null ? " خلال $periodLabel" : " خلال هذا الشهر"}',
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            );
          } else {
            widgets.add(
              pw.TableHelper.fromTextArray(
                headers: [
                  'النوع',
                  'التاريخ',
                  'الأتوبيس',
                  'تفاصيل الرحلة',
                  'الإيراد',
                  'المصروف',
                  'صافي الإيراد',
                  'أجر السائق',
                  'تفاصيل المصروف',
                ],
                data: reportTrips.map((trip) {
                  final dateStr = trip.effectiveDate.year > 1970
                      ? _formatDate(trip.effectiveDate)
                      : 'غير محدد';

                  final tripDetails = trip.details.trim().isNotEmpty
                      ? trip.details.trim()
                      : '-';

                  final expenseDetails =
                      trip.expenseDetails?.trim().isNotEmpty == true
                          ? trip.expenseDetails!.trim()
                          : '-';

                  final driverWage = trip.driverWage ?? 0;

                  return [
                    trip.typeLabel,
                    dateStr,
                    trip.busName.isNotEmpty ? trip.busName : '-',
                    tripDetails,
                    '${trip.revenue.toStringAsFixed(0)} ج.م',
                    '${trip.expenses.toStringAsFixed(0)} ج.م',
                    '${(trip.revenue - trip.expenses).toStringAsFixed(0)} ج.م',
                    '${driverWage.toStringAsFixed(0)} ج.م',
                    expenseDetails,
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                  font: boldFont,
                  fontSize: 7.5,
                ),
                cellStyle: pw.TextStyle(
                  font: regularFont,
                  fontSize: 7,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey200,
                ),
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
                cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 3,
                  vertical: 4,
                ),
                cellAlignment: pw.Alignment.center,
                headerAlignment: pw.Alignment.center,
                columnWidths: {
                  0: const pw.FixedColumnWidth(34),
                  1: const pw.FixedColumnWidth(44),
                  2: const pw.FixedColumnWidth(48),
                  3: pw.FlexColumnWidth(1.7),
                  4: const pw.FixedColumnWidth(44),
                  5: const pw.FixedColumnWidth(44),
                  6: const pw.FixedColumnWidth(44),
                  7: const pw.FixedColumnWidth(44),
                  8: pw.FlexColumnWidth(1.4),
                },
              ),
            );
          }

          return widgets;
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'تقرير_${driver.name}_${now.year}_${now.month}.pdf',
    );
  }

  static pw.Widget _sectionTitle(
    String title,
    pw.Font boldFont,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          font: boldFont,
          fontSize: 11,
          color: PdfColors.grey800,
        ),
      ),
    );
  }

  static pw.Widget _smallSummary({
    required String title,
    required String value,
    required pw.Font regularFont,
    required pw.Font boldFont,
  }) {
    return pw.Column(
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            font: regularFont,
            fontSize: 7.5,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  static String _resolvePeriodLabel(
    String? periodLabel,
    DateTime now,
  ) {
    if (periodLabel == 'الشهر الحالي') {
      return 'شهر ${_monthName(now.month)} ${now.year}';
    }

    if (periodLabel == 'الشهر السابق') {
      final previousMonth = DateTime(now.year, now.month - 1);
      return 'شهر ${_monthName(previousMonth.month)} '
          '${previousMonth.year}';
    }

    if (periodLabel == null || periodLabel.trim().isEmpty) {
      return 'شهر ${_monthName(now.month)} ${now.year}';
    }

    return periodLabel;
  }

  static String _monthName(int month) {
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

    return months[month - 1];
  }
}
