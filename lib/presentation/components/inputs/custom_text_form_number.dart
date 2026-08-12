import 'package:elostaz_travel/core/dimens/dimens.dart';
import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/core/utils/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
class CustomTextFormFieldNumber extends StatelessWidget {
  final String? hint;
  final TextEditingController controller;
  final Widget? prefix;
  final Widget? suffix;
  final bool readOnly;
  final Color? bgColor;
  final double? borderRaduis;
  final ValueChanged<String>? onChange;
  final String? Function(String?)? validator;

  const CustomTextFormFieldNumber({super.key,required this.controller,this.hint,this.prefix,this.suffix,this.readOnly = false,this.bgColor, this.onChange, this.borderRaduis,this.validator});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:  EdgeInsets.symmetric(horizontal: Dimens.padding_16h),
      height: 56.h,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bgColor??AppColors.inputBg,borderRadius: BorderRadius.circular(borderRaduis??16.r)),
      child: TextFormField(
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        readOnly:readOnly ,
        controller: controller,
        validator: validator,
        textAlignVertical: TextAlignVertical.center,
        cursorColor: AppColors.primary,
        style: AppTextStyles().normalText().textColorNormal(AppColors.black),
        keyboardType: const TextInputType.numberWithOptions(signed: false,decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+.?\d{0,1}'))],
        onChanged: onChange,
        decoration: InputDecoration(

          border: InputBorder.none,
          hintText: hint,
          hintTextDirection: TextDirection.rtl,
          hintStyle: AppTextStyles().normalText().textColorNormal(AppColors.inputHint),
          suffixIcon: suffix,
          prefixIcon: prefix,
          suffixIconConstraints:   BoxConstraints(maxHeight: 24.h,maxWidth:96.w,minWidth: 45.w,),
          prefixIconConstraints:  BoxConstraints(maxHeight: 24.h,maxWidth:96.w,minWidth: 45.w),
          counterText: '',

        ),
      ),
    );
  }
}
