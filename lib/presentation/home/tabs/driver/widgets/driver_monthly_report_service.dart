
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

    // ============================================================
    // MONTHLY DATA
    // ============================================================

    final monthlyTrips = trips.where((trip) {
      return trip.createdAt.year == now.year &&
          trip.createdAt.month == now.month;
    }).toList();

    final monthlyAdvances = advances.where((advance) {
      return advance.date.year == now.year &&
          advance.date.month == now.month;
    }).toList();

    final monthlyActiveAdvances = monthlyAdvances.where((advance) {
      return advance.isActive;
    }).toList();

    final monthlyPaidAdvances = monthlyAdvances.where((advance) {
      return advance.isPaid;
    }).toList();

    // ============================================================
    // NORMAL TRIP FINANCIALS
    // ============================================================

    final normalRevenue = monthlyTrips.fold<double>(
      0,
          (sum, trip) => sum + trip.revenue,
    );

    final normalExpenses = monthlyTrips.fold<double>(
      0,
          (sum, trip) => sum + trip.expenses,
    );

    // ============================================================
    // SAHRA FINANCIALS
    // ============================================================

    final totalSahraRevenue = monthlyTrips.fold<double>(
      0,
          (sum, trip) => sum + (trip.sahraRevenue ?? 0),
    );

    final totalSahraExpenses = monthlyTrips.fold<double>(
      0,
          (sum, trip) => sum + (trip.sahraExpense ?? 0),
    );

    // ============================================================
    // TOTAL FINANCIALS
    // ============================================================

    final totalRevenue = normalRevenue + totalSahraRevenue;

    final totalExpenses = normalExpenses + totalSahraExpenses;

    final totalNetRevenue = totalRevenue - totalExpenses;

    // ============================================================
    // ADVANCES
    // ============================================================

    final activeAdvances = advances.where((advance) {
      return advance.isActive;
    }).toList();

    final paidAdvances = advances.where((advance) {
      return advance.isPaid;
    }).toList();

    final outstandingAdvances = activeAdvances.fold<double>(
      0,
          (sum, advance) => sum + advance.amount,
    );

    final paidAdvancesTotal = paidAdvances.fold<double>(
      0,
          (sum, advance) => sum + advance.amount,
    );

    // ============================================================
    // FONTS
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
        // FOOTER
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
                  'تقرير رحلات السواق',
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
        // CONTENT
        // ========================================================

        build: (context) {
          return [
            // ====================================================
            // HEADER
            // ====================================================

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
                      'تقرير رحلات السواق',
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
                      driver.name,
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 15,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      driver.phone,
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

            // ====================================================
            // DRIVER DOCUMENTS
            // ====================================================

            _sectionTitle(
              'مستندات السواق',
              boldFont,
            ),

            pw.Container(
              padding: const pw.EdgeInsets.all(10),
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
                    child: _documentStatus(
                      title: 'صورة البطاقة',
                      available:
                      driver.idCardImageUrl != null &&
                          driver.idCardImageUrl!
                              .isNotEmpty,
                      regularFont: regularFont,
                      boldFont: boldFont,
                    ),
                  ),
                  pw.Expanded(
                    child: _documentStatus(
                      title: 'صورة الرخصة',
                      available:
                      driver.licenseImageUrl != null &&
                          driver.licenseImageUrl!
                              .isNotEmpty,
                      regularFont: regularFont,
                      boldFont: boldFont,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 14),

            // ====================================================
            // FINANCIAL SUMMARY
            // ====================================================

            _sectionTitle(
              'الملخص المالي',
              boldFont,
            ),

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
              child: pw.Column(
                children: [
                  pw.Row(
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

                  pw.SizedBox(height: 10),

                  pw.Divider(
                    color: PdfColors.grey300,
                  ),

                  pw.SizedBox(height: 6),

                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: _smallSummary(
                          title: 'إيراد السهرات',
                          value:
                          '${totalSahraRevenue.toStringAsFixed(0)} ج.م',
                          regularFont: regularFont,
                          boldFont: boldFont,
                        ),
                      ),
                      pw.Expanded(
                        child: _smallSummary(
                          title: 'مصروف السهرات',
                          value:
                          '${totalSahraExpenses.toStringAsFixed(0)} ج.م',
                          regularFont: regularFont,
                          boldFont: boldFont,
                        ),
                      ),
                      pw.Expanded(
                        child: _smallSummary(
                          title: 'السلف المستحقة',
                          value:
                          '${outstandingAdvances.toStringAsFixed(0)} ج.م',
                          regularFont: regularFont,
                          boldFont: boldFont,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 16),

            // ====================================================
            // TRIPS
            // ====================================================

            _sectionTitle(
              'تفاصيل الرحلات',
              boldFont,
            ),

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
                    'لا توجد رحلات لهذا السواق خلال هذا الشهر',
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 12,
                    ),
                  ),
                ),
              )
            else
              ...monthlyTrips.map(
                    (trip) => _buildTripCard(
                  trip: trip,
                  regularFont: regularFont,
                  boldFont: boldFont,
                ),
              ),

            pw.SizedBox(height: 16),

            // ====================================================
            // ADVANCES
            // ====================================================

            _sectionTitle(
              'سلف السواق',
              boldFont,
            ),

            if (monthlyAdvances.isEmpty)
              pw.Container(
                width: double.infinity,
                padding:
                const pw.EdgeInsets.all(18),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius:
                  pw.BorderRadius.circular(7),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'لا توجد سلف مسجلة خلال هذا الشهر',
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 10,
                    ),
                  ),
                ),
              )
            else ...[
              _buildAdvanceSummary(
                activeTotal: outstandingAdvances,
                paidTotal: paidAdvancesTotal,
                regularFont: regularFont,
                boldFont: boldFont,
              ),

              pw.SizedBox(height: 10),

              if (monthlyActiveAdvances.isNotEmpty) ...[
                _advanceSectionHeader(
                  'السلف المستحقة',
                  boldFont,
                  color: PdfColors.red900,
                  badgeText: '${monthlyActiveAdvances.length} سلفة',
                ),
                pw.SizedBox(height: 6),
                ...monthlyActiveAdvances.map(
                  (advance) => _buildAdvanceCard(
                    advance: advance,
                    regularFont: regularFont,
                    boldFont: boldFont,
                  ),
                ),
                pw.SizedBox(height: 8),
              ],

              if (monthlyPaidAdvances.isNotEmpty) ...[
                _advanceSectionHeader(
                  'السلف التي تم سدادها',
                  boldFont,
                  color: PdfColors.green900,
                  badgeText: '${monthlyPaidAdvances.length} سلفة مسددة',
                ),
                pw.SizedBox(height: 6),
                ...monthlyPaidAdvances.map(
                  (advance) => _buildAdvanceCard(
                    advance: advance,
                    regularFont: regularFont,
                    boldFont: boldFont,
                  ),
                ),
              ],
            ],

            pw.SizedBox(height: 14),

            // ====================================================
            // FINAL SUMMARY
            // ====================================================

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
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment:
                    pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'إجمالي الإيرادات:',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 9,
                        ),
                      ),
                      pw.Text(
                        '${totalRevenue.toStringAsFixed(0)} ج.م',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 5),

                  pw.Row(
                    mainAxisAlignment:
                    pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'إجمالي المصروفات:',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 9,
                        ),
                      ),
                      pw.Text(
                        '${totalExpenses.toStringAsFixed(0)} ج.م',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 5),

                  pw.Divider(
                    color: PdfColors.grey300,
                  ),

                  pw.Row(
                    mainAxisAlignment:
                    pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'الصافي:',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 11,
                        ),
                      ),
                      pw.Text(
                        '${totalNetRevenue.toStringAsFixed(0)} ج.م',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 8),

                  pw.Row(
                    mainAxisAlignment:
                    pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'السلف المستحقة على السواق:',
                        style: pw.TextStyle(
                          font: regularFont,
                          fontSize: 9,
                        ),
                      ),
                      pw.Text(
                        '${outstandingAdvances.toStringAsFixed(0)} ج.م',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    // ============================================================
    // SHARE PDF
    // ============================================================

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename:
      'تقرير_${driver.name}_${now.year}_${now.month}.pdf',
    );
  }

  // ==============================================================
  // TRIP CARD
  // ==============================================================

  static pw.Widget _buildTripCard({
    required TripEntity trip,
    required pw.Font regularFont,
    required pw.Font boldFont,
  }) {
    final normalNet =
        trip.revenue - trip.expenses;

    final sahraRevenue =
        trip.sahraRevenue ?? 0;

    final sahraExpense =
        trip.sahraExpense ?? 0;

    final hasSahra =
        trip.sahraDetails != null ||
            trip.sahraDriverName != null ||
            sahraRevenue > 0 ||
            sahraExpense > 0;

    final totalTripRevenue =
        trip.revenue + sahraRevenue;

    final totalTripExpense =
        trip.expenses + sahraExpense;

    final totalTripNet =
        totalTripRevenue - totalTripExpense;

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius:
        pw.BorderRadius.circular(7),
        border: pw.Border.all(
          color: PdfColors.grey300,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment:
        pw.CrossAxisAlignment.stretch,
        children: [
          // --------------------------------------------------------
          // TRIP HEADER
          // --------------------------------------------------------

          pw.Row(
            mainAxisAlignment:
            pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                _formatDate(trip.createdAt),
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 10,
                ),
              ),
              pw.Text(
                trip.busName,
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 11,
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 3),

          pw.Text(
            'اللوحة: ${trip.plateNumber}',
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 8,
              color: PdfColors.grey700,
            ),
          ),

          // --------------------------------------------------------
          // FACTORY
          // --------------------------------------------------------

          if (_factoryName(trip).isNotEmpty) ...[
            pw.SizedBox(height: 6),
            _infoRow(
              title: 'المصنع',
              value: _factoryName(trip),
              regularFont: regularFont,
              boldFont: boldFont,
            ),
          ],

          pw.SizedBox(height: 8),

          pw.Divider(
            color: PdfColors.grey300,
          ),

          // --------------------------------------------------------
          // TRIP DETAILS
          // --------------------------------------------------------

          _infoRow(
            title: 'تفاصيل الرحلة',
            value: trip.details.isEmpty
                ? '-'
                : trip.details,
            regularFont: regularFont,
            boldFont: boldFont,
          ),

          pw.SizedBox(height: 5),

          _infoRow(
            title: 'إيراد الرحلة',
            value:
            '${trip.revenue.toStringAsFixed(0)} ج.م',
            regularFont: regularFont,
            boldFont: boldFont,
          ),

          if (trip.expenses > 0 || (trip.expenseDetails ?? '').isNotEmpty) ...[
            pw.SizedBox(height: 5),
            _infoRow(
              title: 'مصروف السواق في الرحلة',
              value:
              '${trip.expenses.toStringAsFixed(0)} ج.م',
              regularFont: regularFont,
              boldFont: boldFont,
            ),
            if ((trip.expenseDetails ?? '').isNotEmpty) ...[
              pw.SizedBox(height: 5),
              _infoRow(
                title: 'تفاصيل مصروف السواق',
                value: trip.expenseDetails ?? '',
                regularFont: regularFont,
                boldFont: boldFont,
              ),
            ],
          ],

          pw.SizedBox(height: 5),

          _infoRow(
            title: 'صافي الرحلة',
            value:
            '${normalNet.toStringAsFixed(0)} ج.م',
            regularFont: regularFont,
            boldFont: boldFont,
          ),

          // --------------------------------------------------------
          // SAHRA
          // --------------------------------------------------------

          if (hasSahra) ...[
            pw.SizedBox(height: 10),

            pw.Container(
              padding:
              const pw.EdgeInsets.all(9),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                borderRadius:
                pw.BorderRadius.circular(6),
                border: pw.Border.all(
                  color: PdfColors.green300,
                ),
              ),
              child: pw.Column(
                crossAxisAlignment:
                pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Text(
                    'سهرة (وردية إضافية)',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 11,
                      color: PdfColors.green900,
                    ),
                  ),

                  pw.SizedBox(height: 7),

                  if ((trip.sahraDetails ?? '')
                      .isNotEmpty)
                    _infoRow(
                      title: 'تفاصيل السهرة',
                      value:
                      trip.sahraDetails!,
                      regularFont:
                      regularFont,
                      boldFont: boldFont,
                    ),

                  if ((trip.sahraDriverName ?? '')
                      .isNotEmpty) ...[
                    pw.SizedBox(height: 5),
                    _infoRow(
                      title: 'سائق السهرة',
                      value:
                      trip.sahraDriverName!,
                      regularFont:
                      regularFont,
                      boldFont: boldFont,
                    ),
                  ],

                  if (sahraRevenue > 0) ...[
                    pw.SizedBox(height: 5),
                    _infoRow(
                      title: 'إيراد السهرة',
                      value:
                      '${sahraRevenue.toStringAsFixed(0)} ج.م',
                      regularFont:
                      regularFont,
                      boldFont: boldFont,
                    ),
                  ],

                  if (sahraExpense > 0) ...[
                    pw.SizedBox(height: 5),
                    _infoRow(
                      title: 'مصروف السهرة',
                      value:
                      '${sahraExpense.toStringAsFixed(0)} ج.م',
                      regularFont:
                      regularFont,
                      boldFont: boldFont,
                    ),
                  ],

                  if ((trip.sahraExpenseDetails ??
                      '')
                      .isNotEmpty) ...[
                    pw.SizedBox(height: 5),
                    _infoRow(
                      title:
                      'تفاصيل مصروف السهرة',
                      value:
                      trip.sahraExpenseDetails!,
                      regularFont:
                      regularFont,
                      boldFont: boldFont,
                    ),
                  ],

                  pw.SizedBox(height: 5),

                  _infoRow(
                    title: 'صافي السهرة',
                    value:
                    '${(sahraRevenue - sahraExpense).toStringAsFixed(0)} ج.م',
                    regularFont:
                    regularFont,
                    boldFont: boldFont,
                  ),
                ],
              ),
            ),
          ],

          // --------------------------------------------------------
          // TOTAL TRIP
          // --------------------------------------------------------

          if (hasSahra) ...[
            pw.SizedBox(height: 8),

            pw.Container(
              padding:
              const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius:
                pw.BorderRadius.circular(5),
              ),
              child: pw.Row(
                mainAxisAlignment:
                pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'إجمالي الرحلة والسهرة',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 8,
                    ),
                  ),
                  pw.Text(
                    'إيراد: ${totalTripRevenue.toStringAsFixed(0)} - '
                        'مصروف: ${totalTripExpense.toStringAsFixed(0)} - '
                        'صافي: ${totalTripNet.toStringAsFixed(0)} ج.م',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==============================================================
  // ADVANCE SECTION HEADER
  // ==============================================================

  static pw.Widget _advanceSectionHeader(
    String title,
    pw.Font boldFont, {
    required PdfColor color,
    required String badgeText,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 4, bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 10,
              color: color,
            ),
          ),
          pw.Text(
            badgeText,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 8.5,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // ADVANCE SUMMARY
  // ==============================================================

  static pw.Widget _buildAdvanceSummary({
    required double activeTotal,
    required double paidTotal,
    required pw.Font regularFont,
    required pw.Font boldFont,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(9),
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
              title: 'السلف المستحقة',
              value:
              '${activeTotal.toStringAsFixed(0)} ج.م',
              regularFont: regularFont,
              boldFont: boldFont,
            ),
          ),
          pw.Expanded(
            child: _smallSummary(
              title: 'السلف المسددة',
              value:
              '${paidTotal.toStringAsFixed(0)} ج.م',
              regularFont: regularFont,
              boldFont: boldFont,
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // ADVANCE CARD
  // ==============================================================

  static pw.Widget _buildAdvanceCard({
    required DriverAdvanceEntity advance,
    required pw.Font regularFont,
    required pw.Font boldFont,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 7),
      padding: const pw.EdgeInsets.all(9),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius:
        pw.BorderRadius.circular(6),
        border: pw.Border.all(
          color: advance.isPaid ? PdfColors.green300 : PdfColors.red300,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment:
        pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            mainAxisAlignment:
            pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'قيمة السلفة: ${advance.amount.toStringAsFixed(0)} ج.م',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 9.5,
                  color: advance.isPaid ? PdfColors.green900 : PdfColors.red900,
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: advance.isPaid ? PdfColors.green50 : PdfColors.red50,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(
                    color: advance.isPaid ? PdfColors.green400 : PdfColors.red400,
                    width: 0.5,
                  ),
                ),
                child: pw.Text(
                  advance.isPaid ? 'تم السداد' : 'مستحقة',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 8,
                    color: advance.isPaid ? PdfColors.green900 : PdfColors.red900,
                  ),
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 5),

          _infoRow(
            title: 'تاريخ السلفة',
            value:
            _formatDate(advance.date),
            regularFont: regularFont,
            boldFont: boldFont,
          ),

          pw.SizedBox(height: 4),

          _infoRow(
            title: 'سبب السلفة / الملاحظات',
            value: advance.note.isNotEmpty ? advance.note : 'لا توجد ملاحظات',
            regularFont: regularFont,
            boldFont: boldFont,
          ),

          if (advance.paidAt != null) ...[
            pw.SizedBox(height: 4),
            _infoRow(
              title: 'تاريخ السداد',
              value:
              _formatDate(advance.paidAt!),
              regularFont: regularFont,
              boldFont: boldFont,
            ),
          ],
        ],
      ),
    );
  }

  // ==============================================================
  // DOCUMENT STATUS
  // ==============================================================

  static pw.Widget _documentStatus({
    required String title,
    required bool available,
    required pw.Font regularFont,
    required pw.Font boldFont,
  }) {
    return pw.Column(
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 9,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          available
              ? 'متوفرة'
              : 'غير مرفوعة',
          style: pw.TextStyle(
            font: regularFont,
            fontSize: 8,
            color: available
                ? PdfColors.green
                : PdfColors.grey600,
          ),
        ),
      ],
    );
  }

  // ==============================================================
  // INFO ROW
  // ==============================================================

  static pw.Widget _infoRow({
    required String title,
    required String value,
    required pw.Font regularFont,
    required pw.Font boldFont,
  }) {
    return pw.Row(
      crossAxisAlignment:
      pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 85,
          child: pw.Text(
            '$title:',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 8,
            ),
          ),
        ),
        pw.Expanded(
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
  // SECTION TITLE
  // ==============================================================

  static pw.Widget _sectionTitle(
      String title,
      pw.Font boldFont,
      ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(
        bottom: 7,
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          font: boldFont,
          fontSize: 13,
        ),
      ),
    );
  }

  // ==============================================================
  // SMALL SUMMARY
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
  // FACTORY NAME
  // ==============================================================

  static String _factoryName(
      TripEntity trip,
      ) {
    return trip.factoryName ?? '';
  }

  // ==============================================================
  // DATE
  // ==============================================================

  static String _formatDate(
      DateTime date,
      ) {
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