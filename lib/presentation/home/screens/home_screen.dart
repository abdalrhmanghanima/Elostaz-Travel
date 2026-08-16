import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/core/utils/app_icons.dart';
import 'package:elostaz_travel/presentation/home/provider/bottom_nav_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/bus_tab.dart';
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
  final List<Widget> screens = [
    HomeTab(),
    BusTab(),
    DriversTab(),
    NotificationsTab(),
    ProfileTab(),
  ];
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
          unselectedItemColor: AppColors.black,
          selectedFontSize: 14.sp,
          unselectedFontSize: 13.sp,

          items: [
            BottomNavigationBarItem(
              icon: Transform.translate(
                offset: Offset(0, -1.h),
                child: SizedBox(
                  height: 24.w,
                  width: 24.w,
                  child: SvgPicture.asset(
                    AppIcons.home,
                    colorFilter: ColorFilter.mode(
                      currentScreen == 0
                          ? AppColors.primary
                          : AppColors.black,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              label: 'الرئيسية',
            ),

            BottomNavigationBarItem(
              icon: Transform.translate(
                offset: Offset(0, -1.h),
                child: SizedBox(
                  height: 24.w,
                  width: 24.w,
                  child: SvgPicture.asset(
                    AppIcons.bus,
                    colorFilter: ColorFilter.mode(
                      currentScreen == 1
                          ? AppColors.primary
                          : AppColors.black,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              label: 'الأتوبيسات',
            ),
            BottomNavigationBarItem(
              icon: Transform.translate(
                offset: Offset(0, -1.h),
                child: SizedBox(
                  height: 24.w,
                  width: 24.w,
                  child: SvgPicture.asset(
                    AppIcons.person,
                    colorFilter: ColorFilter.mode(
                      currentScreen == 1
                          ? AppColors.primary
                          : AppColors.black,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              label: 'السواقين',
            ),

            BottomNavigationBarItem(
              icon: Transform.translate(
                offset: Offset(0, -1.h),
                child: SizedBox(
                  height: 24.w,
                  width: 24.w,
                  child: SvgPicture.asset(
                    AppIcons.notification,
                    colorFilter: ColorFilter.mode(
                      currentScreen == 2
                          ? AppColors.primary
                          : AppColors.black,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              label: 'التنبيهات',
            ),

            BottomNavigationBarItem(
              icon: Transform.translate(
                offset: Offset(0, -1.h),
                child: SizedBox(
                  height: 24.w,
                  width: 24.w,
                  child: SvgPicture.asset(
                    AppIcons.settings,
                    colorFilter: ColorFilter.mode(
                      currentScreen == 3
                          ? AppColors.primary
                          : AppColors.black,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              label: 'الاعدادات',
            ),
          ],
        ),
      ),
    );
  }
}
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('ProfileTab')));
  }
}

