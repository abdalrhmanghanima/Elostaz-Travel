
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
  }) async {
    final now = DateTime.now();

    // Monthly trips
    final monthlyTrips = trips.where((trip) {
      final date = trip.effectiveDate;
      return date.year == now.year && date.month == now.month;
    }).toList()
      ..sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));

    final tripsCount = monthlyTrips.where((t) => t.isTrip).length;
    final nightOutingsCount = monthlyTrips.where((t) => t.isNightOuting).length;

    // Monthly Advances
    final monthlyAdvances = advances.where((advance) {
      return advance.date.year == now.year && advance.date.month == now.month;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    // Financial Totals (Unified)
    final totalRevenue = monthlyTrips.fold<double>(
      0,
      (sum, trip) => sum + trip.revenue,
    );

    final totalExpenses = monthlyTrips.fold<double>(
      0,
      (sum, trip) => sum + trip.expenses,
    );

    final totalNetRevenue = totalRevenue - totalExpenses;

    final outstandingAdvances = advances
        .where((a) => a.isActive)
        .fold<double>(0, (sum, a) => sum + a.amount);


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
                  'تقرير عمليات السائق — شركة الأستاذ للنقل السياحي',
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
                      'تقرير حساب وعمليات السائق',
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
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
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
                      title: 'الصافي',
                      value: '${totalNetRevenue.toStringAsFixed(0)} ج.م',
                      regularFont: regularFont,
                      boldFont: boldFont,
                    ),
                  ),
                  pw.Expanded(
                    child: _smallSummary(
                      title: 'السلف المستحقة',
                      value: '${outstandingAdvances.toStringAsFixed(0)} ج.م',
                      regularFont: regularFont,
                      boldFont: boldFont,
                    ),
                  ),
                ],
              ),
            ),
          );

          widgets.add(pw.SizedBox(height: 10));

          // Operations Section
          widgets.add(
            _sectionTitle('تفاصيل العمليات والرحلات', boldFont),
          );

          if (monthlyTrips.isEmpty) {
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
                    'لا توجد رحلات أو سهرات مسجلة لهذا السائق خلال هذا الشهر',
                    style: pw.TextStyle(font: regularFont, fontSize: 11),
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
                  'المصنع / الجهة',
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
                    trip.busName.isNotEmpty ? trip.busName : '-',
                    factoryLabel,
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
                  2: const pw.FixedColumnWidth(60),
                  3: const pw.FixedColumnWidth(60),
                  4: const pw.FlexColumnWidth(2.5),
                  5: const pw.FixedColumnWidth(45),
                  6: const pw.FixedColumnWidth(45),
                  7: const pw.FixedColumnWidth(45),
                },
              ),
            );
          }

          // Advances Section
          if (monthlyAdvances.isNotEmpty) {
            widgets.add(pw.SizedBox(height: 12));
            widgets.add(_sectionTitle('سلف السائق خلال الشهر', boldFont));

            widgets.add(
              pw.TableHelper.fromTextArray(
                headers: ['التاريخ', 'المبلغ', 'الحالة', 'البيان والتفاصيل'],
                data: monthlyAdvances.map((adv) {
                  return [
                    _formatDate(adv.date),
                    '${adv.amount.toStringAsFixed(0)} ج.م',
                    adv.isActive ? 'مستحقة' : 'تم السداد',
                    adv.note.isNotEmpty ? adv.note : '-',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(font: boldFont, fontSize: 7.5),
                cellStyle: pw.TextStyle(font: regularFont, fontSize: 7),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                cellAlignment: pw.Alignment.center,
                headerAlignment: pw.Alignment.center,
                columnWidths: {
                  0: const pw.FixedColumnWidth(60),
                  1: const pw.FixedColumnWidth(60),
                  2: const pw.FixedColumnWidth(60),
                  3: const pw.FlexColumnWidth(2),
                },
              ),
            );
          }

          // Final Settlement Summary
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
                    'صافي العمليات: ${totalNetRevenue.toStringAsFixed(0)} ج.م',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 9.5,
                      color: totalNetRevenue >= 0 ? PdfColors.green800 : PdfColors.red800,
                    ),
                  ),
                  pw.Text(
                    'السلف المستحقة: ${outstandingAdvances.toStringAsFixed(0)} ج.م',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 8.5,
                      color: PdfColors.red800,
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
      filename: 'تقرير_${driver.name}_${now.year}_${now.month}.pdf',
    );
  }

  static pw.Widget _sectionTitle(String title, pw.Font boldFont) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          font: boldFont,
          fontSize: 10.5,
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
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // ==============================================================
  // MONTH NAME
  // ==============================================================

  static String _monthName(
      int month,
      ) {
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