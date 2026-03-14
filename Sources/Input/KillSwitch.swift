import Foundation

final class KillSwitch {
    private let appState: AppState
    private var timer: Timer?
    private let duration: TimeInterval = 5.0

    init(appState: AppState) {
        self.appState = appState
    }

    func activate() {
        timer?.invalidate()

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            appState.killSwitchActive = true

            timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                self?.appState.killSwitchActive = false
                self?.timer = nil
            }
        }
    }
}
