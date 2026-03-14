// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SlowTV",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "SlowTV",
            path: "Sources",
            swiftSettings: [
                .unsafeFlags(["-target", "arm64-apple-macosx15.0"]),
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("GameController"),
                .linkedFramework("CoreGraphics"),
            ]
        ),
    ]
)
