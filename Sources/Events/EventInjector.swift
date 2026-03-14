import CoreGraphics

final class EventInjector {

    // MARK: - Mouse Clicks

    func postLeftClickDown() {
        postMouseEvent(type: .leftMouseDown, button: .left)
    }

    func postLeftClickUp() {
        postMouseEvent(type: .leftMouseUp, button: .left)
    }

    func postLeftClick() {
        postMouseEvent(type: .leftMouseDown, button: .left)
        postMouseEvent(type: .leftMouseUp, button: .left)
    }

    func postRightClickDown() {
        postMouseEvent(type: .rightMouseDown, button: .right)
    }

    func postRightClickUp() {
        postMouseEvent(type: .rightMouseUp, button: .right)
    }

    func postRightClick() {
        postMouseEvent(type: .rightMouseDown, button: .right)
        postMouseEvent(type: .rightMouseUp, button: .right)
    }

    // MARK: - Drag (R2)

    func postDragDown() {
        postMouseEvent(type: .leftMouseDown, button: .left)
    }

    func postDragUp() {
        postMouseEvent(type: .leftMouseUp, button: .left)
    }

    // MARK: - Key Press

    func postKeyDown(_ keyCode: CGKeyCode) {
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true) else { return }
        event.post(tap: .cgSessionEventTap)
    }

    func postKeyUp(_ keyCode: CGKeyCode) {
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false) else { return }
        event.post(tap: .cgSessionEventTap)
    }

    func postKeyPress(_ keyCode: CGKeyCode) {
        postKeyDown(keyCode)
        postKeyUp(keyCode)
    }

    // MARK: - Scroll

    func postScroll(deltaY: Int32) {
        guard let event = CGEvent(scrollWheelEvent2Source: nil, units: .line,
                                   wheelCount: 1, wheel1: deltaY, wheel2: 0, wheel3: 0) else { return }
        event.post(tap: .cgSessionEventTap)
    }

    // MARK: - Private

    private func postMouseEvent(type: CGEventType, button: CGMouseButton) {
        let pos = CGEvent(source: nil)?.location ?? .zero
        guard let event = CGEvent(mouseEventSource: nil, mouseType: type,
                                   mouseCursorPosition: pos, mouseButton: button) else { return }
        event.post(tap: .cgSessionEventTap)
    }
}
