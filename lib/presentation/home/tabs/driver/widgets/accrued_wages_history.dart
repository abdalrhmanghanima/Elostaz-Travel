import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_wage_entry_entity.dart';
import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/widgets/empty_wage_box.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/widgets/wage_history_row.dart';
import 'package:flutter/material.dart';

class AccruedWagesHistory extends StatelessWidget {
  final List<TripEntity> trips;
  final List<DriverWageEntryEntity> entries;

  const AccruedWagesHistory({
    super.key,
    required this.trips,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final items = <({DateTime date, double amount, String label, String notes})>[
      ...trips
          .where((t) => t.driverWage != null && t.driverWage! > 0)
          .map(
            (t) => (
        date: t.effectiveDate,
        amount: t.driverWage!,
        label: t.isNightOuting ? 'سهرة' : 'رحلة',
        notes: t.details,
        ),
      ),
      ...entries.map(
            (e) => (
        date: e.date,
        amount: e.amount,
        label: 'أجر إضافي',
        notes: e.notes,
        ),
      ),
    ]..sort((a, b) => b.date.compareTo(a.date));

    if (items.isEmpty) {
      return EmptyWageBox(title: 'لا توجد أجور مستحقة مسجلة');
    }

    return Column(
      children: items
          .map(
            (item) => Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: WageHistoryRow(
            date: item.date,
            amount: item.amount,
            notes: item.notes.isEmpty ? item.label : '${item.label} • ${item.notes}',
          ),
        ),
      )
          .toList(),
    );
  }
}
