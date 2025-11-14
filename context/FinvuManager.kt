package com.finvu.android

import com.finvu.android.models.accountDiscover.AccountDiscoverRequest
import com.finvu.android.models.accountLinking.AccountLinkingRequest
import com.finvu.android.models.consentRequest.FinancialInformationEntityIdentifier
import com.finvu.android.models.consentRequest.ProcessConsentAccountDetail
import com.finvu.android.models.consentRequest.ProcessConsentFIPDetail
import com.finvu.android.publicInterface.AccountAggregatorView
import com.finvu.android.publicInterface.AccountLinkingResult
import com.finvu.android.publicInterface.ConfirmAccountLinkingResponse
import com.finvu.android.publicInterface.ConsentDetail
import com.finvu.android.publicInterface.ConsentHandleStatusResponse
import com.finvu.android.publicInterface.DiscoverAccountsResponse
import com.finvu.android.publicInterface.DiscoveredAccount
import com.finvu.android.publicInterface.EntityInfo
import com.finvu.android.publicInterface.FIPReferenceView
import com.finvu.android.publicInterface.FetchConsentDetailsResponse
import com.finvu.android.publicInterface.FetchLinkedAccountsResponse
import com.finvu.android.publicInterface.FinvuErrorCode
import com.finvu.android.publicInterface.FipDetails
import com.finvu.android.publicInterface.FipsAllFIPOptionsResponse
import com.finvu.android.publicInterface.HandleInfo
import com.finvu.android.publicInterface.LinkedAccountDetails
import com.finvu.android.publicInterface.LoginOtpReference
import com.finvu.android.publicInterface.ProcessAccountConsentResponse
import com.finvu.android.publicInterface.TypeIdentifierInfo
import com.finvu.android.publicInterface.auth.FinvuAuthProviderRegistry
import com.finvu.android.publicInterface.FinvuEventListener
import com.finvu.android.publicInterface.FinvuEventType
import com.finvu.android.events.FinvuEventTracker
import com.finvu.android.events.EventDefinition
import com.finvu.android.types.FinvuWebsocketRequest
import com.finvu.android.utils.FinvuConfig
import com.finvu.android.utils.FinvuErrorUtils
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import java.util.stream.Collectors


class FinvuManager private constructor() {
    private val networkingManager = FinvuNetworkingManager()
    private val storageManager = FinvuStorageManager.shared
    private val finvuRequestsManager = FinvuRequestsManager.shared
    private val finvuResponseManager = FinvuResponseManager.shared
    private val loginManager = LoginManager.shared
    private val eventTracker = FinvuEventTracker.shared
    private var finvuConfig: FinvuConfig? = null

    companion object {
        val shared: FinvuManager by lazy { FinvuManager() }
    }

    init {
        finvuRequestsManager.setFinvuNetworkingManager(networkingManager)
        finvuRequestsManager.setFinvuResponseHandler(finvuResponseManager)
    }

    /**
     * Set the completion coroutine scope for the SDK
     *
     * If this is not configured, the SDK will use the Dispatchers.IO coroutine scope for completion
     *
     * @param coroutineScope Coroutine scope to use for completion blocks
     */
    fun setCompletionCoroutineScope(coroutineScope: CoroutineScope) {
        finvuRequestsManager.coroutineScope = coroutineScope
    }

    /**
     * Initialize the SDK with the configuration
     *
     * @param config Configuration for the SDK
     */
    fun initializeWith(config: FinvuConfig) {
        finvuConfig = config
    }

    /**
     * Add an event listener to receive SDK events
     *
     * This initializes the event tracker on first call.
     * No coroutine scope needed - tracker handles it internally.
     *
     * @param listener The event listener to add
     */
    fun addEventListener(listener: FinvuEventListener) {
        eventTracker.addEventListener(listener)
    }

    /**
     * Remove an event listener
     *
     * When the last listener is removed, the tracker is cleaned up
     * and all event counts are reset.
     *
     * @param listener The event listener to remove
     */
    fun removeEventListener(listener: FinvuEventListener) {
        eventTracker.removeEventListener(listener)
    }

    /**
     * Enable/disable event tracking
     *
     * @param enabled True to enable, false to disable
     */
    fun setEventsEnabled(enabled: Boolean) {
        eventTracker.setEventsEnabled(enabled)
    }

    /**
     * Register custom events
     *
     * Custom events allow you to track events specific to your app.
     * They follow the same structure as standard events.
     *
     * Example:
     * ```
     * val customEvents = mapOf(
     *     "CUSTOM_BUTTON_CLICKED" to EventDefinition("ui", count = 0),
     *     "CUSTOM_API_CALLED" to EventDefinition("api", count = 0)
     * )
     * finvuManager.registerCustomEvents(customEvents)
     * ```
     *
     * Then track them:
     * ```
     * eventTracker.track("CUSTOM_BUTTON_CLICKED", mapOf("buttonId" to "login"))
     * ```
     *
     * @param events Map of event name to EventDefinition
     */
    fun registerCustomEvents(events: Map<String, EventDefinition>) {
        eventTracker.registerCustomEvents(events)
    }

    /**
     * Register event aliases
     *
     * Aliases allow you to use custom names for standard events.
     * Useful for analytics or when integrating with third-party tools.
     *
     * Example:
     * ```
     * val aliases = mapOf(
     *     "LOGIN_OTP_GENERATED" to "otp_sent",
     *     "WEBSOCKET_CONNECTED" to "connection_established"
     * )
     * finvuManager.registerAliases(aliases)
     * ```
     *
     * When events are tracked, the alias will be used instead of the original name.
     *
     * @param aliases Map of standard event name to alias
     */
    fun registerAliases(aliases: Map<String, String>) {
        eventTracker.registerAliases(aliases)
    }

    /**
     * Connect to the Finvu AA server
     *
     * @param completion Completion block with the result of the API call
     */
    fun connect(completion: (Result<Unit>) -> Unit) {
        finvuConfig!!.let { 
            networkingManager.connect(it, completion)
        }
    }

    /**
     * Disconnect from the Finvu AA server
     */
    fun disconnect() {
        networkingManager.disconnect()
        eventTracker.track(FinvuEventType.WEBSOCKET_DISCONNECTED.eventName)
        FinvuAuthProviderRegistry.getProviderOrNoop().onDestroy()
    }

    /**
     * Check if the SDK is connected to the Finvu AA server
     *
     * @return True if connected, false otherwise
     */
    fun isConnected(): Boolean {
        return networkingManager.isConnected
    }

    /**
     * Check if the SDK has an active session
     *
     * @return True if session is active, false otherwise
     */
    fun hasSession(): Boolean {
        return storageManager.getSessionId() != null
    }

    /**
     * Login with username or mobile number.
     *
     * One of username of mobile number is required. Calling this API will initiate an OTP to users
     * registered mobile number via the AA servers. The OTP reference received in the completion result.
     *
     * @param username Finvu username
     * @param mobileNumber Users mobile number
     * @param consentHandleId Consent handle id received from server to server call to AA
     * @param completion Completion block with the result of the API call
     */
    fun loginWithUsernameOrMobileNumber(
        username: String?,
        mobileNumber: String?,
        consentHandleId: String,
        completion: (Result<LoginOtpReference>) -> Unit
    ) {
        loginManager.loginWithUsernameOrMobileNumber(
            username = username,
            mobileNumber = mobileNumber,
            consentHandleId = consentHandleId,
            finvuConfig = finvuConfig,
            completion = completion
        )
    }

    /**
     * Verify the OTP received on the users mobile number
     *
     * Verify the OTP sent in the [loginWithUsernameOrMobileNumber] API. Once the OTP is verified,
     * the user session will be established on the SDK.
     *
     * @param otp OTP received on the users mobile number
     * @param otpReference OTP reference received in [loginWithUsernameOrMobileNumber]
     * @param completion Completion block with the result of the API call
     */
    fun verifyLoginOtp(
        otp: String, otpReference: String, completion: (Result<HandleInfo>) -> Unit
    ) {
        val request = FinvuWebsocketRequest.verifyLoginOtp(otp = otp, otpReference = otpReference)
        finvuRequestsManager.sendRequest(request, completion)
    }

    /**
     * Add a mobile number to the users account
     *
     * Sometimes a user might want to use a different mobile than the one used for logging in, in
     * which case they need to verify such a mobile before performing a request like discovery.
     * This API needs to be called within an authenticated session (i.e. after [verifyLoginOtp]) to
     * register additional mobiles with Finvu AA. Calling this API will trigger an OTP to the given
     * mobile number.
     *
     * @param mobileNumber Users mobile number
     * @param completion Completion block with the result of the API call
     */
    fun initiateMobileVerification(mobileNumber: String, completion: (Result<Unit>) -> Unit) {
        val request = FinvuWebsocketRequest.initiateMobileVerificationRequest(
            mobileNumber, storageManager.getSessionId()!!
        )

        finvuRequestsManager.sendRequest(request, completion)
    }


    /**
     * Verify the OTP received on the users mobile number
     *
     * Verify the OTP sent in the [initiateMobileVerification] API. Once the OTP is verified,
     * the mobile number will be added to the users account. The mobile number is only added for
     * current session
     *
     * @param mobileNumber Users mobile number
     * @param otp OTP received on the users mobile number
     * @param completion Completion block with the result of the API call
     */
    fun completeMobileVerification(
        mobileNumber: String, otp: String, completion: (Result<Unit>) -> Unit
    ) {
        val request = FinvuWebsocketRequest.completeMobileVerificationRequest(
            mobileNumber, otp, storageManager.getSessionId()!!
        )

        finvuRequestsManager.sendRequest(request, completion)
    }

    /**
     * Fetch the linked accounts for the user
     *
     * API to get a list of already linked accounts of the user with Finvu AA. If there are no
     * linked accounts, account discovery and linking should be performed to discover and link
     * accounts, and then invoke this API again to get the list of accounts to display for selecting
     * the account for inclusion in the consent.
     *
     * @param completion Completion block with the result of the API call
     */
    fun fetchLinkedAccounts(completion: (Result<FetchLinkedAccountsResponse>) -> Unit) {
        val request = FinvuWebsocketRequest.fetchLinkedAccountsRequest(
            storageManager.getUsername()!!, storageManager.getSessionId()!!
        )
        finvuRequestsManager.sendRequest(request, completion)
    }

    /**
     * Discover accounts for the user
     *
     * API to get list of accounts that the user has with the requested FIP.
     *
     * @param fipDetails FIP details for which the accounts need to be discovered
     * @param fiTypes List of FI types for which the accounts need to be discovered
     * @param identifiers List of identifiers for the user to discover accounts as per REBIT spec for the FI Types
     * @param completion Completion block with the result of the API call
     */
    fun discoverAccounts(
        fipId: String,
        fiTypes: List<String>,
        identifiers: List<TypeIdentifierInfo>,
        completion: (Result<DiscoverAccountsResponse>) -> Unit
    ) {
        eventTracker.track(FinvuEventType.DISCOVERY_INITIATED.eventName)
        val request = FinvuWebsocketRequest.discoverAccountsRequest(
            storageManager.getUsername()!!, fipId, fiTypes, identifiers.map {
                AccountDiscoverRequest.Customer.Identifier(
                    it.category, it.type, it.value
                )
            }, storageManager.getSessionId()!!
        )
        finvuRequestsManager.sendRequest(request, completion)
    }

    fun discoverAccountsAsync(
        fipId: String,
        fiTypes: List<String>,
        identifiers: List<TypeIdentifierInfo>,
        completion: (Result<DiscoverAccountsResponse>) -> Unit
    ) {
        eventTracker.track(FinvuEventType.DISCOVERY_INITIATED.eventName)
        val request = FinvuWebsocketRequest.discoverAccountsAsyncRequest(
            storageManager.getUsername()!!, fipId, fiTypes, identifiers.map {
                AccountDiscoverRequest.Customer.Identifier(
                    it.category, it.type, it.value
                )
            }, storageManager.getSessionId()!!
        )
        finvuRequestsManager.sendRequest(request, completion)
    }

    /**
     * Link accounts for the user
     *
     * API to initiate the account linking process. This API will trigger an OTP to the registered
     * mobile number of the user.
     *
     * @param accounts List of discovered accounts to link from [discoverAccounts] API
     * @param fipDetails FIP details for which the accounts need to be linked
     * @param completion Completion block with the result of the API call
     */
    fun linkAccounts(
        accounts: List<DiscoveredAccount>,
        fipDetails: FipDetails,
        completion: (Result<AccountLinkingResult>) -> Unit
    ) {
        eventTracker.track(FinvuEventType.LINKING_INITIATED.eventName, mapOf("fipId" to fipDetails.fipId))
        val accountsToLink = accounts.map {
            AccountLinkingRequest.Customer.Account(
                it.fiType, it.accountReferenceNumber, it.accountType, it.maskedAccountNumber
            )
        }
        val request = FinvuWebsocketRequest.linkingRequest(
            storageManager.getUsername()!!,
            fipDetails.fipId,
            accountsToLink,
            storageManager.getSessionId()!!
        )
        finvuRequestsManager.sendRequest(request, completion)
    }

    /**
     *  Fetch Fip Details
     */
    fun fetchFipDetails(fipId: String, completion: (Result<FipDetails>) -> Unit) {
        val request = FinvuWebsocketRequest.fetchFipDetailsRequest(
            fipId = fipId, storageManager.getSessionId()!!
        )
        finvuRequestsManager.sendRequest(request, completion)
    }

    /**
     * Get Entity Information
     */
    fun getEntityInfo(
        entityId: String, entityType: String, completion: (Result<EntityInfo>) -> Unit
    ) {
        val request = FinvuWebsocketRequest.fetchEntityInfoRequest(
            storageManager.getSessionId()!!, entityId, entityType
        )
        finvuRequestsManager.sendRequest(request, completion)
    }


    /**
     * Get All FIPs
     *
     * @param onlyEnabled If true, returns only enabled FIPs. Default is false
     * @param completion Completion block with the result of the API call
     */
    fun fipsAllFIPOptions(
        onlyEnabled: Boolean = false, completion: (Result<FipsAllFIPOptionsResponse>) -> Unit
    ) {
        val request = FinvuWebsocketRequest.fipsAllFIPOptionsRequest(storageManager.getSessionId())
        finvuRequestsManager.sendRequest(request, { result: Result<FipsAllFIPOptionsResponse> ->
            val processedResult = result.map { response ->
                if (onlyEnabled) {
                    response.copy(searchOptions = response.searchOptions.filter { it.enabled })
                } else {
                    response
                }
            }
            completion(processedResult)
        })
    }

    /**
     * Confirm account linking
     *
     * API to complete the account linking process. Upon successful linking response, FIP will
     * respond with details of accounts linked.
     *
     * @param accountLinkingRefNumber Account linking reference number received in [linkAccounts] API
     * @param otp OTP received on the users mobile number
     * @param completion Completion block with the result of the API call
     */
    fun confirmAccountLinking(
        accountLinkingRefNumber: String,
        otp: String,
        completion: (Result<ConfirmAccountLinkingResponse>) -> Unit
    ) {
        val request = FinvuWebsocketRequest.confirmAccountLinkingRequest(
            accountLinkingRefNumber, otp, storageManager.getSessionId()!!
        )
        finvuRequestsManager.sendRequest(request, completion)
    }

    /**
     * Fetch consent request details
     *
     * API to get the consent requests raised by FIU with Finvu AA in a previous server to server
     *
     * @param consentHandleId Consent handle id received in the consent request
     * @param completion Completion block with the result of the API call
     */
    fun getConsentRequestDetails(
        consentHandleId: String, completion: (Result<FetchConsentDetailsResponse>) -> Unit
    ) {
        val request = FinvuWebsocketRequest.fetchConsentDetailsRequest(
            storageManager.getUsername()!!, consentHandleId, storageManager.getSessionId()!!
        )
        finvuRequestsManager.sendRequest(request, completion)
    }

    /**
     * Approve consent request
     *
     * API to approve the consent request raised by FIU with Finvu AA. This API should be called
     * after the user has selected the accounts to be included in the consent.
     *
     * @param consentDetail Consent details received in [getConsentRequestDetails] API
     * @param linkedAccounts List of linked accounts to be included in the consent
     * @param completion Completion block with the result of the API call
     */
    fun approveConsentRequest(
        consentDetail: ConsentDetail,
        linkedAccounts: List<LinkedAccountDetails>,
        completion: (Result<ProcessAccountConsentResponse>) -> Unit
    ) {
        val fipIdWiseLinkedAccounts =
            linkedAccounts.stream().collect(Collectors.groupingBy { it.fipId })
        
        // Track linked accounts summary
        val uniqueFips = linkedAccounts.map { it.fipId }.distinct()
        val uniqueFiTypes = linkedAccounts.map { it.fiType }.distinct()
        eventTracker.track(
            FinvuEventType.LINKED_ACCOUNTS_SUMMARY.eventName,
            mapOf(
                "count" to linkedAccounts.size,
                "fips" to uniqueFips,
                "fiTypes" to uniqueFiTypes
            )
        )
        
        val fipDetails = fipIdWiseLinkedAccounts.map { (fipId, linkedAccounts) ->
            val details = linkedAccounts.map {
                ProcessConsentAccountDetail(
                    linkReferenceNumber = it.linkReferenceNumber,
                    accountType = it.accountType,
                    accountReferenceNumber = it.accountReferenceNumber,
                    maskedAccountNumber = it.maskedAccountNumber,
                    fiType = it.fiType,
                    fipId = fipId,
                    fipName = it.fipName
                )
            }
            ProcessConsentFIPDetail(
                fip = FinancialInformationEntityIdentifier(fipId), accounts = details
            )
        }

        val request = FinvuWebsocketRequest.approveAccountConsentRequest(
            storageManager.getSessionId()!!,
            consentDetail.consentHandle,
            consentDetail.financialInformationUser.id,
            fipDetails
        )
        finvuRequestsManager.sendRequest(request, completion, metadata = mapOf("handleStatus" to "ACCEPT"))
    }

    /**
     * Deny consent request
     *
     * API to deny the consent request raised by FIU with Finvu AA.
     *
     * @param consentDetail Consent details received in [getConsentRequestDetails] API
     * @param completion Completion block with the result of the API call
     */
    fun denyConsentRequest(
        consentDetail: ConsentDetail, completion: (Result<ProcessAccountConsentResponse>) -> Unit
    ) {
        val request = FinvuWebsocketRequest.denyAccountConsentRequest(
            storageManager.getSessionId()!!,
            consentDetail.consentHandle,
            consentDetail.financialInformationUser.id
        )
        finvuRequestsManager.sendRequest(request, completion, metadata = mapOf("handleStatus" to "DENY"))
    }

    /**
     * Revoke consent given by the user for a consent
     *
     * API to revoke the consent given by the user to the FIU.
     *
     * @param consentInfo Consent details received in [getConsentRequestDetails] API
     * @param accountAggregatorView Account Aggregator detail
     * @param fipDetails FIP details
     * @param completion Completion block with the result of the API call
     */
    fun revokeConsent(
        consentId: String,
        accountAggregatorView: AccountAggregatorView?,
        fipDetails: FIPReferenceView?,
        completion: (Result<Unit>) -> Unit
    ) {
        val request = FinvuWebsocketRequest.revokeConsent(
            storageManager.getUsername()!!,
            storageManager.getSessionId()!!,
            consentId,
            accountAggregatorView,
            fipDetails
        )
        finvuRequestsManager.sendRequest(request, completion)
    }

    /**
     * Get the status of the consent handle
     *
     * API to poll the consent handle status after it has been approved by user.
     * When the user approves a consent request, AA server will need to post the consent to all
     * the FIPs selected by the user. Once all FIPs have accepted the consent posted by AA, AA
     * server will change the status of the consent handle to READY. If any FIP rejects the consent,
     * then the status will change to REJECTED.
     * Note: This api can only be called a limited number of times, usually 5 times. If any attempts
     * to call this api more than the allowed number of times, the websocket session will be
     * terminated and the connection will become unusable. This is to prevent any runaway client
     * process trying to poll the consent handle status in an endless loop."
     *
     * @param handleId Consent handle id received in the consent request
     * @param completion Completion block with the result of the API call
     */
    fun getConsentHandleStatus(
        handleId: String, completion: (Result<ConsentHandleStatusResponse>) -> Unit
    ) {
        val request = FinvuWebsocketRequest.getConsentHandleStatusRequest(
            handleId, storageManager.getSessionId()!!
        )
        finvuRequestsManager.sendRequest(request, completion)
    }

    /**
     * Logout the user
     *
     * API to logout the user from the Finvu AA server. This will invalidate the session and the user
     * will need to login again to perform any further operations.
     *
     * @param completion Completion block with the result of the API call
     */
    fun logout(completion: (Result<Unit>) -> Unit) {
        val request = FinvuWebsocketRequest.logoutRequest(
            storageManager.getUsername()!!, storageManager.getSessionId()!!
        )
        finvuRequestsManager.sendRequest(request, completion, isInternal = true)
    }
}
