import '../../models/auth/user_model.dart';

abstract class AuthState {
  const AuthState();

  // Factory constructors
  const factory AuthState.initial() = AuthStateInitial;
  const factory AuthState.loading() = AuthStateLoading;
  const factory AuthState.unauthenticated() = AuthStateUnauthenticated;
  const factory AuthState.authenticated({
    required UserModel user,
    required String accessToken,
    required String refreshToken,
  }) = AuthStateAuthenticated;
  const factory AuthState.error(String message) = AuthStateError;

  // When method for pattern matching
  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function() unauthenticated,
    required T Function(UserModel user, String accessToken, String refreshToken)
    authenticated,
    required T Function(String message) error,
  }) {
    if (this is AuthStateInitial) {
      return initial();
    } else if (this is AuthStateLoading) {
      return loading();
    } else if (this is AuthStateUnauthenticated) {
      return unauthenticated();
    } else if (this is AuthStateAuthenticated) {
      final state = this as AuthStateAuthenticated;
      return authenticated(state.user, state.accessToken, state.refreshToken);
    } else if (this is AuthStateError) {
      final state = this as AuthStateError;
      return error(state.message);
    }
    throw StateError('Unknown AuthState: $this');
  }

  // MaybeWhen method for optional pattern matching
  T maybeWhen<T>({
    T Function()? initial,
    T Function()? loading,
    T Function()? unauthenticated,
    T Function(UserModel user, String accessToken, String refreshToken)?
    authenticated,
    T Function(String message)? error,
    required T Function() orElse,
  }) {
    if (this is AuthStateInitial && initial != null) {
      return initial();
    } else if (this is AuthStateLoading && loading != null) {
      return loading();
    } else if (this is AuthStateUnauthenticated && unauthenticated != null) {
      return unauthenticated();
    } else if (this is AuthStateAuthenticated && authenticated != null) {
      final state = this as AuthStateAuthenticated;
      return authenticated(state.user, state.accessToken, state.refreshToken);
    } else if (this is AuthStateError && error != null) {
      final state = this as AuthStateError;
      return error(state.message);
    }
    return orElse();
  }

  // WhenOrNull method
  T? whenOrNull<T>({
    T Function()? initial,
    T Function()? loading,
    T Function()? unauthenticated,
    T Function(UserModel user, String accessToken, String refreshToken)?
    authenticated,
    T Function(String message)? error,
  }) {
    if (this is AuthStateInitial && initial != null) {
      return initial();
    } else if (this is AuthStateLoading && loading != null) {
      return loading();
    } else if (this is AuthStateUnauthenticated && unauthenticated != null) {
      return unauthenticated();
    } else if (this is AuthStateAuthenticated && authenticated != null) {
      final state = this as AuthStateAuthenticated;
      return authenticated(state.user, state.accessToken, state.refreshToken);
    } else if (this is AuthStateError && error != null) {
      final state = this as AuthStateError;
      return error(state.message);
    }
    return null;
  }

  // Map method for transforming states
  T map<T>({
    required T Function(AuthStateInitial value) initial,
    required T Function(AuthStateLoading value) loading,
    required T Function(AuthStateUnauthenticated value) unauthenticated,
    required T Function(AuthStateAuthenticated value) authenticated,
    required T Function(AuthStateError value) error,
  }) {
    if (this is AuthStateInitial) {
      return initial(this as AuthStateInitial);
    } else if (this is AuthStateLoading) {
      return loading(this as AuthStateLoading);
    } else if (this is AuthStateUnauthenticated) {
      return unauthenticated(this as AuthStateUnauthenticated);
    } else if (this is AuthStateAuthenticated) {
      return authenticated(this as AuthStateAuthenticated);
    } else if (this is AuthStateError) {
      return error(this as AuthStateError);
    }
    throw StateError('Unknown AuthState: $this');
  }

  // MaybeMap method
  T maybeMap<T>({
    T Function(AuthStateInitial value)? initial,
    T Function(AuthStateLoading value)? loading,
    T Function(AuthStateUnauthenticated value)? unauthenticated,
    T Function(AuthStateAuthenticated value)? authenticated,
    T Function(AuthStateError value)? error,
    required T Function(AuthState value) orElse,
  }) {
    if (this is AuthStateInitial && initial != null) {
      return initial(this as AuthStateInitial);
    } else if (this is AuthStateLoading && loading != null) {
      return loading(this as AuthStateLoading);
    } else if (this is AuthStateUnauthenticated && unauthenticated != null) {
      return unauthenticated(this as AuthStateUnauthenticated);
    } else if (this is AuthStateAuthenticated && authenticated != null) {
      return authenticated(this as AuthStateAuthenticated);
    } else if (this is AuthStateError && error != null) {
      return error(this as AuthStateError);
    }
    return orElse(this);
  }

  // MapOrNull method
  T? mapOrNull<T>({
    T Function(AuthStateInitial value)? initial,
    T Function(AuthStateLoading value)? loading,
    T Function(AuthStateUnauthenticated value)? unauthenticated,
    T Function(AuthStateAuthenticated value)? authenticated,
    T Function(AuthStateError value)? error,
  }) {
    if (this is AuthStateInitial && initial != null) {
      return initial(this as AuthStateInitial);
    } else if (this is AuthStateLoading && loading != null) {
      return loading(this as AuthStateLoading);
    } else if (this is AuthStateUnauthenticated && unauthenticated != null) {
      return unauthenticated(this as AuthStateUnauthenticated);
    } else if (this is AuthStateAuthenticated && authenticated != null) {
      return authenticated(this as AuthStateAuthenticated);
    } else if (this is AuthStateError && error != null) {
      return error(this as AuthStateError);
    }
    return null;
  }
}

// Concrete implementations
class AuthStateInitial extends AuthState {
  const AuthStateInitial();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AuthStateInitial;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'AuthState.initial()';
}

class AuthStateLoading extends AuthState {
  const AuthStateLoading();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AuthStateLoading;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'AuthState.loading()';
}

class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AuthStateUnauthenticated;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'AuthState.unauthenticated()';
}

class AuthStateAuthenticated extends AuthState {
  const AuthStateAuthenticated({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  final UserModel user;
  final String accessToken;
  final String refreshToken;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuthStateAuthenticated &&
          other.user == user &&
          other.accessToken == accessToken &&
          other.refreshToken == refreshToken);

  @override
  int get hashCode => Object.hash(user, accessToken, refreshToken);

  @override
  String toString() =>
      'AuthState.authenticated(user: $user, accessToken: $accessToken, refreshToken: $refreshToken)';

  // CopyWith method
  AuthStateAuthenticated copyWith({
    UserModel? user,
    String? accessToken,
    String? refreshToken,
  }) {
    return AuthStateAuthenticated(
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }
}

class AuthStateError extends AuthState {
  const AuthStateError(this.message);

  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuthStateError && other.message == message);

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'AuthState.error(message: $message)';

  // CopyWith method
  AuthStateError copyWith({String? message}) {
    return AuthStateError(message ?? this.message);
  }
}
