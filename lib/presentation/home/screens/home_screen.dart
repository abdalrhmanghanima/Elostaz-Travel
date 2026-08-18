import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/services/license_notification_service.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/core/utils/app_icons.dart';
import 'package:elostaz_travel/presentation/home/provider/bottom_nav_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/bus_tab.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/provider/bus_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/driver_tab.dart';
import 'package:elostaz_travel/presentation/home/tabs/home/home_tab.dart';
import 'package:elostaz_travel/presentation/home/tabs/notifications/notifications_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _hasScheduledExistingBuses = false;

  final List<Widget> screens = [
    HomeTab(),
    BusTab(),
    DriversTab(),
    NotificationsTab(),

  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleExistingBusesOnce();
    });
  }

  void _scheduleExistingBusesOnce() {
    ref.listenManual(busProvider, (previous, next) {
      next.whenData((buses) {
        if (!_hasScheduledExistingBuses && buses.isNotEmpty) {
          _hasScheduledExistingBuses = true;
          LicenseNotificationService.instance
              .scheduleAllExistingBusLicenseNotifications(buses);
        }
      });
    }, fireImmediately: true);
  }
  @override
  Widget build(BuildContext context) {
    final currentScreen= ref.watch(bottomNavProvider);
    return Scaffold(
      body: IndexedStack(
        index: currentScreen,
        children: screens,
      ),

      bottomNavigationBar: Container(
        height: 85.h,
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, -3),
            ),
          ],
        ),

        child: BottomNavigationBar(
          elevation: 0,
          backgroundColor: AppColors.white,
          type: BottomNavigationBarType.fixed,

          currentIndex: currentScreen,

          onTap: (index) {
            ref.read(bottomNavProvider.notifier).state = index;
          },

          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.black,
          selectedFontSize: 14.sp,
          unselectedFontSize: 13.sp,

          items: [
            BottomNavigationBarItem(
              icon: Transform.translate(
                offset: Offset(0, -1.h),
                child: _AnimatedNavBarIcon(
                  assetName: AppIcons.home,
                  filledAssetName: AppIcons.homeFilled,
                  isSelected: currentScreen == 0,
                ),
              ),
              label: 'الرئيسية',
            ),

            BottomNavigationBarItem(
              icon: Transform.translate(
                offset: Offset(0, -1.h),
                child: _AnimatedNavBarIcon(
                  assetName: AppIcons.bus,
                  filledAssetName: AppIcons.busFilled,
                  isSelected: currentScreen == 1,
                ),
              ),
              label: 'الأتوبيسات',
            ),
            BottomNavigationBarItem(
              icon: Transform.translate(
                offset: Offset(0, -1.h),
                child: _AnimatedNavBarIcon(
                  assetName: AppIcons.person,
                  filledAssetName: AppIcons.personFilled,
                  isSelected: currentScreen == 2,
                ),
              ),
              label: 'السواقين',
            ),

            BottomNavigationBarItem(
              icon: Transform.translate(
                offset: Offset(0, -1.h),
                child: _AnimatedNavBarIcon(
                  assetName: AppIcons.notification,
                  filledAssetName: AppIcons.notificationFilled,
                  isSelected: currentScreen == 3,
                ),
              ),
              label: 'التنبيهات',
            ),

          ],
        ),
      ),
    );
  }
}

class _AnimatedNavBarIcon extends StatelessWidget {
  final String assetName;
  final String filledAssetName;
  final bool isSelected;

  const _AnimatedNavBarIcon({
    required this.assetName,
    required this.filledAssetName,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
      tween: Tween<double>(end: isSelected ? 1.0 : 0.0),
      builder: (context, progress, child) {
        final scale = 1.0 + (0.10 * progress);

        return Transform.scale(
          scale: scale,
          child: SizedBox(
            height: 24.w,
            width: 24.w,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Outline icon — fades out when selected
                Opacity(
                  opacity: 1.0 - progress,
                  child: SvgPicture.asset(
                    assetName,
                    colorFilter: const ColorFilter.mode(
                      Colors.black,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                // Filled icon — fades in when selected
                Opacity(
                  opacity: progress,
                  child: SvgPicture.asset(
                    filledAssetName,
                    colorFilter: ColorFilter.mode(
                      AppColors.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

