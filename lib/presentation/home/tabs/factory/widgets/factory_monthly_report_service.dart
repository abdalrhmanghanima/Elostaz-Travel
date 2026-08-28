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
  }) async {
    final now = DateTime.now();

    final sortedTrips = List<TripEntity>.from(trips)
      ..sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));

    final tripsCount = sortedTrips.where((t) => t.isTrip).length;
    final nightOutingsCount = sortedTrips.where((t) => t.isNightOuting).length;

    final totalRevenue = sortedTrips.fold<double>(
      0,
      (sum, trip) => sum + trip.revenue,
    );

    final totalExpenses = sortedTrips.fold<double>(
      0,
      (sum, trip) => sum + trip.expenses,
    );

    final totalNetRevenue = totalRevenue - totalExpenses;

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
                  'تقرير حساب وعمليات المصنع — شركة الأستاذ للنقل السياحي',
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

          // ── Header ────────────────────────────────────────────────────────
          widgets.add(
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'تقرير عمليات وحسابات المصنع',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 17,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'تاريخ التقرير: ${_formatDate(now)}',
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
                      factory.name,
                      style: pw.TextStyle(font: boldFont, fontSize: 15),
                    ),
                    if (factory.phone.trim().isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'هاتف: ${factory.phone}',
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

          widgets.add(pw.SizedBox(height: 8));

          // ── Factory info block if exists ──────────────────────────────────
          if (factory.details.trim().isNotEmpty) {
            widgets.add(
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'الملاحظات: ',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 8.5,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        factory.details,
                        style: pw.TextStyle(font: regularFont, fontSize: 8.5),
                      ),
                    ),
                  ],
                ),
              ),
            );
            widgets.add(pw.SizedBox(height: 8));
          }

          // ── KPI Summary ───────────────────────────────────────────────────
          widgets.add(
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: _kpi(
                      title: 'إجمالي العمليات',
                      value: '${sortedTrips.length} ($tripsCount رحلة + $nightOutingsCount سهرة)',
                      regularFont: regularFont,
                      boldFont: boldFont,
                    ),
                  ),
                  pw.Expanded(
                    child: _kpi(
                      title: 'إجمالي الإيراد',
                      value: '${totalRevenue.toStringAsFixed(0)} ج.م',
                      regularFont: regularFont,
                      boldFont: boldFont,
                    ),
                  ),
                  pw.Expanded(
                    child: _kpi(
                      title: 'إجمالي المصروفات',
                      value: '${totalExpenses.toStringAsFixed(0)} ج.م',
                      regularFont: regularFont,
                      boldFont: boldFont,
                    ),
                  ),
                  pw.Expanded(
                    child: _kpi(
                      title: 'الصافي',
                      value: '${totalNetRevenue.toStringAsFixed(0)} ج.م',
                      regularFont: regularFont,
                      boldFont: boldFont,
                      valueColor: totalNetRevenue >= 0
                          ? PdfColors.green800
                          : PdfColors.red800,
                    ),
                  ),
                ],
              ),
            ),
          );

          widgets.add(pw.SizedBox(height: 10));

          // ── Trips Table ───────────────────────────────────────────────────
          if (sortedTrips.isEmpty) {
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
                    'لا توجد رحلات أو سهرات مسجلة لهذا المصنع',
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
                  'السائق',
                  'التفاصيل وملاحظات المصروف',
                  'الإيراد',
                  'المصروف',
                  'الصافي',
                ],
                data: sortedTrips.map((trip) {
                  final net = trip.revenue - trip.expenses;

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

          // ── Footer totals ─────────────────────────────────────────────────
          widgets.add(pw.SizedBox(height: 10));
          widgets.add(
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
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
                    'صافي الحساب: ${totalNetRevenue.toStringAsFixed(0)} ج.م',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 9.5,
                      color: totalNetRevenue >= 0
                          ? PdfColors.green800
                          : PdfColors.red800,
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
      filename: 'تقرير_مصنع_${factory.name}_${now.year}_${now.month}.pdf',
    );
  }

  // ── Helper Widgets ─────────────────────────────────────────────────────────

  static pw.Widget _kpi({
    required String title,
    required String value,
    required pw.Font regularFont,
    required pw.Font boldFont,
    PdfColor? valueColor,
  }) {
    return pw.Column(
      children: [
        pw.Text(
          title,
          textAlign: pw.TextAlign.center,
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
            color: valueColor ?? PdfColors.black,
          ),
        ),
      ],
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

