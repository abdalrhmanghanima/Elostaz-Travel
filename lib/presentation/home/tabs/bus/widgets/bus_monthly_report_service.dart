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

    // Current month trips
    final monthlyTrips = trips.where((trip) {
      final date = trip.effectiveDate;
      return date.year == now.year && date.month == now.month;
    }).toList()
      ..sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));

    final tripsCount = monthlyTrips.where((t) => t.isTrip).length;
    final nightOutingsCount = monthlyTrips.where((t) => t.isNightOuting).length;

    // Financial totals (Unified)
    final totalRevenue = monthlyTrips.fold<double>(
      0,
      (sum, trip) => sum + trip.revenue,
    );

    final totalExpenses = monthlyTrips.fold<double>(
      0,
      (sum, trip) => sum + trip.expenses,
    );

    final totalNetRevenue = totalRevenue - totalExpenses;

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
        margin: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        footer: (context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 6),
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
                  'تقرير عمليات الأتوبيس — شركة الأستاذ للنقل السياحي',
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
          final List<pw.Widget> widgets = [];

          // Header
          widgets.add(
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'تقرير عمليات ورحلات الأتوبيس',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 17,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'شهر ${_monthName(now.month)} ${now.year}',
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
                      bus.busName,
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 15,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'رقم اللوحة: ${bus.plateNumber}',
                      style: pw.TextStyle(
                        font: regularFont,
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );

          widgets.add(pw.SizedBox(height: 10));

          // Summary KPIs
          widgets.add(
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: _smallSummary(
                      title: 'إجمالي العمليات',
                      value: '${monthlyTrips.length} ($tripsCount رحلة + $nightOutingsCount سهرة)',
                      regularFont: regularFont,
                      boldFont: boldFont,
                    ),
                  ),
                  pw.Expanded(
                    child: _smallSummary(
                      title: 'إجمالي الإيراد',
                      value: '${totalRevenue.toStringAsFixed(0)} ج.م',
                      regularFont: regularFont,
                      boldFont: boldFont,
                    ),
                  ),
                  pw.Expanded(
                    child: _smallSummary(
                      title: 'إجمالي المصروفات',
                      value: '${totalExpenses.toStringAsFixed(0)} ج.م',
                      regularFont: regularFont,
                      boldFont: boldFont,
                    ),
                  ),
                  pw.Expanded(
                    child: _smallSummary(
                      title: 'صافي الربح',
                      value: '${totalNetRevenue.toStringAsFixed(0)} ج.م',
                      regularFont: regularFont,
                      boldFont: boldFont,
                    ),
                  ),
                ],
              ),
            ),
          );

          widgets.add(pw.SizedBox(height: 10));

          // Operations Table
          if (monthlyTrips.isEmpty) {
            widgets.add(
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'لا توجد رحلات أو سهرات لهذا الأتوبيس خلال هذا الشهر',
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
                  'المصنع / الجهة',
                  'السائق',
                  'التفاصيل وملاحظات المصروف',
                  'الإيراد',
                  'المصروف',
                  'الصافي',
                ],
                data: monthlyTrips.map((trip) {
                  final net = trip.revenue - trip.expenses;
                  final factoryLabel = (trip.factoryName != null && trip.factoryName!.trim().isNotEmpty)
                      ? trip.factoryName!
                      : '-';

                  String details = trip.details.trim();
                  if (trip.expenseDetails != null && trip.expenseDetails!.trim().isNotEmpty) {
                    if (details.isNotEmpty) {
                      details += '\n[مصروف: ${trip.expenseDetails!.trim()}]';
                    } else {
                      details = '[مصروف: ${trip.expenseDetails!.trim()}]';
                    }
                  }
                  if (details.isEmpty) details = '-';

                  final dateStr = trip.effectiveDate.year > 1970
                      ? _formatDate(trip.effectiveDate)
                      : 'غير محدد';

                  return [
                    trip.typeLabel,
                    dateStr,
                    factoryLabel,
                    trip.driverName.isNotEmpty ? trip.driverName : '-',
                    details,
                    '${trip.revenue.toStringAsFixed(0)} ج.م',
                    '${trip.expenses.toStringAsFixed(0)} ج.م',
                    '${net.toStringAsFixed(0)} ج.م',
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
                  vertical: 3,
                ),
                cellAlignment: pw.Alignment.center,
                headerAlignment: pw.Alignment.center,
                columnWidths: {
                  0: const pw.FixedColumnWidth(40),
                  1: const pw.FixedColumnWidth(50),
                  2: const pw.FixedColumnWidth(65),
                  3: const pw.FixedColumnWidth(65),
                  4: const pw.FlexColumnWidth(2.5),
                  5: const pw.FixedColumnWidth(45),
                  6: const pw.FixedColumnWidth(45),
                  7: const pw.FixedColumnWidth(45),
                },
              ),
            );
          }

          // Footer totals
          widgets.add(pw.SizedBox(height: 10));

          widgets.add(
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'إجمالي الإيرادات: ${totalRevenue.toStringAsFixed(0)} ج.م',
                    style: pw.TextStyle(font: boldFont, fontSize: 8.5),
                  ),
                  pw.Text(
                    'إجمالي المصروفات: ${totalExpenses.toStringAsFixed(0)} ج.م',
                    style: pw.TextStyle(font: boldFont, fontSize: 8.5),
                  ),
                  pw.Text(
                    'صافي الأرباح: ${totalNetRevenue.toStringAsFixed(0)} ج.م',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 9.5,
                      color: totalNetRevenue >= 0 ? PdfColors.green800 : PdfColors.red800,
                    ),
                  ),
                ],
              ),
            ),
          );

          return widgets;
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'تقرير_${bus.busName}_${now.year}_${now.month}.pdf',
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
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static String _monthName(int month) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return months[month - 1];
  }
}