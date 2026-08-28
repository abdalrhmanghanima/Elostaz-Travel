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

    final tripsCount = summary.allTrips.where((t) => t.isTrip).length;
    final nightOutingsCount = summary.allTrips.where((t) => t.isNightOuting).length;

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
                  'الملخص المالي الشامل — شركة الأستاذ للنقل السياحي',
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
                      'الملخص المالي العام للشركة',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 17,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 2),
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
                      'شركة الأستاذ للنقل السياحي',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 14,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 2),
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

          widgets.add(pw.SizedBox(height: 10));

          // ── 2. Top Summary KPI Card ─────────────────────────────────────
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
                    child: _kpiItem(
                      title: 'إجمالي العمليات',
                      value: '${summary.totalTrips} ($tripsCount رحلة + $nightOutingsCount سهرة)',
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
                      title: 'صافي الأرباح',
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

          widgets.add(pw.SizedBox(height: 10));

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
                    'لا توجد رحلات أو سهرات مسجلة في هذه الفترة',
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 11,
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
                  margin: const pw.EdgeInsets.only(top: 6, bottom: 4),
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
                          fontSize: 9.5,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.Text(
                        'لوحة: ${group.plateNumber}',
                        style: pw.TextStyle(
                          font: regularFont,
                          fontSize: 8.5,
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
                    'النوع',
                    'التاريخ',
                    'السائق',
                    'المصنع / الجهة',
                    'التفاصيل وملاحظات المصروف',
                    'الإيراد',
                    'المصروف',
                    'الصافي',
                  ],
                  data: group.trips.map((trip) {
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
                      trip.driverName.isNotEmpty ? trip.driverName : '-',
                      factoryLabel,
                      details,
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

              // Bus Subtotal
              widgets.add(
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 6),
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey50,
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'إجمالي الأتوبيس (${group.trips.length} عملية):',
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
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blueGrey100,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.blueGrey300, width: 0.5),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'إجمالي الشركة (${summary.totalTrips} عملية):',
                      style: pw.TextStyle(font: boldFont, fontSize: 9),
                    ),
                    pw.Text(
                      'الإيرادات: ${_formatCurrency(summary.totalRevenue)} ج.م',
                      style: pw.TextStyle(font: boldFont, fontSize: 8.5),
                    ),
                    pw.Text(
                      'المصروفات: ${_formatCurrency(summary.totalExpenses)} ج.م',
                      style: pw.TextStyle(font: boldFont, fontSize: 8.5),
                    ),
                    pw.Text(
                      'صافي الأرباح: ${_formatCurrency(summary.totalNetRevenue)} ج.م',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 9.5,
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

  static String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}

