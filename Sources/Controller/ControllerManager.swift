import GameController

final class ControllerManager {
    private let appState: AppState
    private let inputMapper: InputMapper
    private var currentController: GCController?
    private var pollTimer: DispatchSourceTimer?
    private let pollQueue = DispatchQueue(label: "com.slowtv.controllerpoll", qos: .userInteractive)

    init(appState: AppState, inputMapper: InputMapper) {
        self.appState = appState
        self.inputMapper = inputMapper
    }

    private var pollCount = 0

    func startDiscovery() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(controllerConnected(_:)),
            name: .GCControllerDidConnect,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(controllerDisconnected(_:)),
            name: .GCControllerDidDisconnect,
            object: nil
        )
        GCController.startWirelessControllerDiscovery {}

        // Check for already-connected controllers
        let existing = GCController.controllers()
        NSLog("[Controller] startDiscovery — \(existing.count) already connected")
        for c in existing {
            NSLog("[Controller]   \(c.vendorName ?? "unknown") extendedGamepad=\(c.extendedGamepad != nil)")
        }
        if let controller = existing.first {
            bind(controller)
        }
    }

    func stopDiscovery() {
        GCController.stopWirelessControllerDiscovery()
        NotificationCenter.default.removeObserver(self)
        stopPolling()
    }

    @objc private func controllerConnected(_ notification: Notification) {
        guard let controller = notification.object as? GCController else { return }
        NSLog("[Controller] connected: \(controller.vendorName ?? "unknown") extendedGamepad=\(controller.extendedGamepad != nil)")
        if currentController == nil {
            bind(controller)
        }
    }

    @objc private func controllerDisconnected(_ notification: Notification) {
        guard let controller = notification.object as? GCController,
              controller === currentController else { return }
        currentController = nil
        stopPolling()

        DispatchQueue.main.async { [weak self] in
            self?.appState.controllerConnected = false
            self?.appState.controllerName = ""
        }
        inputMapper.controllerDisconnected()

        // Try to bind another controller if available
        if let next = GCController.controllers().first {
            bind(next)
        }
    }

    private func bind(_ controller: GCController) {
        currentController = controller
        controller.playerIndex = .index1

        DispatchQueue.main.async { [weak self] in
            self?.appState.controllerConnected = true
            self?.appState.controllerName = controller.vendorName ?? "Controller"
        }

        startPolling()
    }

    private func startPolling() {
        stopPolling()
        let timer = DispatchSource.makeTimerSource(queue: pollQueue)
        timer.schedule(deadline: .now(), repeating: 1.0 / 60.0)
        timer.setEventHandler { [weak self] in
            self?.poll()
        }
        timer.resume()
        pollTimer = timer
    }

    private func stopPolling() {
        pollTimer?.cancel()
        pollTimer = nil
    }

    private func poll() {
        guard let controller = currentController,
              let gamepad = controller.extendedGamepad else { return }

        pollCount += 1
        if pollCount == 1 || pollCount % 300 == 0 {
            NSLog("[Poll] #\(pollCount) stick=(\(gamepad.leftThumbstick.xAxis.value), \(gamepad.leftThumbstick.yAxis.value)) A=\(gamepad.buttonA.isPressed) canInject=\(appState.canInject) ax=\(appState.accessibilityGranted) enabled=\(appState.injectionEnabled) connected=\(appState.controllerConnected) kill=\(appState.killSwitchActive)")
        }

        var state = ControllerState()

        state.leftStickX = gamepad.leftThumbstick.xAxis.value
        state.leftStickY = gamepad.leftThumbstick.yAxis.value
        state.rightStickX = gamepad.rightThumbstick.xAxis.value
        state.rightStickY = gamepad.rightThumbstick.yAxis.value

        state.leftTrigger = gamepad.leftTrigger.value
        state.rightTrigger = gamepad.rightTrigger.value

        state.buttonA = gamepad.buttonA.isPressed
        state.buttonB = gamepad.buttonB.isPressed
        state.buttonX = gamepad.buttonX.isPressed
        state.buttonY = gamepad.buttonY.isPressed

        state.leftShoulder = gamepad.leftShoulder.isPressed
        state.rightShoulder = gamepad.rightShoulder.isPressed

        state.dpadUp = gamepad.dpad.up.isPressed
        state.dpadDown = gamepad.dpad.down.isPressed
        state.dpadLeft = gamepad.dpad.left.isPressed
        state.dpadRight = gamepad.dpad.right.isPressed

        state.buttonMenu = gamepad.buttonMenu.isPressed
        state.buttonOptions = gamepad.buttonOptions?.isPressed ?? false

        inputMapper.process(state)
    }
}
