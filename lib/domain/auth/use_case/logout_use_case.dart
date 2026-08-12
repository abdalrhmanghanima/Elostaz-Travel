import 'package:elostaz_travel/domain/auth/repository/auth_repo.dart';

class LogoutUseCase {
  final AuthRepo authRepo;

  LogoutUseCase(this.authRepo);

  Future<void> call() {
    return authRepo.logout();
  }
}