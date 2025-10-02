// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'authentication_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(authenticationRepository)
const authenticationRepositoryProvider = AuthenticationRepositoryProvider._();

final class AuthenticationRepositoryProvider extends $FunctionalProvider<
    AuthenticationRepository,
    AuthenticationRepository,
    AuthenticationRepository> with $Provider<AuthenticationRepository> {
  const AuthenticationRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'authenticationRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$authenticationRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthenticationRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthenticationRepository create(Ref ref) {
    return authenticationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthenticationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthenticationRepository>(value),
    );
  }
}

String _$authenticationRepositoryHash() =>
    r'b856937e305e0cdf1a18e38094595206e2d96f65';
