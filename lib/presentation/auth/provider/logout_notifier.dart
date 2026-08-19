import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LogoutNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> logout() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await FirebaseAuth.instance.signOut();
    });
  }
}