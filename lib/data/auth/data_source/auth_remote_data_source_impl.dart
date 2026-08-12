import 'package:elostaz_travel/data/auth/data_source/auth_remote_data_source.dart';
import 'package:elostaz_travel/data/auth/model/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  AuthRemoteDataSourceImpl(this.firebaseAuth);
  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final credential = await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;
    return UserModel.fromFirebaseUser(uid: user.uid, email: email);
  }
  @override
  Future<void> logout() async {
    await firebaseAuth.signOut();
  }
}
