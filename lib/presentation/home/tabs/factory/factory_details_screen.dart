import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/navigator/navigator.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/core/utils/app_icons.dart';
import 'package:elostaz_travel/core/utils/custom_loading.dart';
import 'package:elostaz_travel/domain/factory/entity/factory_entity.dart';
import 'package:elostaz_travel/presentation/components/custom_app_bar/custom_app_bar.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/widgets/trip_card.dart';
import 'package:elostaz_travel/presentation/home/tabs/factory/add_factory_screen.dart';
import 'package:elostaz_travel/presentation/home/tabs/factory/provider/factory_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/factory/widgets/add_factory_trip_bottom_sheet.dart';
import 'package:elostaz_travel/presentation/home/tabs/factory/widgets/factory_action_bottom_sheet.dart';
import 'package:elostaz_travel/presentation/home/tabs/factory/widgets/factory_monthly_report_service.dart';
import 'package:elostaz_travel/presentation/trip/provider/trip_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FactoryDetailsScreen extends ConsumerWidget {
  final FactoryEntity factory;

  const FactoryDetailsScreen({
    super.key,
    required this.factory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep factory data updated from the provider list
    final factoriesList = ref.watch(factoriesProvider).valueOrNull;

    FactoryEntity currentFactory = factory;

    if (factoriesList != null) {
      final match = factoriesList.where(
            (f) => f.id == factory.id,
      );

      if (match.isNotEmpty) {
        final model = match.first;

        currentFactory = FactoryEntity(
          id: model.id,
          name: model.name,
          phone: model.phone,
          details: model.details,
          tripsCount: model.tripsCount,
          totalRevenue: model.totalRevenue,
          createdAt: model.createdAt,
        );
      }
    }

    final tripsState = ref.watch(
      factoryTripsProvider(currentFactory.id),
    );

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        showToolBar: true,
        bgColor: AppColors.primary,
        centerTitle: true,
        title: 'بيانات المصنع',
        fontColor: AppColors.white,
        fontSize: 22.sp,
        iconPath: AppIcons.arrowLeft,
        onPressed: () {
          NavigatorHandler.pop();
        },
        actions: [
          IconButton(
            onPressed: tripsState.hasValue
                ? () async {
                    final trips = tripsState.valueOrNull ?? [];
                    await FactoryMonthlyReportService.shareFactoryReport(
                      factory: currentFactory,
                      trips: trips,
                    );
                  }
                : null,
            icon: Icon(
              Icons.print_outlined,
              color: AppColors.white,
              size: 24.sp,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 4.w),
            child: InkWell(
              borderRadius: BorderRadius.circular(22.r),
              onTap: () async {
                final action = await showModalBottomSheet<FactoryActionType>(
                  context: context,
                  backgroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24.r),
                    ),
                  ),
                  builder: (_) => const FactoryActionsBottomSheet(),
                );

                if (action == null || !context.mounted) return;

                if (action == FactoryActionType.addTrip) {
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => AddFactoryTripBottomSheet(
                      factory: currentFactory,
                    ),
                  );
                } else if (action == FactoryActionType.editFactory) {
                  NavigatorHandler.push(
                    AddFactoryScreen(factory: currentFactory),
                  );
                } else if (action == FactoryActionType.deleteFactory) {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dialogCtx) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      title: const Text(
                        'حذف المصنع',
                        textAlign: TextAlign.right,
                      ),
                      content: Text(
                        'هل أنت متأكد من حذف ${currentFactory.name}؟',
                        textAlign: TextAlign.right,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogCtx, false),
                          child: const Text('إلغاء'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogCtx, true),
                          child: const Text(
                            'حذف',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    final success = await ref
                        .read(factoriesProvider.notifier)
                        .deleteFactory(currentFactory.id);

                    if (context.mounted && success) {
                      NavigatorHandler.pop();
                    }
                  }
                }
              },
              child: Padding(
                padding: EdgeInsets.all(8.w),
                child: Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.white,
                  size: 24.sp,
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.white,
        onRefresh: () async {
          await Future.wait([
            ref.read(factoriesProvider.notifier).getFactories(),
            ref.refresh(factoryTripsProvider(currentFactory.id).future),
          ]);
        },
        child: tripsState.when(
          loading: () => const Center(
            child: CustomLoading(),
          ),
          error: (error, stackTrace) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: 150.h),
              Center(
                child: CustomText(
                  title: 'حدث خطأ في تحميل رحلات المصنع',
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          data: (trips) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: 20.w,
                vertical: 20.h,
              ),
              child: Column(
                children: [
                  // =================== FACTORY INFO CARD ===================
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 18.w,
                      vertical: 18.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(
                        color: const Color(0xFFE7E8EC),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .04),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 82.w,
                          height: 82.w,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F4FF),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFD0DCFF),
                              width: 3.w,
                            ),
                          ),
                          child: Icon(
                            Icons.factory_outlined,
                            size: 42.sp,
                            color: AppColors.primary,
                          ),
                        ),

                        SizedBox(height: 12.h),

                        CustomText(
                          title: currentFactory.name,
                          fontSize: 19.sp,
                          fontWeight: FontWeight.w700,
                          fontColor: AppColors.primary,
                        ),

                        if (currentFactory.phone.isNotEmpty) ...[
                          SizedBox(height: 6.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomText(
                                title: currentFactory.phone,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                fontColor: const Color(0xFF666A73),
                              ),
                              SizedBox(width: 5.w),
                              Icon(
                                Icons.phone_outlined,
                                size: 16.sp,
                                color: const Color(0xFF666A73),
                              ),
                            ],
                          ),
                        ],

                        if (currentFactory.details.isNotEmpty) ...[
                          SizedBox(height: 10.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: CustomText(
                              title: currentFactory.details,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              fontColor: const Color(0xFF4B5563),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],

                        SizedBox(height: 18.h),

                        Row(
                          children: [
                            Expanded(
                              child: _FactoryStatItem(
                                title: 'إجمالي الإيرادات',
                                value:
                                    '${currentFactory.totalRevenue.toStringAsFixed(0)} ج.م',
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _FactoryStatItem(
                                title: 'الرحلات / الشفتات',
                                value: '${currentFactory.tripsCount}',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // =================== TRIPS SECTION ===================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          await showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => AddFactoryTripBottomSheet(
                              factory: currentFactory,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 8.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                        icon: Icon(
                          Icons.add_rounded,
                          size: 18.sp,
                          color: Colors.white,
                        ),
                        label: CustomText(
                          title: 'إضافة رحلة',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          fontColor: Colors.white,
                        ),
                      ),
                      CustomText(
                        title: 'رحلات وشفتات المصنع',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        fontColor: AppColors.primary,
                      ),
                    ],
                  ),

                  SizedBox(height: 12.h),

                  if (trips.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 40.h),
                      child: Column(
                        children: [
                          Icon(
                            Icons.directions_bus_outlined,
                            size: 48.sp,
                            color: const Color(0xFFD1D5DB),
                          ),
                          SizedBox(height: 10.h),
                          CustomText(
                            title: 'لا توجد رحلات مسجلة لهذا المصنع حتى الآن',
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            fontColor: const Color(0xFF777B85),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: trips.length,
                      separatorBuilder: (_, _) => SizedBox(height: 12.h),
                      itemBuilder: (context, index) {
                        final trip = trips[index];
                        return TripCard(
                          trip: trip,
                          showBus: true,
                        );
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FactoryStatItem extends StatelessWidget {
  final String title;
  final String value;

  const _FactoryStatItem({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 8.w,
        vertical: 10.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundGray,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomText(
            title: title,
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            fontColor: const Color(0xFF666A73),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 5.h),
          CustomText(
            title: value,
            fontSize: 17.sp,
            fontWeight: FontWeight.w800,
            fontColor: AppColors.primary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
