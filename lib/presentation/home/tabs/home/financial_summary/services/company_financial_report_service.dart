import 'package:elostaz_travel/presentation/home/tabs/home/financial_summary/provider/company_financial_summary_provider.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CompanyFinancialReportService {
  static Future<void> shareCompanyReport({
    required CompanyFinancialSummary summary,
    String? periodTitle,
  }) async {
    final now = DateTime.now();

    final displayPeriod =
        periodTitle ?? summary.periodLabel;

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
    // Essential statistics only
    // ============================================================

    final tripsCount =
        summary.allTrips.where((t) => t.isTrip).length;

    final nightOutingsCount =
        summary.allTrips.where((t) => t.isNightOuting).length;

    // ============================================================
    // PDF
    // ============================================================

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        textDirection: pw.TextDirection.rtl,

        // Small margins = more content per page.
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
                  'الملخص المالي للشركة',
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
                      'الملخص المالي للشركة',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 16,
                        color: PdfColors.blue900,
                      ),
                    ),

                    pw.SizedBox(height: 2),

                    pw.Text(
                      'الفترة: ${_resolvePeriodLabel(
                        displayPeriod,
                        summary,
                        now,
                      )}',
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
                      'شركة الأستاذ للنقل السياحي',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 13,
                        color: PdfColors.blue900,
                      ),
                    ),

                    pw.SizedBox(height: 2),

                    pw.Text(
                      'تاريخ التقرير: ${_formatDate(now)}',
                      style: pw.TextStyle(
                        font: regularFont,
                        fontSize: 8,
                        color: PdfColors.grey600,
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
          // ONE Compact Financial Summary
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
                      value:
                      '${summary.totalTrips}',
                      regularFont: regularFont,
                      boldFont: boldFont,
                    ),
                  ),

                  pw.Expanded(
                    child: _smallSummary(
                      title: 'الرحلات / السهرات',
                      value:
                      '$tripsCount / $nightOutingsCount',
                      regularFont: regularFont,
                      boldFont: boldFont,
                    ),
                  ),

                  pw.Expanded(
                    child: _smallSummary(
                      title: 'الإيراد',
                      value:
                      '${_formatCurrency(summary.totalRevenue)} ج.م',
                      regularFont: regularFont,
                      boldFont: boldFont,
                    ),
                  ),

                  pw.Expanded(
                    child: _smallSummary(
                      title: 'المصروف',
                      value:
                      '${_formatCurrency(summary.totalExpenses)} ج.م',
                      regularFont: regularFont,
                      boldFont: boldFont,
                    ),
                  ),

                  pw.Expanded(
                    child: _smallSummary(
                      title: 'صافي الأرباح',
                      value:
                      '${_formatCurrency(summary.totalNetRevenue)} ج.م',
                      regularFont: regularFont,
                      boldFont: boldFont,
                    ),
                  ),

                  pw.Expanded(
                    child: _smallSummary(
                      title: 'أجور السائقين',
                      value:
                      '${_formatCurrency(summary.totalDriverWages)} ج.م',
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
          // ONE Operations Table
          // ========================================================

          if (summary.allTrips.isEmpty) {
            widgets.add(
              pw.Container(
                width: double.infinity,
                padding:
                const pw.EdgeInsets.all(18),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius:
                  pw.BorderRadius.circular(5),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'لا توجد رحلات أو سهرات مسجلة في هذه الفترة',
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            );
          } else {
            final trips = [...summary.allTrips]
              ..sort(
                    (a, b) => b.effectiveDate
                    .compareTo(a.effectiveDate),
              );

            widgets.add(
              pw.TableHelper.fromTextArray(
                headers: [
                  'النوع',
                  'التاريخ',
                  'الأتوبيس',
                  'السائق',
                  'الجهة',
                  'تفاصيل الرحلة والمصروف',
                  'الإيراد',
                  'المصروف',
                  'الصافي',
                  'أجر السائق',
                ],

                data: trips.map((trip) {
                  final net =
                      trip.revenue - trip.expenses;

                  final dateStr =
                  trip.effectiveDate.year > 1970
                      ? _formatDate(
                    trip.effectiveDate,
                  )
                      : 'غير محدد';

                  final factoryLabel =
                  trip.factoryName != null &&
                      trip.factoryName!
                          .trim()
                          .isNotEmpty
                      ? trip.factoryName!.trim()
                      : '-';

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
                      ? '${_formatCurrency(
                    trip.driverWage!,
                  )} ج.م'
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

                    factoryLabel,

                    details,

                    '${_formatCurrency(
                      trip.revenue,
                    )} ج.م',

                    '${_formatCurrency(
                      trip.expenses,
                    )} ج.م',

                    '${_formatCurrency(
                      net,
                    )} ج.م',

                    driverWage,
                  ];
                }).toList(),

                headerStyle: pw.TextStyle(
                  font: boldFont,
                  fontSize: 6.5,
                ),

                cellStyle: pw.TextStyle(
                  font: regularFont,
                  fontSize: 6.2,
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

                // Keep the table as compact as possible.
                columnWidths: {
                  0: const pw.FixedColumnWidth(30),
                  1: const pw.FixedColumnWidth(42),
                  2: const pw.FixedColumnWidth(43),
                  3: const pw.FixedColumnWidth(43),
                  4: const pw.FixedColumnWidth(43),

                  // Main details column.
                  5: const pw.FlexColumnWidth(2.4),

                  6: const pw.FixedColumnWidth(42),
                  7: const pw.FixedColumnWidth(42),
                  8: const pw.FixedColumnWidth(42),
                  9: const pw.FixedColumnWidth(42),
                },
              ),
            );
          }

          // No bus subtotals.
          // No duplicated company grand total.
          // The compact summary at the top contains
          // all required financial totals.

          return widgets;
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename:
      'تقرير_الملخص_المالي_${summary.period.name}_${now.year}_${now.month}_${now.day}.pdf',
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
            fontSize: 6.2,
            color: PdfColors.grey600,
          ),
        ),

        pw.SizedBox(height: 1.5),

        pw.Text(
          value,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 8,
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
      CompanyFinancialSummary summary,
      DateTime now,
      ) {
    if (periodLabel == 'الشهر الحالي') {
      return 'شهر ${_monthName(now.month)} ${now.year}';
    }

    if (periodLabel == 'الشهر السابق') {
      final previousMonth =
      DateTime(now.year, now.month - 1);

      return 'شهر ${_monthName(
        previousMonth.month,
      )} ${previousMonth.year}';
    }

    if (periodLabel == null ||
        periodLabel.trim().isEmpty) {
      return summary.periodLabel.isNotEmpty
          ? summary.periodLabel
          : 'شهر ${_monthName(now.month)} ${now.year}';
    }

    // Custom month labels already contain
    // the concrete month/year.
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

  // ==============================================================
  // Currency
  // ==============================================================

  static String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
    );
  }
}