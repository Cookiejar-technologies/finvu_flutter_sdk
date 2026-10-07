import Foundation
import FinvuSDK

/// Bridges the native MFA step objects to Flutter. Native steps carry functions, which cannot
/// cross the pigeon bridge, so each live step is kept here under a stepId and Dart refers to it
/// by that id. Steps are cleared on a new login and on logout.
final class FinvuMfaBridge {
    typealias Completion = (Result<NativeMfaStep, Error>) -> Void

    private let lock = NSLock()
    private var steps: [String: MfaStep] = [:]

    func clear() {
        lock.lock(); steps.removeAll(); lock.unlock()
    }

    func login(_ params: NativeMfaLoginParams, completion: @escaping Completion) {
        clear()
        var clientContext: [String: Any]? = nil
        if let context = params.clientContext {
            var converted: [String: Any] = [:]
            for (key, value) in context {
                if let key = key, let value = value { converted[key] = value }
            }
            clientContext = converted
        }
        let loginParams = LoginParams(
            mobileNumber: params.mobileNumber,
            username: params.username,
            consentHandle: params.consentHandle,
            handleId: params.handleId,
            clientContext: clientContext,
            supportedFactors: SupportedFactors(
                firstFactor: params.firstFactor?.compactMap { $0 } ?? [],
                secondFactor: params.secondFactor?.compactMap { $0 } ?? []
            ),
            useEncConsent: params.useEncConsent,
            finalizeSession: params.finalizeSession,
            selectFactorChoice: params.selectFactorChoice
        )
        run(completion) { await FinvuManager.shared.mfaClient.login(loginParams) }
    }

    func submit(stepId: String, value: String, completion: @escaping Completion) {
        withStep(stepId, as: MfaInputStep.self, completion) { await $0.submit(value) }
    }

    func resend(stepId: String, completion: @escaping Completion) {
        withStep(stepId, as: MfaInputStep.self, completion) { step in
            guard let resend = step.resend else { return nil }
            return await resend()
        }
    }

    func forgotPin(stepId: String, completion: @escaping Completion) {
        withStep(stepId, as: MfaInputStep.self, completion) { step in
            guard let forgotPin = step.forgotPin else { return nil }
            return await forgotPin()
        }
    }

    func selectFactor(stepId: String, factor: String, completion: @escaping Completion) {
        withStep(stepId, as: MfaSelectFactorStep.self, completion) { await $0.selectFactor(factor) }
    }

    func awaitCompletion(stepId: String, completion: @escaping Completion) {
        withStep(stepId, as: MfaSilentStep.self, completion) { await $0.completion.value }
    }

    func retry(stepId: String, completion: @escaping Completion) {
        withStep(stepId, as: MfaCompleteStep.self, completion) { step in
            guard let retry = step.retry else { return nil }
            return await retry()
        }
    }

    // MARK: - Helpers

    /// Runs `block` on the step with `stepId`; a nil result means the action is not available on it.
    private func withStep<T>(_ stepId: String, as type: T.Type, _ completion: @escaping Completion,
                             _ block: @escaping (T) async -> MfaStep?) {
        lock.lock()
        let step = steps[stepId] as? T
        lock.unlock()
        guard let step = step else {
            reply(completion, failed(code: "mfaStepNotFound", message: "MFA step not found or no longer valid"))
            return
        }
        run(completion) { await block(step) }
    }

    private func run(_ completion: @escaping Completion, _ block: @escaping () async -> MfaStep?) {
        Task {
            let nativeStep: NativeMfaStep
            if let step = await block() {
                nativeStep = toNative(step)
            } else {
                nativeStep = failed(code: "actionNotAvailable", message: "This action is not available on the step")
            }
            reply(completion, nativeStep)
        }
    }

    /// Pigeon replies must be sent on the main thread.
    private func reply(_ completion: @escaping Completion, _ step: NativeMfaStep) {
        DispatchQueue.main.async { completion(.success(step)) }
    }

    private func toNative(_ step: MfaStep) -> NativeMfaStep {
        let stepId = UUID().uuidString
        lock.lock(); steps[stepId] = step; lock.unlock()

        switch step {
        case let input as MfaInputStep:
            return NativeMfaStep(
                stepId: stepId,
                action: input.action,
                factor: input.factor,
                requirement: input.requirement,
                purpose: input.purpose,
                pinLength: input.inputSpec.map { Int64($0.pinLength) },
                validationError: input.validationError.map {
                    NativeMfaValidationError(code: $0.code, message: $0.message,
                                             attemptsRemaining: $0.attemptsRemaining.map { Int64($0) })
                },
                resendInfo: input.resendInfo.map {
                    NativeMfaResendInfo(resendAfterSeconds: $0.resendAfterSeconds.map { Int64($0) },
                                        resendsRemaining: $0.resendsRemaining.map { Int64($0) })
                },
                hasResend: input.resend != nil,
                hasForgotPin: input.forgotPin != nil,
                hasRetry: false
            )
        case let silent as MfaSilentStep:
            return NativeMfaStep(stepId: stepId, action: silent.action, factor: silent.factor,
                                 hasResend: false, hasForgotPin: false, hasRetry: false)
        case let select as MfaSelectFactorStep:
            return NativeMfaStep(stepId: stepId, action: select.action, availableFactors: select.availableFactors,
                                 hasResend: false, hasForgotPin: false, hasRetry: false)
        case let complete as MfaCompleteStep:
            return NativeMfaStep(
                stepId: stepId,
                action: complete.action,
                resultStatus: complete.result.status,
                session: complete.result.session.map {
                    NativeMfaSession(userId: $0.userId, sessionId: $0.sessionId, csid: $0.csid)
                },
                error: complete.result.error.map { NativeMfaError(code: $0.code, message: $0.message) },
                hasResend: false,
                hasForgotPin: false,
                hasRetry: complete.retry != nil
            )
        default:
            return failed(code: "unexpectedStep", message: "Unexpected MFA step")
        }
    }

    /// A failed 'complete' step built on this side (not stored: it has no retry).
    private func failed(code: String, message: String) -> NativeMfaStep {
        NativeMfaStep(stepId: UUID().uuidString, action: "complete", resultStatus: "failed",
                      error: NativeMfaError(code: code, message: message),
                      hasResend: false, hasForgotPin: false, hasRetry: false)
    }
}
