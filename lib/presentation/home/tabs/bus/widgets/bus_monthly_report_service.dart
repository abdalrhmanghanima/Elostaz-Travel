import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class BusMonthlyReportService {
  static Future<void> shareCurrentMonthReport({
    required BusEntity bus,
    required List<TripEntity> trips,
  }) async {
    final now = DateTime.now();

    final monthlyTrips = trips.where((trip) {
      return trip.createdAt.year == now.year &&
          trip.createdAt.month == now.month;
    }).toList();

    final totalRevenue = monthlyTrips.fold<double>(
      0,
          (sum, trip) => sum + trip.revenue,
    );

    final totalExpenses = monthlyTrips.fold<double>(
      0,
          (sum, trip) => sum + trip.expenses,
    );

    final totalNetRevenue =
        totalRevenue - totalExpenses;

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

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20,
        ),
        footer: (context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 8),
            child: pw.Row(
              mainAxisAlignment:
              pw.MainAxisAlignment.spaceBetween,
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
                  'تقرير رحلات الأتوبيس',
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
          return [
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
                      'تقرير رحلات الأتوبيس',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 20,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'شهر ${_monthName(now.month)} ${now.year}',
                      style: pw.TextStyle(
                        font: regularFont,
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment:
                  pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      bus.busName,
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 15,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'رقم اللوحة: ${bus.plateNumber}',
                      style: pw.TextStyle(
                        font: regularFont,
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 14),

            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 9,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius:
                pw.BorderRadius.circular(7),
                border: pw.Border.all(
                  color: PdfColors.grey300,
                ),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: _smallSummary(
                      title: 'الرحلات',
                      value:
                      '${monthlyTrips.length}',
                      regularFont: regularFont,
                      boldFont: boldFont,
                    ),
                  ),
                  pw.Expanded(
                    child: _smallSummary(
                      title: 'الإيرادات',
                      value:
                      '${totalRevenue.toStringAsFixed(0)} ج.م',
                      regularFont: regularFont,
                      boldFont: boldFont,
                    ),
                  ),
                  pw.Expanded(
                    child: _smallSummary(
                      title: 'المصروفات',
                      value:
                      '${totalExpenses.toStringAsFixed(0)} ج.م',
                      regularFont: regularFont,
                      boldFont: boldFont,
                    ),
                  ),
                  pw.Expanded(
                    child: _smallSummary(
                      title: 'الصافي',
                      value:
                      '${totalNetRevenue.toStringAsFixed(0)} ج.م',
                      regularFont: regularFont,
                      boldFont: boldFont,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 14),

            if (monthlyTrips.isEmpty)
              pw.Container(
                width: double.infinity,
                padding:
                const pw.EdgeInsets.all(25),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius:
                  pw.BorderRadius.circular(7),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'لا توجد رحلات لهذا الأتوبيس خلال هذا الشهر',
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 12,
                    ),
                  ),
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                headers: [
                  'التاريخ',
                  'السائق',
                  'التفاصيل',
                  'الإيراد',
                  'المصروفات',
                  'الصافي',
                ],
                data: monthlyTrips.map((trip) {
                  final net =
                      trip.revenue - trip.expenses;

                  return [
                    _formatDate(trip.createdAt),
                    trip.driverName,
                    trip.details.isEmpty
                        ? '-'
                        : trip.details,
                    '${trip.revenue.toStringAsFixed(0)}\nج.م',
                    '${trip.expenses.toStringAsFixed(0)}\nج.م',
                    '${net.toStringAsFixed(0)}\nج.م',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                  font: boldFont,
                  fontSize: 8,
                ),
                cellStyle: pw.TextStyle(
                  font: regularFont,
                  fontSize: 7.5,
                ),
                headerDecoration:
                const pw.BoxDecoration(
                  color: PdfColors.grey200,
                ),
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
                cellPadding:
                const pw.EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 5,
                ),
                cellAlignment:
                pw.Alignment.center,
                headerAlignment:
                pw.Alignment.center,
                columnWidths: {
                  0: const pw.FixedColumnWidth(55),
                  1: const pw.FixedColumnWidth(80),
                  2: const pw.FlexColumnWidth(2.2),
                  3: const pw.FixedColumnWidth(58),
                  4: const pw.FixedColumnWidth(58),
                  5: const pw.FixedColumnWidth(58),
                },
              ),

            pw.SizedBox(height: 12),

            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 9,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius:
                pw.BorderRadius.circular(7),
                border: pw.Border.all(
                  color: PdfColors.grey300,
                ),
              ),
              child: pw.Row(
                mainAxisAlignment:
                pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'الإيرادات: '
                        '${totalRevenue.toStringAsFixed(0)} ج.م',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 9,
                    ),
                  ),
                  pw.Text(
                    'المصروفات: '
                        '${totalExpenses.toStringAsFixed(0)} ج.م',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 9,
                    ),
                  ),
                  pw.Text(
                    'الصافي: '
                        '${totalNetRevenue.toStringAsFixed(0)} ج.م',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename:
      'تقرير_${bus.busName}_${now.year}_${now.month}.pdf',
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
            fontSize: 8,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 3),
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
    return '${date.day}-${date.month}-${date.year}';
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