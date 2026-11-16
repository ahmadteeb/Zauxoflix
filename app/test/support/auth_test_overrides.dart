import 'package:zauxoflix/data/backend/auth_models.dart';
import 'package:zauxoflix/data/backend/backend_providers.dart';

class _AuthedController extends AuthController {
  @override
  AuthState build() =>
      const Authenticated(BackendUser(id: 'test', email: 'test@x.com'));
}

final authenticatedOverride = authControllerProvider.overrideWith(
  _AuthedController.new,
);
