import 'package:elostaz_travel/domain/auth/entity/user_entity.dart';
import 'package:elostaz_travel/presentation/auth/provider/login_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final loginProvider =
AsyncNotifierProvider<LoginNotifier, UserEntity?>(
  LoginNotifier.new,
);