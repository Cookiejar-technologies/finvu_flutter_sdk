/// Step-based MFA login (OTP, SNA, PIN, device binding).
///
/// Every call resolves to an [MfaStep] and never throws; failures come back as an
/// [MfaCompleteStep] whose [MfaResult.status] is 'failed'. Act on each step until an
/// [MfaCompleteStep] is returned.
library;

/// String values used on steps. Same strings as the native SDKs.
class MfaConstants {
  static const actionInput = 'input';
  static const actionSilent = 'silent';
  static const actionSelectFactor = 'selectFactor';
  static const actionComplete = 'complete';

  static const factorOtp = 'otp';
  static const factorSna = 'sna';
  static const factorPin = 'pin';
  static const factorDeviceBinding = 'deviceBinding';

  static const requirementVerification = 'verification';
  static const requirementEnrollment = 'enrollment';

  static const purposePinReset = 'pinReset';

  static const statusAuthenticated = 'authenticated';
  static const statusFailed = 'failed';
}

class ValidationError {
  ValidationError({required this.code, required this.message, this.attemptsRemaining});

  final String code;
  final String message;
  final int? attemptsRemaining;
}

class MfaError {
  MfaError({required this.code, required this.message});

  final String code;
  final String message;
}

class MfaSession {
  MfaSession({this.userId, this.sessionId, this.csid});

  final String? userId;
  final String? sessionId;
  final String? csid;
}

/// [status] is 'authenticated' ([session] set) or 'failed' ([error] set).
class MfaResult {
  MfaResult({required this.status, this.session, this.error});

  final String status;
  final MfaSession? session;
  final MfaError? error;

  bool get isAuthenticated => status == MfaConstants.statusAuthenticated;
}

class InputSpec {
  InputSpec({required this.pinLength});

  final int pinLength;
}

class ResendInfo {
  ResendInfo({this.resendAfterSeconds, this.resendsRemaining});

  final int? resendAfterSeconds;
  final int? resendsRemaining;
}

/// Backend factor vocabulary: 'SNA', 'OTP', 'PIN', 'DEVICE_BINDING'. Empty list = not specified.
class SupportedFactors {
  SupportedFactors({this.firstFactor = const [], this.secondFactor = const []});

  final List<String> firstFactor;
  final List<String> secondFactor;
}

class LoginParams {
  LoginParams({
    this.mobileNumber,
    this.username,
    this.consentHandle,
    this.handleId,
    this.clientContext,
    this.supportedFactors,
    this.useEncConsent = true,
    this.finalizeSession,
    this.selectFactorChoice = false,
  });

  final String? mobileNumber;
  final String? username;
  final String? consentHandle;
  final String? handleId;
  final Map<String, Object?>? clientContext;
  final SupportedFactors? supportedFactors;
  final bool useEncConsent;
  final bool? finalizeSession;
  final bool selectFactorChoice;
}

typedef MfaAction = Future<MfaStep> Function();

/// One step of the MFA login. Check [action] (or the subtype) and act on it.
sealed class MfaStep {
  String get action;
}

/// Ask the user for an OTP or PIN, then call [submit].
class MfaInputStep extends MfaStep {
  MfaInputStep({
    required this.factor,
    required this.requirement,
    this.purpose,
    this.inputSpec,
    this.validationError,
    this.resendInfo,
    required Future<MfaStep> Function(String value) onSubmit,
    this.resend,
    this.forgotPin,
  }) : _onSubmit = onSubmit;

  @override
  String get action => MfaConstants.actionInput;

  /// 'otp' or 'pin'
  final String factor;

  /// 'verification' or 'enrollment'
  final String requirement;

  /// 'pinReset' during forgot PIN, otherwise null
  final String? purpose;
  final InputSpec? inputSpec;

  /// Set when the previous value was rejected; show the same form again.
  final ValidationError? validationError;
  final ResendInfo? resendInfo;

  /// OTP only.
  final MfaAction? resend;

  /// PIN verification only (not during a PIN reset).
  final MfaAction? forgotPin;

  final Future<MfaStep> Function(String value) _onSubmit;

  Future<MfaStep> submit(String value) => _onSubmit(value);
}

/// Work runs without user input (SNA, device binding prompt). Show a loader and await [completion].
class MfaSilentStep extends MfaStep {
  MfaSilentStep({required this.factor, required this.completion});

  @override
  String get action => MfaConstants.actionSilent;

  /// 'sna' or 'deviceBinding'
  final String factor;
  final Future<MfaStep> completion;
}

/// Let the user choose the step-up factor.
class MfaSelectFactorStep extends MfaStep {
  MfaSelectFactorStep({
    required this.availableFactors,
    required Future<MfaStep> Function(String factor) onSelect,
  }) : _onSelect = onSelect;

  @override
  String get action => MfaConstants.actionSelectFactor;

  final List<String> availableFactors;
  final Future<MfaStep> Function(String factor) _onSelect;

  Future<MfaStep> selectFactor(String factor) => _onSelect(factor);
}

/// Login finished. [retry] is set only when an on-device device-binding prompt failed; it can be
/// used once and resolves like a silent step's completion.
class MfaCompleteStep extends MfaStep {
  MfaCompleteStep({required this.result, this.retry});

  @override
  String get action => MfaConstants.actionComplete;

  final MfaResult result;
  final MfaAction? retry;
}
