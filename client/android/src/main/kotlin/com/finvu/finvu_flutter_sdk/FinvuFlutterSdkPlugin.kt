@file:Suppress("LABEL_NAME_CLASH")

package com.finvu.finvu_flutter_sdk

import NativeAccountLinkingRequestReference
import NativeConfirmAccountLinkingInfo
import NativeConsentDataFrequency
import NativeConsentDataLifePeriod
import NativeConsentHandleStatusResponse
import NativeConsentInfo
import NativeConsentPurposeInfo
import NativeConsentRequestDetailInfo
import NativeDateTimeRange
import NativeDiscoveredAccountInfo
import NativeDiscoveredAccountsResponse
import NativeFIPDetails
import NativeFinancialInformationEntity
import NativeFinvuConfig
import NativeFinvuError
import NativeFinvuManager
import NativeHandleInfo
import NativeLinkedAccountDetailsInfo
import NativeLinkedAccountInfo
import NativeLinkedAccountsResponse
import NativeLoginOtpReference
import NativeProcessConsentRequestResponse
import NativeTypeIdentifierInfo
import NativeAccountAggregator
import NativeEntityInfo
import NativeFIPFiTypeIdentifier
import NativeFIPInfo
import NativeFIPSearchResponse
import NativeTypeIdentifier
import NativeFIPReference
import com.finvu.android.utils.FinvuConfig
import com.finvu.android.FinvuManager
import com.finvu.android.publicInterface.ConsentDataFrequency
import com.finvu.android.publicInterface.ConsentDataLifePeriod
import com.finvu.android.publicInterface.ConsentDetail
import com.finvu.android.publicInterface.ConsentPurpose
import com.finvu.android.publicInterface.DateTimeRange
import com.finvu.android.publicInterface.DiscoveredAccount
import com.finvu.android.publicInterface.FinancialInformationEntity
import com.finvu.android.publicInterface.FinvuException
import com.finvu.android.publicInterface.FipDetails
import com.finvu.android.publicInterface.FipFiTypeIdentifier
import com.finvu.android.publicInterface.LinkedAccountDetails
import com.finvu.android.publicInterface.TypeIdentifier
import com.finvu.android.publicInterface.TypeIdentifierInfo
import com.finvu.android.publicInterface.AccountAggregatorView
import com.finvu.android.publicInterface.FIPReferenceView
import com.finvu.android.publicInterface.UserConsentInfo
import com.finvu.android.publicInterface.UserConsentInfoDetails
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

data class FinvuClientConfig(override val finvuEndpoint: String,
                             override val certificatePins: List<String>?
) : FinvuConfig

/** FinvuFlutterSdkPlugin */
class FinvuFlutterSdkPlugin: FlutterPlugin, NativeFinvuManager {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel

  private val dateFormatter = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSXXX", Locale.getDefault())

  init {
    dateFormatter.timeZone = TimeZone.getDefault()
  }

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    NativeFinvuManager.setUp(binding.binaryMessenger, this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    NativeFinvuManager.setUp(binding.binaryMessenger, null)
  }

  override fun initialize(config: NativeFinvuConfig) {
    val pins: List<String>? = config.certificatePins?.filterNotNull()
    FinvuManager.shared.initializeWith(FinvuClientConfig(config.finvuEndpoint, pins))
  }

  override fun connect(callback: (Result<Unit>) -> Unit) {
    FinvuManager.shared.connect {
      if (it.isFailure) {
        val error = it.exceptionOrNull() as FinvuException
        callback(Result.failure(NativeFinvuError(code = error.code.toString(), message = error.message)))
        return@connect
      }

      callback(Result.success(Unit))
    }
  }

  override fun disconnect() {
    FinvuManager.shared.disconnect()
  }

  override fun isConnected(): Boolean {
    return FinvuManager.shared.isConnected()
  }

  override fun hasSession(): Boolean {
    return FinvuManager.shared.hasSession()
  }

  override fun loginWithUsernameOrMobileNumberAndConsentHandle(
    username: String?,
    mobileNumber: String?,
    consentHandleId: String,
    callback: (Result<NativeLoginOtpReference>) -> Unit
  ) {
    FinvuManager.shared.loginWithUsernameOrMobileNumber(
      username = username,
      mobileNumber = mobileNumber,
      consentHandleId = consentHandleId
    ) {
      if (it.isFailure) {
        val error = it.exceptionOrNull() as FinvuException
        callback(Result.failure(NativeFinvuError(code = error.code.toString(), message = error.message)))
        return@loginWithUsernameOrMobileNumber
      }

      val response = it.getOrThrow()
      val loginOtpReference = NativeLoginOtpReference(response.reference)
      callback(Result.success(loginOtpReference))
    }
  }

  override fun verifyLoginOtp(
    otp: String,
    otpReference: String,
    callback: (Result<NativeHandleInfo>) -> Unit
  ) {
    FinvuManager.shared.verifyLoginOtp(otp = otp, otpReference = otpReference) {
      if (it.isFailure) {
        val error = it.exceptionOrNull() as FinvuException
        callback(Result.failure(NativeFinvuError(code = error.code.toString(), message = error.message)))
        return@verifyLoginOtp
      }

      val response = it.getOrThrow()
      val handleInfo = NativeHandleInfo(response.userId)
      callback(Result.success(handleInfo))
    }
  }

  override fun discoverAccounts(
    fipId: String,
    fiTypes: List<String>,
    identifiers: List<NativeTypeIdentifierInfo>,
    callback: (Result<NativeDiscoveredAccountsResponse>) -> Unit
  ) {
    val finvuIdentifiers = identifiers.map { TypeIdentifierInfo(category = it.category, type = it.type, value = it.value) }

    FinvuManager.shared.discoverAccounts(fipId, fiTypes, finvuIdentifiers) { result ->
      if (result.isFailure) {
        val error = result.exceptionOrNull() as FinvuException
        callback(Result.failure(NativeFinvuError(code = error.code.toString(), message = error.message)))
        return@discoverAccounts
      }

      val response = result.getOrThrow()
      val accounts = response.discoveredAccounts.map {
        NativeDiscoveredAccountInfo(
          accountType = it.accountType,
          accountReferenceNumber = it.accountReferenceNumber,
          maskedAccountNumber = it.maskedAccountNumber,
          fiType = it.fiType
        )
      }

      callback(Result.success(NativeDiscoveredAccountsResponse(accounts)))
    }
  }

  override fun discoverAccountsAsync(
  fipId: String,
  fiTypes: List<String>,
  identifiers: List<NativeTypeIdentifierInfo>,
  callback: (Result<NativeDiscoveredAccountsResponse>) -> Unit
  ) {
    val finvuIdentifiers = identifiers.map { TypeIdentifierInfo(category = it.category, type = it.type, value = it.value) }

    FinvuManager.shared.discoverAccountsAsync(fipId, fiTypes, finvuIdentifiers) { result ->
      if (result.isFailure) {
        val error = result.exceptionOrNull() as FinvuException
        callback(Result.failure(NativeFinvuError(code = error.code.toString(), message = error.message)))
        return@discoverAccountsAsync
      }

      val response = result.getOrThrow()
      val accounts = response.discoveredAccounts.map {
        NativeDiscoveredAccountInfo(
          accountType = it.accountType,
          accountReferenceNumber = it.accountReferenceNumber,
          maskedAccountNumber = it.maskedAccountNumber,
          fiType = it.fiType
        )
      }

      callback(Result.success(NativeDiscoveredAccountsResponse(accounts)))
    }
  }

  override fun linkAccounts(
    fipDetails: NativeFIPDetails,
    accounts: List<NativeDiscoveredAccountInfo>,
    callback: (Result<NativeAccountLinkingRequestReference>) -> Unit
  ) {
    val finvuFipDetails = getFipDetails(fipDetails)
    val finvuAccounts = accounts.map {
      DiscoveredAccount(
        accountType = it.accountType,
        accountReferenceNumber = it.accountReferenceNumber,
        maskedAccountNumber = it.maskedAccountNumber,
        fiType = it.fiType
      )
    }

    FinvuManager.shared.linkAccounts(finvuAccounts, finvuFipDetails) { result ->
      if (result.isFailure) {
        val error = result.exceptionOrNull() as FinvuException
        callback(Result.failure(NativeFinvuError(code = error.code.toString(), message = error.message)))
        return@linkAccounts
      }

      val response = result.getOrThrow()
      val accountLinkingRequestReference = NativeAccountLinkingRequestReference(response.referenceNumber)

      callback(Result.success(accountLinkingRequestReference))
    }
  }

  private fun getFipDetails(fipDetails: NativeFIPDetails): FipDetails {
    val finvuTypeIdentifiers = fipDetails.typeIdentifiers.filterNotNull().map { fipFiTypeIdentifier ->
      val finvuIdentifiers = fipFiTypeIdentifier.identifiers.filterNotNull().map {
        TypeIdentifier(type = it.type, category = it.category)
      }
      FipFiTypeIdentifier(
        fipFiTypeIdentifier.fiType,
        finvuIdentifiers
      )
    }
    return FipDetails(fipDetails.fipId, finvuTypeIdentifiers)
  }

  override fun confirmAccountLinking(
    requestReference: NativeAccountLinkingRequestReference,
    otp: String,
    callback: (Result<NativeConfirmAccountLinkingInfo>) -> Unit
  ) {
    FinvuManager.shared.confirmAccountLinking(requestReference.referenceNumber, otp) { result ->
      if (result.isFailure) {
        val error = result.exceptionOrNull() as FinvuException
        callback(Result.failure(NativeFinvuError(code = error.code.toString(), message = error.message)))
        return@confirmAccountLinking
      }

      val response = result.getOrThrow()
      val accounts = response.linkedAccounts.map {
        NativeLinkedAccountInfo(
          customerAddress = it.customerAddress,
          accountReferenceNumber = it.accountReferenceNumber,
          linkReferenceNumber = it.linkReferenceNumber,
          status = it.status
        )
      }

      callback(Result.success(NativeConfirmAccountLinkingInfo(accounts)))
    }
  }

  override fun fetchLinkedAccounts(callback: (Result<NativeLinkedAccountsResponse>) -> Unit) {
    FinvuManager.shared.fetchLinkedAccounts { result ->
      if (result.isFailure) {
        val error = result.exceptionOrNull() as FinvuException
        callback(Result.failure(NativeFinvuError(code = error.code.toString(), message = error.message)))
        return@fetchLinkedAccounts
      }

      val response = result.getOrThrow()
      val accounts = response.linkedAccounts.map {
        NativeLinkedAccountDetailsInfo(
          userId = it.userId,
          fipId = it.fipId,
          fipName = it.fipName,
          maskedAccountNumber = it.maskedAccountNumber,
          accountReferenceNumber = it.accountReferenceNumber,
          linkReferenceNumber = it.linkReferenceNumber,
          consentIdList = it.consentIdList,
          fiType = it.fiType,
          accountType = it.accountType,
          linkedAccountUpdateTimestamp = it.linkedAccountUpdateTimestamp?.let { date -> dateFormatter.format(date) } ,
          authenticatorType = it.authenticatorType
        )
      }

      callback(Result.success(NativeLinkedAccountsResponse(accounts)))
    }
  }

  override fun initiateMobileVerification(mobileNumber: String, callback: (Result<Unit>) -> Unit) {
    FinvuManager.shared.initiateMobileVerification(mobileNumber) { result ->
      if (result.isFailure) {
        val error = result.exceptionOrNull() as FinvuException
        callback(Result.failure(NativeFinvuError(code = error.code.toString(), message = error.message)))
        return@initiateMobileVerification
      }

      callback(Result.success(Unit))
    }
  }

  override fun completeMobileVerification(
    mobileNumber: String,
    otp: String,
    callback: (Result<Unit>) -> Unit
  ) {
    FinvuManager.shared.completeMobileVerification(mobileNumber, otp) { result ->
      if (result.isFailure) {
        val error = result.exceptionOrNull() as FinvuException
        callback(Result.failure(NativeFinvuError(code = error.code.toString(), message = error.message)))
        return@completeMobileVerification
      }

      callback(Result.success(Unit))
    }
  }

  override fun fipsAllFIPOptions(callback: (Result<NativeFIPSearchResponse>) -> Unit) {
    FinvuManager.shared.fipsAllFIPOptions { result ->
      if (result.isFailure) {
        val error = result.exceptionOrNull() as FinvuException
        callback(Result.failure(NativeFinvuError(code = error.code.toString(), message = error.message)))
        return@fipsAllFIPOptions
      }

      val response = result.getOrThrow()
      val searchOptions = response.searchOptions.map {
        NativeFIPInfo(
          fipId = it.fipId,
          fipFitypes = it.fipFiTypes,
          fipFsr = it.fipFsr,
          productName = it.productName,
          productDesc = it.productDesc,
          productIconUri = it.productIconUri,
          enabled = it.enabled
        )
      }

      callback(Result.success(NativeFIPSearchResponse(searchOptions)))
    }
  }

  override fun fetchFIPDetails(fipId: String, callback: (Result<NativeFIPDetails>) -> Unit) {
    FinvuManager.shared.fetchFipDetails(fipId) { result ->
      if (result.isFailure) {
        val error = result.exceptionOrNull() as FinvuException
        callback(Result.failure(NativeFinvuError(code = error.code.toString(), message = error.message)))
        return@fetchFipDetails
      }

      val response = result.getOrThrow()
      val typeIdentifiers = response.typeIdentifiers.map { fipFiTypeIdentifier ->
        val identifiers = fipFiTypeIdentifier.identifiers.map {
          NativeTypeIdentifier(type = it.type, category = it.category)
        }
        NativeFIPFiTypeIdentifier(
          fipFiTypeIdentifier.fiType,
          identifiers
        )
      }
      val fipDetails = NativeFIPDetails(response.fipId, typeIdentifiers)
      callback(Result.success(fipDetails))
    }
  }

  override fun getEntityInfo(
    entityId: String,
    entityType: String,
    callback: (Result<NativeEntityInfo>) -> Unit
  ) {
    FinvuManager.shared.getEntityInfo(entityId, entityType) { result ->
      if (result.isFailure) {
        val error = result.exceptionOrNull() as FinvuException
        callback(Result.failure(NativeFinvuError(code = error.code.toString(), message = error.message)))
        return@getEntityInfo
      }

      val response = result.getOrThrow()
      val entityInfo = NativeEntityInfo(
        entityId = response.entityId,
        entityName = response.entityName,
        entityIconUri = response.entityIconUri,
        entityLogoUri = response.entityLogoUri,
        entityLogoWithNameUri = response.entityLogoWithNameUri
      )

      callback(Result.success(entityInfo))
    }
  }

  override fun approveConsentRequest(
    consentRequest: NativeConsentRequestDetailInfo,
    linkedAccounts: List<NativeLinkedAccountDetailsInfo>,
    callback: (Result<NativeProcessConsentRequestResponse>) -> Unit
  ) {
    val consentDetails = ConsentDetail(
      consentHandle = consentRequest.consentHandleId,
      financialInformationUser = FinancialInformationEntity(
        id = consentRequest.financialInformationUser.id,
        name = consentRequest.financialInformationUser.name
      ),
      statusLastUpdateTimestamp = null,
      consentPurpose = ConsentPurpose(
        code = consentRequest.consentPurposeInfo.code,
        text = consentRequest.consentPurposeInfo.text
      ),
      consentDisplayDescriptions = consentRequest.consentDisplayDescriptions.filterNotNull(),
      dataDateTimeRange = DateTimeRange(
        from = dateFormatter.parse(consentRequest.dataDateTimeRange.from)!!,
        to = dateFormatter.parse(consentRequest.dataDateTimeRange.to)!!
      ),
      consentDateTimeRange = DateTimeRange(
        from = dateFormatter.parse(consentRequest.consentDateTimeRange.from)!!,
        to = dateFormatter.parse(consentRequest.consentDateTimeRange.to)!!
      ),
      consentDataLife = ConsentDataLifePeriod(
        unit = consentRequest.consentDataLifePeriod.unit,
        value = consentRequest.consentDataLifePeriod.value
      ),
      consentDataFrequency = ConsentDataFrequency(
        unit = consentRequest.consentDataFrequency.unit,
        value = consentRequest.consentDataFrequency.value
      ),
      fiTypes = consentRequest.fiTypes?.filterNotNull(),
      consentId = consentRequest.consentId
    )

    val finvuLinkedAccounts = linkedAccounts.map {
      LinkedAccountDetails(
        userId = it.userId,
        fipId = it.fipId,
        fipName = it.fipName,
        maskedAccountNumber = it.maskedAccountNumber,
        accountReferenceNumber = it.accountReferenceNumber,
        linkReferenceNumber = it.linkReferenceNumber,
        consentIdList = it.consentIdList?.filterNotNull(),
        fiType = it.fiType,
        accountType = it.accountType,
        linkedAccountUpdateTimestamp = it.linkedAccountUpdateTimestamp?.let { timestamp -> dateFormatter.parse(timestamp) },
        authenticatorType = it.authenticatorType
      )
    }

    FinvuManager.shared.approveConsentRequest(consentDetails, finvuLinkedAccounts) { result ->
      if (result.isFailure) {
        val error = result.exceptionOrNull() as FinvuException
        callback(Result.failure(NativeFinvuError(code = error.code.toString(), message = error.message)))
        return@approveConsentRequest
      }

      val response = result.getOrThrow()
      val nativeResponse = NativeProcessConsentRequestResponse(
        consentIntentId = response.consentIntentId,
        consentInfo = response.consentsInfo?.map { consentInfo -> NativeConsentInfo(consentId = consentInfo.consentId, fipId = consentInfo.fipId) }
      )

      callback(Result.success(nativeResponse))
    }
  }

  override fun denyConsentRequest(
    consentRequest: NativeConsentRequestDetailInfo,
    callback: (Result<NativeProcessConsentRequestResponse>) -> Unit
  ) {
    val consentDetails = ConsentDetail(
      consentHandle = consentRequest.consentHandleId,
      financialInformationUser = FinancialInformationEntity(
        id = consentRequest.financialInformationUser.id,
        name = consentRequest.financialInformationUser.name
      ),
      statusLastUpdateTimestamp = null,
      consentPurpose = ConsentPurpose(
        code = consentRequest.consentPurposeInfo.code,
        text = consentRequest.consentPurposeInfo.text
      ),
      consentDisplayDescriptions = consentRequest.consentDisplayDescriptions.filterNotNull(),
      dataDateTimeRange = DateTimeRange(
        from = dateFormatter.parse(consentRequest.dataDateTimeRange.from)!!,
        to = dateFormatter.parse(consentRequest.dataDateTimeRange.to)!!
      ),
      consentDateTimeRange = DateTimeRange(
        from = dateFormatter.parse(consentRequest.consentDateTimeRange.from)!!,
        to = dateFormatter.parse(consentRequest.consentDateTimeRange.to)!!
      ),
      consentDataLife = ConsentDataLifePeriod(
        unit = consentRequest.consentDataLifePeriod.unit,
        value = consentRequest.consentDataLifePeriod.value
      ),
      consentDataFrequency = ConsentDataFrequency(
        unit = consentRequest.consentDataFrequency.unit,
        value = consentRequest.consentDataFrequency.value
      ),
      fiTypes = consentRequest.fiTypes?.filterNotNull(),
      consentId = consentRequest.consentId
      )

    FinvuManager.shared.denyConsentRequest(consentDetails) { result ->
      if (result.isFailure) {
        val error = result.exceptionOrNull() as FinvuException
        callback(Result.failure(NativeFinvuError(code = error.code.toString(), message = error.message)))
        return@denyConsentRequest
      }

      val response = result.getOrThrow()
      val nativeResponse = NativeProcessConsentRequestResponse(
        consentIntentId = response.consentIntentId,
        consentInfo = response.consentsInfo?.map { consentInfo ->
          NativeConsentInfo(consentId = consentInfo.consentId, fipId = consentInfo.fipId)
        }
      )

      callback(Result.success(nativeResponse))
    }
  }

  override fun revokeConsent(consentId: String, accountAggregator: NativeAccountAggregator?, fipDetails: NativeFIPReference?, callback: (Result<Unit>) -> Unit) {
    val aa = if (accountAggregator != null) AccountAggregatorView(id = accountAggregator.id) else null
    val _fipDetails = if (fipDetails != null) FIPReferenceView(fipId = fipDetails.fipId, fipName = fipDetails.fipName) else null
    FinvuManager.shared.revokeConsent(consentId, aa, _fipDetails) { result ->
      if (result.isFailure) {
        val error = result.exceptionOrNull() as FinvuException
        callback(Result.failure(NativeFinvuError(code = error.code.toString(), message = error.message)))
        return@revokeConsent
      }

      callback(Result.success(Unit))
    }
  }

  override fun getConsentHandleStatus(
    handleId: String,
    callback: (Result<NativeConsentHandleStatusResponse>) -> Unit
  ) {
    FinvuManager.shared.getConsentHandleStatus(handleId) { result ->
      if (result.isFailure) {
        val error = result.exceptionOrNull() as FinvuException
        callback(Result.failure(NativeFinvuError(code = error.code.toString(), message = error.message)))
        return@getConsentHandleStatus
      }

      val response = result.getOrThrow()
      val consentHandleStatus = NativeConsentHandleStatusResponse(status = response.status)
      callback(Result.success(consentHandleStatus))
    }
  }

  override fun getConsentRequestDetails(
    handleId: String,
    callback: (Result<NativeConsentRequestDetailInfo>) -> Unit
  ) {
    FinvuManager.shared.getConsentRequestDetails(handleId) { result ->
      if (result.isFailure) {
        val error = result.exceptionOrNull() as FinvuException
        callback(Result.failure(NativeFinvuError(code = error.code.toString(), message = error.message)))
        return@getConsentRequestDetails
      }

      val response = result.getOrThrow()
      val consentRequestDetail = NativeConsentRequestDetailInfo(
        consentId = response.consentDetail.consentId,
        consentHandleId = response.consentDetail.consentHandle,
        statusLastUpdateTimestamp = response.consentDetail.statusLastUpdateTimestamp?.let {
          dateFormatter.format(it)
        } ?: "",
        financialInformationUser = NativeFinancialInformationEntity(
          id = response.consentDetail.financialInformationUser.id,
          name = response.consentDetail.financialInformationUser.name,
        ),
        consentPurposeInfo = NativeConsentPurposeInfo(
          code = response.consentDetail.consentPurpose.code,
          text = response.consentDetail.consentPurpose.text,
        ),
        consentDisplayDescriptions = response.consentDetail.consentDisplayDescriptions,
        dataDateTimeRange = NativeDateTimeRange(
          from = dateFormatter.format(response.consentDetail.dataDateTimeRange.from),
          to = dateFormatter.format(response.consentDetail.dataDateTimeRange.to)
        ),
        consentDateTimeRange = NativeDateTimeRange(
          from = dateFormatter.format(response.consentDetail.consentDateTimeRange.from),
          to = dateFormatter.format(response.consentDetail.consentDateTimeRange.to)
        ),
        consentDataLifePeriod = NativeConsentDataLifePeriod(
          unit = response.consentDetail.consentDataLife.unit,
          value = response.consentDetail.consentDataLife.value
        ),
        consentDataFrequency = NativeConsentDataFrequency(
          unit = response.consentDetail.consentDataFrequency.unit,
          value = response.consentDetail.consentDataFrequency.value
        ),
        fiTypes = response.consentDetail.fiTypes,
      )

      callback(Result.success(consentRequestDetail))
    }
  }

  override fun logout(callback: (Result<Unit>) -> Unit) {
    FinvuManager.shared.logout {
      if (it.isFailure) {
        val error = it.exceptionOrNull() as FinvuException
        callback(Result.failure(NativeFinvuError(code = error.code.toString(), message = error.message)))
        return@logout
      }

      callback(Result.success(Unit))
    }
  }
}
