import CoreGraphics

enum SemanticAction {
    case movePointer(x: Float, y: Float, precision: Bool)
    case leftClickDown
    case leftClickUp
    case rightClickDown
    case rightClickUp
    case dragDown
    case dragUp
    case keyDown(CGKeyCode)
    case keyUp(CGKeyCode)
    case scroll(deltaY: Int32)
    case killSwitch
}

// Common macOS virtual key codes
enum KeyCode {
    static let escape: CGKeyCode = 53
    static let returnKey: CGKeyCode = 36
    static let upArrow: CGKeyCode = 126
    static let downArrow: CGKeyCode = 125
    static let leftArrow: CGKeyCode = 123
    static let rightArrow: CGKeyCode = 124
}
