// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_sign_in_with_apple_suppression.dart';

const _tracerName = 'dartastic_otel_libs_sign_in_with_apple';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class SignInWithAppleResult {
  const SignInWithAppleResult({
    this.userIdentifier,
    this.platform,
    this.credentialState,
    this.realUserStatus,
    this.scopesRequested,
    this.hasEmail,
    this.hasFullName,
    this.emailPrivateRelay,
    this.identityTokenLength,
    this.authorizationCodeLength,
    this.errorCode,
  });

  /// Stable Apple user identifier (sub).
  final String? userIdentifier;

  /// `ios`, `android`, `web`, `macos`.
  final String? platform;

  /// `authorized`, `revoked`, `notFound`, `transferred`.
  final String? credentialState;

  /// Apple-provided likelihood: `likelyReal`, `unknown`, `unsupported`.
  final String? realUserStatus;

  /// `email` / `fullName` requested in `AppleIDAuthorizationScopes`.
  final List<String>? scopesRequested;

  /// Whether response included an email.
  final bool? hasEmail;

  /// Whether response included a full name.
  final bool? hasFullName;

  /// Email is an Apple private-relay address (`@privaterelay.appleid.com`).
  final bool? emailPrivateRelay;

  final int? identityTokenLength;
  final int? authorizationCodeLength;

  /// `canceled`, `failed`, `invalidResponse`, `notHandled`,
  /// `notInteractive`, `unknown`.
  final String? errorCode;
}

class SignInWithAppleCallResult<T> {
  const SignInWithAppleCallResult({required this.value, this.result});
  final T value;
  final SignInWithAppleResult? result;
}

/// Wraps a Sign in with Apple call in a CLIENT span. [operation] is one of
/// `getAppleIDCredential`, `getCredentialState`, `isAvailable`,
/// `getKeychainCredential`.
Future<T> tracedSignInWithApple<T>({
  required String operation,
  required Future<SignInWithAppleCallResult<T>> Function() invoke,
}) async {
  if (signInWithAppleInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'sign_in_with_apple',
    'rpc.method': operation,
    'sign_in_with_apple.operation': operation,
  };

  final span = _tracer().startSpan(
    'sign_in_with_apple $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final res = r.result!;
      final extras = <Attribute<Object>>[];
      if (res.userIdentifier != null) {
        extras.add(OTel.attributeString(
          'sign_in_with_apple.user.id',
          res.userIdentifier!,
        ));
      }
      if (res.platform != null) {
        extras.add(OTel.attributeString(
          'sign_in_with_apple.platform',
          res.platform!,
        ));
      }
      if (res.credentialState != null) {
        extras.add(OTel.attributeString(
          'sign_in_with_apple.credential.state',
          res.credentialState!,
        ));
        if (res.credentialState == 'revoked') {
          span.setStatus(
            SpanStatusCode.Error,
            'Apple credential revoked',
          );
        }
      }
      if (res.realUserStatus != null) {
        extras.add(OTel.attributeString(
          'sign_in_with_apple.real_user_status',
          res.realUserStatus!,
        ));
      }
      if (res.scopesRequested != null) {
        extras.add(OTel.attributeStringList(
          'sign_in_with_apple.scopes.requested',
          res.scopesRequested!,
        ));
      }
      if (res.hasEmail != null) {
        extras.add(OTel.attributeBool(
          'sign_in_with_apple.has_email',
          res.hasEmail!,
        ));
      }
      if (res.hasFullName != null) {
        extras.add(OTel.attributeBool(
          'sign_in_with_apple.has_full_name',
          res.hasFullName!,
        ));
      }
      if (res.emailPrivateRelay != null) {
        extras.add(OTel.attributeBool(
          'sign_in_with_apple.email.private_relay',
          res.emailPrivateRelay!,
        ));
      }
      if (res.identityTokenLength != null) {
        extras.add(OTel.attributeInt(
          'sign_in_with_apple.identity_token.length',
          res.identityTokenLength!,
        ));
      }
      if (res.authorizationCodeLength != null) {
        extras.add(OTel.attributeInt(
          'sign_in_with_apple.authorization_code.length',
          res.authorizationCodeLength!,
        ));
      }
      if (res.errorCode != null) {
        extras.add(OTel.attributeString(
          'sign_in_with_apple.error.code',
          res.errorCode!,
        ));
        if (res.errorCode == 'failed' ||
            res.errorCode == 'invalidResponse' ||
            res.errorCode == 'notHandled') {
          span.setStatus(
            SpanStatusCode.Error,
            'Sign in with Apple ${res.errorCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
