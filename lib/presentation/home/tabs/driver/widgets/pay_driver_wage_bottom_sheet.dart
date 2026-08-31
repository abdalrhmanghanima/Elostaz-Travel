import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/core/utils/app_date_picker.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_entity.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_wage_balance.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/components/inputs/custom_text_form.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/provider/driver_wage_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PayDriverWageBottomSheet extends ConsumerStatefulWidget {
  final DriverEntity driver;
  final double outstanding;

  const PayDriverWageBottomSheet({
    super.key,
    required this.driver,
    required this.outstanding,
  });

  @override
  ConsumerState<PayDriverWageBottomSheet> createState() =>
      _PayDriverWageBottomSheetState();
}

class _PayDriverWageBottomSheetState
    extends ConsumerState<PayDriverWageBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  String _formatAmount(double amount) {
    return amount % 1 == 0 ? amount.toInt().toString() : amount.toString();
  }

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: _formatAmount(widget.outstanding),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await AppDatePicker.show(
      context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'اختر تاريخ التسديد',
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null) return;

    setState(() => _isLoading = true);

    final success =
        await ref.read(driverWageNotifierProvider.notifier).addWagePayment(
              driverId: widget.driver.id,
              amount: amount,
              date: _selectedDate,
              notes: _notesController.text.trim().isEmpty
                  ? (amount < widget.outstanding - 0.0001 ? 'دفعة جزئية' : '')
                  : _notesController.text.trim(),
            );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context);
    } else {
      final error = ref.read(driverWageNotifierProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error?.toString() ?? 'حدث خطأ أثناء تسديد الأجر'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20.w,
        12.h,
        20.w,
        MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).viewPadding.bottom +
            20.h,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Center(
              child: Container(
                width: 45.w,
                height: 5.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Center(
              child: CustomText(
                title: 'تسديد أجر السائق',
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                fontColor: AppColors.primary,
              ),
            ),
            SizedBox(height: 6.h),
            Center(
              child: CustomText(
                title:
                    'المتبقي للسائق: ${widget.outstanding.toStringAsFixed(0)} ج.م',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                fontColor: const Color(0xFFB45309),
              ),
            ),
            SizedBox(height: 20.h),
            CustomTextFormField(
              controller: _amountController,
              hint: 'المبلغ المراد تسديده *',
              textInputType: const TextInputType.numberWithOptions(decimal: true),
              prefix: Icon(
                Icons.payments_outlined,
                size: 22.sp,
                color: const Color(0xFF777B85),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'من فضلك أدخل المبلغ المراد تسديده';
                }
                final amount = double.tryParse(value.trim());
                if (amount == null) {
                  return 'أدخل مبلغ صحيح';
                }
                return DriverWageBalance.validatePayment(
                  amount: amount,
                  outstanding: widget.outstanding,
                );
              },
            ),
            SizedBox(height: 14.h),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: AppColors.inputBg,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 20.sp,
                      color: const Color(0xFF777B85),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: CustomText(
                        title: AppDateFormatter.format(_selectedDate),
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        textAlign: TextAlign.right,
                      ),
                    ),
                    CustomText(
                      title: 'تاريخ التسديد',
                      fontSize: 14.sp,
                      fontColor: const Color(0xFF777B85),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 14.h),
            CustomTextFormField(
              controller: _notesController,
              hint: 'ملاحظات (اختياري)',
              prefix: Icon(
                Icons.notes_rounded,
                size: 22.sp,
                color: const Color(0xFF777B85),
              ),
            ),
            SizedBox(height: 22.h),
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 22.w,
                        height: 22.h,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : CustomText(
                        title: 'تأكيد التسديد',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        fontColor: Colors.white,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
