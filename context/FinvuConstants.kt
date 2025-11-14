package com.finvu.android.utils

import com.finvu.android.models.consentRequest.models.AccountAggregator

class FinvuConstants {
    object API {
        const val REBIT_VERSION = "1.1.2"
        val finvuAA = AccountAggregator("cookiejar-aa@finvu.in")

        const val PURPOSE_CODE_101 = "101"
        const val PURPOSE_CODE_102 = "102"
        const val PURPOSE_CODE_103 = "103"
        const val PURPOSE_CODE_104 = "104"
        const val PURPOSE_CODE_105 = "105"

        const val PURPOSE_REFER_URI_101 = "https://api.rebit.org.in/aa/purpose/101.xml"
        const val PURPOSE_REFER_URI_102 = "https://api.rebit.org.in/aa/purpose/102.xml"
        const val PURPOSE_REFER_URI_103 = "https://api.rebit.org.in/aa/purpose/103.xml"
        const val PURPOSE_REFER_URI_104 = "https://api.rebit.org.in/aa/purpose/104.xml"
        const val PURPOSE_REFER_URI_105 = "https://api.rebit.org.in/aa/purpose/105.xml"
    }
}

object FinvuErrorMessages {
    // SNA Authentication Messages
    const val SNA_AUTHENTICATION_FAILED = "SNA authentication failed"
    const val SNA_AUTHENTICATION_CANCELLED = "SNA authentication was cancelled"
    const val SNA_AUTHENTICATION_TIMEOUT = "SNA authentication timed out"

    // Log Messages
    const val LOGIN_OTP_SUCCESS = "Login OTP success: otpRef=%s, authType=%s"
    const val SNA_FLOW_STARTING = "SNA flow: starting performSna for otpRef=%s"
    const val SNA_PERFORM_TIMEOUT = "performSna timed out or threw: %s"
    const val SNA_AUTHENTICATION_SUCCESSFUL = "SNA authentication successful for otpRef=%s"
    const val SNA_AUTHENTICATION_FAILED_LOG = "SNA authentication failed for otpRef=%s, error=%s"
    const val SNA_COROUTINE_CANCELLED = "SNA coroutine cancelled for otpRef=%s"
    const val SNA_PERFORM_UNEXPECTED = "SNA perform threw unexpected"

    // Networking Messages
    const val CSID_ALREADY_EXISTS = "CSID already exists: %s, skipping API call"
    const val CSID_API_RESPONSE = "CSID API response: %s"
    const val CSID_SAVED = "CSID saved: %s"
    const val CSID_NOT_FOUND = "CSID not found in response"
    const val CSID_API_FAILED = "CSID API failed with code: %s"
    const val CSID_PARSE_ERROR = "Error parsing CSID response: %s"
    const val CSID_API_CALL_FAILED = "Failed to get CSID: %s"
    const val WEBSOCKET_OPENED = "WebSocket opened."
    const val WEBSOCKET_MESSAGE_SENT = "WebSocket message sent: %s"
    const val WEBSOCKET_MESSAGE_RECEIVED = "WebSocket message received: %s"
    const val WEBSOCKET_BINARY_MESSAGE_RECEIVED = "WebSocket binary message received: %s"
    const val WEBSOCKET_CLOSED = "WebSocket closed: code=%s, reason=%s"
    const val WEBSOCKET_FAILURE = "WebSocket failure: %s"
    const val COULD_NOT_AUTO_CONNECT = "Could not auto-connect: error=%s"
    const val SET_COOKIES = "Set Cookies: %s"

    // Default Values
    const val UNKNOWN_PURPOSE = "Unknown Purpose"
    const val SNA_AUTH_TYPE = "SNA"
    const val CONSENT_API_V2_PATH = "/consentapiv2"

    // Event Tracker Messages
    const val EVENT_TRACKER_INITIALIZED = "Event tracker initialized"
    const val EVENT_TRACKER_CLEANED_UP = "Event tracker cleaned up and reset"
    const val EVENT_TRACKING_ENABLED = "Event tracking enabled"
    const val EVENT_TRACKING_DISABLED = "Event tracking disabled"
    const val EVENT_LISTENER_ADDED = "Event listener added. Total listeners: %s"
    const val EVENT_LISTENER_REMOVED = "Event listener removed. Remaining listeners: %s"
    const val UNKNOWN_EVENT = "Unknown event: %s"
    const val ERROR_TRACKING_EVENT = "Error tracking event: %s"
    const val ERROR_NOTIFYING_LISTENER = "Error notifying listener: %s"
    const val EVENT_NAME_ALREADY_EXISTS = "Event name %s already exists in default events"
    const val ALIAS_ALREADY_IN_USE = "Alias %s is already in use"
    const val CANNOT_CREATE_ALIAS = "Cannot create alias: Unknown standard event name '%s'"
}
