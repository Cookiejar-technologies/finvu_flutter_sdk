package com.finvu.finvu_flutter_sdk

import NativeMfaError
import NativeMfaLoginParams
import NativeMfaResendInfo
import NativeMfaSession
import NativeMfaStep
import NativeMfaValidationError
import com.finvu.android.FinvuManager
import com.finvu.android.mfa.LoginParams
import com.finvu.android.mfa.MfaCompleteStep
import com.finvu.android.mfa.MfaInputStep
import com.finvu.android.mfa.MfaSelectFactorStep
import com.finvu.android.mfa.MfaSilentStep
import com.finvu.android.mfa.MfaStep
import com.finvu.android.mfa.SupportedFactors
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.launch
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

/**
 * Bridges the native MFA step objects to Flutter. Native steps carry functions, which cannot
 * cross the pigeon bridge, so each live step is kept here under a stepId and Dart refers to it
 * by that id. Steps are cleared on a new login and on logout.
 */
internal class FinvuMfaBridge(private val scopeProvider: () -> CoroutineScope?) {

  private val steps = ConcurrentHashMap<String, MfaStep>()

  fun clear() = steps.clear()

  fun login(params: NativeMfaLoginParams, callback: (Result<NativeMfaStep>) -> Unit) {
    clear()
    val loginParams = LoginParams(
      mobileNumber = params.mobileNumber,
      username = params.username,
      consentHandle = params.consentHandle,
      handleId = params.handleId,
      clientContext = params.clientContext
        ?.filterKeys { it != null }
        ?.mapKeys { it.key!! },
      supportedFactors = SupportedFactors(
        firstFactor = params.firstFactor?.filterNotNull() ?: emptyList(),
        secondFactor = params.secondFactor?.filterNotNull() ?: emptyList()
      ),
      useEncConsent = params.useEncConsent,
      finalizeSession = params.finalizeSession,
      selectFactorChoice = params.selectFactorChoice
    )
    run(callback) { FinvuManager.shared.mfaClient.login(loginParams) }
  }

  fun submit(stepId: String, value: String, callback: (Result<NativeMfaStep>) -> Unit) =
    withStep<MfaInputStep>(stepId, callback) { it.submit(value) }

  fun resend(stepId: String, callback: (Result<NativeMfaStep>) -> Unit) =
    withStep<MfaInputStep>(stepId, callback) { step ->
      step.resend?.invoke() ?: return@withStep null
    }

  fun forgotPin(stepId: String, callback: (Result<NativeMfaStep>) -> Unit) =
    withStep<MfaInputStep>(stepId, callback) { step ->
      step.forgotPin?.invoke() ?: return@withStep null
    }

  fun selectFactor(stepId: String, factor: String, callback: (Result<NativeMfaStep>) -> Unit) =
    withStep<MfaSelectFactorStep>(stepId, callback) { it.selectFactor(factor) }

  fun awaitCompletion(stepId: String, callback: (Result<NativeMfaStep>) -> Unit) =
    withStep<MfaSilentStep>(stepId, callback) { it.completion.await() }

  fun retry(stepId: String, callback: (Result<NativeMfaStep>) -> Unit) =
    withStep<MfaCompleteStep>(stepId, callback) { step ->
      step.retry?.invoke() ?: return@withStep null
    }

  /** Runs [block] on the step with [stepId]; a null result means the action is not available on it. */
  private inline fun <reified T : MfaStep> withStep(
    stepId: String,
    noinline callback: (Result<NativeMfaStep>) -> Unit,
    noinline block: suspend (T) -> MfaStep?
  ) {
    val step = steps[stepId] as? T
    if (step == null) {
      callback(Result.success(failed("mfaStepNotFound", "MFA step not found or no longer valid")))
      return
    }
    run(callback) { block(step) }
  }

  private fun run(callback: (Result<NativeMfaStep>) -> Unit, block: suspend () -> MfaStep?) {
    val scope = scopeProvider() ?: MainScope()
    scope.launch {
      val nativeStep = try {
        block()?.let { toNative(it) } ?: failed("actionNotAvailable", "This action is not available on the step")
      } catch (e: CancellationException) {
        throw e
      } catch (t: Throwable) {
        failed("mfaFailed", t.message ?: "Authentication failed")
      }
      callback(Result.success(nativeStep))
    }
  }

  private fun toNative(step: MfaStep): NativeMfaStep {
    val stepId = UUID.randomUUID().toString()
    steps[stepId] = step
    return when (step) {
      is MfaInputStep -> NativeMfaStep(
        stepId = stepId,
        action = step.action,
        factor = step.factor,
        requirement = step.requirement,
        purpose = step.purpose,
        pinLength = step.inputSpec?.pinLength?.toLong(),
        validationError = step.validationError?.let {
          NativeMfaValidationError(it.code, it.message, it.attemptsRemaining?.toLong())
        },
        resendInfo = step.resendInfo?.let {
          NativeMfaResendInfo(it.resendAfterSeconds?.toLong(), it.resendsRemaining?.toLong())
        },
        hasResend = step.resend != null,
        hasForgotPin = step.forgotPin != null,
        hasRetry = false
      )
      is MfaSilentStep -> NativeMfaStep(
        stepId = stepId,
        action = step.action,
        factor = step.factor,
        hasResend = false,
        hasForgotPin = false,
        hasRetry = false
      )
      is MfaSelectFactorStep -> NativeMfaStep(
        stepId = stepId,
        action = step.action,
        availableFactors = step.availableFactors,
        hasResend = false,
        hasForgotPin = false,
        hasRetry = false
      )
      is MfaCompleteStep -> NativeMfaStep(
        stepId = stepId,
        action = step.action,
        resultStatus = step.result.status,
        session = step.result.session?.let { NativeMfaSession(it.userId, it.sessionId, it.csid) },
        error = step.result.error?.let { NativeMfaError(it.code, it.message) },
        hasResend = false,
        hasForgotPin = false,
        hasRetry = step.retry != null
      )
    }
  }

  /** A failed 'complete' step built on this side (not stored: it has no retry). */
  private fun failed(code: String, message: String) = NativeMfaStep(
    stepId = UUID.randomUUID().toString(),
    action = "complete",
    resultStatus = "failed",
    error = NativeMfaError(code, message),
    hasResend = false,
    hasForgotPin = false,
    hasRetry = false
  )
}
