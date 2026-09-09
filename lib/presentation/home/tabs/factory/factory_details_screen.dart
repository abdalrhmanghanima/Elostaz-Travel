import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/navigator/navigator.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/core/utils/app_icons.dart';
import 'package:elostaz_travel/core/utils/custom_loading.dart';
import 'package:elostaz_travel/domain/factory/entity/factory_entity.dart';
import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:elostaz_travel/presentation/components/custom_app_bar/custom_app_bar.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/widgets/trip_card.dart';
import 'package:elostaz_travel/presentation/home/tabs/factory/add_factory_screen.dart';
import 'package:elostaz_travel/presentation/home/tabs/factory/provider/factory_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/factory/widgets/add_factory_trip_bottom_sheet.dart';
import 'package:elostaz_travel/presentation/home/tabs/factory/widgets/factory_action_bottom_sheet.dart';
import 'package:elostaz_travel/presentation/home/tabs/all_trips/all_trips_page.dart';
import 'package:elostaz_travel/presentation/trip/provider/trip_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FactoryDetailsScreen extends ConsumerStatefulWidget {
  final FactoryEntity factory;

  const FactoryDetailsScreen({
    super.key,
    required this.factory,
  });

  @override
  ConsumerState<FactoryDetailsScreen> createState() =>
      _FactoryDetailsScreenState();
}

class _FactoryDetailsScreenState extends ConsumerState<FactoryDetailsScreen> {
  int _selectedFilterIndex = 0; // 0: الكل, 1: الرحلات, 2: السهرات

  @override
  Widget build(BuildContext context) {
    // Keep factory data updated from the provider list
    final factoriesList = ref.watch(factoriesProvider).valueOrNull;

    FactoryEntity currentFactory = widget.factory;

    if (factoriesList != null) {
      final match = factoriesList.where(
        (f) => f.id == widget.factory.id,
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
      factoryTripsLimitedProvider(currentFactory.id),
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
                      initialType: TripType.trip,
                    ),
                  );
                } else if (action == FactoryActionType.addNightOuting) {
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => AddFactoryTripBottomSheet(
                      factory: currentFactory,
                      initialType: TripType.nightOuting,
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
          ref.invalidate(factoryTripsLimitedProvider(currentFactory.id));
          await Future.wait([
            ref.read(factoriesProvider.notifier).getFactories(),
            ref.read(factoryTripsLimitedProvider(currentFactory.id).future),
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
            double totalRev = 0;
            double totalExp = 0;
            double totalDriverWages = 0;
            int tripsCount = 0;
            int nightOutingsCount = 0;

            for (final t in trips) {
              totalRev += t.revenue;
              totalExp += t.expenses;
              totalDriverWages += (t.driverWage ?? 0);
              if (t.isNightOuting) {
                nightOutingsCount++;
              } else {
                tripsCount++;
              }
            }
            final totalNet = totalRev - totalExp;

            final filteredTrips = trips.where((t) {
              if (_selectedFilterIndex == 1) return t.isTrip;
              if (_selectedFilterIndex == 2) return t.isNightOuting;
              return true;
            }).toList();

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
                          width: 76.w,
                          height: 76.w,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F4FF),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFD0DCFF),
                              width: 3.w,
                            ),
                          ),
                          child: Icon(
                            Icons.factory_rounded,
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

                        SizedBox(height: 6.h),

                        if (currentFactory.phone.trim().isNotEmpty) ...[
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
                          SizedBox(height: 6.h),
                        ],

                        if (currentFactory.details.trim().isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16.sp,
                                color: const Color(0xFF666A73),
                              ),
                              SizedBox(width: 5.w),
                              Flexible(
                                child: CustomText(
                                  title: currentFactory.details,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  fontColor: const Color(0xFF666A73),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),
                        ],

                        // Stats Grid: Trips, Night Outings, Revenue, Net
                        Row(
                          children: [
                            Expanded(
                              child: _FactoryStatItem(
                                title: 'الرحلات',
                                value: '$tripsCount',
                                icon: Icons.directions_bus_rounded,
                                iconColor: AppColors.primary,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: _FactoryStatItem(
                                title: 'السهرات',
                                value: '$nightOutingsCount',
                                icon: Icons.nightlight_round,
                                iconColor: AppColors.green,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: _FactoryStatItem(
                                title: 'إجمالي الإيراد',
                                value: '${totalRev.toStringAsFixed(0)} ج.م',
                                icon: Icons.attach_money_rounded,
                                iconColor: AppColors.primary,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: _FactoryStatItem(
                                title: 'الصافي',
                                value: '${totalNet.toStringAsFixed(0)} ج.م',
                                icon: Icons.account_balance_wallet_outlined,
                                iconColor: totalNet >= 0
                                    ? AppColors.green
                                    : AppColors.red,
                              ),
                            ),
                          ],
                        ),

                        if (totalDriverWages > 0) ...[
                          SizedBox(height: 10.h),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 10.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: const Color(0xFFFDE68A),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.badge_outlined,
                                      size: 18.sp,
                                      color: const Color(0xFFD97706),
                                    ),
                                    SizedBox(width: 8.w),
                                    CustomText(
                                      title: 'إجمالي أجور السائقين',
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                      fontColor: const Color(0xFF92400E),
                                    ),
                                  ],
                                ),
                                CustomText(
                                  title: '${totalDriverWages.toStringAsFixed(0)} ج.م',
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w800,
                                  fontColor: const Color(0xFFB45309),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // =================== ACTIONS (إضافة رحلة / إضافة سهرة) ===================
                  Row(
                    children: [
                      // إضافة رحلة
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => AddFactoryTripBottomSheet(
                                factory: currentFactory,
                                initialType: TripType.trip,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(
                              vertical: 12.h,
                              horizontal: 8.w,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
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
                      ),

                      SizedBox(width: 12.w),

                      // إضافة سهرة
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => AddFactoryTripBottomSheet(
                                factory: currentFactory,
                                initialType: TripType.nightOuting,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.green,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(
                              vertical: 12.h,
                              horizontal: 8.w,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          icon: Icon(
                            Icons.nightlight_round,
                            size: 16.sp,
                            color: Colors.white,
                          ),
                          label: CustomText(
                            title: 'إضافة سهرة',
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            fontColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  // =================== عرض الكل ===================
                  Padding(
                    padding: EdgeInsets.only(right: 28.w, left: 24.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () {
                            NavigatorHandler.push(
                              AllTripsPage(
                                entity: currentFactory,
                                title: 'رحلات ${currentFactory.name}',
                              ),
                            );
                          },
                          child: CustomText(
                            title: "عرض كل الرحلات؟",
                            fontWeight: FontWeight.w700,
                            fontSize: 14.sp,
                            fontColor: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        Spacer(),
                        CustomText(
                          title: "رحلات المصنع",
                          fontWeight: FontWeight.w700,
                          fontSize: 16.sp,
                        ),
                        SizedBox(width: 4.w),
                        Icon(
                          Icons.factory_outlined,
                          size: 16.sp,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 8.h),

                  // =================== FILTER TABS ===================
                  Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        _buildFilterButton(
                          index: 0,
                          label: 'الكل (${trips.length})',
                        ),
                        SizedBox(width: 4.w),
                        _buildFilterButton(
                          index: 1,
                          label: 'الرحلات ($tripsCount)',
                        ),
                        SizedBox(width: 4.w),
                        _buildFilterButton(
                          index: 2,
                          label: 'السهرات ($nightOutingsCount)',
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  if (filteredTrips.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 30.h),
                      child: Column(
                        children: [
                          Icon(
                            Icons.directions_bus_outlined,
                            size: 48.sp,
                            color: const Color(0xFFD1D5DB),
                          ),
                          SizedBox(height: 10.h),
                          CustomText(
                            title: _selectedFilterIndex == 2
                                ? 'لا توجد سهرات مسجلة لهذا المصنع'
                                : _selectedFilterIndex == 1
                                    ? 'لا توجد رحلات مسجلة لهذا المصنع'
                                    : 'لا توجد رحلات مسجلة لهذا المصنع حتى الآن',
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
                      itemCount: filteredTrips.length,
                      separatorBuilder: (_, _) => SizedBox(height: 12.h),
                      itemBuilder: (context, index) {
                        final trip = filteredTrips[index];
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

  Widget _buildFilterButton({
    required int index,
    required String label,
  }) {
    final isSelected = _selectedFilterIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilterIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9.r),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: CustomText(
            title: label,
            fontSize: 12.sp,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontColor: isSelected ? AppColors.primary : const Color(0xFF6B7280),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _FactoryStatItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _FactoryStatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 4.w,
        vertical: 8.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundGray,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14.sp,
            color: iconColor,
          ),
          SizedBox(height: 3.h),
          CustomText(
            title: title,
            fontSize: 9.5.sp,
            fontWeight: FontWeight.w600,
            fontColor: const Color(0xFF666A73),
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
          SizedBox(height: 3.h),
          CustomText(
            title: value,
            fontSize: 12.5.sp,
            fontWeight: FontWeight.w800,
            fontColor: AppColors.black,
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

