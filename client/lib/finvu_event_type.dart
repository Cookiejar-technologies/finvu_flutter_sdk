/// Enum for all standard SDK events
/// Use these instead of string literals to avoid typos
enum FinvuEventType {
  // Websocket Events
  websocketConnected('WEBSOCKET_CONNECTED'),
  websocketDisconnected('WEBSOCKET_DISCONNECTED'),

  // Redirection Events
  consentRequestValid('CONSENT_REQUEST_VALID'),
  consentRequestInvalid('CONSENT_REQUEST_INVALID'),

  // Authentication Events
  loginInitiated('LOGIN_INITIATED'),
  loginOtpGenerated('LOGIN_OTP_GENERATED'),
  loginOtpFailed('LOGIN_OTP_FAILED'),
  loginOtpLocked('LOGIN_OTP_LOCKED'),
  loginOtpVerified('LOGIN_OTP_VERIFIED'),
  loginOtpNotVerified('LOGIN_OTP_NOT_VERIFIED'),
  loginWithSnaSucceeded('LOGIN_WITH_SNA_SUCCEDED'),
  loginSnaTokenVerified('LOGIN_SNA_TOKEN_VERIFIED'),
  loginSnaFailed('LOGIN_SNA_FAILED'),
  loginFallbackInitiated('LOGIN_FALLBACK_INITIATED'),

  // Discovery Events
  discoveryInitiated('DISCOVERY_INITIATED'),
  accountsDiscovered('ACCOUNTS_DISCOVERED'),
  discoveryFailed('DISCOVERY_FAILED'),
  accountsNotDiscovered('ACCOUNTS_NOT_DISCOVERED'),

  // Linking Events
  linkingInitiated('LINKING_INITIATED'),
  linkingOtpGenerated('LINKING_OTP_GENERATED'),
  linkingOtpFailed('LINKING_OTP_FAILED'),
  linkingSuccess('LINKING_SUCCESS'),
  linkingFailure('LINKING_FAILURE'),

  // Consent Events
  linkedAccountsSummary('LINKED_ACCOUNTS_SUMMARY'),
  consentApproved('CONSENT_APPROVED'),
  consentDenied('CONSENT_DENIED'),
  approveConsentFailed('APPROVE_CONSENT_FAILED'),
  consentHandleFailed('CONSENT_HANDLE_FAILED'),
  getConsentStatusFailed('GET_CONSENT_STATUS_FAILED'),

  // Error Events
  sessionError('SESSION_ERROR'),
  sessionFailure('SESSION_FAILURE');

  final String eventName;
  const FinvuEventType(this.eventName);
}
