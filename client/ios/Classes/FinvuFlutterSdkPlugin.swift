import Flutter
import UIKit
import FinvuSDK

// This extension of Error is required to do use FlutterError in any Swift code.
extension FlutterError: Error {}

public class FinvuFlutterSdkPlugin: NSObject, FlutterPlugin, NativeFinvuManager {
    func loginWithUsernameOrMobileNumberAndConsentHandle(username: String?, mobileNumber: String?, consentHandleId: String, completion: @escaping (Result<NativeLoginOtpReference, any Error>) -> Void) {
        FinvuManager.shared.loginWith(username: username, mobileNumber: mobileNumber, consentHandleId: consentHandleId) { loginReference, error in
            if (error != nil) {
                completion(.failure(FlutterError(code: "\(error!.code)", message: error?.localizedDescription, details: nil)))
            } else {
                completion(.success(NativeLoginOtpReference(reference: loginReference!.reference, snaToken: loginReference!.snaToken ?? "", authType: loginReference!.authType ?? "")))
            }
        }
    }
    
    
    let formatter = ISO8601DateFormatter();
    
    // Event listener properties
    private var eventListener: FinvuEventListener? = nil
    private var nativeEventListener: NativeFinvuEventListener? = nil
    private var binaryMessenger: FlutterBinaryMessenger? = nil
    
    public override init() {
        super.init()
        formatter.formatOptions =  [.withInternetDateTime, .withFractionalSeconds]
    }
    
    private func convertToNativeEnvironment(environment: FinvuEnv) -> FinvuSDK.FinvuEnvironment {
        switch environment {
        case .uat:
            return .uat
        case .production:
            return .production
        }
    }
    
    // Resolve a view controller safely on iOS 13+
    private func currentRootViewController() -> UIViewController? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger : FlutterBinaryMessenger = registrar.messenger()
        let api : NativeFinvuManager & NSObjectProtocol = FinvuFlutterSdkPlugin.init()
        NativeFinvuManagerSetup.setUp(binaryMessenger: messenger, api: api);
        
        // Store binary messenger and create native event listener
        if let plugin = api as? FinvuFlutterSdkPlugin {
            plugin.binaryMessenger = messenger
            plugin.nativeEventListener = NativeFinvuEventListener(binaryMessenger: messenger)
        }
    }
    
    func initialize(config: NativeFinvuConfig) throws {
        let finvuUrl = URL(string: config.finvuEndpoint)!
        let pins = config.certificatePins?.compactMap { $0 }
        
        // Create SNA auth config if provided
        var finvuSnaAuthConfig: FinvuSnaAuthConfig? = nil
        if let snaConfig = config.finvuSnaAuthConfig {
            // Get the root view controller using the same pattern as reference
            guard let vc = currentRootViewController() else {
                throw FlutterError(code: "INITIALIZATION_ERROR", message: "Unable to get root view controller", details: nil)
            }
            
            let environment = convertToNativeEnvironment(environment: snaConfig.environment)
            // Create config with proper parameter order: environment must precede viewController
            // Ensure initialization happens on main thread like reference implementation
            finvuSnaAuthConfig = FinvuSnaAuthConfig(environment: environment, viewController: vc)
        }
        
        let finvuConfig = FinvuClientConfig(finvuEndpoint: finvuUrl, certificatePins: pins, finvuSnaAuthConfig: finvuSnaAuthConfig)
        FinvuManager.shared.initializeWith(config: finvuConfig)
    }
    
    func connect(completion: @escaping (Result<Void, Error>) -> Void) {
        FinvuManager.shared.connect { error in
            if (error != nil) {
                completion(.failure((FlutterError(code: "\(error!.code)", message: error?.localizedDescription, details: nil))))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func disconnect() throws {
        FinvuManager.shared.disconnect()
    }
    
    func isConnected() throws -> Bool {
        return FinvuManager.shared.isConnected()
    }
    
    func hasSession() throws -> Bool {
        return FinvuManager.shared.hasSession()
    }
    
    func verifyLoginOtp(otp: String, otpReference: String, completion: @escaping (Result<NativeHandleInfo, any Error>) -> Void) {
        FinvuManager.shared.verifyLoginOtp(otp: otp, otpReference: otpReference) { handleInfo, error in
            if (error != nil) {
                completion(.failure(FlutterError(code: "\(error!.code)", message: error?.localizedDescription, details: nil)))
            } else {
                completion(.success(NativeHandleInfo(userId: handleInfo!.userId)))
            }
        }
    }
    
    func discoverAccounts(fipId: String, fiTypes: [String], identifiers : [NativeTypeIdentifierInfo], completion: @escaping (Result<NativeDiscoveredAccountsResponse, Error>) -> Void) {
        let identifiers = identifiers.map { nativeTypeIdentifierInfo in
            TypeIdentifierInfo(category: nativeTypeIdentifierInfo.category, type: nativeTypeIdentifierInfo.type, value: nativeTypeIdentifierInfo.value)
        }
        
        FinvuManager.shared.discoverAccounts(fipId: fipId, fiTypes: fiTypes, identifiers: identifiers) { response, error in
            if (error != nil) {
                completion(.failure(FlutterError(code: "\(error!.code)", message: error?.localizedDescription, details: nil)))
                return
            }
            
            let accounts = response!.accounts.map { account in
                NativeDiscoveredAccountInfo(accountType: account.accountType, accountReferenceNumber: account.accountReferenceNumber, maskedAccountNumber: account.maskedAccountNumber, fiType: account.fiType)
            }
            completion(.success(NativeDiscoveredAccountsResponse(accounts: accounts)))
        }
    }

    func discoverAccountsAsync(fipId: String, fiTypes: [String], identifiers: [NativeTypeIdentifierInfo], completion: @escaping         (Result<NativeDiscoveredAccountsResponse, Error>) -> Void) {
        let identifiers = identifiers.map { nativeTypeIdentifierInfo in
                TypeIdentifierInfo(category: nativeTypeIdentifierInfo.category, type: nativeTypeIdentifierInfo.type, value: nativeTypeIdentifierInfo.value)
        }
            
        FinvuManager.shared.discoverAccounts(fipId: fipId, fiTypes: fiTypes, identifiers: identifiers) { response, error in
            if (error != nil) {
                completion(.failure(FlutterError(code: "\(error!.code)", message: error?.localizedDescription, details: nil)))
                return
            }
            
            let accounts = response!.accounts.map { account in
                NativeDiscoveredAccountInfo(accountType: account.accountType, accountReferenceNumber: account.accountReferenceNumber, maskedAccountNumber: account.maskedAccountNumber, fiType: account.fiType)
            }
            completion(.success(NativeDiscoveredAccountsResponse(accounts: accounts)))
        }
    }

    func linkAccounts(fipDetails: NativeFIPDetails, accounts: [NativeDiscoveredAccountInfo], completion: @escaping (Result<NativeAccountLinkingRequestReference, Error>) -> Void) {
        let fipDetails = FIPDetails(fipId: fipDetails.fipId, typeIdenifiers: fipDetails.typeIdentifiers.map({ nativeFIPFiTypeIdentifier in
            FIPFiTypeIdentifier(fiType: nativeFIPFiTypeIdentifier!.fiType, identifiers: nativeFIPFiTypeIdentifier!.identifiers.map({ nativeTypeIdentifier in
                TypeIdentifier(category: nativeTypeIdentifier!.category, type: nativeTypeIdentifier!.type)
            }))
        }))
        
        let accounts = accounts.map { account in
            DiscoveredAccountInfo(accountType: account.accountType, accountReferenceNumber: account.accountReferenceNumber, maskedAccountNumber: account.maskedAccountNumber, fiType: account.fiType)
        }
        
        FinvuManager.shared.linkAccounts(fipDetails: fipDetails, accounts: accounts) { requestReference, error in
            if (error != nil) {
                completion(.failure(FlutterError(code: "\(error!.code)", message: error?.localizedDescription, details: nil)))
                return
            }
            
            completion(.success(NativeAccountLinkingRequestReference(referenceNumber: requestReference!.referenceNumber)))
        }
    }
    
    func confirmAccountLinking(requestReference: NativeAccountLinkingRequestReference, otp: String, completion: @escaping (Result<NativeConfirmAccountLinkingInfo, Error>) -> Void) {
        FinvuManager.shared.confirmAccountLinking(linkingReference: AccountLinkingRequestReference(referenceNumber: requestReference.referenceNumber), otp: otp) { confirmAccountLinkingInfo, error in
            if (error != nil) {
                completion(.failure(FlutterError(code: "\(error!.code)", message: error?.localizedDescription, details: nil)))
                return
            }
            
            let linkedAccounts = confirmAccountLinkingInfo!.linkedAccounts.map({ account in
                NativeLinkedAccountInfo(customerAddress: account.customerAddress, linkReferenceNumber: account.linkReferenceNumber, accountReferenceNumber: account.accountReferenceNumber, status: account.status)
            })
            
            completion(.success(NativeConfirmAccountLinkingInfo(linkedAccounts: linkedAccounts)))
        }
    }
    
    func fetchLinkedAccounts(completion: @escaping (Result<NativeLinkedAccountsResponse, Error>) -> Void) {
        FinvuManager.shared.fetchLinkedAccounts { response, error in
            if (error != nil) {
                completion(.failure(FlutterError(code: "\(error!.code)", message: error?.localizedDescription, details: nil)))
                return
            }
            
            let accounts = response!.linkedAccounts?.map({ account in
                NativeLinkedAccountDetailsInfo(
                    userId: account.userId,
                    fipId: account.fipId,
                    fipName: account.fipName,
                    maskedAccountNumber: account.maskedAccountNumber,
                    accountReferenceNumber: account.accountReferenceNumber,
                    linkReferenceNumber: account.linkReferenceNumber,
                    consentIdList: account.consentIdList,
                    fiType: account.fiType,
                    accountType: account.accountType,
                    linkedAccountUpdateTimestamp: (account.linkedAccountUpdateTimestamp != nil) ? self.formatter.string(from: account.linkedAccountUpdateTimestamp!) : nil,
                    authenticatorType: account.authenticatorType
                )
            })
            
            completion(.success(NativeLinkedAccountsResponse(linkedAccounts: accounts ?? [])))
        }
    }
    
    func initiateMobileVerification(mobileNumber: String, completion: @escaping (Result<Void, Error>) -> Void) {
        FinvuManager.shared.initiateMobileVerification(mobileNumber: mobileNumber) { error in
            if (error != nil) {
                completion(.failure(FlutterError(code: "\(error!.code)", message: error?.localizedDescription, details: nil)))
                return
            }
            
            completion(.success(()))
        }
    }
    
    func completeMobileVerification(mobileNumber: String, otp: String, completion: @escaping (Result<Void, Error>) -> Void) {
        FinvuManager.shared.completeMobileVerification(mobileNumber: mobileNumber, otp: otp) { error in
            if (error != nil) {
                completion(.failure(FlutterError(code: "\(error!.code)", message: error?.localizedDescription, details: nil)))
                return
            }
            
            completion(.success(()))
        }
    }
    
    func approveConsentRequest(consentRequest: NativeConsentRequestDetailInfo, linkedAccounts: [NativeLinkedAccountDetailsInfo], completion: @escaping (Result<NativeProcessConsentRequestResponse, Error>) -> Void) {
        
        let consentDetail = ConsentRequestDetailInfo(
            consentId: consentRequest.consentId,
            consentHandle: consentRequest.consentHandleId,
            statusLastUpdateTimestamp: nil,
            financialInformationUser: FinancialInformationEntityInfo(
                id: consentRequest.financialInformationUser.id,
                name: consentRequest.financialInformationUser.name
            ),
            consentPurposeInfo: ConsentPurposeInfo(
                code: consentRequest.consentPurposeInfo.code,
                text: consentRequest.consentPurposeInfo.text
            ),
            consentDisplayDescriptions: consentRequest.consentDisplayDescriptions.filter({ description in
                description != nil
            }).map({ description in
                description!
            }),
            consentDateTimeRange: DateTimeRange(
                from: formatter.date(from: consentRequest.consentDateTimeRange.from)!,
                to: formatter.date(from: consentRequest.consentDateTimeRange.to)!
            ),
            dataDateTimeRange: DateTimeRange(
                from: formatter.date(from: consentRequest.dataDateTimeRange.from)!,
                to: formatter.date(from: consentRequest.dataDateTimeRange.to)!
            ),
            consentDataLifePeriod: ConsentDataLifePeriod(
                unit: consentRequest.consentDataLifePeriod.unit,
                value: consentRequest.consentDataLifePeriod.value
            ),
            consentDataFrequency: ConsentDataFrequency(
                unit: consentRequest.consentDataFrequency.unit,
                value: consentRequest.consentDataFrequency.value
            ),
            fiTypes: consentRequest.fiTypes?.compactMap { $0 }
        )
        
        let linkedAccountsInfo = linkedAccounts.map({ account in
            LinkedAccountDetailsInfo(
                userId: account.userId,
                fipId: account.fipId,
                fipName: account.fipName,
                maskedAccountNumber: account.maskedAccountNumber,
                accountReferenceNumber: account.accountReferenceNumber,
                linkReferenceNumber: account.linkReferenceNumber,
                consentIdList: account.consentIdList?.filter({ consentId in
                    consentId != nil
                }).map({ consentId in
                    consentId!
                }),
                fiType: account.fiType,
                accountType: account.accountType,
                linkedAccountUpdateTimestamp: (account.linkedAccountUpdateTimestamp != nil) ? formatter.date(from: account.linkedAccountUpdateTimestamp!) : nil,
                authenticatorType: account.authenticatorType
            )
        })
        
        FinvuManager.shared.approveAccountConsentRequest(consentDetail: consentDetail, linkedAccounts: linkedAccountsInfo) { response, error in
            if (error != nil) {
                completion(.failure(FlutterError(code: "\(error!.code)", message: error?.localizedDescription, details: nil)))
                return
            }
            
            let consentResponse = NativeProcessConsentRequestResponse(
                consentIntentId: response?.consentIntentId,
                consentInfo: response?.consentsInfo?.map({ consentInfo in
                    NativeConsentInfo(consentId: consentInfo.consentId, fipId: consentInfo.fipId)
                })
            )
            
            completion(.success(consentResponse))
        }
    }
    
    func denyConsentRequest(consentRequest: NativeConsentRequestDetailInfo, completion: @escaping (Result<NativeProcessConsentRequestResponse, Error>) -> Void) {
        let consentDetail = ConsentRequestDetailInfo(
            consentId: consentRequest.consentId,
            consentHandle: consentRequest.consentHandleId,
            statusLastUpdateTimestamp: nil,
            financialInformationUser: FinancialInformationEntityInfo(
                id: consentRequest.financialInformationUser.id,
                name: consentRequest.financialInformationUser.name
            ),
            consentPurposeInfo: ConsentPurposeInfo(
                code: consentRequest.consentPurposeInfo.code,
                text: consentRequest.consentPurposeInfo.text
            ),
            consentDisplayDescriptions: consentRequest.consentDisplayDescriptions.filter({ description in
                description != nil
            }).map({ description in
                description!
            }),
            consentDateTimeRange: DateTimeRange(
                from: formatter.date(from: consentRequest.consentDateTimeRange.from)!,
                to: formatter.date(from: consentRequest.consentDateTimeRange.to)!
            ),
            dataDateTimeRange: DateTimeRange(
                from: formatter.date(from: consentRequest.dataDateTimeRange.from)!,
                to: formatter.date(from: consentRequest.dataDateTimeRange.to)!
            ),
            consentDataLifePeriod: ConsentDataLifePeriod(
                unit: consentRequest.consentDataLifePeriod.unit,
                value: consentRequest.consentDataLifePeriod.value
            ),
            consentDataFrequency: ConsentDataFrequency(
                unit: consentRequest.consentDataFrequency.unit,
                value: consentRequest.consentDataFrequency.value
            ),
            fiTypes: consentRequest.fiTypes?.compactMap { $0 }
        )
        
        FinvuManager.shared.denyAccountConsentRequest(consentDetail: consentDetail) { response, error in
            if (error != nil) {
                completion(.failure(FlutterError(code: "\(error!.code)", message: error?.localizedDescription, details: nil)))
                return
            }
            
            let consentResponse = NativeProcessConsentRequestResponse(
                consentIntentId: response?.consentIntentId,
                consentInfo: response?.consentsInfo?.map({ consentInfo in
                    NativeConsentInfo(consentId: consentInfo.consentId, fipId: consentInfo.fipId)
                })
            )
            
            completion(.success(consentResponse))
        }
    }
    
    func revokeConsent(consentId: String, accountAggregator: NativeAccountAggregator?, fipDetails: NativeFIPReference?, completion: @escaping (Result<Void, Error>) -> Void) {
        let aa: AccountAggregator? = accountAggregator != nil ? AccountAggregator(id: accountAggregator!.id) : nil
        let _fipDetails: FIPReference? = fipDetails != nil ? FIPReference(fipId: fipDetails!.fipId, fipName: fipDetails!.fipName) : nil

        FinvuManager.shared.revokeConsent(consentId: consentId, accountAggregator: aa, fipDetails: _fipDetails) { error in
            if (error != nil) {
                completion(.failure(FlutterError(code: "\(error!.code)", message: error?.localizedDescription, details: nil)))
                return
            }
            
            completion(.success(()))
        }
    }
    
    func getConsentRequestDetails(handleId: String, completion: @escaping (Result<NativeConsentRequestDetailInfo, any Error>) -> Void) {
        FinvuManager.shared.getConsentRequestDetails(consentHandleId: handleId) { response, error in
            if (error != nil) {
                completion(.failure(FlutterError(code: "\(error!.code)", message: error?.localizedDescription, details: nil)))
                return
            }
            
            let consentRequestDetail = (response! as ConsentRequestDetailResponse).detail
            
            let nativeConsentRequestDetailInfo = NativeConsentRequestDetailInfo(
                consentHandleId: consentRequestDetail.consentHandle,
                consentId: consentRequestDetail.consentId,
                financialInformationUser: NativeFinancialInformationEntity(
                    id: consentRequestDetail.financialInformationUser.id,
                    name: consentRequestDetail.financialInformationUser.name),
                consentPurposeInfo: NativeConsentPurposeInfo(
                    code: consentRequestDetail.consentPurposeInfo.code,
                    text: consentRequestDetail.consentPurposeInfo.text),
                consentDisplayDescriptions: consentRequestDetail.consentDisplayDescriptions,
                dataDateTimeRange: NativeDateTimeRange(
                    from: self.formatter.string(from: consentRequestDetail.dataDateTimeRange.from),
                    to: self.formatter.string(from: consentRequestDetail.dataDateTimeRange.to)),
                consentDateTimeRange: NativeDateTimeRange(
                    from: self.formatter.string(from: consentRequestDetail.consentDateTimeRange.from),
                    to: self.formatter.string(from: consentRequestDetail.consentDateTimeRange.to)),
                consentDataFrequency: NativeConsentDataFrequency(
                    unit: consentRequestDetail.consentDataFrequency.unit,
                    value: consentRequestDetail.consentDataFrequency.value),
                consentDataLifePeriod: NativeConsentDataLifePeriod(
                    unit: consentRequestDetail.consentDataLifePeriod.unit,
                    value: consentRequestDetail.consentDataLifePeriod.value),
                fiTypes: consentRequestDetail.fiTypes,
                statusLastUpdateTimestamp: self.getDateOrNil(date: consentRequestDetail.statusLastUpdateTimestamp)
            )
            completion(.success(nativeConsentRequestDetailInfo))
        }
    }
    
    func getConsentHandleStatus(handleId: String, completion: @escaping (Result<NativeConsentHandleStatusResponse, any Error>) -> Void) {
        FinvuManager.shared.getConsentHandleStatus(handleId: handleId) { response, error in
            if (error != nil) {
                completion(.failure(FlutterError(code: "\(error!.code)", message: error?.localizedDescription, details: nil)))
                return
            }
            
            completion(.success(NativeConsentHandleStatusResponse(status: response!.status)))
        }
    }
    

    func fipsAllFIPOptions(completion: @escaping (Result<NativeFIPSearchResponse, any Error>) -> Void) {
        FinvuManager.shared.fipsAllFIPOptions { fipSearchResponse, error in
            if (error != nil) {
                completion(.failure(FlutterError(code: "\(error!.code)", message: error?.localizedDescription, details: nil)))
            } else {
                let fipInfoList = fipSearchResponse!.searchOptions.map { fipInfo in
                    NativeFIPInfo(fipId: fipInfo.fipId, productName: fipInfo.productName, fipFitypes: fipInfo.fipFitypes, productDesc: fipInfo.productDesc, productIconUri: fipInfo.productIconUri, enabled: fipInfo.enabled)
                }
                completion(.success(NativeFIPSearchResponse(searchOptions: fipInfoList)))
            }
        }
    }
    
    func fetchFIPDetails(fipId: String, completion: @escaping (Result<NativeFIPDetails, any Error>) -> Void) {
        FinvuManager.shared.fetchFIPDetails(fipId: fipId) { fipDetails, error in
            if (error != nil) {
                completion(.failure(FlutterError(code: "\(error!.code)", message: error?.localizedDescription, details: nil)))
                return
            }
            
            let typeIdentifiers = fipDetails!.typeIdentifiers.map { typeIdentifier in
                let identifiers = typeIdentifier.identifiers.map { identifier in
                    NativeTypeIdentifier(type: identifier.type, category: identifier.category)
                }
                return NativeFIPFiTypeIdentifier(fiType: typeIdentifier.fiType, identifiers: identifiers)
            }
            completion(.success(NativeFIPDetails(fipId: fipDetails!.fipId, typeIdentifiers: typeIdentifiers)))
        }
    }

    func getEntityInfo(entityId: String, entityType: String, completion: @escaping (Result<NativeEntityInfo, Error>) -> Void) {
        FinvuManager.shared.getEntityInfo(entityId: entityId, entityType: entityType) { response, error in
            if (error != nil) {
                completion(.failure(FlutterError(code: "\(error!.code)", message: error?.localizedDescription, details: nil)))
                return
            }
            
            let entityInfo = response!
            let entity = NativeEntityInfo(entityId: entityInfo.entityId,
                                          entityName: entityInfo.entityName,
                                          entityIconUri: entityInfo.entityIconUri,
                                          entityLogoUri: entityInfo.entityLogoUri,
                                          entityLogoWithNameUri: entityInfo.entityLogoWithNameUri)
            completion(.success(entity))
        }
    }
    
    func logout(completion: @escaping (Result<Void, Error>) -> Void) {
        FinvuManager.shared.logout { error in
            if (error != nil) {
                completion(.failure(FlutterError(code: "\(error!.code)", message: error?.localizedDescription, details: nil)))
                return
            }
            
            completion(.success(()))
        }
    }
    
    func getDateOrNil(date: Date?) -> String? {
        return if (date != nil) {
            self.formatter.string(from: date!)
        } else {
            nil
        }
    }
    
    // MARK: - Event Tracking Methods
    
    func addEventListener() throws {
        if eventListener == nil && nativeEventListener != nil {
            // Create a wrapper class that conforms to FinvuEventListener protocol
            class FlutterEventListenerWrapper: FinvuEventListener {
                weak var plugin: FinvuFlutterSdkPlugin?
                
                init(plugin: FinvuFlutterSdkPlugin) {
                    self.plugin = plugin
                }
                
                func onEvent(_ event: FinvuEvent) {
                    guard let plugin = plugin, let nativeEventListener = plugin.nativeEventListener else { return }
                    
                    // Convert iOS SDK event to Pigeon event
                    var paramsMap: [String?: Any?]? = nil
                    // Handle optional params safely
                    if let eventParams = event.params as? [String: Any?], !eventParams.isEmpty {
                        paramsMap = [:]
                        for (key, value) in eventParams {
                            // Convert arrays to string arrays if needed
                            if let arrayValue = value as? [Any] {
                                paramsMap?[key] = arrayValue.map { "\($0)" }
                            } else {
                                paramsMap?[key] = value
                            }
                        }
                    }
                    
                    let nativeEvent = NativeFinvuEvent(
                        eventName: event.eventName,
                        eventCategory: event.eventCategory,
                        timestamp: event.timestamp,
                        aaSdkVersion: event.aaSdkVersion,
                        params: paramsMap
                    )
                    
                    // Forward event to Flutter on main thread
                    DispatchQueue.main.async {
                        nativeEventListener.onEvent(event: nativeEvent) { result in
                            if case .failure(let error) = result {
                                print("Error forwarding event to Flutter: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
            
            eventListener = FlutterEventListenerWrapper(plugin: self)
            FinvuManager.shared.addEventListener(eventListener!)
        }
    }
    
    func removeEventListener() throws {
        if let listener = eventListener {
            FinvuManager.shared.removeEventListener(listener)
            eventListener = nil
        }
    }
    
    func setEventsEnabled(enabled: Bool) throws {
        FinvuManager.shared.setEventsEnabled(enabled)
    }
    
    func registerCustomEvents(events: [String: NativeEventDefinition]) throws {
        // Convert NativeEventDefinition to iOS SDK EventDefinition
        // Matching Android pattern: EventDefinition with category, stage, fipId, fips (Array<String>), fiTypes (Array<String>)
        // Android uses MutableList<String> which maps to Array<String> in Swift
        let customEvents = events.mapValues { nativeDef in
            // Filter out nil values and convert to Array (matching Android's MutableList)
            let fips = nativeDef.fips?.compactMap { $0 } ?? []
            let fiTypes = nativeDef.fiTypes?.compactMap { $0 } ?? []
            
            // Use FinvuSDK.EventDefinition (fully qualified name since it's in the FinvuSDK module)
            // iOS SDK needs EventDefinition struct/class matching Android SDK structure
            return FinvuSDK.EventDefinition(
                category: nativeDef.category,
                stage: nativeDef.stage,
                fipId: nativeDef.fipId,
                fips: fips,
                fiTypes: fiTypes
            )
        }
        
        // Use FinvuManager.shared (matches Android pattern where it delegates to eventTracker)
        FinvuManager.shared.registerCustomEvents(customEvents)
    }
    
    func registerAliases(aliases: [String: String]) throws {
        // Use FinvuManager.shared (matches Android pattern)
        FinvuManager.shared.registerAliases(aliases)
    }
    
    func track(eventName: String, params: [String?: Any?]?) throws {
        // Convert nullable string keys to non-nullable (matching Android pattern)
        var paramsMap: [String: Any?] = [:]
        if let params = params {
            for (key, value) in params {
                paramsMap[key ?? ""] = value
            }
        }
        
        // Use FinvuEventTracker.shared.track (same as Android)
        // iOS SDK track method signature: track(_ eventName: String, params: [String: Any?])
        FinvuEventTracker.shared.track(eventName, params: paramsMap)
    }
}

final class FinvuClientConfig: FinvuConfig {
    var finvuEndpoint: URL
    var certificatePins: [String]?
    var finvuSnaAuthConfig: FinvuSnaAuthConfig?

    init(finvuEndpoint: URL, certificatePins: [String]?, finvuSnaAuthConfig: FinvuSnaAuthConfig?) {
        self.finvuEndpoint = finvuEndpoint
        self.certificatePins = certificatePins
        self.finvuSnaAuthConfig = finvuSnaAuthConfig
    }
}
