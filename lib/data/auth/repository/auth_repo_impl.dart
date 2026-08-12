import 'package:elostaz_travel/data/auth/data_source/auth_remote_data_source.dart';
import 'package:elostaz_travel/domain/auth/entity/user_entity.dart';
import 'package:elostaz_travel/domain/auth/repository/auth_repo.dart';

class AuthRepoImpl implements AuthRepo{
  final AuthRemoteDataSource authRemoteDataSource;
  AuthRepoImpl(this.authRemoteDataSource);
  @override
  Future<UserEntity> login({required String email, required String password}) {
    return authRemoteDataSource.login(email: email, password: password);
  }
  @override
  Future<void> logout() {
    return authRemoteDataSource.logout();
  }
}