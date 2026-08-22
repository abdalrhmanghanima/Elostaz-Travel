import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/navigator/navigator.dart';
import 'package:elostaz_travel/core/services/driver_local_image_service.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/core/utils/app_icons.dart';
import 'package:elostaz_travel/core/utils/custom_loading.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_advance_entity.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_entity.dart';
import 'package:elostaz_travel/presentation/components/custom_app_bar/custom_app_bar.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/widgets/trip_card.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/provider/driver_advance_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/provider/driver_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/widgets/add_driver_advance_bottom_sheet.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/widgets/driver_monthly_report_service.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/widgets/edit_driver_bottom_sheet.dart';
import 'package:elostaz_travel/presentation/trip/provider/trip_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class DriverDetailsScreen extends ConsumerWidget {
  final DriverEntity driver;

  const DriverDetailsScreen({
    super.key,
    required this.driver,
  });

  Future<void> _pickAndSaveImage({
    required BuildContext context,
    required WidgetRef ref,
    required bool isIdCard,
  }) async {
    final picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                title: isIdCard ? 'اختر صورة البطاقة' : 'اختر صورة الرخصة',
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                fontColor: AppColors.primary,
              ),
              SizedBox(height: 16.h),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                ),
                title: const Text('الكاميرا'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Icon(Icons.photo_library_outlined, color: AppColors.primary),
                ),
                title: const Text('المعرض'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (picked != null) {
        final file = File(picked.path);
        if (isIdCard) {
          await DriverLocalImageService.instance.saveIdCardImage(driver.id, file);
        } else {
          await DriverLocalImageService.instance.saveLicenseImage(driver.id, file);
        }
        ref.invalidate(driverLocalImagesProvider(driver.id));
      }
    } catch (e) {
      debugPrint('Error picking driver image: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drivers = ref.watch(driversProvider).valueOrNull;
    DriverEntity currentDriver = driver;
    if (drivers != null) {
      final index = drivers.indexWhere((d) => d.id == driver.id);
      if (index != -1) {
        currentDriver = drivers[index];
      }
    }

    final tripsState = ref.watch(driverTripsProvider(currentDriver.id));
    final advancesState = ref.watch(driverAdvancesProvider(currentDriver.id));
    final localImagesState = ref.watch(driverLocalImagesProvider(currentDriver.id));

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        showToolBar: true,
        bgColor: AppColors.primary,
        centerTitle: true,
        title: 'بيانات السواق',
        fontColor: AppColors.white,
        fontSize: 22.sp,
        iconPath: AppIcons.arrowLeft,
        onPressed: () {
          NavigatorHandler.pop();
        },
        actions: [
          IconButton(
            tooltip: 'تعديل بيانات السائق',
            onPressed: () async {
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(28.r),
                  ),
                ),
                builder: (_) => EditDriverBottomSheet(
                  driver: currentDriver,
                ),
              );
            },
            icon: Icon(
              Icons.edit_outlined,
              color: AppColors.white,
              size: 22.sp,
            ),
          ),
          IconButton(
            tooltip: 'طباعة تقرير السائق',
            onPressed: tripsState.hasValue
                ? () async {
                    await DriverMonthlyReportService.shareCurrentMonthReport(
                      driver: currentDriver,
                      trips: tripsState.value!,
                      advances: advancesState.valueOrNull ?? [],
                    );
                  }
                : null,
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
          await Future.wait([
            ref.read(driversProvider.notifier).getDrivers(),
            ref.refresh(driverTripsProvider(currentDriver.id).future),
            ref.refresh(driverAdvancesProvider(currentDriver.id).future),
            ref.refresh(driverLocalImagesProvider(currentDriver.id).future),
          ]);
        },
        child: tripsState.when(
          loading: () => const Center(child: CustomLoading()),
          error: (error, stackTrace) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: 150.h),
              Center(
                child: CustomText(
                  title: 'حدث خطأ في تحميل الرحلات',
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          data: (trips) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                top: 24.h,
                right: 20.w,
                left: 20.w,
                bottom: 40.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // ─── Driver Info Card ───────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 18.w,
                      vertical: 18.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(color: const Color(0xFFE7E8EC)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
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
                            color: const Color(0xFFF0F2F6),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFE3E6EC),
                              width: 3.w,
                            ),
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            size: 43.sp,
                            color: AppColors.primary,
                          ),
                        ),

                        SizedBox(height: 12.h),

                        CustomText(
                          title: currentDriver.name,
                          fontSize: 19.sp,
                          fontWeight: FontWeight.w700,
                          fontColor: AppColors.primary,
                        ),

                        SizedBox(height: 6.h),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomText(
                              title: currentDriver.phone,
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

                        SizedBox(height: 18.h),

                        Row(
                          children: [
                            Expanded(
                              child: _DriverStatItem(
                                title: 'إجمالي الإيرادات',
                                value:
                                    '${currentDriver.totalRevenue.toStringAsFixed(0)} ج.م',
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _DriverStatItem(
                                title: 'الرحلات المكتملة',
                                value: '${currentDriver.tripsCount}',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 28.h),

                  // ─── Driver Documents ───────────────────────────────────
                  _SectionHeader(title: 'وثائق السواق'),

                  SizedBox(height: 14.h),

                  localImagesState.when(
                    loading: () => const Center(child: CustomLoading()),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (images) => Row(
                      children: [
                        Expanded(
                          child: _DocumentImageCard(
                            label: 'صورة البطاقة',
                            icon: Icons.badge_outlined,
                            imageFile: images.idCardImage,
                            imageUrl: currentDriver.idCardImageUrl,
                            onTapUpload: () => _pickAndSaveImage(
                              context: context,
                              ref: ref,
                              isIdCard: true,
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _DocumentImageCard(
                            label: 'رخصة القيادة',
                            icon: Icons.drive_eta_outlined,
                            imageFile: images.licenseImage,
                            imageUrl: currentDriver.licenseImageUrl,
                            onTapUpload: () => _pickAndSaveImage(
                              context: context,
                              ref: ref,
                              isIdCard: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 28.h),

                  // ─── Driver Advances ────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: AppColors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(28.r),
                              ),
                            ),
                            builder: (_) => AddDriverAdvanceBottomSheet(
                              driver: currentDriver,
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 7.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, color: Colors.white, size: 16.sp),
                              SizedBox(width: 4.w),
                              CustomText(
                                title: 'إضافة سلفة',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                fontColor: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                      _SectionHeader(title: 'السلف المستحقة'),
                    ],
                  ),

                  SizedBox(height: 14.h),

                  advancesState.when(
                    loading: () => const Center(child: CustomLoading()),
                    error: (_, _) => Center(
                      child: CustomText(
                        title: 'حدث خطأ في تحميل السلف',
                        fontSize: 14.sp,
                        fontColor: AppColors.red,
                      ),
                    ),
                    data: (advances) {
                      final active = advances
                          .where((a) => a.isActive)
                          .toList()
                        ..sort((a, b) => b.date.compareTo(a.date));

                      final totalActive = active.fold<double>(
                        0,
                        (sum, a) => sum + a.amount,
                      );

                      if (active.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 24.h),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundGray,
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          child: Center(
                            child: CustomText(
                              title: 'لا توجد سلف مستحقة',
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w500,
                              fontColor: const Color(0xFF999999),
                            ),
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Total banner
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 10.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF7E0),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: const Color(0xFFF57C00).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                CustomText(
                                  title:
                                      '${totalActive.toStringAsFixed(0)} ج.م',
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w800,
                                  fontColor: const Color(0xFFF57C00),
                                ),
                                SizedBox(width: 6.w),
                                CustomText(
                                  title: 'إجمالي السلف المستحقة:',
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  fontColor: const Color(0xFFF57C00),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 12.h),

                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: active.length,
                            separatorBuilder: (_, _) =>
                                SizedBox(height: 10.h),
                            itemBuilder: (context, index) {
                              final advance = active[index];
                              return _AdvanceCard(
                                advance: advance,
                                driverId: currentDriver.id,
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),

                  SizedBox(height: 28.h),

                  // ─── Trips Section ──────────────────────────────────────
                  _SectionHeader(title: 'رحلات السواق'),

                  SizedBox(height: 12.h),

                  if (trips.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 40.h),
                      child: Center(
                        child: CustomText(
                          title: 'لا توجد رحلات لهذا السواق',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          fontColor: const Color(0xFF777B85),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: trips.length,
                      separatorBuilder: (_, _) => SizedBox(height: 12.h),
                      itemBuilder: (context, index) {
                        return TripCard(trip: trips[index]);
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

// ─────────────────────────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return CustomText(
      title: title,
      fontSize: 19.sp,
      fontWeight: FontWeight.w700,
      fontColor: AppColors.primary,
      textAlign: TextAlign.right,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Document Image Card
// ─────────────────────────────────────────────────────────────────────────────
class _DocumentImageCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final File? imageFile;
  final String? imageUrl;
  final VoidCallback onTapUpload;

  const _DocumentImageCard({
    required this.label,
    required this.icon,
    this.imageFile,
    this.imageUrl,
    required this.onTapUpload,
  });

  bool get _hasImage =>
      imageFile != null || (imageUrl != null && imageUrl!.isNotEmpty);

  void _showImageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.all(16.w),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: imageFile != null
                    ? Image.file(
                        imageFile!,
                        fit: BoxFit.contain,
                      )
                    : CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.contain,
                        placeholder: (_, _) => const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                        errorWidget: (_, _, _) => const Icon(
                          Icons.broken_image,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
              ),
            ),
            Positioned(
              top: 8.h,
              left: 8.w,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _hasImage ? () => _showImageDialog(context) : onTapUpload,
      child: Container(
        height: 130.h,
        decoration: BoxDecoration(
          color: AppColors.backgroundGray,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: _hasImage
                ? AppColors.primary.withValues(alpha: 0.25)
                : const Color(0xFFE0E0E0),
          ),
        ),
        child: _hasImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(13.r),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    imageFile != null
                        ? Image.file(
                            imageFile!,
                            fit: BoxFit.cover,
                          )
                        : CachedNetworkImage(
                            imageUrl: imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (_, _, _) => const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                            ),
                          ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 6.h,
                          horizontal: 8.w,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.65),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomText(
                              title: label,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              fontColor: Colors.white,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6.h,
                      left: 6.w,
                      child: GestureDetector(
                        onTap: onTapUpload,
                        child: Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.edit_outlined,
                            size: 14.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 34.sp,
                    color: const Color(0xFFBFC3CB),
                  ),
                  SizedBox(height: 8.h),
                  CustomText(
                    title: label,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    fontColor: const Color(0xFF777B85),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4.h),
                  CustomText(
                    title: 'اضغط للرفع',
                    fontSize: 11.sp,
                    fontColor: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Advance Card
// ─────────────────────────────────────────────────────────────────────────────
class _AdvanceCard extends ConsumerWidget {
  final DriverAdvanceEntity advance;
  final String driverId;

  const _AdvanceCard({required this.advance, required this.driverId});

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFE7E8EC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Mark as paid button
              TextButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text(
                        'تأكيد السداد',
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                      ),
                      content: Text(
                        'هل تم سداد هذه السلفة (${advance.amount.toStringAsFixed(0)} ج.م)؟',
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('إلغاء'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.green,
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            'تم السداد',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await ref
                        .read(driverAdvanceNotifierProvider.notifier)
                        .markAdvancePaid(
                          driverId: driverId,
                          advanceId: advance.id,
                        );
                  }
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  backgroundColor: AppColors.lightGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: CustomText(
                  title: 'تم السداد ✓',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  fontColor: AppColors.green,
                ),
              ),

              // Amount
              CustomText(
                title: '${advance.amount.toStringAsFixed(0)} ج.م',
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                fontColor: AppColors.primary,
              ),
            ],
          ),

          SizedBox(height: 6.h),

          // Date
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomText(
                title: _formatDate(advance.date),
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                fontColor: const Color(0xFF666A73),
              ),
              SizedBox(width: 4.w),
              Icon(
                Icons.calendar_today_outlined,
                size: 13.sp,
                color: const Color(0xFF666A73),
              ),
            ],
          ),

          if (advance.note.isNotEmpty) ...[
            SizedBox(height: 6.h),
            CustomText(
              title: advance.note,
              fontSize: 13.sp,
              fontColor: const Color(0xFF777B85),
              textAlign: TextAlign.right,
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Driver Stat Item
// ─────────────────────────────────────────────────────────────────────────────
class _DriverStatItem extends StatelessWidget {
  final String title;
  final String value;

  const _DriverStatItem({
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
