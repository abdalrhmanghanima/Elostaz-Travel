import 'dart:io';

import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_entity.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/provider/bus_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/widgets/add_trip_bottom_sheet.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/widgets/edit_bus_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BusActionsBottomSheet extends ConsumerWidget {
  const BusActionsBottomSheet({
    super.key,
    required this.drivers,
    required this.bus
  });

  final List<DriverEntity> drivers;
  final BusEntity bus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 20.w,
          vertical: 20.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 45.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),

            SizedBox(height: 20.h),

            InkWell(
              onTap: () async {
                Navigator.pop(context);

                await Future.delayed(
                  const Duration(milliseconds: 200),
                );

                if (!context.mounted) return;

                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) {
                    return AddTripBottomSheet(
                      drivers: drivers,
                      bus: bus,
                    );
                  },
                );
              },
              child: Row(
                children: [
                  Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20.sp,
                    color: Colors.grey,
                  ),
                  const Spacer(),
                  CustomText(
                    title: "إضافة رحلة",
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  SizedBox(width: 16.w),
                  Container(
                    width: 45.w,
                    height: 45.w,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: AppColors.primary,
                      size: 25.sp,
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 20.h),

            InkWell(
              onTap: () {
                Navigator.pop(context);

                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24.r),
                    ),
                  ),
                  builder: (_) {
                    return EditBusBottomSheet(
                      bus: bus,
                      onSave: ({
                        required String busName,
                        required DateTime licenseExpiryDate,
                        File? busImage,
                        File? licenseImage,
                      }) async {
                        final updatedBus = BusEntity(
                          id: bus.id,
                          busName: busName,
                          plateNumber: bus.plateNumber,
                          brand: bus.brand,
                          modelYear: bus.modelYear,
                          chassisNumber: bus.chassisNumber,
                          engineNumber: bus.engineNumber,
                          passengerCount: bus.passengerCount,
                          vehicleType: bus.vehicleType,
                          licenseExpiryDate: licenseExpiryDate,
                          licenseImageUrl: bus.licenseImageUrl,
                          busImageUrl: bus.busImageUrl,
                          specialConditions: bus.specialConditions,
                          insuranceType: bus.insuranceType,
                        );

                        final success = await ref
                            .read(busProvider.notifier)
                            .updateBus(
                          bus: updatedBus,
                        );

                        if (success) {
                          ref.invalidate(busProvider);
                        }

                        return success;
                      },
                    );
                  },
                );
              },
              child: Row(
                children: [
                  Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20.sp,
                    color: Colors.grey,
                  ),
                  const Spacer(),
                  CustomText(
                    title: "تعديل بيانات الأتوبيس",
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  SizedBox(width: 16.w),
                  Container(
                    width: 45.w,
                    height: 45.w,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.edit_outlined,
                      color: AppColors.primary,
                      size: 23.sp,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }
}