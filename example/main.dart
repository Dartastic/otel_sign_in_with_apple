// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_sign_in_with_apple/otel_sign_in_with_apple.dart';

/// Traces Sign in with Apple calls with OpenTelemetry.
///
/// `otel_sign_in_with_apple` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Sign in with Apple call in
/// [tracedSignInWithApple]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'sign-in-with-apple-example');

  // Wraps a Sign in with Apple call in a CLIENT span.
  final signInWithAppleId = await tracedSignInWithApple<String>(
    operation: 'create',
    invoke: () async {
      // Make the Sign in with Apple call here, then report what it returned.
      const id = 'sign_in_with_apple_8f3a2c';
      return const SignInWithAppleCallResult(
          value: id,
          result: SignInWithAppleResult(
              userIdentifier: 'example',
              platform: 'ios',
              credentialState: 'authorized',
              realUserStatus: 'likelyReal',
              scopesRequested: ['email'],
              hasEmail: true,
              hasFullName: true,
              emailPrivateRelay: true,
              identityTokenLength: 128,
              authorizationCodeLength: 1,
              errorCode: 'canceled'));
    },
  );
  OTelLog.info('tracedSignInWithApple create returned $signInWithAppleId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutSignInWithAppleInstrumentationAsync.
  await runWithoutSignInWithAppleInstrumentationAsync(
    () => tracedSignInWithApple<String>(
      operation: 'create',
      invoke: () async {
        const id = 'sign_in_with_apple_8f3a2c';
        return const SignInWithAppleCallResult(
            value: id,
            result: SignInWithAppleResult(
                userIdentifier: 'example',
                platform: 'ios',
                credentialState: 'authorized',
                realUserStatus: 'likelyReal',
                scopesRequested: ['email'],
                hasEmail: true,
                hasFullName: true,
                emailPrivateRelay: true,
                identityTokenLength: 128,
                authorizationCodeLength: 1,
                errorCode: 'canceled'));
      },
    ),
  );

  await OTel.shutdown();
}
