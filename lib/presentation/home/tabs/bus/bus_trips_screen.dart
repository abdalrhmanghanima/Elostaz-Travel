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
import 'package:elostaz_travel/presentation/home/tabs/bus/widgets/trip_actions_bottom_sheet.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/widgets/trip_card.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/provider/driver_provider.dart';
import 'package:elostaz_travel/presentation/trip/provider/trip_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BusTripsScreen extends ConsumerWidget {
  const BusTripsScreen({
    super.key,
    required this.bus,
  });

  final BusEntity bus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsState = ref.watch(
      busTripsProvider(bus.id!),
    );

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        showToolBar: true,
        bgColor: AppColors.primary,
        centerTitle: true,
        title: 'كل الرحلات',
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
                  BusMonthlyReportService
                      .shareCurrentMonthReport(
                    bus: bus,
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
      body: tripsState.when(
        loading: () => const Center(
          child: CustomLoading(),
        ),
        error: (error, stackTrace) => Center(
          child: CustomText(
            title: 'حدث خطأ في تحميل الرحلات',
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        data: (trips) {
          if (trips.isEmpty) {
            return Column(
              children: [
                BusInfoCard(bus: bus),
                Expanded(
                  child: Center(
                    child: CustomText(
                      title: 'لا توجد رحلات لهذا الأتوبيس',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              BusInfoCard(bus: bus),

              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    16.w,
                    4.h,
                    16.w,
                    16.h,
                  ),
                  itemCount: trips.length,
                  itemBuilder: (context, index) {
                    final trip = trips[index];

                    return InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24.r),
                            ),
                          ),
                          builder: (_) {
                            return TripActionsBottomSheet(
                              onDelete: () async {
                                Navigator.pop(context);

                                final success = await ref
                                    .read(tripProvider.notifier)
                                    .deleteTrip(trip.id);

                                if (success) {
                                  ref.invalidate(
                                    busTripsProvider(bus.id!),
                                  );

                                  ref.invalidate(
                                    driverTripsProvider(trip.driverId),
                                  );

                                  ref.invalidate(
                                    driversProvider,
                                  );
                                }
                              },
                            );
                          },
                        );
                      },
                      child: TripCard(
                        trip: trip,
                        busId: bus.id!,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}