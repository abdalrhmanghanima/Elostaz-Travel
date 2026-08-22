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

    final totalRevenue = trips.fold<double>(
      0,
      (sum, trip) =>
          sum +
          trip.revenue +
          (trip.sahraRevenue ?? 0),
    );

    final totalExpenses = trips.fold<double>(
      0,
      (sum, trip) =>
          sum +
          trip.expenses +
          (trip.sahraExpense ?? 0),
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
        margin: const pw.EdgeInsets.fromLTRB(20, 20, 20, 20),
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
                  'تقرير المصنع - ${factory.name}',
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
                      'تقرير المصنع',
                      style: pw.TextStyle(font: boldFont, fontSize: 20),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'تاريخ التقرير: ${_formatDate(now)}',
                      style: pw.TextStyle(
                        font: regularFont,
                        fontSize: 10,
                        color: PdfColors.grey600,
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
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'هاتف: ${factory.phone}',
                        style: pw.TextStyle(
                          font: regularFont,
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );

          widgets.add(pw.SizedBox(height: 10));

          // ── Factory info block ────────────────────────────────────────────
          if (factory.details.trim().isNotEmpty) {
            widgets.add(
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  borderRadius: pw.BorderRadius.circular(5),
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'التفاصيل / الملاحظات:',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      factory.details,
                      style: pw.TextStyle(font: regularFont, fontSize: 9),
                    ),
                  ],
                ),
              ),
            );
            widgets.add(pw.SizedBox(height: 10));
          }

          // ── KPI Summary ───────────────────────────────────────────────────
          widgets.add(
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 9,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(7),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: _kpi(
                      title: 'عدد الرحلات',
                      value: '${trips.length}',
                      regularFont: regularFont,
                      boldFont: boldFont,
                    ),
                  ),
                  pw.Expanded(
                    child: _kpi(
                      title: 'إجمالي الإيرادات',
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
                      title: 'صافي الإيراد',
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

          widgets.add(pw.SizedBox(height: 14));

          // ── Trips ─────────────────────────────────────────────────────────
          if (trips.isEmpty) {
            widgets.add(
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(25),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(7),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'لا توجد رحلات لهذا المصنع',
                    style: pw.TextStyle(font: regularFont, fontSize: 12),
                  ),
                ),
              ),
            );
          } else {
            widgets.add(
              pw.Text(
                'تفاصيل الرحلات / الورديات',
                style: pw.TextStyle(font: boldFont, fontSize: 11),
              ),
            );
            widgets.add(pw.SizedBox(height: 6));

            for (int i = 0; i < trips.length; i++) {
              final trip = trips[i];
              final net = trip.revenue - trip.expenses;

              // Main trip card
              widgets.add(
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                      color: PdfColors.grey300,
                      width: 0.5,
                    ),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Trip header bar
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey200,
                          borderRadius: pw.BorderRadius.only(
                            topLeft: pw.Radius.circular(5),
                            topRight: pw.Radius.circular(5),
                          ),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'رحلة ${i + 1} — ${_formatDate(trip.createdAt)}',
                              style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 9,
                              ),
                            ),
                            if (trip.isNightShift)
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.green100,
                                  borderRadius: pw.BorderRadius.circular(3),
                                  border: pw.Border.all(
                                    color: PdfColors.green700,
                                    width: 0.5,
                                  ),
                                ),
                                child: pw.Text(
                                  'سهرة',
                                  style: pw.TextStyle(
                                    font: boldFont,
                                    fontSize: 8,
                                    color: PdfColors.green900,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Trip details body
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            // Row: Bus + Driver
                            pw.Row(
                              children: [
                                pw.Expanded(
                                  child: _labelValue(
                                    label: 'الأتوبيس',
                                    value:
                                        '${trip.busName} (${trip.plateNumber})',
                                    regularFont: regularFont,
                                    boldFont: boldFont,
                                  ),
                                ),
                                pw.Expanded(
                                  child: _labelValue(
                                    label: 'السائق',
                                    value: trip.driverName,
                                    regularFont: regularFont,
                                    boldFont: boldFont,
                                  ),
                                ),
                              ],
                            ),

                            if (trip.details.trim().isNotEmpty) ...[
                              pw.SizedBox(height: 4),
                              _labelValue(
                                label: 'تفاصيل الوردية',
                                value: trip.details,
                                regularFont: regularFont,
                                boldFont: boldFont,
                              ),
                            ],

                            pw.SizedBox(height: 5),

                            // Financial row
                            pw.Row(
                              children: [
                                pw.Expanded(
                                  child: _finBox(
                                    label: 'الإيراد',
                                    value:
                                        '${trip.revenue.toStringAsFixed(0)} ج.م',
                                    regularFont: regularFont,
                                    boldFont: boldFont,
                                  ),
                                ),
                                pw.SizedBox(width: 4),
                                pw.Expanded(
                                  child: _finBox(
                                    label: 'المصروف',
                                    value:
                                        '${trip.expenses.toStringAsFixed(0)} ج.م',
                                    regularFont: regularFont,
                                    boldFont: boldFont,
                                  ),
                                ),
                                pw.SizedBox(width: 4),
                                pw.Expanded(
                                  child: _finBox(
                                    label: 'الصافي',
                                    value: '${net.toStringAsFixed(0)} ج.م',
                                    regularFont: regularFont,
                                    boldFont: boldFont,
                                    valueColor: net >= 0
                                        ? PdfColors.green800
                                        : PdfColors.red800,
                                  ),
                                ),
                              ],
                            ),

                            if (trip.expenseDetails != null &&
                                trip.expenseDetails!.trim().isNotEmpty) ...[
                              pw.SizedBox(height: 4),
                              _noteRow(
                                label: 'تفاصيل المصروف',
                                value: trip.expenseDetails!,
                                regularFont: regularFont,
                                boldFont: boldFont,
                              ),
                            ],

                            // Sahra section
                            if (trip.hasSahra) ...[
                              pw.SizedBox(height: 6),
                              pw.Container(
                                width: double.infinity,
                                padding: const pw.EdgeInsets.all(7),
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.green50,
                                  borderRadius: pw.BorderRadius.circular(4),
                                  border: pw.Border.all(
                                    color: PdfColors.green300,
                                    width: 0.5,
                                  ),
                                ),
                                child: pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text(
                                      'السهرة (وردية إضافية):',
                                      style: pw.TextStyle(
                                        font: boldFont,
                                        fontSize: 9,
                                        color: PdfColors.green900,
                                      ),
                                    ),
                                    pw.SizedBox(height: 4),
                                    if (trip.sahraDetails != null &&
                                        trip.sahraDetails!.trim().isNotEmpty)
                                      _labelValue(
                                        label: 'تفاصيل السهرة',
                                        value: trip.sahraDetails!,
                                        regularFont: regularFont,
                                        boldFont: boldFont,
                                      ),
                                    if (trip.sahraDriverName != null &&
                                        trip.sahraDriverName!
                                            .trim()
                                            .isNotEmpty) ...[
                                      pw.SizedBox(height: 3),
                                      _labelValue(
                                        label: 'سائق السهرة',
                                        value: trip.sahraDriverName!,
                                        regularFont: regularFont,
                                        boldFont: boldFont,
                                      ),
                                    ],
                                    pw.SizedBox(height: 4),
                                    pw.Row(
                                      children: [
                                        if (trip.sahraRevenue != null &&
                                            trip.sahraRevenue! > 0)
                                          pw.Expanded(
                                            child: _finBox(
                                              label: 'إيراد السهرة',
                                              value:
                                                  '${trip.sahraRevenue!.toStringAsFixed(0)} ج.م',
                                              regularFont: regularFont,
                                              boldFont: boldFont,
                                              valueColor: PdfColors.green800,
                                            ),
                                          ),
                                        if (trip.sahraRevenue != null &&
                                            trip.sahraRevenue! > 0 &&
                                            trip.sahraExpense != null &&
                                            trip.sahraExpense! > 0)
                                          pw.SizedBox(width: 4),
                                        if (trip.sahraExpense != null &&
                                            trip.sahraExpense! > 0)
                                          pw.Expanded(
                                            child: _finBox(
                                              label: 'مصروف السهرة',
                                              value:
                                                  '${trip.sahraExpense!.toStringAsFixed(0)} ج.م',
                                              regularFont: regularFont,
                                              boldFont: boldFont,
                                              valueColor: PdfColors.red800,
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (trip.sahraExpenseDetails != null &&
                                        trip.sahraExpenseDetails!
                                            .trim()
                                            .isNotEmpty) ...[
                                      pw.SizedBox(height: 4),
                                      _noteRow(
                                        label: 'تفاصيل مصروف السهرة',
                                        value: trip.sahraExpenseDetails!,
                                        regularFont: regularFont,
                                        boldFont: boldFont,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          }

          // ── Footer totals ─────────────────────────────────────────────────
          widgets.add(pw.SizedBox(height: 8));
          widgets.add(
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 9,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(7),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'إجمالي الإيرادات: ${totalRevenue.toStringAsFixed(0)} ج.م',
                    style: pw.TextStyle(font: boldFont, fontSize: 9),
                  ),
                  pw.Text(
                    'إجمالي المصروفات: ${totalExpenses.toStringAsFixed(0)} ج.م',
                    style: pw.TextStyle(font: boldFont, fontSize: 9),
                  ),
                  pw.Text(
                    'صافي الإيراد: ${totalNetRevenue.toStringAsFixed(0)} ج.م',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 10,
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
            color: valueColor ?? PdfColors.black,
          ),
        ),
      ],
    );
  }

  static pw.Widget _labelValue({
    required String label,
    required String value,
    required pw.Font regularFont,
    required pw.Font boldFont,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '$label: ',
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 8.5,
            color: PdfColors.grey700,
          ),
        ),
        pw.Flexible(
          child: pw.Text(
            value,
            style: pw.TextStyle(font: regularFont, fontSize: 8.5),
          ),
        ),
      ],
    );
  }

  static pw.Widget _finBox({
    required String label,
    required String value,
    required pw.Font regularFont,
    required pw.Font boldFont,
    PdfColor? valueColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(3),
        border: pw.Border.all(color: PdfColors.grey200, width: 0.5),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            label,
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
      ),
    );
  }

  static pw.Widget _noteRow({
    required String label,
    required String value,
    required pw.Font regularFont,
    required pw.Font boldFont,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(3),
        border: pw.Border.all(color: PdfColors.grey200, width: 0.5),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '$label: ',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 8,
              color: PdfColors.grey700,
            ),
          ),
          pw.Flexible(
            child: pw.Text(
              value,
              style: pw.TextStyle(font: regularFont, fontSize: 8),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
