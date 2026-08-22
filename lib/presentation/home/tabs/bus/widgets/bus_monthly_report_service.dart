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

    // ============================================================
    // Current month trips
    // ============================================================
    final monthlyTrips = trips.where((trip) {
      return trip.createdAt.year == now.year &&
          trip.createdAt.month == now.month;
    }).toList();

    // ============================================================
    // Main trip financial totals
    // ============================================================
    final totalRevenue = monthlyTrips.fold<double>(
      0,
          (sum, trip) => sum + trip.revenue,
    );

    final totalExpenses = monthlyTrips.fold<double>(
      0,
          (sum, trip) => sum + trip.expenses,
    );

    final totalNetRevenue = totalRevenue - totalExpenses;

    // ============================================================
    // Sahra totals - kept completely separate
    // ============================================================
    final totalSahraRevenue = monthlyTrips.fold<double>(
      0,
          (sum, trip) => sum + (trip.sahraRevenue ?? 0),
    );

    final totalSahraExpenses = monthlyTrips.fold<double>(
      0,
          (sum, trip) => sum + (trip.sahraExpense ?? 0),
    );

    final hasSahraTrips = monthlyTrips.any(
          (trip) => trip.hasSahra,
    );

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

    // ============================================================
    // PDF
    // ============================================================
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

        // ========================================================
        // Footer
        // ========================================================
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

        // ========================================================
        // Page content
        // ========================================================
        build: (context) {
          final List<pw.Widget> widgets = [];

          // ======================================================
          // Header
          // ======================================================
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
          );

          widgets.add(
            pw.SizedBox(height: 14),
          );

          // ======================================================
          // Summary KPIs
          // ======================================================
          widgets.add(
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 9,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(7),
                border: pw.Border.all(
                  color: PdfColors.grey300,
                ),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: _smallSummary(
                      title: 'الرحلات',
                      value: '${monthlyTrips.length}',
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
          );

          // ======================================================
          // Sahra summary
          // ======================================================
          if (hasSahraTrips) {
            widgets.add(
              pw.SizedBox(height: 6),
            );

            widgets.add(
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  borderRadius: pw.BorderRadius.circular(5),
                  border: pw.Border.all(
                    color: PdfColors.green300,
                    width: 0.5,
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment:
                  pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'إجمالي السهرات:',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 8,
                        color: PdfColors.green900,
                      ),
                    ),
                    pw.Text(
                      'إيراد السهرات: '
                          '${totalSahraRevenue.toStringAsFixed(0)} ج.م',
                      style: pw.TextStyle(
                        font: regularFont,
                        fontSize: 8,
                        color: PdfColors.green900,
                      ),
                    ),
                    pw.Text(
                      'مصروف السهرات: '
                          '${totalSahraExpenses.toStringAsFixed(0)} ج.م',
                      style: pw.TextStyle(
                        font: regularFont,
                        fontSize: 8,
                        color: PdfColors.green900,
                      ),
                    ),
                    pw.Text(
                      'صافي السهرات: '
                          '${(totalSahraRevenue - totalSahraExpenses).toStringAsFixed(0)} ج.م',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 8,
                        color: PdfColors.green900,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          widgets.add(
            pw.SizedBox(height: 14),
          );

          // ======================================================
          // Trips
          // ======================================================
          if (monthlyTrips.isEmpty) {
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
                    'لا توجد رحلات لهذا الأتوبيس خلال هذا الشهر',
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          } else {
            // ====================================================
            // Main trip table
            // ====================================================
            widgets.add(
              pw.TableHelper.fromTextArray(
                headers: [
                  'التاريخ',
                  'المصنع',
                  'السائق',
                  'التفاصيل',
                  'الإيراد',
                  'المصروف',
                  'الصافي',
                ],
                data: monthlyTrips.map((trip) {
                  final net =
                      trip.revenue - trip.expenses;

                  final factoryLabel =
                  (trip.factoryName != null &&
                      trip.factoryName!
                          .trim()
                          .isNotEmpty)
                      ? trip.factoryName!
                      : '-';

                  final tripDetails =
                  trip.details.trim();

                  return [
                    _formatDate(trip.createdAt),
                    factoryLabel,
                    trip.driverName,
                    tripDetails.isEmpty
                        ? '-'
                        : tripDetails,
                    '${trip.revenue.toStringAsFixed(0)}\nج.م',
                    '${trip.expenses.toStringAsFixed(0)}\nج.م',
                    '${net.toStringAsFixed(0)}\nج.م',
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
                  horizontal: 3,
                  vertical: 4,
                ),
                cellAlignment:
                pw.Alignment.center,
                headerAlignment:
                pw.Alignment.center,
                columnWidths: {
                  0: const pw.FixedColumnWidth(55),
                  1: const pw.FixedColumnWidth(60),
                  2: const pw.FixedColumnWidth(65),
                  3: const pw.FlexColumnWidth(2.2),
                  4: const pw.FixedColumnWidth(48),
                  5: const pw.FixedColumnWidth(48),
                  6: const pw.FixedColumnWidth(48),
                },
              ),
            );

            // ====================================================
            // Expense details section
            //
            // This is the important new section.
            // It prints exactly what the user entered in:
            // "تفاصيل المصروف"
            // ====================================================
            final tripsWithExpenseDetails =
            monthlyTrips.where((trip) {
              return trip.expenseDetails != null &&
                  trip.expenseDetails!.trim().isNotEmpty;
            }).toList();

            if (tripsWithExpenseDetails.isNotEmpty) {
              widgets.add(
                pw.SizedBox(height: 12),
              );

              widgets.add(
                pw.Text(
                  'تفاصيل مصروفات الرحلات:',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 11,
                  ),
                ),
              );

              widgets.add(
                pw.SizedBox(height: 5),
              );

              for (final trip
              in tripsWithExpenseDetails) {
                widgets.add(
                  pw.Container(
                    width: double.infinity,
                    margin: const pw.EdgeInsets.only(
                      bottom: 6,
                    ),
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.orange50,
                      borderRadius:
                      pw.BorderRadius.circular(5),
                      border: pw.Border.all(
                        color: PdfColors.orange200,
                        width: 0.5,
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment:
                      pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment:
                          pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'رحلة ${_formatDate(trip.createdAt)}',
                              style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 8.5,
                              ),
                            ),
                            pw.Text(
                              'السائق: ${trip.driverName}',
                              style: pw.TextStyle(
                                font: regularFont,
                                fontSize: 8,
                              ),
                            ),
                          ],
                        ),

                        pw.SizedBox(height: 4),

                        _noteRow(
                          label: 'قيمة المصروف',
                          value:
                          '${trip.expenses.toStringAsFixed(0)} ج.م',
                          regularFont: regularFont,
                          boldFont: boldFont,
                        ),

                        pw.SizedBox(height: 3),

                        _noteRow(
                          label: 'المصروف اتصرف في إيه',
                          value:
                          trip.expenseDetails!.trim(),
                          regularFont: regularFont,
                          boldFont: boldFont,
                        ),

                        if (trip.factoryName != null &&
                            trip.factoryName!
                                .trim()
                                .isNotEmpty) ...[
                          pw.SizedBox(height: 3),
                          _noteRow(
                            label: 'المصنع',
                            value:
                            trip.factoryName!.trim(),
                            regularFont: regularFont,
                            boldFont: boldFont,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }
            }

            // ====================================================
            // Sahra detail blocks
            // ====================================================
            final sahraTrips = monthlyTrips
                .where((t) => t.hasSahra)
                .toList();

            if (sahraTrips.isNotEmpty) {
              widgets.add(
                pw.SizedBox(height: 10),
              );

              widgets.add(
                pw.Text(
                  'تفاصيل السهرات:',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 10,
                  ),
                ),
              );

              widgets.add(
                pw.SizedBox(height: 4),
              );

              for (final trip in sahraTrips) {
                widgets.add(
                  pw.Container(
                    margin: const pw.EdgeInsets.only(
                      bottom: 6,
                    ),
                    padding: const pw.EdgeInsets.all(7),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.green50,
                      borderRadius:
                      pw.BorderRadius.circular(4),
                      border: pw.Border.all(
                        color: PdfColors.green300,
                        width: 0.5,
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment:
                      pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment:
                          pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'سهرة — '
                                  '${_formatDate(trip.createdAt)} — '
                                  '${trip.driverName}',
                              style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 8.5,
                                color:
                                PdfColors.green900,
                              ),
                            ),
                          ],
                        ),

                        if (trip.sahraDetails != null &&
                            trip.sahraDetails!
                                .trim()
                                .isNotEmpty) ...[
                          pw.SizedBox(height: 3),
                          _noteRow(
                            label: 'تفاصيل السهرة',
                            value:
                            trip.sahraDetails!,
                            regularFont: regularFont,
                            boldFont: boldFont,
                          ),
                        ],

                        if (trip.sahraDriverName != null &&
                            trip.sahraDriverName!
                                .trim()
                                .isNotEmpty) ...[
                          pw.SizedBox(height: 3),
                          _noteRow(
                            label: 'سائق السهرة',
                            value:
                            trip.sahraDriverName!,
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
                                child: pw.Text(
                                  'إيراد السهرة: '
                                      '${trip.sahraRevenue!.toStringAsFixed(0)} ج.م',
                                  style: pw.TextStyle(
                                    font: boldFont,
                                    fontSize: 8,
                                    color:
                                    PdfColors.green900,
                                  ),
                                ),
                              ),

                            if (trip.sahraExpense != null &&
                                trip.sahraExpense! > 0)
                              pw.Expanded(
                                child: pw.Text(
                                  'مصروف السهرة: '
                                      '${trip.sahraExpense!.toStringAsFixed(0)} ج.م',
                                  style: pw.TextStyle(
                                    font: boldFont,
                                    fontSize: 8,
                                    color:
                                    PdfColors.red800,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        if (trip.sahraExpenseDetails !=
                            null &&
                            trip.sahraExpenseDetails!
                                .trim()
                                .isNotEmpty) ...[
                          pw.SizedBox(height: 3),
                          _noteRow(
                            label:
                            'تفاصيل مصروف السهرة',
                            value:
                            trip.sahraExpenseDetails!,
                            regularFont: regularFont,
                            boldFont: boldFont,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }
            }
          }

          // ======================================================
          // Footer totals
          // ======================================================
          widgets.add(
            pw.SizedBox(height: 12),
          );

          widgets.add(
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 9,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(7),
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
          );

          return widgets;
        },
      ),
    );

    // ============================================================
    // Share PDF
    // ============================================================
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename:
      'تقرير_${bus.busName}_${now.year}_${now.month}.pdf',
    );
  }

  // ==============================================================
  // Small summary widget
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

  // ==============================================================
  // Note row
  // ==============================================================
  static pw.Widget _noteRow({
    required String label,
    required String value,
    required pw.Font regularFont,
    required pw.Font boldFont,
  }) {
    return pw.Row(
      crossAxisAlignment:
      pw.CrossAxisAlignment.start,
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
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 8,
            ),
          ),
        ),
      ],
    );
  }

  // ==============================================================
  // Date formatter
  // ==============================================================
  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ==============================================================
  // Arabic month name
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
}