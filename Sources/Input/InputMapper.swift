import CoreGraphics

final class InputMapper {
    private let appState: AppState
    private let cursorMover: CursorMover
    private let eventInjector: EventInjector
    private let killSwitch: KillSwitch

    // Previous state for edge detection
    private var prevState = ControllerState()
    private var scrollAccumulator: Float = 0
    private let scrollThreshold: Float = 0.15
    private let scrollSpeed: Float = 3.0

    init(appState: AppState, cursorMover: CursorMover, eventInjector: EventInjector, killSwitch: KillSwitch) {
        self.appState = appState
        self.cursorMover = cursorMover
        self.eventInjector = eventInjector
        self.killSwitch = killSwitch
    }

    func process(_ state: ControllerState) {
        let actions = mapActions(current: state, previous: prevState)
        execute(actions)
        prevState = state
    }

    func controllerDisconnected() {
        // Release any held buttons
        if prevState.buttonA { eventInjector.postLeftClickUp() }
        if prevState.buttonB { eventInjector.postRightClickUp() }
        if prevState.rightTrigger > 0.5 { eventInjector.postDragUp() }
        prevState = ControllerState()
        cursorMover.updateStick(x: 0, y: 0, precision: false)
    }

    private func mapActions(current: ControllerState, previous: ControllerState) -> [SemanticAction] {
        var actions: [SemanticAction] = []

        // Kill switch: Start + B
        if current.buttonMenu && current.buttonB && !(previous.buttonMenu && previous.buttonB) {
            actions.append(.killSwitch)
            return actions  // Don't process other inputs when triggering kill switch
        }

        // Left stick → pointer movement
        let precisionMode = current.leftTrigger > 0.3
        actions.append(.movePointer(x: current.leftStickX, y: current.leftStickY, precision: precisionMode))

        // A (Cross) → left click
        if current.buttonA && !previous.buttonA {
            actions.append(.leftClickDown)
        } else if !current.buttonA && previous.buttonA {
            actions.append(.leftClickUp)
        }

        // B (Circle) → right click (only when menu not held — otherwise it's kill switch)
        if !current.buttonMenu {
            if current.buttonB && !previous.buttonB {
                actions.append(.rightClickDown)
            } else if !current.buttonB && previous.buttonB {
                actions.append(.rightClickUp)
            }
        }

        // R2 → drag
        let r2Pressed = current.rightTrigger > 0.5
        let r2WasPressed = previous.rightTrigger > 0.5
        if r2Pressed && !r2WasPressed {
            actions.append(.dragDown)
        } else if !r2Pressed && r2WasPressed {
            actions.append(.dragUp)
        }

        // D-pad → arrow keys
        if current.dpadUp && !previous.dpadUp { actions.append(.keyDown(KeyCode.upArrow)) }
        if !current.dpadUp && previous.dpadUp { actions.append(.keyUp(KeyCode.upArrow)) }

        if current.dpadDown && !previous.dpadDown { actions.append(.keyDown(KeyCode.downArrow)) }
        if !current.dpadDown && previous.dpadDown { actions.append(.keyUp(KeyCode.downArrow)) }

        if current.dpadLeft && !previous.dpadLeft { actions.append(.keyDown(KeyCode.leftArrow)) }
        if !current.dpadLeft && previous.dpadLeft { actions.append(.keyUp(KeyCode.leftArrow)) }

        if current.dpadRight && !previous.dpadRight { actions.append(.keyDown(KeyCode.rightArrow)) }
        if !current.dpadRight && previous.dpadRight { actions.append(.keyUp(KeyCode.rightArrow)) }

        // L1 → Escape
        if current.leftShoulder && !previous.leftShoulder { actions.append(.keyDown(KeyCode.escape)) }
        if !current.leftShoulder && previous.leftShoulder { actions.append(.keyUp(KeyCode.escape)) }

        // R1 → Enter
        if current.rightShoulder && !previous.rightShoulder { actions.append(.keyDown(KeyCode.returnKey)) }
        if !current.rightShoulder && previous.rightShoulder { actions.append(.keyUp(KeyCode.returnKey)) }

        // Right stick Y → scroll
        if abs(current.rightStickY) > scrollThreshold {
            let scrollDelta = Int32(-current.rightStickY * scrollSpeed)
            if scrollDelta != 0 {
                actions.append(.scroll(deltaY: scrollDelta))
            }
        }

        return actions
    }

    private func execute(_ actions: [SemanticAction]) {
        for action in actions {
            switch action {
            case .movePointer(let x, let y, let precision):
                cursorMover.updateStick(x: x, y: y, precision: precision)

            case .leftClickDown:
                guard appState.canInject else { continue }
                eventInjector.postLeftClickDown()

            case .leftClickUp:
                guard appState.canInject else { continue }
                eventInjector.postLeftClickUp()

            case .rightClickDown:
                guard appState.canInject else { continue }
                eventInjector.postRightClickDown()

            case .rightClickUp:
                guard appState.canInject else { continue }
                eventInjector.postRightClickUp()

            case .dragDown:
                guard appState.canInject else { continue }
                eventInjector.postDragDown()

            case .dragUp:
                guard appState.canInject else { continue }
                eventInjector.postDragUp()

            case .keyDown(let keyCode):
                guard appState.canInject else { continue }
                eventInjector.postKeyDown(keyCode)

            case .keyUp(let keyCode):
                guard appState.canInject else { continue }
                eventInjector.postKeyUp(keyCode)

            case .scroll(let deltaY):
                guard appState.canInject else { continue }
                eventInjector.postScroll(deltaY: deltaY)

            case .killSwitch:
                killSwitch.activate()
            }
        }
    }
}
