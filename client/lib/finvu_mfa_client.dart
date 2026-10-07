import 'package:finvu_flutter_sdk/generated/native_finvu_manager.g.dart'
    as native;
import 'package:finvu_flutter_sdk_core/finvu_mfa.dart';
import 'package:flutter/services.dart';

/// Step-based MFA login (OTP, SNA, PIN, device binding), backed by the native SDKs.
///
/// Usage:
/// ```dart
/// var step = await FinvuManager().mfaClient.login(
///   LoginParams(mobileNumber: '9876543210', consentHandle: handleId),
/// );
/// ```
/// Act on each returned [MfaStep] until an [MfaCompleteStep]. On 'authenticated' the SDK
/// session is set, so the other FinvuManager APIs can be called. Nothing here throws.
class MfaClient {
  MfaClient(this._native);

  final native.NativeFinvuManager _native;

  /// Starts an MFA login. Call [FinvuManager.connect] first.
  Future<MfaStep> login(LoginParams params) {
    final nativeParams = native.NativeMfaLoginParams(
      mobileNumber: params.mobileNumber,
      username: params.username,
      consentHandle: params.consentHandle,
      handleId: params.handleId,
      clientContext: params.clientContext,
      firstFactor: params.supportedFactors?.firstFactor,
      secondFactor: params.supportedFactors?.secondFactor,
      useEncConsent: params.useEncConsent,
      finalizeSession: params.finalizeSession,
      selectFactorChoice: params.selectFactorChoice,
    );
    return _call(() => _native.mfaLogin(nativeParams));
  }

  /// Native steps live on the platform side; Dart refers to them by stepId.
  Future<MfaStep> _call(Future<native.NativeMfaStep> Function() call) async {
    try {
      return _toStep(await call());
    } on PlatformException catch (e) {
      return _failed(e.code, e.message);
    } catch (e) {
      return _failed('mfaFailed', e.toString());
    }
  }

  MfaStep _toStep(native.NativeMfaStep step) {
    final stepId = step.stepId;
    switch (step.action) {
      case MfaConstants.actionInput:
        final validationError = step.validationError;
        final resendInfo = step.resendInfo;
        return MfaInputStep(
          factor: step.factor ?? MfaConstants.factorOtp,
          requirement: step.requirement ?? MfaConstants.requirementVerification,
          purpose: step.purpose,
          inputSpec: step.pinLength != null
              ? InputSpec(pinLength: step.pinLength!)
              : null,
          validationError: validationError != null
              ? ValidationError(
                  code: validationError.code,
                  message: validationError.message,
                  attemptsRemaining: validationError.attemptsRemaining,
                )
              : null,
          resendInfo: resendInfo != null
              ? ResendInfo(
                  resendAfterSeconds: resendInfo.resendAfterSeconds,
                  resendsRemaining: resendInfo.resendsRemaining,
                )
              : null,
          onSubmit: (value) => _call(() => _native.mfaSubmit(stepId, value)),
          resend: step.hasResend
              ? () => _call(() => _native.mfaResend(stepId))
              : null,
          forgotPin: step.hasForgotPin
              ? () => _call(() => _native.mfaForgotPin(stepId))
              : null,
        );

      case MfaConstants.actionSilent:
        return MfaSilentStep(
          factor: step.factor ?? '',
          // Started right away, like the native completion
          completion: _call(() => _native.mfaAwaitCompletion(stepId)),
        );

      case MfaConstants.actionSelectFactor:
        return MfaSelectFactorStep(
          availableFactors:
              step.availableFactors?.whereType<String>().toList() ?? const [],
          onSelect: (factor) =>
              _call(() => _native.mfaSelectFactor(stepId, factor)),
        );

      default:
        final session = step.session;
        final error = step.error;
        return MfaCompleteStep(
          result: MfaResult(
            status: step.resultStatus ?? MfaConstants.statusFailed,
            session: session != null
                ? MfaSession(
                    userId: session.userId,
                    sessionId: session.sessionId,
                    csid: session.csid,
                  )
                : null,
            error: error != null
                ? MfaError(code: error.code, message: error.message)
                : null,
          ),
          retry: step.hasRetry
              ? () => _call(() => _native.mfaRetry(stepId))
              : null,
        );
    }
  }

  MfaCompleteStep _failed(String code, String? message) => MfaCompleteStep(
        result: MfaResult(
          status: MfaConstants.statusFailed,
          error: MfaError(
            code: code.isEmpty ? 'mfaFailed' : code,
            message: (message == null || message.isEmpty)
                ? 'Authentication failed'
                : message,
          ),
        ),
      );
}
