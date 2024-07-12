import 'package:finvu_flutter_sdk/finvu_config.dart';
import 'package:finvu_flutter_sdk/generated/native_finvu_manager.g.dart';
import 'package:finvu_flutter_sdk_core/finvu_consent_info.dart';
import 'package:finvu_flutter_sdk_core/finvu_discovered_accounts.dart';
import 'package:finvu_flutter_sdk_core/finvu_exception.dart';
import 'package:finvu_flutter_sdk_core/finvu_fip_details.dart';
import 'package:finvu_flutter_sdk_core/finvu_handle_info.dart';
import 'package:finvu_flutter_sdk_core/finvu_linked_accounts.dart';
import 'package:flutter/services.dart';

class FinvuManager {
  final _nativeFinvuManager = NativeFinvuManager();

  static final FinvuManager _instance = FinvuManager._internal();

  factory FinvuManager() {
    return _instance;
  }

  FinvuManager._internal();

  get _platformExceptionTest => (e) => e is PlatformException;

  /// Initializes the SDK with the [config]
  void initialize(final FinvuConfig config) {
    final NativeFinvuConfig nativeFinvuConfig = NativeFinvuConfig(
      finvuEndpoint: config.finvuEndpoint,
      certificatePins: config.certificatePins,
    );
    _nativeFinvuManager.initialize(nativeFinvuConfig);
  }

  /// Connects to the Finvu AA server
  Future<void> connect() {
    return _nativeFinvuManager.connect().catchError(
          (e) => throw FinvuException.from(e),
          test: _platformExceptionTest,
        );
  }

  /// Disconnect from the Finvu AA server
  void disconnect() {
    _nativeFinvuManager.disconnect();
  }

  /// Check if the SDK is connected to the Finvu AA server
  Future<bool> isConnected() {
    return _nativeFinvuManager.isConnected().catchError(
          (e) => throw FinvuException.from(e),
          test: _platformExceptionTest,
        );
  }

  /// Check if the SDK has an active session
  Future<bool> hasSession() {
    return _nativeFinvuManager.hasSession();
  }

  /// Login with [username] or [mobileNumber].
  /// One of [username] or [mobileNumber] is required. Calling this API will
  /// initiate an OTP to users registered mobile number via the AA servers.
  ///
  /// [FinvuLoginOtpReference] is returned on success.
  /// Thows [FinvuException] on failure.
  Future<FinvuLoginOtpReference>
      loginWithUsernameOrMobileNumberAndConsentHandle(
    String? username,
    String? mobileNumber,
    String consentHandleId,
  ) {
    return _nativeFinvuManager
        .loginWithUsernameOrMobileNumberAndConsentHandle(
          username,
          mobileNumber,
          consentHandleId,
        )
        .then(
          (otpReference) => FinvuLoginOtpReference(
            reference: otpReference.reference,
          ),
        )
        .catchError(
          (e) => throw FinvuException.from(e),
          test: _platformExceptionTest,
        );
  }

  /// Verify the [otp] received on the registered mobile number. [otpReference]
  /// received in [loginWithUsernameOrMobileNumberAndConsentHandle]
  ///
  /// [FinvuHandleInfo] is returned on success, and session is established.
  /// Thows [FinvuException] on failure.
  Future<FinvuHandleInfo> verifyLoginOtp(
    String otp,
    String otpReference,
  ) {
    return _nativeFinvuManager
        .verifyLoginOtp(otp, otpReference)
        .then(
          (handleInfo) => FinvuHandleInfo(userId: handleInfo.userId),
        )
        .catchError(
          (e) => throw FinvuException.from(e),
          test: _platformExceptionTest,
        );
  }

  /// Initiates mobile verification for the given [mobileNumber]. Sometimes a
  /// user might want to use a different mobile than the one used for logging in,
  /// in which case they need to verify such a mobile before performing a request
  /// like discovery. This API needs to be called within an authenticated session
  /// (i.e. after [verifyLoginOtp]) to register additional mobiles with Finvu AA.
  /// Calling this API will trigger an OTP to the given mobile number.
  ///
  /// Throws [FinvuException] on failure.
  Future<void> initiateMobileVerification(String mobileNumber) {
    return _nativeFinvuManager
        .initiateMobileVerification(mobileNumber)
        .catchError(
          (e) => throw FinvuException.from(e),
          test: _platformExceptionTest,
        );
  }

  /// Completes the mobile verification process for the given [mobileNumber] and [otp].
  /// The mobile number is only added for current session.
  ///
  /// Throws [FinvuException] on failure.
  Future<void> completeMobileVerification(String mobileNumber, String otp) {
    return _nativeFinvuManager
        .completeMobileVerification(mobileNumber, otp)
        .catchError(
          (e) => throw FinvuException.from(e),
          test: _platformExceptionTest,
        );
  }

  /// Fetch the linked accounts for the current user. If there are no linked
  /// accounts, account discovery and linking should be performed to discover
  /// and link accounts, and then invoke this API again to get the list of
  /// accounts to display for selecting the account for inclusion in the consent.
  ///
  /// Returns a list of [FinvuLinkedAccountDetailsInfo] on success.
  /// Throws [FinvuException] on failure.
  Future<List<FinvuLinkedAccountDetailsInfo>> fetchLinkedAccounts() {
    return _nativeFinvuManager
        .fetchLinkedAccounts()
        .then(
          (value) => value.linkedAccounts.nonNulls
              .map(
                (account) => FinvuLinkedAccountDetailsInfo(
                  userId: account.userId,
                  fipId: account.fipId,
                  fipName: account.fipName,
                  maskedAccountNumber: account.maskedAccountNumber,
                  accountReferenceNumber: account.accountReferenceNumber,
                  linkReferenceNumber: account.linkReferenceNumber,
                  consentIdList: account.consentIdList?.nonNulls.toList(),
                  fiType: account.fiType,
                  accountType: account.accountType,
                  linkedAccountUpdateTimestamp: account
                              .linkedAccountUpdateTimestamp !=
                          null
                      ? DateTime.tryParse(account.linkedAccountUpdateTimestamp!)
                      : null,
                  authenticatorType: account.authenticatorType,
                ),
              )
              .toList(),
        )
        .catchError(
          (e) => throw FinvuException.from(e),
          test: _platformExceptionTest,
        );
  }

  /// Fetch the list of accounts that the user has with [fipDetails]. Accounts
  /// will be discovered for all [fiTypes]. [identifiers] should be passed to
  /// discover accounts as per REBIT spec for the [fiTypes].
  ///
  /// Returns a list of [FinvuDiscoveredAccountInfo] on success.
  /// Throws [FinvuException] on failure.
  Future<List<FinvuDiscoveredAccountInfo>> discoverAccounts(
    FinvuFIPDetails fipDetails,
    List<String> fiTypes,
    List<FinvuTypeIdentifierInfo> identifiers,
  ) {
    final NativeFIPDetails nativeFipDetails = NativeFIPDetails(
      fipId: fipDetails.fipId,
      typeIdentifiers: fipDetails.typeIdentifiers
          .map(
            (fipFiTypeIdentifier) => NativeFIPFiTypeIdentifier(
              fiType: fipFiTypeIdentifier.fiType,
              identifiers: fipFiTypeIdentifier.identifiers
                  .map(
                    (typeIdentifier) => NativeTypeIdentifier(
                      type: typeIdentifier.type,
                      category: typeIdentifier.category,
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
    );

    final List<NativeTypeIdentifierInfo> nativeTypeIdentifierInfo = identifiers
        .map(
          (identifier) => NativeTypeIdentifierInfo(
            category: identifier.category,
            type: identifier.type,
            value: identifier.value,
          ),
        )
        .toList();

    return _nativeFinvuManager
        .discoverAccounts(nativeFipDetails, fiTypes, nativeTypeIdentifierInfo)
        .then(
          (response) => response.accounts.nonNulls
              .map(
                (account) => FinvuDiscoveredAccountInfo(
                  accountType: account.accountType,
                  accountReferenceNumber: account.accountReferenceNumber,
                  maskedAccountNumber: account.maskedAccountNumber,
                  fiType: account.fiType,
                ),
              )
              .toList(),
        )
        .catchError(
          (e) => throw FinvuException.from(e),
          test: _platformExceptionTest,
        );
  }

  /// API to initiate the account linking process for [accounts] with [fipDetails].
  /// This API will trigger an OTP to the registered mobile number of the user.
  ///
  /// Returns a [FinvuAccountLinkingRequestReference] on success.
  /// Throws [FinvuException] on failure.
  Future<FinvuAccountLinkingRequestReference> linkAccounts(
    FinvuFIPDetails fipDetails,
    List<FinvuDiscoveredAccountInfo> accounts,
  ) {
    final nativeFipDetails = NativeFIPDetails(
      fipId: fipDetails.fipId,
      typeIdentifiers: fipDetails.typeIdentifiers
          .map(
            (typeIdentifier) => NativeFIPFiTypeIdentifier(
              fiType: typeIdentifier.fiType,
              identifiers: typeIdentifier.identifiers
                  .map(
                    (identifier) => NativeTypeIdentifier(
                      type: identifier.type,
                      category: identifier.category,
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
    );

    final nativeAccounts = accounts
        .map(
          (account) => NativeDiscoveredAccountInfo(
            accountType: account.accountType,
            accountReferenceNumber: account.accountReferenceNumber,
            maskedAccountNumber: account.maskedAccountNumber,
            fiType: account.fiType,
          ),
        )
        .toList();

    return _nativeFinvuManager
        .linkAccounts(nativeFipDetails, nativeAccounts)
        .then(
          (value) => FinvuAccountLinkingRequestReference(
              referenceNumber: value.referenceNumber),
        )
        .catchError(
          (e) => throw FinvuException.from(e),
          test: _platformExceptionTest,
        );
  }

  /// Confirm the account linking process with the [otp] received on the
  /// registered mobile number and [requestReference] received in [linkAccounts]
  ///
  /// Returns a list of [FinvuLinkedAccountInfo] on success.
  /// Throws [FinvuException] on failure.
  Future<FinvuConfirmAccountLinkingInfo> confirmAccountLinking(
    FinvuAccountLinkingRequestReference requestReference,
    String otp,
  ) {
    final nativeRequestReference = NativeAccountLinkingRequestReference(
      referenceNumber: requestReference.referenceNumber,
    );
    return _nativeFinvuManager
        .confirmAccountLinking(nativeRequestReference, otp)
        .then(
          (value) => FinvuConfirmAccountLinkingInfo(
            linkedAccounts: value.linkedAccounts.nonNulls
                .map(
                  (account) => FinvuLinkedAccountInfo(
                    customerAddress: account.customerAddress,
                    linkReferenceNumber: account.linkReferenceNumber,
                    accountReferenceNumber: account.accountReferenceNumber,
                    status: account.status,
                  ),
                )
                .toList(),
          ),
        )
        .catchError(
          (e) => throw FinvuException.from(e),
          test: _platformExceptionTest,
        );
  }

  /// API to get consent requests raised by FIU with Finvu AA in a previous
  /// server to server
  ///
  /// Returns a list of [FinvuConsentRequestInfo] on success.
  /// Throws [FinvuException] on failure.
  Future<FinvuConsentRequestDetailInfo> getConsentRequestDetails(
    String handleId,
  ) {
    return _nativeFinvuManager
        .getConsentRequestDetails(handleId)
        .then(
          (response) => FinvuConsentRequestDetailInfo(
            consentId: response.consentId,
            consentHandle: response.consentHandleId,
            financialInformationUser: FinvuFinancialInformationEntityInfo(
              id: response.financialInformationUser.id,
              name: response.financialInformationUser.name,
            ),
            consentPurposeInfo: FinvuConsentPurposeInfo(
              code: response.consentPurposeInfo.code,
              text: response.consentPurposeInfo.text,
            ),
            consentDisplayDescriptions:
                response.consentDisplayDescriptions.nonNulls.toList(),
            dataDateTimeRange: FinvuDateTimeRange(
              from: DateTime.tryParse(response.dataDateTimeRange.from),
              to: DateTime.tryParse(response.dataDateTimeRange.to),
            ),
            consentDateTimeRange: FinvuDateTimeRange(
              from: DateTime.tryParse(response.consentDateTimeRange.from),
              to: DateTime.tryParse(response.consentDateTimeRange.to),
            ),
            consentDataFrequency: FinvuConsentDataFrequency(
              unit: response.consentDataFrequency.unit,
              value: response.consentDataFrequency.value,
            ),
            consentDataLifePeriod: FinvuConsentDataLifePeriod(
              unit: response.consentDataLifePeriod.unit,
              value: response.consentDataLifePeriod.value,
            ),
            fiTypes: response.fiTypes?.nonNulls.toList(),
          ),
        )
        .catchError(
          (e) => throw FinvuException.from(e),
          test: _platformExceptionTest,
        );
  }

  /// API to approve the consent request raised by FIU with Finvu AA. This API
  /// should be called after the user has selected the [linkedAccounts] to be
  /// included  in the [consentInfo].
  ///
  /// Returns a [FinvuProcessConsentRequestResponse] on success.
  /// Throws [FinvuException] on failure.
  Future<FinvuProcessConsentRequestResponse> approveConsentRequest(
    FinvuConsentRequestDetailInfo consentInfo,
    List<FinvuLinkedAccountDetailsInfo> linkedAccounts,
  ) {
    final nativeConsentInfo = NativeConsentRequestDetailInfo(
      consentHandleId: consentInfo.consentHandle,
      financialInformationUser: NativeFinancialInformationEntity(
        id: consentInfo.financialInformationUser.id,
        name: consentInfo.financialInformationUser.name,
      ),
      consentPurposeInfo: NativeConsentPurposeInfo(
        code: consentInfo.consentPurposeInfo.code,
        text: consentInfo.consentPurposeInfo.text,
      ),
      consentDisplayDescriptions: consentInfo.consentDisplayDescriptions,
      dataDateTimeRange: NativeDateTimeRange(
        from: consentInfo.dataDateTimeRange.from?.toIso8601String() ?? "",
        to: consentInfo.dataDateTimeRange.to?.toIso8601String() ?? "",
      ),
      consentDateTimeRange: NativeDateTimeRange(
        from: consentInfo.consentDateTimeRange.from?.toIso8601String() ?? "",
        to: consentInfo.consentDateTimeRange.to?.toIso8601String() ?? "",
      ),
      consentDataFrequency: NativeConsentDataFrequency(
        unit: consentInfo.consentDataFrequency.unit,
        value: consentInfo.consentDataFrequency.value,
      ),
      consentDataLifePeriod: NativeConsentDataLifePeriod(
        unit: consentInfo.consentDataLifePeriod.unit,
        value: consentInfo.consentDataLifePeriod.value,
      ),
    );

    final nativeLinkedAccounts = linkedAccounts
        .map(
          (account) => NativeLinkedAccountDetailsInfo(
            userId: account.userId,
            fipId: account.fipId,
            fipName: account.fipName,
            maskedAccountNumber: account.maskedAccountNumber,
            accountReferenceNumber: account.accountReferenceNumber,
            linkReferenceNumber: account.linkReferenceNumber,
            consentIdList: account.consentIdList,
            fiType: account.fiType,
            accountType: account.accountType,
            linkedAccountUpdateTimestamp:
                account.linkedAccountUpdateTimestamp?.toIso8601String(),
            authenticatorType: account.authenticatorType,
          ),
        )
        .toList();

    return _nativeFinvuManager
        .approveConsentRequest(nativeConsentInfo, nativeLinkedAccounts)
        .then(
          (response) => FinvuProcessConsentRequestResponse(
            consentIntentId: response.consentIntentId,
            consentInfo: response.consentInfo?.nonNulls
                .map(
                  (consentInfo) => FinvuConsentInfo(
                    consentId: consentInfo.consentId,
                    fipId: consentInfo.fipId,
                  ),
                )
                .toList(),
          ),
        )
        .catchError(
          (e) => throw FinvuException.from(e),
          test: _platformExceptionTest,
        );
  }

  /// API to deny the consent request raised by FIU with Finvu AA.
  ///
  /// Returns a [FinvuProcessConsentRequestResponse] on success.
  /// Throws [FinvuException] on failure.
  Future<FinvuProcessConsentRequestResponse> denyConsentRequest(
    FinvuConsentRequestDetailInfo consentInfo,
  ) {
    final nativeConsentInfo = NativeConsentRequestDetailInfo(
      consentHandleId: consentInfo.consentHandle,
      financialInformationUser: NativeFinancialInformationEntity(
        id: consentInfo.financialInformationUser.id,
        name: consentInfo.financialInformationUser.name,
      ),
      consentPurposeInfo: NativeConsentPurposeInfo(
        code: consentInfo.consentPurposeInfo.code,
        text: consentInfo.consentPurposeInfo.text,
      ),
      consentDisplayDescriptions: consentInfo.consentDisplayDescriptions,
      dataDateTimeRange: NativeDateTimeRange(
        from: consentInfo.dataDateTimeRange.from?.toIso8601String() ?? "",
        to: consentInfo.dataDateTimeRange.to?.toIso8601String() ?? "",
      ),
      consentDateTimeRange: NativeDateTimeRange(
        from: consentInfo.consentDateTimeRange.from?.toIso8601String() ?? "",
        to: consentInfo.consentDateTimeRange.to?.toIso8601String() ?? "",
      ),
      consentDataFrequency: NativeConsentDataFrequency(
        unit: consentInfo.consentDataFrequency.unit,
        value: consentInfo.consentDataFrequency.value,
      ),
      consentDataLifePeriod: NativeConsentDataLifePeriod(
        unit: consentInfo.consentDataLifePeriod.unit,
        value: consentInfo.consentDataLifePeriod.value,
      ),
    );

    return _nativeFinvuManager
        .denyConsentRequest(nativeConsentInfo)
        .then(
          (response) => FinvuProcessConsentRequestResponse(
            consentIntentId: response.consentIntentId,
            consentInfo: response.consentInfo?.nonNulls
                .map(
                  (consentInfo) => FinvuConsentInfo(
                    consentId: consentInfo.consentId,
                    fipId: consentInfo.fipId,
                  ),
                )
                .toList(),
          ),
        )
        .catchError(
          (e) => throw FinvuException.from(e),
          test: _platformExceptionTest,
        );
  }

  /// API to revoke the consent for the given [consentId] and [consent].
  ///
  /// Throws [FinvuException] on failure.
  Future<void> revokeConsent(String consentId, FinvuUserConsentInfo consent,
      AccountAggregator? accountAggregator, FIPReference? fipDetails) {
    final nativeConsent = NativeUserConsentInfoDetails(
      consentId: consentId,
      consentIntentEntityId: consent.consentIntentEntityId,
      consentIdList: consent.consentIdList,
      consentIntentEntityName: consent.consentIntentEntityName,
      consentIntentUpdateTimestamp:
          consent.consentIntentUpdateTimestamp?.toIso8601String() ?? "",
      consentPurposeText: consent.consentPurposeText,
      status: consent.status,
    );
    final nativeAA = accountAggregator != null
        ? NativeAccountAggregator(id: accountAggregator.id!)
        : null;
    final nativeFipDetails = fipDetails != null
        ? NativeFIPReference(
            fipId: fipDetails.fipId, fipName: fipDetails.fipName)
        : null;

    return _nativeFinvuManager
        .revokeConsent(nativeConsent, nativeAA, nativeFipDetails)
        .catchError(
          (e) => throw FinvuException.from(e),
          test: _platformExceptionTest,
        );
  }

  /// Gets the status of the [handleId] after it has been approved by the user.
  /// When the user approves a consent request, AA server will need to post the
  /// consent to all the FIPs selected by the user. Once all FIPs have accepted
  /// the consent posted by AA, AA server will change the status of the consent
  /// [handleId] to READY. If any FIP rejects the consent, then the status will
  /// change to REJECTED.
  /// Note: This api can only be called a limited number of times, usually 5
  /// times. If any attempts to call this api more than the allowed number of
  /// times, the websocket session will be terminated and the connection will
  /// become unusable. This is to prevent any runaway client process trying to
  /// poll the consent handle status in an endless loop.
  ///
  /// Returns a [FinvuConsentHandleStatusResponse] on success.
  /// Throws [FinvuException] on failure.
  Future<FinvuConsentHandleStatusResponse> getConsentHandleStatus(
    String handleId,
  ) {
    return _nativeFinvuManager
        .getConsentHandleStatus(handleId)
        .then(
          (response) => FinvuConsentHandleStatusResponse(
            status: response.status,
          ),
        )
        .catchError(
          (e) => throw FinvuException.from(e),
          test: _platformExceptionTest,
        );
  }

  /// API to logout the user from the Finvu AA server. This will invalidate the
  /// session and the user will need to login again to perform any further operations.
  ///
  /// Throws [FinvuException] on failure.
  Future<void> logout() {
    return _nativeFinvuManager.logout().catchError(
          (e) => throw FinvuException.from(e),
          test: _platformExceptionTest,
        );
  }
}
