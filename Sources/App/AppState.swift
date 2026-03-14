import Foundation
import Observation

@Observable
final class AppState {
    var injectionEnabled: Bool = true
    var controllerConnected: Bool = false
    var controllerName: String = ""
    var accessibilityGranted: Bool = false
    var killSwitchActive: Bool = false

    var canInject: Bool {
        injectionEnabled && controllerConnected && accessibilityGranted && !killSwitchActive
    }
}
