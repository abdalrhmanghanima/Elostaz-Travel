import 'package:elostaz_travel/core/services/license_notification_service.dart';
import 'package:elostaz_travel/firebase_options.dart';
import 'package:elostaz_travel/presentation/auth/provider/auth_state_provider.dart';
import 'package:elostaz_travel/presentation/auth/provider/user_data_invalidation.dart';
import 'package:elostaz_travel/presentation/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/constants.dart';

final navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await LicenseNotificationService.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: _AuthScopeWatcher(
        child: MaterialApp(
          title: 'Flutter Demo',
          debugShowCheckedModeBanner: false,
          locale: Locale(appLanguage[0].languageCode, appLanguage[0].countryCode),
          navigatorKey: navigatorKey,
          theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
          home: SplashScreen(),
        ),
      ),
    );
  }
}

/// Watches the Firebase auth stream at the app root and, whenever the signed-in
/// user changes, invalidates every account-scoped data provider. This makes the
/// next screen read re-resolve against the new user, so no data from a previous
/// account remains visible (including after logout → login as another account).
class _AuthScopeWatcher extends ConsumerStatefulWidget {
  const _AuthScopeWatcher({required this.child});

  final Widget child;

  @override
  ConsumerState<_AuthScopeWatcher> createState() => _AuthScopeWatcherState();
}

class _AuthScopeWatcherState extends ConsumerState<_AuthScopeWatcher> {
  @override
  void initState() {
    super.initState();
    ref.listenManual(authStateProvider, (previous, next) {
      final prevUid = previous?.valueOrNull?.uid;
      final nextUid = next.valueOrNull?.uid;
      if (prevUid != nextUid) {
        invalidateUserScopedData(ref);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
