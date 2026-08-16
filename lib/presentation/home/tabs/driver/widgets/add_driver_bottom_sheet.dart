import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/components/inputs/custom_text_form.dart';
import 'package:flutter/material.dart';

class AddDriverBottomSheet extends StatefulWidget {
  const AddDriverBottomSheet({super.key});

  @override
  State<AddDriverBottomSheet> createState() => _AddDriverBottomSheetState();
}

class _AddDriverBottomSheetState extends State<AddDriverBottomSheet> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final revenueController = TextEditingController();
  final tripsController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    revenueController.dispose();
    tripsController.dispose();
    super.dispose();
  }

  void submit() {
    if (!formKey.currentState!.validate()) return;

    final double totalRevenue =
        double.tryParse(revenueController.text.trim()) ?? 0;

    final int tripsCount = int.tryParse(tripsController.text.trim()) ?? 0;

    Navigator.pop(context, {
      'name': nameController.text.trim(),
      'phone': phoneController.text.trim(),
      'totalRevenue': totalRevenue,
      'tripsCount': tripsCount,
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20.w,
          12.h,
          20.w,
          MediaQuery.of(context).viewInsets.bottom + 20.h,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 45.w,
                height: 5.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              SizedBox(height: 20.h),
              CustomText(
                title: 'إضافة سواق جديد',
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                fontColor: AppColors.primary,
              ),
              SizedBox(height: 20.h),
              CustomTextFormField(
                controller: nameController,
                hint: 'اسم السواق',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'من فضلك أدخل اسم السواق';
                  }
                  return null;
                },
              ),

              SizedBox(height: 12.h),
              CustomTextFormField(
                controller: phoneController,
                hint: 'رقم التليفون',
                textInputType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'من فضلك أدخل رقم التليفون';
                  }
                  return null;
                },
              ),

              SizedBox(height: 12.h),

              CustomTextFormField(
                controller: revenueController,
                hint: 'إجمالي الإيراد',
                textInputType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),

              SizedBox(height: 12.h),

              CustomTextFormField(
                controller: tripsController,
                hint: 'عدد الرحلات',
                textInputType: TextInputType.number,
              ),

              SizedBox(height: 20.h),

              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: CustomText(
                    title: 'إضافة السواق',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    fontColor: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
