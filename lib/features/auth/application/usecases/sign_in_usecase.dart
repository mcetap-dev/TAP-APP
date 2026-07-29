import '../../../../core/errors/failures.dart';
import '../../domain/entities/auth_state.dart';
import '../../domain/repositories/auth_repository.dart';

class SignInUseCase {
  final AuthRepository repository;

  SignInUseCase({required this.repository});

  Future<({AuthState state, Failure? failure})> call({
    required String email,
    required String password,
  }) async {
    return repository.signIn(email: email, password: password);
  }
}