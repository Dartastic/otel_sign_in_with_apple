// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_sign_in_with_apple/otel_sign_in_with_apple.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_sign_in_with_apple-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('getAppleIDCredential records user + real_user + private relay',
      () async {
    await tracedSignInWithApple<String>(
      operation: 'getAppleIDCredential',
      invoke: () async => const SignInWithAppleCallResult(
        value: 'ok',
        result: SignInWithAppleResult(
          userIdentifier: '001234.aabbccddee',
          platform: 'ios',
          realUserStatus: 'likelyReal',
          hasEmail: true,
          emailPrivateRelay: true,
          scopesRequested: ['email', 'fullName'],
        ),
      ),
    );
    final a = attrsOf(
      spans.findSpanByName('sign_in_with_apple getAppleIDCredential')!,
    );
    expect(a['sign_in_with_apple.real_user_status'], 'likelyReal');
    expect(a['sign_in_with_apple.email.private_relay'], true);
  });

  test('revoked credential state sets span error', () async {
    await tracedSignInWithApple<String>(
      operation: 'getCredentialState',
      invoke: () async => const SignInWithAppleCallResult(
        value: 'ok',
        result: SignInWithAppleResult(credentialState: 'revoked'),
      ),
    );
    expect(
      spans.findSpanByName('sign_in_with_apple getCredentialState')!.status,
      SpanStatusCode.Error,
    );
  });

  test('canceled does NOT set span error', () async {
    await tracedSignInWithApple<String>(
      operation: 'getAppleIDCredential',
      invoke: () async => const SignInWithAppleCallResult(
        value: 'ok',
        result: SignInWithAppleResult(errorCode: 'canceled'),
      ),
    );
    expect(
      spans.findSpanByName('sign_in_with_apple getAppleIDCredential')!.status,
      isNot(SpanStatusCode.Error),
    );
  });

  test('suppression skips spans', () async {
    await runWithoutSignInWithAppleInstrumentationAsync(() async {
      await tracedSignInWithApple<String>(
        operation: 'isAvailable',
        invoke: () async => const SignInWithAppleCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('sign_in_with_apple '), isEmpty);
  });
}
