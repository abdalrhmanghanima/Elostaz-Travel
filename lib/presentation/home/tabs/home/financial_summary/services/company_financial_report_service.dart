import 'package:elostaz_travel/presentation/home/tabs/home/financial_summary/provider/company_financial_summary_provider.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CompanyFinancialReportService {
  static Future<void> shareCompanyReport({
    required CompanyFinancialSummary summary,
  }) async {
    final now = DateTime.now();

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
        margin: const pw.EdgeInsets.all(20),
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
                  'الملخص المالي الشامل - Elostaz Travel',
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

          // ── 1. Header ──────────────────────────────────────────────────
          widgets.add(
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'الملخص المالي للشركة',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 20,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'الفترة: ${summary.periodLabel}',
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
                      'Elostaz Travel',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 15,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'تاريخ التقرير: ${_formatDate(now)}',
                      style: pw.TextStyle(
                        font: regularFont,
                        fontSize: 9,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );

          widgets.add(pw.SizedBox(height: 12));

          // ── 2. Top Summary KPI Card ─────────────────────────────────────
          widgets.add(
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: _kpiItem(
                      title: 'إجمالي الرحلات',
                      value: '${summary.totalTrips}',
                      regularFont: regularFont,
                      boldFont: boldFont,
                    ),
                  ),
                  pw.Expanded(
                    child: _kpiItem(
                      title: 'إجمالي الإيرادات',
                      value: '${_formatCurrency(summary.totalRevenue)} ج.م',
                      regularFont: regularFont,
                      boldFont: boldFont,
                    ),
                  ),
                  pw.Expanded(
                    child: _kpiItem(
                      title: 'إجمالي المصروفات',
                      value: '${_formatCurrency(summary.totalExpenses)} ج.م',
                      regularFont: regularFont,
                      boldFont: boldFont,
                    ),
                  ),
                  pw.Expanded(
                    child: _kpiItem(
                      title: 'صافي الإيرادات',
                      value: '${_formatCurrency(summary.totalNetRevenue)} ج.م',
                      regularFont: regularFont,
                      boldFont: boldFont,
                      valueColor: summary.totalNetRevenue >= 0
                          ? PdfColors.green800
                          : PdfColors.red800,
                    ),
                  ),
                ],
              ),
            ),
          );

          widgets.add(pw.SizedBox(height: 14));

          // ── 3. Empty State or Grouped Bus Details ───────────────────────
          if (summary.busGroups.isEmpty) {
            widgets.add(
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(25),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'لا توجد رحلات في هذه الفترة',
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          } else {
            for (final group in summary.busGroups) {
              // Bus section header
              widgets.add(
                pw.Container(
                  margin: const pw.EdgeInsets.only(top: 8, bottom: 4),
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.blueGrey50,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'الأتوبيس: ${group.busName}',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 10,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.Text(
                        'لوحة: ${group.plateNumber}',
                        style: pw.TextStyle(
                          font: regularFont,
                          fontSize: 9,
                          color: PdfColors.grey800,
                        ),
                      ),
                    ],
                  ),
                ),
              );

              // Compact Table for Bus Trips
              widgets.add(
                pw.TableHelper.fromTextArray(
                  headers: [
                    'التاريخ',
                    'السائق',
                    'التفاصيل',
                    'الإيراد',
                    'المصروفات',
                    'الصافي',
                  ],
                  data: group.trips.map((trip) {
                    final net = trip.revenue - trip.expenses;
                    return [
                      _formatDate(trip.createdAt),
                      trip.driverName,
                      trip.details.isEmpty ? '-' : trip.details,
                      '${_formatCurrency(trip.revenue)} ج.م',
                      '${_formatCurrency(trip.expenses)} ج.م',
                      '${_formatCurrency(net)} ج.م',
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
                    horizontal: 4,
                    vertical: 3,
                  ),
                  cellAlignment: pw.Alignment.center,
                  headerAlignment: pw.Alignment.center,
                  columnWidths: {
                    0: const pw.FixedColumnWidth(55),
                    1: const pw.FixedColumnWidth(80),
                    2: const pw.FlexColumnWidth(2.2),
                    3: const pw.FixedColumnWidth(55),
                    4: const pw.FixedColumnWidth(55),
                    5: const pw.FixedColumnWidth(55),
                  },
                ),
              );

              // Bus Subtotal
              widgets.add(
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey50,
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'إجمالي الأتوبيس (${group.trips.length} رحلة):',
                        style: pw.TextStyle(font: boldFont, fontSize: 8),
                      ),
                      pw.Text(
                        'الإيراد: ${_formatCurrency(group.busRevenue)} ج.م',
                        style: pw.TextStyle(font: regularFont, fontSize: 8),
                      ),
                      pw.Text(
                        'المصروف: ${_formatCurrency(group.busExpenses)} ج.م',
                        style: pw.TextStyle(font: regularFont, fontSize: 8),
                      ),
                      pw.Text(
                        'الصافي: ${_formatCurrency(group.busNet)} ج.م',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 8.5,
                          color: group.busNet >= 0
                              ? PdfColors.green800
                              : PdfColors.red800,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            widgets.add(pw.SizedBox(height: 8));

            // ── 4. Grand Final Total ───────────────────────────────────────
            widgets.add(
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blueGrey100,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.blueGrey300),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'إجمالي الشركة (${summary.totalTrips} رحلة):',
                      style: pw.TextStyle(font: boldFont, fontSize: 9.5),
                    ),
                    pw.Text(
                      'الإيرادات: ${_formatCurrency(summary.totalRevenue)} ج.م',
                      style: pw.TextStyle(font: boldFont, fontSize: 9),
                    ),
                    pw.Text(
                      'المصروفات: ${_formatCurrency(summary.totalExpenses)} ج.م',
                      style: pw.TextStyle(font: boldFont, fontSize: 9),
                    ),
                    pw.Text(
                      'صافي الشركة: ${_formatCurrency(summary.totalNetRevenue)} ج.م',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 10.5,
                        color: summary.totalNetRevenue >= 0
                            ? PdfColors.green900
                            : PdfColors.red900,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

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

  static pw.Widget _kpiItem({
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
          style: pw.TextStyle(
            font: regularFont,
            fontSize: 7.5,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          value,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 9.5,
            color: valueColor ?? PdfColors.black,
          ),
        ),
      ],
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}
