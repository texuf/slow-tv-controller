import AppKit

@main
struct SlowTVApp {
    static let delegate = AppDelegate()

    static func main() {
        let app = NSApplication.shared
        app.delegate = delegate
        app.run()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var appState: AppState!
    private var menuBarController: MenuBarController!
    private var controllerManager: ControllerManager!
    private var accessibilityManager: AccessibilityManager!
    private var inputMapper: InputMapper!
    private var cursorMover: CursorMover!
    private var eventInjector: EventInjector!
    private var killSwitch: KillSwitch!

    func applicationDidFinishLaunching(_ notification: Notification) {
        appState = AppState()

        menuBarController = MenuBarController(appState: appState)
        menuBarController.onToggleEnabled = { [weak self] in
            self?.appState.injectionEnabled.toggle()
        }
        menuBarController.onQuit = {
            NSApplication.shared.terminate(nil)
        }

        accessibilityManager = AccessibilityManager(appState: appState)
        accessibilityManager.checkAndPrompt()

        eventInjector = EventInjector()

        let cursorEngine = CursorEngine()
        cursorMover = CursorMover(appState: appState, engine: cursorEngine)

        killSwitch = KillSwitch(appState: appState)

        inputMapper = InputMapper(
            appState: appState,
            cursorMover: cursorMover,
            eventInjector: eventInjector,
            killSwitch: killSwitch
        )

        controllerManager = ControllerManager(appState: appState, inputMapper: inputMapper)
        controllerManager.startDiscovery()
    }

    func applicationWillTerminate(_ notification: Notification) {
        cursorMover.stop()
        controllerManager.stopDiscovery()
    }
}
