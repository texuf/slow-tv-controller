import Foundation

struct ControllerState {
    var leftStickX: Float = 0
    var leftStickY: Float = 0
    var rightStickX: Float = 0
    var rightStickY: Float = 0
    var leftTrigger: Float = 0   // L2
    var rightTrigger: Float = 0  // R2

    var buttonA: Bool = false     // Cross
    var buttonB: Bool = false     // Circle
    var buttonX: Bool = false     // Square
    var buttonY: Bool = false     // Triangle

    var leftShoulder: Bool = false   // L1
    var rightShoulder: Bool = false  // R1

    var dpadUp: Bool = false
    var dpadDown: Bool = false
    var dpadLeft: Bool = false
    var dpadRight: Bool = false

    var buttonMenu: Bool = false     // Start / Options
    var buttonOptions: Bool = false  // Share / Create
}
