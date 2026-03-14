import Foundation

struct CursorEngine {
    private let deadZone: Float = 0.18
    private let gamma: Float = 1.6
    private let maxSpeed: Float = 1800  // points per second
    private let precisionFactor: Float = 0.35

    func computeVelocity(stickX: Float, stickY: Float, precisionMode: Bool) -> (dx: CGFloat, dy: CGFloat) {
        let magnitude = sqrtf(stickX * stickX + stickY * stickY)

        if magnitude < deadZone {
            return (0, 0)
        }

        // Remap: [deadZone, 1] → [0, 1]
        let adjusted = min((magnitude - deadZone) / (1.0 - deadZone), 1.0)

        // Gamma curve
        var curved = powf(adjusted, gamma)

        // Precision mode
        if precisionMode {
            curved *= precisionFactor
        }

        // Direction (normalize by magnitude)
        let dirX = stickX / magnitude
        let dirY = stickY / magnitude

        // Velocity in points/second
        let vx = dirX * curved * maxSpeed
        let vy = dirY * curved * maxSpeed

        // Note: CG coordinate system has Y increasing downward,
        // but Game Controller Y axis is up-positive, so negate Y
        return (CGFloat(vx), CGFloat(-vy))
    }
}
