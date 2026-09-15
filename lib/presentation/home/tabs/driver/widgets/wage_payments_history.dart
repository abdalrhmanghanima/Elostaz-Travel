import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_wage_payment_entity.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/widgets/empty_wage_box.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/widgets/wage_history_row.dart';
import 'package:flutter/material.dart';

class WagePaymentsHistory extends StatelessWidget {
  final List<DriverWagePaymentEntity> payments;

  const WagePaymentsHistory({super.key, required this.payments});

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return EmptyWageBox(title: 'لا يوجد سجل تسديد');
    }

    final sorted = [...payments]..sort((a, b) => b.date.compareTo(a.date));
    return Column(
      children: sorted
          .map(
            (p) => Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: WageHistoryRow(
            date: p.date,
            amount: p.amount,
            notes: p.notes,
          ),
        ),
      )
          .toList(),
    );
  }
}
