import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/navigator/navigator.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/core/utils/app_icons.dart';
import 'package:elostaz_travel/domain/factory/entity/factory_entity.dart';
import 'package:elostaz_travel/presentation/components/custom_app_bar/custom_app_bar.dart';
import 'package:elostaz_travel/presentation/components/custom_button/custom_button.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/components/inputs/custom_text_form.dart';
import 'package:elostaz_travel/presentation/home/tabs/factory/provider/factory_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddFactoryScreen extends ConsumerStatefulWidget {
  final FactoryEntity? factory;

  const AddFactoryScreen({
    super.key,
    this.factory,
  });

  @override
  ConsumerState<AddFactoryScreen> createState() => _AddFactoryScreenState();
}

class _AddFactoryScreenState extends ConsumerState<AddFactoryScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _detailsController;

  bool get _isEditing => widget.factory != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.factory?.name ?? '');
    _phoneController = TextEditingController(text: widget.factory?.phone ?? '');
    _detailsController =
        TextEditingController(text: widget.factory?.details ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final factoryState = ref.watch(factoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        showToolBar: true,
        bgColor: AppColors.primary,
        centerTitle: true,
        title: _isEditing ? "تعديل بيانات المصنع" : "إضافة مصنع جديد",
        fontColor: AppColors.white,
        fontSize: 22.sp,
        iconPath: AppIcons.arrowLeft,
        onPressed: () {
          NavigatorHandler.pop();
        },
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: 20.w,
          vertical: 24.h,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 90.w,
                  height: 90.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD0DCFF),
                      width: 2.w,
                    ),
                  ),
                  child: Icon(
                    _isEditing ? Icons.edit_note_rounded : Icons.factory_outlined,
                    size: 45.sp,
                    color: AppColors.primary,
                  ),
                ),
              ),

              SizedBox(height: 28.h),

              // Factory Name
              CustomText(
                title: 'اسم المصنع *',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                fontColor: const Color(0xFF444444),
              ),

              SizedBox(height: 8.h),

              CustomTextFormField(
                controller: _nameController,
                hint: 'أدخل اسم المصنع أو الشركة',
                prefix: Icon(
                  Icons.factory_outlined,
                  size: 22.sp,
                  color: const Color(0xFF777B85),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'من فضلك أدخل اسم المصنع';
                  }
                  return null;
                },
              ),

              SizedBox(height: 18.h),

              // Factory Phone
              CustomText(
                title: 'رقم الهاتف / التواصل (اختياري)',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                fontColor: const Color(0xFF444444),
              ),

              SizedBox(height: 8.h),

              CustomTextFormField(
                controller: _phoneController,
                hint: 'أدخل رقم هاتف المصنع أو مسؤول الحركة',
                textInputType: TextInputType.phone,
                prefix: Icon(
                  Icons.phone_outlined,
                  size: 22.sp,
                  color: const Color(0xFF777B85),
                ),
              ),

              SizedBox(height: 18.h),

              // Factory Details / Notes
              CustomText(
                title: 'تفاصيل / مواعيد الوردية / ملاحظات (اختياري)',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                fontColor: const Color(0xFF444444),
              ),

              SizedBox(height: 8.h),

              CustomTextFormField(
                controller: _detailsController,
                hint: 'مثال: مواعيد الشفتات، العنوان، أسماء المشرفين...',
                prefix: Icon(
                  Icons.notes_rounded,
                  size: 22.sp,
                  color: const Color(0xFF777B85),
                ),
              ),

              SizedBox(height: 36.h),

              // Save Button
              CustomButton(
                title: _isEditing ? 'حفظ التعديلات' : 'حفظ المصنع',
                width: double.infinity,
                height: 56.h,
                bg: AppColors.primary,
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                fontColor: AppColors.white,
                radius: 12.r,
                elevation: 0,
                isLoading: factoryState.isLoading,
                onTap: () async {
                  if (!_formKey.currentState!.validate()) {
                    return;
                  }

                  bool success;
                  if (_isEditing) {
                    final updated = FactoryEntity(
                      id: widget.factory!.id,
                      name: _nameController.text.trim(),
                      phone: _phoneController.text.trim(),
                      details: _detailsController.text.trim(),
                      tripsCount: widget.factory!.tripsCount,
                      totalRevenue: widget.factory!.totalRevenue,
                      createdAt: widget.factory!.createdAt,
                    );
                    success = await ref
                        .read(factoriesProvider.notifier)
                        .updateFactory(updated);
                  } else {
                    success = await ref
                        .read(factoriesProvider.notifier)
                        .addFactory(
                          name: _nameController.text.trim(),
                          phone: _phoneController.text.trim(),
                          details: _detailsController.text.trim(),
                          totalRevenue: 0,
                          tripsCount: 0,
                        );
                  }

                  if (!context.mounted) return;

                  if (success) {
                    NavigatorHandler.pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_isEditing
                            ? 'حدث خطأ أثناء تعديل بيانات المصنع'
                            : 'حدث خطأ أثناء حفظ المصنع'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
