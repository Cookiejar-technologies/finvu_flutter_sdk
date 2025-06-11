import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/generated/native_finvu_manager.g.dart',
  kotlinOut:
      'android/src/main/kotlin/com/finvu/finvu_flutter_sdk/generated/NativeFinvuManager.g.kt',
  swiftOut: 'ios/Classes/generated/NativeFinvuManager.g.swift',
  kotlinOptions: KotlinOptions(errorClassName: 'NativeFinvuError'),
))
class NativeFinvuConfig {
  NativeFinvuConfig({
    required this.finvuEndpoint,
    this.certificatePins,
  });
  String finvuEndpoint;
  List<String?>? certificatePins;
}

class NativeHandleInfo {
  NativeHandleInfo({required this.userId});
  String userId;
}

class NativeFIPDetails {
  NativeFIPDetails({
    required this.fipId,
    required this.typeIdentifiers,
  });
  String fipId;
  List<NativeFIPFiTypeIdentifier?> typeIdentifiers;
}

class NativeFIPFiTypeIdentifier {
  NativeFIPFiTypeIdentifier({
    required this.fiType,
    required this.identifiers,
  });
  String fiType;
  List<NativeTypeIdentifier?> identifiers;
}

class NativeTypeIdentifier {
  NativeTypeIdentifier({
    required this.type,
    required this.category,
  });
  String type;
  String category;
}

class NativeTypeIdentifierInfo {
  NativeTypeIdentifierInfo({
    required this.category,
    required this.type,
    required this.value,
  });
  String category;
  String type;
  String value;
}

class NativeDiscoveredAccountInfo {
  NativeDiscoveredAccountInfo({
    required this.accountType,
    required this.accountReferenceNumber,
    required this.maskedAccountNumber,
    required this.fiType,
  });
  String accountType;
  String accountReferenceNumber;
  String maskedAccountNumber;
  String fiType;
}

class NativeDiscoveredAccountsResponse {
  NativeDiscoveredAccountsResponse({
    required this.accounts,
  });

  List<NativeDiscoveredAccountInfo?> accounts;
}

class NativeAccountLinkingRequestReference {
  NativeAccountLinkingRequestReference({
    required this.referenceNumber,
  });
  String referenceNumber;
}

class NativeLinkedAccountInfo {
  NativeLinkedAccountInfo({
    required this.customerAddress,
    required this.linkReferenceNumber,
    required this.accountReferenceNumber,
    required this.status,
  });
  String customerAddress;
  String linkReferenceNumber;
  String accountReferenceNumber;
  String status;
}

class NativeConfirmAccountLinkingInfo {
  NativeConfirmAccountLinkingInfo({
    required this.linkedAccounts,
  });
  List<NativeLinkedAccountInfo?> linkedAccounts;
}

class NativeLinkedAccountsResponse {
  NativeLinkedAccountsResponse({
    required this.linkedAccounts,
  });
  List<NativeLinkedAccountDetailsInfo?> linkedAccounts;
}

class NativeLinkedAccountDetailsInfo {
  NativeLinkedAccountDetailsInfo({
    required this.userId,
    required this.fipId,
    required this.fipName,
    required this.maskedAccountNumber,
    required this.accountReferenceNumber,
    required this.linkReferenceNumber,
    required this.consentIdList,
    required this.fiType,
    required this.accountType,
    required this.linkedAccountUpdateTimestamp,
    required this.authenticatorType,
  });
  String userId;
  String fipId;
  String fipName;
  String maskedAccountNumber;
  String accountReferenceNumber;
  String linkReferenceNumber;
  List<String?>? consentIdList;
  String fiType;
  String accountType;
  String? linkedAccountUpdateTimestamp;
  String authenticatorType;
}

class NativeFinancialInformationEntity {
  NativeFinancialInformationEntity({
    required this.id,
    required this.name,
  });

  String id;
  String name;
}

class NativeConsentPurposeInfo {
  NativeConsentPurposeInfo({
    required this.code,
    required this.text,
  });

  String code;
  String text;
}

class NativeConsentRequestDetailInfo {
  NativeConsentRequestDetailInfo({
    required this.consentHandleId,
    required this.consentId,
    required this.statusLastUpdateTimestamp,
    required this.financialInformationUser,
    required this.consentPurposeInfo,
    required this.consentDisplayDescriptions,
    required this.dataDateTimeRange,
    required this.consentDateTimeRange,
    required this.consentDataFrequency,
    required this.consentDataLifePeriod,
    required this.fiTypes,
  });

  String consentHandleId;
  String? consentId;
  NativeFinancialInformationEntity financialInformationUser;
  NativeConsentPurposeInfo consentPurposeInfo;
  List<String?> consentDisplayDescriptions;
  NativeDateTimeRange dataDateTimeRange;
  NativeDateTimeRange consentDateTimeRange;
  NativeConsentDataFrequency consentDataFrequency;
  NativeConsentDataLifePeriod consentDataLifePeriod;
  List<String?>? fiTypes;
  String? statusLastUpdateTimestamp;
}

class NativeDateTimeRange {
  NativeDateTimeRange({
    required this.from,
    required this.to,
  });

  String from;
  String to;
}

class NativeConsentDataFrequency {
  NativeConsentDataFrequency({
    required this.unit,
    required this.value,
  });

  String unit;
  double value;
}

class NativeConsentDataLifePeriod {
  NativeConsentDataLifePeriod({
    required this.unit,
    required this.value,
  });

  String unit;
  double value;
}

class NativeConsentInfo {
  NativeConsentInfo({
    required this.consentId,
    required this.fipId,
  });

  String consentId;
  String? fipId;
}

class NativeProcessConsentRequestResponse {
  NativeProcessConsentRequestResponse({
    required this.consentIntentId,
    required this.consentInfo,
  });

  String? consentIntentId;
  List<NativeConsentInfo?>? consentInfo;
}

class NativeUserConsentInfo {
  NativeUserConsentInfo({
    required this.consentIntentId,
    required this.consentIntentEntityId,
    required this.consentIntentEntityName,
    required this.consentIdList,
    required this.consentIntentUpdateTimestamp,
    required this.consentPurposeText,
    required this.status,
  });

  String consentIntentId;
  String? consentIntentEntityId;
  String consentIntentEntityName;
  List<String?> consentIdList;
  String consentIntentUpdateTimestamp;
  String consentPurposeText;
  String? status;
}

class NativeUserConsentInfoDetails {
  NativeUserConsentInfoDetails({
    required this.consentId,
    required this.consentIntentEntityId,
    required this.consentIntentEntityName,
    required this.consentIdList,
    required this.consentIntentUpdateTimestamp,
    required this.consentPurposeText,
    required this.status,
  });

  String consentId;
  String? consentIntentEntityId;
  String consentIntentEntityName;
  List<String?> consentIdList;
  String consentIntentUpdateTimestamp;
  String consentPurposeText;
  String? status;
}

class NativeAccountAggregator {
  NativeAccountAggregator({
    required this.id,
  });

  String id;
}

class NativeFIPReference {
  NativeFIPReference({
    required this.fipId,
    required this.fipName,
  });

  String fipId;
  String fipName;
}

class NativeConsentAccountDetails {
  NativeConsentAccountDetails({
    required this.accountReferenceNumber,
    required this.maskedAccountNumber,
    required this.fiType,
    required this.accountType,
    required this.linkReferenceNumber,
    required this.fipId,
  });

  String fiType;
  String fipId;
  String accountType;
  String? accountReferenceNumber;
  String maskedAccountNumber;
  String linkReferenceNumber;
}

class NativeLoginOtpReference {
  NativeLoginOtpReference({
    required this.reference,
  });
  String reference;
}

class NativeConsentHandleStatusResponse {
  NativeConsentHandleStatusResponse({
    required this.status,
  });
  String status;
}

class NativeFIPInfo {
  NativeFIPInfo({
    required this.fipId,
    required this.productName,
    required this.fipFitypes,
    required this.productDesc,
    required this.productIconUri,
    required this.enabled,
    this.fipFsr,
  });

  String fipId;
  String? productName;
  List<String?> fipFitypes;
  String? fipFsr;
  String? productDesc;
  String? productIconUri;
  bool enabled;
}

class NativeFIPSearchResponse {
  NativeFIPSearchResponse({
    required this.searchOptions,
  });
  List<NativeFIPInfo?> searchOptions;
}

class NativeEntityInfo {
  NativeEntityInfo({
    required this.entityId,
    required this.entityName,
    required this.entityIconUri,
    required this.entityLogoUri,
    required this.entityLogoWithNameUri,
  });

  String entityId;
  String entityName;
  String? entityIconUri;
  String? entityLogoUri;
  String? entityLogoWithNameUri;
}

@HostApi()
abstract class NativeFinvuManager {
  void initialize(NativeFinvuConfig config);

  @async
  void connect();

  void disconnect();

  bool isConnected();

  bool hasSession();

  @async
  NativeLoginOtpReference loginWithUsernameOrMobileNumberAndConsentHandle(
    String? username,
    String? mobileNumber,
    String consentHandleId,
  );

  @async
  NativeHandleInfo verifyLoginOtp(
    String otp,
    String otpReference,
  );

  @async
  NativeDiscoveredAccountsResponse discoverAccountsAsync(
    String fipId,
    List<String> fiTypes,
    List<NativeTypeIdentifierInfo> identifiers,
  );

  @async
  NativeDiscoveredAccountsResponse discoverAccounts(
    String fipId,
    List<String> fiTypes,
    List<NativeTypeIdentifierInfo> identifiers,
  );

  @async
  NativeAccountLinkingRequestReference linkAccounts(
    NativeFIPDetails fipDetails,
    List<NativeDiscoveredAccountInfo> accounts,
  );

  @async
  NativeConfirmAccountLinkingInfo confirmAccountLinking(
    NativeAccountLinkingRequestReference requestReference,
    String otp,
  );

  @async
  NativeLinkedAccountsResponse fetchLinkedAccounts();

  @async
  void initiateMobileVerification(String mobileNumber);

  @async
  void completeMobileVerification(String mobileNumber, String otp);

  @async
  NativeFIPSearchResponse fipsAllFIPOptions();

  @async
  NativeFIPDetails fetchFIPDetails(String fipId);

  @async
  NativeEntityInfo getEntityInfo(String entityId, String entityType);

  @async
  NativeProcessConsentRequestResponse approveConsentRequest(
    NativeConsentRequestDetailInfo consentRequest,
    List<NativeLinkedAccountDetailsInfo> linkedAccounts,
  );

  @async
  NativeProcessConsentRequestResponse denyConsentRequest(
    NativeConsentRequestDetailInfo consentRequest,
  );

  @async
  void revokeConsent(
    String consentId,
    NativeAccountAggregator? accountAggregator,
    NativeFIPReference? fipDetails,
  );

  @async
  NativeConsentHandleStatusResponse getConsentHandleStatus(String handleId);

  @async
  NativeConsentRequestDetailInfo getConsentRequestDetails(String handleId);

  @async
  void logout();
}
