import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/navigator/navigator.dart';
import 'package:elostaz_travel/core/utils/app_assets.dart';
import 'package:elostaz_travel/presentation/auth/screen/login_screen.dart';
import 'package:elostaz_travel/presentation/components/custom_asset_image/custom_asset_image.dart';
import 'package:elostaz_travel/presentation/home/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth/provider/auth_state_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();

    ref.listenManual<AsyncValue<User?>>(
      authStateProvider,
          (previous, next) {
        next.whenData((user) async {
          await Future.delayed(
            const Duration(seconds: 2),
          );

          if (!mounted) return;

          if (user != null) {
            NavigatorHandler.pushAndRemoveUntil(
              const HomeScreen(),
            );
          } else {
            NavigatorHandler.pushAndRemoveUntil(
              const LoginScreen(),
            );
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CustomAssetImage(assetName: AppAssets.placeHolder,
        width: 240.w,height: 250.h,
        ),
      ),
    );
  }
}