import 'package:elostaz_travel/domain/factory/entity/factory_entity.dart';
import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class FactoryMonthlyReportService {
  static Future<void> shareFactoryReport({
    required FactoryEntity factory,
    required List<TripEntity> trips,
    String? periodLabel,
    String? typeFilterLabel,
  }) async {
    final now = DateTime.now();

    // ============================================================
    // Apply type filter
    // ============================================================

    List<TripEntity> filteredTrips = trips;

    if (typeFilterLabel != null && typeFilterLabel.isNotEmpty) {
      if (typeFilterLabel == 'الرحلات') {
        filteredTrips = trips.where((t) => t.isTrip).toList();
      } else if (typeFilterLabel == 'السهرات') {
        filteredTrips = trips.where((t) => t.isNightOuting).toList();
      }
    }

    // ============================================================
    // Sort trips
    // ============================================================

    final sortedTrips = List<TripEntity>.from(filteredTrips)
      ..sort(
            (a, b) => b.effectiveDate.compareTo(a.effectiveDate),
      );

    // ============================================================
    // Essential financial totals
    // ============================================================

    final tripsCount =
        sortedTrips.where((t) => t.isTrip).length;

    final nightOutingsCount =
        sortedTrips.where((t) => t.isNightOuting).length;

    final totalRevenue = sortedTrips.fold<double>(
      0,
          (sum, trip) => sum + trip.revenue,
    );

    final totalExpenses = sortedTrips.fold<double>(
      0,
          (sum, trip) => sum + trip.expenses,
    );

    // Driver wages are calculated from the individual trips.
    // They do NOT reduce the trip net revenue.
    final totalDriverWages = sortedTrips.fold<double>(
      0,
          (sum, trip) => sum + (trip.driverWage ?? 0),
    );

    final totalNetRevenue =
        totalRevenue - totalExpenses;

    // ============================================================
    // Fonts
    // ============================================================

    final regularFont = pw.Font.ttf(
      await rootBundle.load(
        'assets/fonts/Cairo-Regular.ttf',
      ),
    );

    final boldFont = pw.Font.ttf(
      await rootBundle.load(
        'assets/fonts/Cairo-Bold.ttf',
      ),
    );

    final pdf = pw.Document();

    final theme = pw.ThemeData.withFont(
      base: regularFont,
      bold: boldFont,
    );

    // ============================================================
    // PDF
    // ============================================================

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        textDirection: pw.TextDirection.rtl,

        // Small margins to maximize available table space.
        margin: const pw.EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),

        footer: (context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 4),
            child: pw.Row(
              mainAxisAlignment:
              pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'صفحة ${context.pageNumber} من ${context.pagesCount}',
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 7,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  'تقرير المصنع',
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 7,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          );
        },

        build: (context) {
          final widgets = <pw.Widget>[];

          // ========================================================
          // Header
          // ========================================================

          widgets.add(
            pw.Row(
              mainAxisAlignment:
              pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment:
              pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment:
                  pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'تقرير عمليات المصنع',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 16,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'الفترة: ${_resolvePeriodLabel(periodLabel, now)}',
                      style: pw.TextStyle(
                        font: regularFont,
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),

                pw.Column(
                  crossAxisAlignment:
                  pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      factory.name,
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 14,
                      ),
                    ),
                    if (factory.phone.trim().isNotEmpty)
                      pw.Text(
                        'هاتف: ${factory.phone}',
                        style: pw.TextStyle(
                          font: regularFont,
                          fontSize: 8,
                          color: PdfColors.grey700,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );

          widgets.add(
            pw.SizedBox(height: 8),
          );

          // ========================================================
          // Compact Financial Summary
          // One summary only — no duplicated totals later.
          // ========================================================

          widgets.add(
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 6,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius:
                pw.BorderRadius.circular(5),
                border: pw.Border.all(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: _smallSummary(
                      title: 'العمليات',
                      value: '${sortedTrips.length}',
                      regularFont: regularFont,
                      boldFont: boldFont,
                    ),
                  ),

                  pw.Expanded(
                    child: _smallSummary(
                      title: 'الإيراد',
                      value:
                      '${totalRevenue.toStringAsFixed(0)} ج.م',
                      regularFont: regularFont,
                      boldFont: boldFont,
                    ),
                  ),

                  pw.Expanded(
                    child: _smallSummary(
                      title: 'المصروف',
                      value:
                      '${totalExpenses.toStringAsFixed(0)} ج.م',
                      regularFont: regularFont,
                      boldFont: boldFont,
                    ),
                  ),

                  pw.Expanded(
                    child: _smallSummary(
                      title: 'صافي الإيراد',
                      value:
                      '${totalNetRevenue.toStringAsFixed(0)} ج.م',
                      regularFont: regularFont,
                      boldFont: boldFont,
                    ),
                  ),

                  pw.Expanded(
                    child: _smallSummary(
                      title: 'أجر السائقين',
                      value:
                      '${totalDriverWages.toStringAsFixed(0)} ج.م',
                      regularFont: regularFont,
                      boldFont: boldFont,
                    ),
                  ),
                ],
              ),
            ),
          );

          widgets.add(
            pw.SizedBox(height: 8),
          );

          // ========================================================
          // Single Trips Table
          // ========================================================

          if (sortedTrips.isEmpty) {
            widgets.add(
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(18),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius:
                  pw.BorderRadius.circular(5),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'لا توجد رحلات أو سهرات مسجلة لهذا المصنع'
                        '${periodLabel != null ? " خلال $periodLabel" : ""}',
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 10,
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
                  'السائق',
                  'تفاصيل الرحلة والمصروف',
                  'الإيراد',
                  'المصروف',
                  'الصافي',
                  'أجر السائق',
                ],

                data: sortedTrips.map((trip) {
                  final net =
                      trip.revenue - trip.expenses;

                  final dateStr =
                  trip.effectiveDate.year > 1970
                      ? _formatDate(
                    trip.effectiveDate,
                  )
                      : 'غير محدد';

                  // Combine trip details and expense
                  // details into one compact cell.
                  String details =
                  trip.details.trim();

                  final expenseDetails =
                      trip.expenseDetails
                          ?.trim() ??
                          '';

                  if (expenseDetails.isNotEmpty) {
                    if (details.isNotEmpty) {
                      details +=
                      '\nمصروف: $expenseDetails';
                    } else {
                      details =
                      'مصروف: $expenseDetails';
                    }
                  }

                  if (details.isEmpty) {
                    details = '-';
                  }

                  final driverWage =
                  trip.driverWage != null &&
                      trip.driverWage! > 0
                      ? '${trip.driverWage!.toStringAsFixed(0)} ج.م'
                      : '-';

                  return [
                    trip.typeLabel,

                    dateStr,

                    trip.busName.isNotEmpty
                        ? trip.busName
                        : '-',

                    trip.driverName.isNotEmpty
                        ? trip.driverName
                        : '-',

                    details,

                    '${trip.revenue.toStringAsFixed(0)} ج.م',

                    '${trip.expenses.toStringAsFixed(0)} ج.م',

                    '${net.toStringAsFixed(0)} ج.م',

                    driverWage,
                  ];
                }).toList(),

                headerStyle: pw.TextStyle(
                  font: boldFont,
                  fontSize: 6.8,
                ),

                cellStyle: pw.TextStyle(
                  font: regularFont,
                  fontSize: 6.5,
                ),

                headerDecoration:
                const pw.BoxDecoration(
                  color: PdfColors.grey200,
                ),

                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.4,
                ),

                cellPadding:
                const pw.EdgeInsets.symmetric(
                  horizontal: 2,
                  vertical: 2.5,
                ),

                cellAlignment:
                pw.Alignment.center,

                headerAlignment:
                pw.Alignment.center,

                // Keep the table compact.
                columnWidths: {
                  0: const pw.FixedColumnWidth(32),
                  1: const pw.FixedColumnWidth(43),
                  2: const pw.FixedColumnWidth(45),
                  3: const pw.FixedColumnWidth(45),

                  // Details get the largest space.
                  4: const pw.FlexColumnWidth(2.4),

                  5: const pw.FixedColumnWidth(42),
                  6: const pw.FixedColumnWidth(42),
                  7: const pw.FixedColumnWidth(42),
                  8: const pw.FixedColumnWidth(42),
                },
              ),
            );
          }

          // No duplicated footer totals.
          // All financial totals are already displayed above.

          return widgets;
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename:
      'تقرير_مصنع_${factory.name}_${now.year}_${now.month}.pdf',
    );
  }

  // ==============================================================
  // Compact Summary Item
  // ==============================================================

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
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            font: regularFont,
            fontSize: 6.5,
            color: PdfColors.grey600,
          ),
        ),

        pw.SizedBox(height: 1.5),

        pw.Text(
          value,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 8.5,
          ),
        ),
      ],
    );
  }

  // ==============================================================
  // Period
  // ==============================================================

  static String _resolvePeriodLabel(
      String? periodLabel,
      DateTime now,
      ) {
    if (periodLabel == 'الشهر الحالي') {
      return 'شهر ${_monthName(now.month)} ${now.year}';
    }

    if (periodLabel == 'الشهر السابق') {
      final previousMonth = DateTime(
        now.year,
        now.month - 1,
      );

      return 'شهر ${_monthName(previousMonth.month)} '
          '${previousMonth.year}';
    }

    if (periodLabel == null ||
        periodLabel.trim().isEmpty) {
      return 'شهر ${_monthName(now.month)} ${now.year}';
    }

    return periodLabel;
  }

  // ==============================================================
  // Arabic Month
  // ==============================================================

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

  // ==============================================================
  // Date
  // ==============================================================

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}