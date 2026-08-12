import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/navigator/navigator.dart';
import 'package:elostaz_travel/core/utils/app_assets.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/core/utils/app_icons.dart';
import 'package:elostaz_travel/domain/auth/entity/user_entity.dart';
import 'package:elostaz_travel/presentation/auth/provider/login_provider.dart';
import 'package:elostaz_travel/presentation/components/custom_app_bar/custom_app_bar.dart';
import 'package:elostaz_travel/presentation/components/custom_asset_image/custom_asset_image.dart';
import 'package:elostaz_travel/presentation/components/custom_button/custom_button.dart';
import 'package:elostaz_travel/presentation/components/custom_snack_bar/custom_snack_bar.dart';
import 'package:elostaz_travel/presentation/components/custom_svg/custom_svg_icon.dart';
import 'package:elostaz_travel/presentation/components/inputs/custom_text_form.dart';
import 'package:elostaz_travel/presentation/home/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  @override
  void initState() {
    ref.listenManual<AsyncValue<UserEntity?>>(loginProvider, (previous, next) {
      next.whenOrNull(
        data: (user) {
          if (user != null) {
            NavigatorHandler.pushAndRemoveUntil(HomeScreen());
          }
        },
        error: (error, stackTrace) {
          String message = 'حدث خطأ أثناء تسجيل الدخول';

          if (error is FirebaseAuthException) {
            switch (error.code) {
              case 'invalid-credential':
              case 'user-not-found':
              case 'wrong-password':
                message = 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
                break;

              case 'invalid-email':
                message = 'البريد الإلكتروني غير صحيح';
                break;

              case 'network-request-failed':
                message = 'تأكد من اتصالك بالإنترنت وحاول مرة أخرى';
                break;

              case 'too-many-requests':
                message = 'تم إجراء محاولات كثيرة، حاول مرة أخرى لاحقًا';
                break;

              default:
                message = 'حدث خطأ أثناء تسجيل الدخول، حاول مرة أخرى';
            }
          }
          CustomSnackBar.show(
            context,
            message: message,
          );
        },
      );
    });
    super.initState();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginProvider);
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(showToolBar: true),
      body: Padding(
        padding: const EdgeInsetsDirectional.only(start: 16, end: 16),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CustomAssetImage(
                    assetName: AppAssets.placeHolder,
                    height: 170.h,
                    width: 190.w,
                  ),
                ),
                SizedBox(height: 64.h),
                CustomTextFormField(
                  controller: emailController,
                  hint: "ادخل البريد الإلكتروني",
                  suffix: Padding(
                    padding: EdgeInsetsDirectional.only(start: 20.w),
                    child: Icon(Icons.email),
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';

                    if (email.isEmpty) {
                      return "البريد الإلكتروني مطلوب";
                    }

                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(email)) {
                      return "ادخل بريد إلكتروني صحيح";
                    }

                    return null;
                  },
                ),
                SizedBox(height: 24.h),
                CustomTextFormField(
                  controller: passwordController,
                  hint: "ادخل كلمة المرور",
                  suffix: Padding(
                    padding: EdgeInsetsDirectional.only(start: 20.w),
                    child: CustomSvgIcon(assetName: AppIcons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "كلمة المرور مطلوبة";
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(20.r),
        child: CustomButton(
          title: "تسجيل الدخول",
          bg: AppColors.primary,
          isLoading: loginState.isLoading,
          onTap: () async {
            if (!formKey.currentState!.validate()) return;
            await ref
                .read(loginProvider.notifier)
                .login(
                  email: emailController.text,
                  password: passwordController.text,
                );
          },
        ),
      ),
    );
  }
}
