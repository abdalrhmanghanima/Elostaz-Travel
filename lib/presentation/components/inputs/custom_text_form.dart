import 'package:elostaz_travel/core/dimens/dimens.dart';
import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/core/utils/text_styles.dart';
import 'package:flutter/material.dart';

class CustomTextFormField extends StatelessWidget {
  final String? hint;
  final TextInputType? textInputType;
  final TextEditingController controller;
  final Widget? prefix;
  final Widget? suffix;
  final bool readOnly;
  final Color? bgColor;
  final double? borderRaduis;
  final ValueChanged<String>? onChange;
  final FocusNode? focusNode;
  final void Function()? onTap;
  final String? Function(String?)? validator;
  final bool obscureText;

  const CustomTextFormField({
    super.key,
    required this.controller,
    this.hint,
    this.prefix,
    this.suffix,
    this.textInputType,
    this.readOnly = false,
    this.bgColor,
    this.onChange,
    this.borderRaduis,
    this.focusNode,
    this.onTap,
    this.validator,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimens.padding_16h,
      ),
      decoration: BoxDecoration(
        color: bgColor ?? AppColors.inputBg,
        borderRadius: BorderRadius.circular(
          borderRaduis ?? 16.r,
        ),
      ),
      child: TextFormField(
        focusNode: focusNode,
        onTap: onTap,
        readOnly: readOnly,
        controller: controller,
        validator: validator,
        obscureText: obscureText,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        textAlignVertical: TextAlignVertical.center,
        cursorColor: AppColors.primary,
        style: AppTextStyles()
            .normalText()
            .textColorNormal(AppColors.black),
        keyboardType: textInputType ?? TextInputType.text,
        onChanged: onChange,

        decoration: InputDecoration(
          border: InputBorder.none,

          hintText: hint,
          hintStyle: AppTextStyles()
              .normalText()
              .textColorNormal(AppColors.inputHint),

          suffixIcon: suffix,
          prefixIcon: prefix,

          suffixIconConstraints: BoxConstraints(
            maxHeight: 24.h,
            maxWidth: 96.w,
            minWidth: 45.w,
          ),

          prefixIconConstraints: BoxConstraints(
            maxHeight: 21.h,
            maxWidth: 96.w,
            minWidth: 9.w,
          ),

          counterText: '',

          // مهم جدًا
          // يخلي الـ input نفسه ثابت و الـ hint في مكانه
          contentPadding: EdgeInsets.symmetric(
            vertical: 16.h,
          ),

          // Error message
          errorStyle: TextStyle(
            fontSize: 11.sp,
            height: 1.2,
            color: AppColors.red,
          ),

          errorMaxLines: 2,
        ),
      ),
    );
  }
}
