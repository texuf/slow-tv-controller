import CoreGraphics
import Foundation
import QuartzCore

final class CursorMover {
    private let appState: AppState
    private let engine: CursorEngine
    private var timer: DispatchSourceTimer?
    private let queue = DispatchQueue(label: "com.slowtv.cursormover", qos: .userInteractive)
    private var lastTickTime: CFTimeInterval = 0
    private let maxDt: CFTimeInterval = 0.05

    // Current stick input — updated from the polling thread
    private var stickX: Float = 0
    private var stickY: Float = 0
    private var precisionMode: Bool = false

    init(appState: AppState, engine: CursorEngine) {
        self.appState = appState
        self.engine = engine
        start()
    }

    func updateStick(x: Float, y: Float, precision: Bool) {
        stickX = x
        stickY = y
        precisionMode = precision
    }

    func start() {
        stop()
        lastTickTime = CACurrentMediaTime()

        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: 1.0 / 60.0)
        timer.setEventHandler { [weak self] in
            self?.tick()
        }
        timer.resume()
        self.timer = timer
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    private func tick() {
        let now = CACurrentMediaTime()
        var dt = now - lastTickTime
        lastTickTime = now

        // Clamp dt to avoid jumps
        if dt > maxDt { dt = maxDt }

        let (vx, vy) = engine.computeVelocity(
            stickX: stickX,
            stickY: stickY,
            precisionMode: precisionMode
        )

        if vx == 0 && vy == 0 { return }
        guard appState.canInject else { return }

        let currentPos = CGEvent(source: nil)?.location ?? .zero
        let dx = vx * CGFloat(dt)
        let dy = vy * CGFloat(dt)

        var newX = currentPos.x + dx
        var newY = currentPos.y + dy

        // Clamp to screen bounds
        let bounds = DisplayUtilities.unionScreenBounds()
        newX = max(bounds.minX, min(newX, bounds.maxX - 1))
        newY = max(bounds.minY, min(newY, bounds.maxY - 1))

        let newPos = CGPoint(x: newX, y: newY)

        guard let event = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved,
                                   mouseCursorPosition: newPos, mouseButton: .left) else { return }
        event.post(tap: .cgSessionEventTap)
    }
}
