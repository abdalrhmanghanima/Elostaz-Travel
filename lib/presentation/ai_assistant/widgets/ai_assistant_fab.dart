import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:flutter/material.dart';

import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/presentation/ai_assistant/model/ai_entry_context.dart';
import 'package:elostaz_travel/presentation/ai_assistant/widgets/ai_assistant_sheet.dart';

class AiAssistantFab extends StatelessWidget {
  const AiAssistantFab({super.key, this.entryContext = const AiEntryContext()});

  final AiEntryContext entryContext;

  void _openAssistant(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => ScaffoldMessenger(
        child: AiAssistantSheet(entryContext: entryContext),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openAssistant(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58.w,
            height: 58.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
              border: Border.all(color: AppColors.white, width: 2.5.w),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 14,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.white,
                size: 27.w,
              ),
            ),
          ),

          SizedBox(height: 5.h),

          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'مساعدك الذكي',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                color: AppColors.white,
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
