import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/core/utils/app_date_picker.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_entity.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/components/inputs/custom_text_form.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/provider/driver_wage_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddDriverWageBottomSheet extends ConsumerStatefulWidget {
  final DriverEntity driver;

  const AddDriverWageBottomSheet({
    super.key,
    required this.driver,
  });

  @override
  ConsumerState<AddDriverWageBottomSheet> createState() =>
      _AddDriverWageBottomSheetState();
}

class _AddDriverWageBottomSheetState
    extends ConsumerState<AddDriverWageBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

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
      helpText: 'اختر تاريخ الأجر',
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
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('من فضلك أدخل مبلغ صحيح')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await ref.read(driverWageNotifierProvider.notifier).addWageEntry(
          driverId: widget.driver.id,
          amount: amount,
          date: _selectedDate,
          notes: _notesController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context);
    } else {
      final error = ref.read(driverWageNotifierProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error?.toString() ?? 'حدث خطأ أثناء إضافة الأجر')),
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
                title: 'إضافة أجر',
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                fontColor: AppColors.primary,
              ),
            ),
            SizedBox(height: 6.h),
            Center(
              child: CustomText(
                title: widget.driver.name,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                fontColor: const Color(0xFF666A73),
              ),
            ),
            SizedBox(height: 20.h),
            CustomTextFormField(
              controller: _amountController,
              hint: 'المبلغ *',
              textInputType: const TextInputType.numberWithOptions(decimal: true),
              prefix: Icon(
                Icons.attach_money,
                size: 22.sp,
                color: const Color(0xFF777B85),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'من فضلك أدخل المبلغ';
                }
                final amount = double.tryParse(value.trim());
                if (amount == null || amount <= 0) {
                  return 'أدخل مبلغ صحيح أكبر من صفر';
                }
                return null;
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
                      title: 'التاريخ',
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
                        title: 'حفظ الأجر',
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
