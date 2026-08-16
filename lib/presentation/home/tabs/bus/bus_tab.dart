import 'package:elostaz_travel/core/dimens/dimens.dart';
import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/navigator/navigator.dart';
import 'package:elostaz_travel/core/utils/app_assets.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/core/utils/app_icons.dart';
import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/presentation/components/custom_app_bar/custom_app_bar.dart';
import 'package:elostaz_travel/presentation/components/custom_asset_image/custom_asset_image.dart';
import 'package:elostaz_travel/presentation/components/custom_svg/custom_svg_icon.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/components/inputs/custom_text_form.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/add_bus_screen.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/bus_details_screen.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/provider/bus_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/widgets/custom_valid_text_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BusTab extends ConsumerStatefulWidget {
  const BusTab({super.key});

  @override
  ConsumerState<BusTab> createState() => _BusTabState();
}

class _BusTabState extends ConsumerState<BusTab> {
  final searchController = TextEditingController();

  String searchQuery = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busesState = ref.watch(busProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        showToolBar: true,
        bgColor: AppColors.primary,
        centerTitle: true,
        title: "الأتوبيسات",
        fontColor: AppColors.white,
        fontSize: 24.sp,
        iconPath: AppIcons.add,
        onPressed: () {
          NavigatorHandler.push(AddBusScreen());
        },
        leadingHeight: 19.h,
      ),
      body: Padding(
        padding: EdgeInsets.only(
          top: 16.h,
          left: 16.w,
          right: 16.w,
        ),
        child: busesState.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => Center(
            child: CustomText(
              title: error.toString(),
              textAlign: TextAlign.center,
            ),
          ),
          data: (buses) {
            final filteredBuses = buses.where((bus) {
              final name = bus.busName.trim().toLowerCase();
              final query = searchQuery.trim().toLowerCase();

              return name.contains(query);
            }).toList();

            return Column(
              children: [
                CustomTextFormField(
                  controller: searchController,
                  hint: 'ابحث باسم الأتوبيس',
                  prefix: Icon(
                    Icons.search_rounded,
                    size: 23.sp,
                    color: const Color(0xFF777B85),
                  ),
                  onChange: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),

                SizedBox(height: 16.h),

                Expanded(
                  child: buses.isEmpty
                      ? const Center(
                    child: CustomText(
                      title: "لا يوجد أتوبيسات",
                    ),
                  )
                      : filteredBuses.isEmpty
                      ? const Center(
                    child: CustomText(
                      title: "لا يوجد أتوبيس بهذا الاسم",
                    ),
                  )
                      : ListView.builder(
                    itemCount: filteredBuses.length,
                    itemBuilder: (context, index) {
                      final bus = filteredBuses[index];

                      return _BusCard(
                        bus: bus,
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
}

class _BusCard extends StatelessWidget {
  final BusEntity bus;

  const _BusCard({
    required this.bus,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLicenseValid =
    bus.licenseExpiryDate.isAfter(DateTime.now());

    return GestureDetector(
      onTap: () => NavigatorHandler.push(BusDetailsScreen(bus: bus,)),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        width: Dimens.width,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 12.w,
            top: 8.h,
            right: 8.w,
            bottom: 8.h,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              CustomSvgIcon(
                assetName: AppIcons.arrowBack,
              ),

              SizedBox(width: 20.w),

              Expanded(
                child: CustomValidTextContainer(
                  text: isLicenseValid ? "ساري" : "منتهي",
                  fontColor: isLicenseValid
                      ? AppColors.black
                      : AppColors.red,
                  backgroundColor: isLicenseValid
                      ? AppColors.lightGreen
                      : AppColors.lightRed,
                ),
              ),
              SizedBox(width: 14.w,),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  CustomText(
                    title: bus.busName,
                    fontSize: 20.sp,
                  ),
                  CustomText(
                    title: "${bus.brand} - ${bus.modelYear}",
                    textAlign: TextAlign.end,
                  ),
                  CustomText(
                    title: bus.plateNumber,
                    textAlign: TextAlign.end,
                  ),

                ],
              ),

              SizedBox(width: 16.w),

              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: bus.busImageUrl != null &&
                    bus.busImageUrl!.isNotEmpty
                    ? Image.network(
                  bus.busImageUrl!,
                  width: 80.w,
                  height: 80.w,
                  fit: BoxFit.cover,
                )
                    : CustomAssetImage(
                  assetName: AppAssets.bus,
                  width: 80.w,
                  height: 80.w,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}