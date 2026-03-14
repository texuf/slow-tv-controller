import AppKit
import Observation

final class MenuBarController {
    private let statusItem: NSStatusItem
    private let appState: AppState
    private var observationTask: Task<Void, Never>?

    var onToggleEnabled: (() -> Void)?
    var onQuit: (() -> Void)?

    init(appState: AppState) {
        self.appState = appState
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "gamecontroller", accessibilityDescription: "SlowTV Controller")
        }

        rebuildMenu()
        startObserving()
    }

    private func startObserving() {
        observationTask = Task { @MainActor [weak self] in
            var lastConnected = self?.appState.controllerConnected ?? false
            var lastEnabled = self?.appState.injectionEnabled ?? false
            var lastKillSwitch = self?.appState.killSwitchActive ?? false
            var lastName = self?.appState.controllerName ?? ""

            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                guard let self else { break }

                if self.appState.controllerConnected != lastConnected ||
                   self.appState.injectionEnabled != lastEnabled ||
                   self.appState.killSwitchActive != lastKillSwitch ||
                   self.appState.controllerName != lastName {
                    lastConnected = self.appState.controllerConnected
                    lastEnabled = self.appState.injectionEnabled
                    lastKillSwitch = self.appState.killSwitchActive
                    lastName = self.appState.controllerName
                    self.rebuildMenu()
                    self.updateIcon()
                }
            }
        }
    }

    private func updateIcon() {
        guard let button = statusItem.button else { return }
        let symbolName: String
        if !appState.controllerConnected {
            symbolName = "gamecontroller"
        } else if appState.killSwitchActive {
            symbolName = "gamecontroller.fill"
        } else if appState.injectionEnabled {
            symbolName = "gamecontroller.fill"
        } else {
            symbolName = "gamecontroller"
        }
        button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "SlowTV Controller")
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        if appState.controllerConnected {
            let controllerItem = NSMenuItem(title: "Controller: \(appState.controllerName)", action: nil, keyEquivalent: "")
            controllerItem.isEnabled = false
            menu.addItem(controllerItem)
        } else {
            let noController = NSMenuItem(title: "No Controller", action: nil, keyEquivalent: "")
            noController.isEnabled = false
            menu.addItem(noController)
        }

        menu.addItem(NSMenuItem.separator())

        let toggleTitle = appState.injectionEnabled ? "Disable Input" : "Enable Input"
        let toggleItem = NSMenuItem(title: toggleTitle, action: #selector(toggleEnabled), keyEquivalent: "")
        toggleItem.target = self
        toggleItem.isEnabled = appState.controllerConnected
        menu.addItem(toggleItem)

        if appState.killSwitchActive {
            let ksItem = NSMenuItem(title: "Kill Switch Active", action: nil, keyEquivalent: "")
            ksItem.isEnabled = false
            menu.addItem(ksItem)
        }

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit SlowTV Controller", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func toggleEnabled() {
        onToggleEnabled?()
    }

    @objc private func quit() {
        onQuit?()
    }

    deinit {
        observationTask?.cancel()
    }
}
