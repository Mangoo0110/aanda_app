import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/auth/domain/repo/auth_repo.dart';

final class VerifyPasswordResetOtpParams {
  const VerifyPasswordResetOtpParams({
    required this.email,
    required this.token,
  });

  final String email;
  final String token;
}

final class VerifyPasswordResetOtp
    implements AsyncUsecase<void, VerifyPasswordResetOtpParams> {
  const VerifyPasswordResetOtp(this._repo);

  final AuthRepo _repo;

  @override
  AsyncRequest<void> call(VerifyPasswordResetOtpParams params) =>
      _repo.verifyPasswordResetOtp(
        email: params.email,
        token: params.token,
      );
}
