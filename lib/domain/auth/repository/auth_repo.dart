import 'package:elostaz_travel/domain/auth/entity/user_entity.dart';

abstract class AuthRepo {
  Future<UserEntity> login({required String email, required String password});
  Future<void> logout();
}