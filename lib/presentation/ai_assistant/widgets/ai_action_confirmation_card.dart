import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:flutter/material.dart';

import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/domain/ai_assistant/entity/ai_trip_draft.dart';
import 'package:elostaz_travel/presentation/ai_assistant/model/ai_action_option.dart';
import 'package:elostaz_travel/presentation/ai_assistant/model/ai_guided_field.dart';

class AiActionConfirmationCard extends StatelessWidget {
  const AiActionConfirmationCard({
    super.key,
    required this.onConfirm,
    required this.onEdit,
    required this.onCancel,
    required this.isConfirming,
    required this.canConfirm,
    required this.draft,
  });

  final VoidCallback onConfirm;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final bool isConfirming;
  final bool canConfirm;
  final AiTripDraft draft;

  @override
  Widget build(BuildContext context) {
    final isNightOuting = draft.type == 'night_outing';
    final title = isNightOuting ? 'إنشاء سهرة جديدة' : 'إنشاء رحلة جديدة';

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isNightOuting
                      ? Icons.nightlight_round
                      : Icons.directions_bus_rounded,
                  color: AppColors.primary,
                  size: 22.w,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          _InfoRow(
            label: 'الأتوبيس',
            value: draft.busName != null
                ? '${draft.busName}${draft.plateNumber != null ? ' (${draft.plateNumber})' : ''}'
                : '-',
            icon: Icons.directions_bus_outlined,
          ),

          _InfoRow(
            label: 'السواق',
            value: draft.driverName ?? '-',
            icon: Icons.person_outline_rounded,
          ),

          _InfoRow(
            label: 'النوع',
            value: isNightOuting ? 'سهرة' : 'رحلة',
            icon: isNightOuting
                ? Icons.nightlight_round
                : Icons.directions_bus_outlined,
          ),

          if (draft.factoryName != null)
            _InfoRow(
              label: 'المصنع',
              value: draft.factoryName!,
              icon: Icons.factory_outlined,
            ),

          if (draft.tripDate != null)
            _InfoRow(
              label: 'التاريخ',
              value: _formatDate(draft.tripDate!),
              icon: Icons.calendar_today_outlined,
            ),

          if (draft.departureTime != null &&
              draft.departureTime!.isNotEmpty)
            _InfoRow(
              label: 'المغادرة',
              value: draft.departureTime!,
              icon: Icons.access_time_rounded,
            ),

          if (draft.revenue != null)
            _InfoRow(
              label: 'الايراد',
              value: '${draft.revenue!.toInt()} ج.م',
              icon: Icons.payments_outlined,
            ),

          if (draft.driverWage != null)
            _InfoRow(
              label: 'أجر السواق',
              value: '${draft.driverWage!.toInt()} ج.م',
              icon: Icons.account_balance_wallet_outlined,
            ),

          if (draft.details != null && draft.details!.isNotEmpty)
            _InfoRow(
              label: 'التفاصيل',
              value: draft.details!,
              icon: Icons.notes_rounded,
            ),

          if (draft.expenses != null)
            _InfoRow(
              label: 'مصروف الرحلة',
              value: '${draft.expenses!.toInt()} ج.م',
              icon: Icons.receipt_long_outlined,
            ),

          if (draft.expenseDetails != null &&
              draft.expenseDetails!.isNotEmpty)
            _InfoRow(
              label: 'تفاصيل المصروف',
              value: draft.expenseDetails!,
              icon: Icons.money_off_outlined,
            ),

          SizedBox(height: 14.h),

          Text(
            'هل تريد تنفيذ هذا الطلب؟',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: 12.h),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isConfirming ? null : onEdit,
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(
                      double.infinity,
                      46.h,
                    ),
                    side: BorderSide(
                      color: AppColors.primary,
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'تعديل',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              SizedBox(width: 10.w),

              Expanded(
                child: OutlinedButton(
                  onPressed: isConfirming ? null : onCancel,
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(
                      double.infinity,
                      46.h,
                    ),
                    side: BorderSide(
                      color: Colors.redAccent.shade100,
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'إلغاء',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 10.h),

          ElevatedButton(
            onPressed: (canConfirm && !isConfirming) ? onConfirm : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
              minimumSize: Size(
                double.infinity,
                48.h,
              ),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: isConfirming
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'جاري إضافة الرحلة...',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'تأكيد وتنفيذ',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      '',
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 11.h),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(
            icon,
            size: 19.w,
            color: AppColors.primary,
          ),

          SizedBox(width: 9.w),

          Text(
            '$label:',
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),

          SizedBox(width: 6.w),

          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AiCreateConfirmationCard extends StatelessWidget {
  const AiCreateConfirmationCard({
    super.key,
    required this.action,
    required this.values,
    required this.onConfirm,
    required this.onEdit,
    required this.onCancel,
    required this.isConfirming,
    required this.canConfirm,
  });

  final AiActionId action;
  final Map<String, String> values;
  final VoidCallback onConfirm;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final bool isConfirming;
  final bool canConfirm;

  @override
  Widget build(BuildContext context) {
    final (title, icon) = switch (action) {
      AiActionId.addBus => ('تأكيد إضافة أتوبيس', Icons.directions_bus_rounded),
      AiActionId.addDriver => ('تأكيد إضافة سائق', Icons.person_add_alt_1_rounded),
      AiActionId.addFactory => ('تأكيد إضافة مصنع', Icons.factory_outlined),
      _ => ('تأكيد الإضافة', Icons.add_circle_outline_rounded),
    };

    final option = availableAiActions.firstWhere(
      (o) => o.id == action,
      orElse: () => availableAiActions.first,
    );

    final fields = [...option.requiredFields, ...option.optionalFields];

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 22.w,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          for (final f in fields)
            if (values.containsKey(f.name) && values[f.name]!.isNotEmpty)
              _InfoRow(
                label: f.label,
                value: values[f.name]!,
                icon: Icons.check_circle_outline_rounded,
              ),

          for (final entry in values.entries)
            if (entry.value.isNotEmpty &&
                !fields.any((f) => f.name == entry.key))
              _InfoRow(
                label: AiGuidedField.byName(entry.key)?.label ?? entry.key,
                value: entry.value,
                icon: Icons.check_circle_outline_rounded,
              ),

          SizedBox(height: 14.h),

          Text(
            'هل تريد حفظ هذه البيانات؟',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: 12.h),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isConfirming ? null : onEdit,
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(
                      double.infinity,
                      46.h,
                    ),
                    side: BorderSide(
                      color: AppColors.primary,
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'تعديل',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              SizedBox(width: 10.w),

              Expanded(
                child: OutlinedButton(
                  onPressed: isConfirming ? null : onCancel,
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(
                      double.infinity,
                      46.h,
                    ),
                    side: BorderSide(
                      color: Colors.redAccent.shade100,
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'إلغاء',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 10.h),

          ElevatedButton(
            onPressed: (canConfirm && !isConfirming) ? onConfirm : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              disabledBackgroundColor:
                  AppColors.primary.withValues(alpha: 0.6),
              minimumSize: Size(
                double.infinity,
                48.h,
              ),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: isConfirming
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'جاري الحفظ...',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'تأكيد وتنفيذ',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}