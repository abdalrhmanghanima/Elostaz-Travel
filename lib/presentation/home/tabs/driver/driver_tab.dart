import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/navigator/navigator.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/core/utils/app_icons.dart';
import 'package:elostaz_travel/presentation/components/custom_app_bar/custom_app_bar.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/components/inputs/custom_text_form.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/driver_details_screen.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/provider/driver_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/widgets/add_driver_bottom_sheet.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/widgets/delete_driver_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DriversTab extends ConsumerStatefulWidget {
  const DriversTab({super.key});

  @override
  ConsumerState<DriversTab> createState() => _DriversTabState();
}

class _DriversTabState extends ConsumerState<DriversTab> {
  final TextEditingController searchController = TextEditingController();
  String normalizeArabic(String text) {
    return text
        .trim()
        .toLowerCase()
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي');
  }

  String searchQuery = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driverState = ref.watch(driversProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        showToolBar: true,
        bgColor: AppColors.primary,
        centerTitle: true,
        title: "السواقين",
        fontColor: AppColors.white,
        fontSize: 24.sp,
        iconPath: AppIcons.add,
        onPressed: () async {
          final result = await showModalBottomSheet<Map<String, dynamic>>(
            context: context,
            isScrollControlled: true,
            backgroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
            ),
            builder: (_) => const AddDriverBottomSheet(),
          );
          if (result == null) return;
          await ref
              .read(driversProvider.notifier)
              .addDriver(
                name: result['name'],
                phone: result['phone'],
                totalRevenue: result['totalRevenue'],
                tripsCount: result['tripsCount'],
              );
        },
        leadingHeight: 19.h,
      ),

      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.white,
        onRefresh: () async {
          await ref.read(driversProvider.notifier).getDrivers();
        },
        child: driverState.when(
          loading: () {
            return const Center(child: CircularProgressIndicator());
          },

          error: (error, stackTrace) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: 150.h),
                Center(
                  child: CustomText(
                    title: 'حدث خطأ أثناء تحميل السواقين',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          },

          data: (drivers) {
            final filteredDrivers = drivers.where((driver) {
              final driverName = normalizeArabic(driver.name);
              final query = normalizeArabic(searchQuery);

              return driverName.contains(query);
            }).toList();

            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                  child: CustomTextFormField(
                    controller: searchController,
                    hint: 'ابحث عن سواق',
                    onChange: (value) {
                      setState(() {
                        searchQuery = value.trim();
                      });
                    },
                    suffix: Icon(
                      Icons.search_rounded,
                      size: 22.sp,
                      color: AppColors.primary,
                    ),
                    bgColor: AppColors.inputBg,
                  ),
                ),
                Expanded(
                  child: filteredDrivers.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: 150.h),
                            Center(
                              child: CustomText(
                                title: searchQuery.isEmpty
                                    ? 'لا يوجد سواقين حتى الآن'
                                    : 'لا يوجد سواق بهذا الاسم',
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                fontColor: AppColors.primary,
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 27.h,
                          ),
                          itemCount: filteredDrivers.length,
                          separatorBuilder: (_, __) => SizedBox(height: 12.h),
                          itemBuilder: (context, index) {
                            final driver = filteredDrivers[index];

                            return InkWell(
                            onTap: () {
                              NavigatorHandler.push(DriverDetailsScreen(driver: driver));                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 20.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: const Color(0xFFE7E8EC),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(.04),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // ─────────────────────────────────────────
                                  // الإيرادات + حذف السائق
                                  // ─────────────────────────────────────────
                                  SizedBox(
                                    width: 105.w,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(left: 8.w),
                                          child: GestureDetector(
                                            onTap: () async {
                                              final shouldDelete =
                                              await showModalBottomSheet<bool>(
                                                context: context,
                                                isScrollControlled: true,
                                                backgroundColor: AppColors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.vertical(
                                                    top: Radius.circular(28.r),
                                                  ),
                                                ),
                                                builder: (_) {
                                                  return DeleteDriverBottomSheet(
                                                    driverName: driver.name,
                                                  );
                                                },
                                              );

                                              if (shouldDelete == true && context.mounted) {
                                                await ref
                                                    .read(driversProvider.notifier)
                                                    .deleteDriver(driver.id);
                                              }
                                            },
                                            child: Container(
                                              width: 38.w,
                                              height: 38.w,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFFF0F0),
                                                borderRadius: BorderRadius.circular(11.r),
                                              ),
                                              child: Icon(
                                                Icons.delete_outline_rounded,
                                                size: 21.sp,
                                                color: AppColors.red,
                                              ),
                                            ),
                                          ),
                                        ),

                                        SizedBox(height: 10.h),

                                        CustomText(
                                          title: ':إجمالي الإيرادات',
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w700,
                                          fontColor: AppColors.gray,
                                        ),

                                        SizedBox(height: 6.h),

                                        Container(
                                          width: double.infinity,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8.w,
                                            vertical: 5.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.backgroundGray,
                                            borderRadius: BorderRadius.circular(24.r),
                                          ),
                                          child: Directionality(
                                            textDirection: TextDirection.ltr,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Flexible(
                                                  child: CustomText(
                                                    title: driver.totalRevenue.toStringAsFixed(0),
                                                    fontSize: 14.sp,
                                                    fontWeight: FontWeight.w800,
                                                    fontColor: AppColors.primary,
                                                    maxLines: 1,
                                                  ),
                                                ),

                                                SizedBox(width: 3.w),

                                                CustomText(
                                                  title: 'ج.م',
                                                  fontSize: 12.sp,
                                                  fontWeight: FontWeight.w700,
                                                  fontColor: AppColors.primary,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  SizedBox(width: 10.w),

                                  // ─────────────────────────────────────────
                                  // بيانات السائق
                                  // ─────────────────────────────────────────
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        // اسم السائق
                                        CustomText(
                                          title: driver.name,
                                          textAlign: TextAlign.right,
                                          fontSize: 17.sp,
                                          fontWeight: FontWeight.w700,
                                          fontColor: AppColors.primary,
                                        ),

                                        SizedBox(height: 7.h),

                                        // رقم الهاتف
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            Flexible(
                                              child: CustomText(
                                                title: driver.phone,
                                                maxLines: 1,
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.w700,
                                                fontColor: const Color(0xFF666A73),
                                              ),
                                            ),

                                            SizedBox(width: 5.w),

                                            Icon(
                                              Icons.phone_outlined,
                                              size: 16.sp,
                                              color: const Color(0xFF777B85),
                                            ),
                                          ],
                                        ),

                                        SizedBox(height: 12.h),

                                        // عدد الرحلات
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10.w,
                                            vertical: 5.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.backgroundGray,
                                            borderRadius: BorderRadius.circular(24.r),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              CustomText(
                                                title: 'رحلات',
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.w700,
                                                fontColor: AppColors.primary,
                                              ),

                                              SizedBox(width: 3.w),

                                              CustomText(
                                                title: '${driver.tripsCount}',
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.w700,
                                                fontColor: AppColors.primary,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  SizedBox(width: 12.w),

                                  // ─────────────────────────────────────────
                                  // صورة السائق
                                  // ─────────────────────────────────────────
                                  Container(
                                    width: 60.w,
                                    height: 60.w,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF0F2F6),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.person_rounded,
                                      size: 33.sp,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      )
    );
  }
}
