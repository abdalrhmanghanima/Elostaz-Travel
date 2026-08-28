import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/navigator/navigator.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/core/utils/app_icons.dart';
import 'package:elostaz_travel/core/utils/custom_loading.dart';
import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/presentation/components/custom_app_bar/custom_app_bar.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/widgets/bus_info_card.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/widgets/bus_monthly_report_service.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/widgets/trip_card.dart';
import 'package:elostaz_travel/presentation/trip/provider/trip_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TripFilterType {
  all(title: 'الكل'),
  trips(title: 'الرحلات'),
  nightOutings(title: 'السهرات');

  final String title;
  const TripFilterType({required this.title});
}

class BusTripsScreen extends ConsumerStatefulWidget {
  const BusTripsScreen({
    super.key,
    required this.bus,
  });

  final BusEntity bus;

  @override
  ConsumerState<BusTripsScreen> createState() => _BusTripsScreenState();
}

class _BusTripsScreenState extends ConsumerState<BusTripsScreen> {
  TripFilterType selectedFilter = TripFilterType.all;

  @override
  Widget build(BuildContext context) {
    final tripsState = ref.watch(
      busTripsProvider(widget.bus.id!),
    );

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        showToolBar: true,
        bgColor: AppColors.primary,
        centerTitle: true,
        title: 'العمليات والرحلات',
        fontColor: AppColors.white,
        fontSize: 22.sp,
        iconPath: AppIcons.arrowLeft,
        onPressed: () {
          NavigatorHandler.pop();
        },
        actions: [
          IconButton(
            onPressed: () {
              tripsState.whenData(
                (trips) {
                  BusMonthlyReportService.shareCurrentMonthReport(
                    bus: widget.bus,
                    trips: trips,
                  );
                },
              );
            },
            icon: Icon(
              Icons.print_outlined,
              color: AppColors.white,
              size: 24.sp,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.white,
        onRefresh: () async {
          ref.invalidate(busTripsProvider(widget.bus.id!));
          await ref.read(busTripsProvider(widget.bus.id!).future);
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
                  title: 'حدث خطأ في تحميل العمليات',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          data: (trips) {
            final tripsCount = trips.where((t) => t.isTrip).length;
            final nightOutingsCount = trips.where((t) => t.isNightOuting).length;

            final filteredTrips = trips.where((t) {
              if (selectedFilter == TripFilterType.trips) {
                return t.isTrip;
              } else if (selectedFilter == TripFilterType.nightOutings) {
                return t.isNightOuting;
              }
              return true;
            }).toList();

            return Column(
              children: [
                BusInfoCard(bus: widget.bus),

                // Filter Tabs: الكل | الرحلات | السهرات
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        _buildFilterTab(
                          type: TripFilterType.all,
                          label: 'الكل (${trips.length})',
                          isSelected: selectedFilter == TripFilterType.all,
                        ),
                        SizedBox(width: 4.w),
                        _buildFilterTab(
                          type: TripFilterType.trips,
                          label: 'الرحلات ($tripsCount)',
                          isSelected: selectedFilter == TripFilterType.trips,
                        ),
                        SizedBox(width: 4.w),
                        _buildFilterTab(
                          type: TripFilterType.nightOutings,
                          label: 'السهرات ($nightOutingsCount)',
                          isSelected: selectedFilter == TripFilterType.nightOutings,
                        ),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: filteredTrips.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: 80.h),
                            Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.directions_bus_outlined,
                                    size: 48.sp,
                                    color: const Color(0xFFD1D5DB),
                                  ),
                                  SizedBox(height: 10.h),
                                  CustomText(
                                    title: selectedFilter == TripFilterType.nightOutings
                                        ? 'لا توجد سهرات مسجلة لهذا الأتوبيس'
                                        : selectedFilter == TripFilterType.trips
                                            ? 'لا توجد رحلات مسجلة لهذا الأتوبيس'
                                            : 'لا توجد عمليات لهذا الأتوبيس',
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w600,
                                    fontColor: const Color(0xFF777B85),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            16.w,
                            4.h,
                            16.w,
                            16.h,
                          ),
                          itemCount: filteredTrips.length,
                          itemBuilder: (context, index) {
                            final trip = filteredTrips[index];
                            return TripCard(
                              trip: trip,
                              busId: widget.bus.id!,
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterTab({
    required TripFilterType type,
    required String label,
    required bool isSelected,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedFilter = type;
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