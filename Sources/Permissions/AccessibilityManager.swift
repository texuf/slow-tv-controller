import AppKit
import ApplicationServices

final class AccessibilityManager {
    private let appState: AppState
    private var pollTimer: Timer?
    private var onboardingController: OnboardingWindowController?

    init(appState: AppState) {
        self.appState = appState
    }

    func checkAndPrompt() {
        let trusted = AXIsProcessTrusted()
        NSLog("[Accessibility] trusted = %d", trusted)
        if trusted {
            appState.accessibilityGranted = true
            return
        }

        // Show onboarding window (no system prompt — ours is better)
        onboardingController = OnboardingWindowController()
        onboardingController?.showWindow()

        // Poll until granted
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            let granted = AXIsProcessTrusted()
            if granted {
                NSLog("[Accessibility] granted!")
                self?.appState.accessibilityGranted = true
                self?.pollTimer?.invalidate()
                self?.pollTimer = nil
                self?.onboardingController?.close()
                self?.onboardingController = nil
            }
        }
    }
}
