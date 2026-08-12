import 'package:elostaz_travel/data/auth/data_source/auth_remote_data_source.dart';
import 'package:elostaz_travel/data/auth/data_source/auth_remote_data_source_impl.dart';
import 'package:elostaz_travel/data/auth/repository/auth_repo_impl.dart';
import 'package:elostaz_travel/domain/auth/entity/user_entity.dart';
import 'package:elostaz_travel/domain/auth/repository/auth_repo.dart';
import 'package:elostaz_travel/domain/auth/use_case/login_use_case.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginNotifier extends AsyncNotifier<UserEntity?>{
  @override
  Future<UserEntity?> build() async{
    return null;
  }
  Future<void> login({required String email, required String password})async{
   state = const AsyncLoading();
   state = await AsyncValue.guard((){
     return ref.read(loginUseCaseProvider).call(email: email, password: password);
   });
  }
}
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});
final authRemoteDataProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(ref.read(firebaseAuthProvider));
});
final authRepoProvider = Provider<AuthRepo>((ref) {
  return AuthRepoImpl(ref.read(authRemoteDataProvider));
});
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.read(authRepoProvider));
});