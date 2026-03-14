import AppKit

enum DisplayUtilities {
    /// Returns the union of all screen frames in CG (top-left origin) coordinates.
    static func unionScreenBounds() -> CGRect {
        let screens = NSScreen.screens
        guard !screens.isEmpty else {
            return CGRect(x: 0, y: 0, width: 1920, height: 1080)
        }

        // NSScreen uses bottom-left origin; CG uses top-left origin.
        // We need to convert. The main screen's frame determines the coordinate flip.
        let mainHeight = NSScreen.main?.frame.height ?? screens[0].frame.height

        var union = CGRect.null
        for screen in screens {
            let nsFrame = screen.frame
            // Convert: CG.y = mainHeight - (ns.y + ns.height)
            let cgY = mainHeight - (nsFrame.origin.y + nsFrame.height)
            let cgFrame = CGRect(x: nsFrame.origin.x, y: cgY,
                                 width: nsFrame.width, height: nsFrame.height)
            union = union.union(cgFrame)
        }
        return union
    }
}
