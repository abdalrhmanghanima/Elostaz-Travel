import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:flutter/material.dart';

import 'package:elostaz_travel/core/utils/app_colors.dart';

class AiChatMessage extends StatelessWidget {
  const AiChatMessage({
    super.key,
    required this.message,
    required this.isUser,
  });

  final String message;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser
          ? AlignmentDirectional.centerStart
          : AlignmentDirectional.centerEnd,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 12.h,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.primary
              : const Color(0xFFF1F3F5),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18.r),
            topRight: Radius.circular(18.r),
            bottomLeft: Radius.circular(
              isUser ? 18.r : 4.r,
            ),
            bottomRight: Radius.circular(
              isUser ? 4.r : 18.r,
            ),
          ),
        ),
        child: Text(
          message,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 15.sp,
            height: 1.5,
            fontWeight: FontWeight.w500,
            color: isUser
                ? AppColors.white
                : AppColors.black,
          ),
        ),
      ),
    );
  }
}