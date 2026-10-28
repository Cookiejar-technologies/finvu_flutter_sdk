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

  /// PIN recovery proof methods (the factor of a pinRecovery proof step).
  static const factorQuestionLinkedAccount = 'questionLinkedAccount';
  static const factorQuestionPan = 'questionPan';
  static const factorEmailOtp = 'emailOtp';
  static const factorEmailLink = 'emailLink';

  static const requirementVerification = 'verification';
  static const requirementEnrollment = 'enrollment';

  static const purposePinRecovery = 'pinRecovery';

  @Deprecated('Forgot PIN now runs PIN recovery; steps use purposePinRecovery')
  static const purposePinReset = 'pinReset';

  static const statusAuthenticated = 'authenticated';
  static const statusFailed = 'failed';
}

/// [support] is set on PIN recovery errors that carry contact details, such as noRecoveryOptions.
class ValidationError {
  ValidationError({required this.code, required this.message, this.attemptsRemaining, this.support});

  final String code;
  final String message;
  final int? attemptsRemaining;
  final RecoverySupport? support;
}

/// Who to contact when PIN recovery is not possible. Only the keys the backend sent are set.
class RecoverySupport {
  RecoverySupport({this.email, this.phone, this.message});

  final String? email;
  final String? phone;
  final String? message;
}

/// A linked account to answer for, on a questionLinkedAccount proof step. Never carries digits.
class RecoveryAccount {
  RecoveryAccount({required this.fipId, this.fiType, this.accType});

  final String fipId;
  final String? fiType;
  final String? accType;
}

/// A verified email the code or link can go to. [selected] marks where the current one went.
class RecoveryEmail {
  RecoveryEmail({required this.emailHash, required this.maskedEmail, required this.primary, required this.selected});

  final String emailHash;
  final String maskedEmail;
  final bool primary;
  final bool selected;
}

/// One answer on a questionLinkedAccount proof step: the account and its last 4 digits.
class RecoveryAccountAnswer {
  RecoveryAccountAnswer({required this.fipId, required this.last4, this.fiType, this.accType});

  final String fipId;
  final String last4;
  final String? fiType;
  final String? accType;
}

/// PIN recovery data on a step. On a proof step: [method], [availableMethods], plus [accounts] and
/// [minAccountsRequired] (questionLinkedAccount) or [emails] (emailOtp, emailLink). On the new PIN
/// step: [expiresAt], when the backend sent the recovery window's deadline.
class RecoveryInfo {
  RecoveryInfo({
    this.method,
    this.availableMethods = const [],
    this.accounts,
    this.minAccountsRequired,
    this.emails,
    this.expiresAt,
  });

  final String? method;
  final List<String> availableMethods;
  final List<RecoveryAccount>? accounts;
  final int? minAccountsRequired;
  final List<RecoveryEmail>? emails;
  final String? expiresAt;
}

class MfaError {
  MfaError({required this.code, required this.message});

  final String code;
  final String message;
}

/// [newUser] and [hasLinkedAccounts] come from the login's first response ("Y" / "N");
/// null when Finvu did not send them.
class MfaSession {
  MfaSession({this.userId, this.sessionId, this.csid, this.newUser, this.hasLinkedAccounts});

  final String? userId;
  final String? sessionId;
  final String? csid;
  final bool? newUser;
  final bool? hasLinkedAccounts;
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
    this.emailId,
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

  /// The user's email ID, sent with the login. Optional.
  final String? emailId;
}

typedef MfaAction = Future<MfaStep> Function();

/// One step of the MFA login. Check [action] (or the subtype) and act on it.
sealed class MfaStep {
  String get action;
}

/// Ask the user for a value, then call [submit]: an OTP or PIN, or during PIN recovery
/// ([purpose] 'pinRecovery') the proof for [factor] or the new PIN.
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
    this.recovery,
    this.cancel,
    this.switchMethod,
    this.selectEmail,
    Future<MfaStep> Function(List<RecoveryAccountAnswer> accounts)? onSubmitAccounts,
  })  : _onSubmit = onSubmit,
        _onSubmitAccounts = onSubmitAccounts;

  @override
  String get action => MfaConstants.actionInput;

  /// 'otp' or 'pin'; on a PIN recovery proof step 'questionLinkedAccount', 'questionPan',
  /// 'emailOtp' or 'emailLink'
  final String factor;

  /// 'verification' or 'enrollment'
  final String requirement;

  /// 'pinRecovery' during forgot PIN, otherwise null
  final String? purpose;
  final InputSpec? inputSpec;

  /// Set when the previous value was rejected; show the same form again.
  final ValidationError? validationError;
  final ResendInfo? resendInfo;

  /// OTP, and the emailOtp / emailLink proof steps (sends the code or link again).
  final MfaAction? resend;

  /// PIN verification only. Starts PIN recovery.
  final MfaAction? forgotPin;

  /// PIN recovery steps only. See [RecoveryInfo].
  final RecoveryInfo? recovery;

  /// PIN recovery steps only. Back to the PIN verification step, with no error.
  final MfaAction? cancel;

  /// Proof step with more than one method. Takes a value from recovery.availableMethods.
  final Future<MfaStep> Function(String method)? switchMethod;

  /// emailOtp / emailLink proof steps. Takes an emailHash from recovery.emails.
  final Future<MfaStep> Function(String emailHash)? selectEmail;

  final Future<MfaStep> Function(String value) _onSubmit;
  final Future<MfaStep> Function(List<RecoveryAccountAnswer> accounts)? _onSubmitAccounts;

  Future<MfaStep> submit(String value) => _onSubmit(value);

  /// questionLinkedAccount proof step: the last 4 digits of each account. With exactly one
  /// account, [submit] with just the digits works too. Other steps return themselves unchanged.
  Future<MfaStep> submitAccounts(List<RecoveryAccountAnswer> accounts) =>
      _onSubmitAccounts?.call(accounts) ?? Future.value(this);
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

/// Login finished. [retry] is never set: every device-binding failure falls back to PIN instead.
/// It is kept for API compatibility.
class MfaCompleteStep extends MfaStep {
  MfaCompleteStep({required this.result, this.retry});

  @override
  String get action => MfaConstants.actionComplete;

  final MfaResult result;
  final MfaAction? retry;
}
