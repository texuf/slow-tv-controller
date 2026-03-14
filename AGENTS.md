# Agent Guide

## Build System

No SPM or Xcode build. The app compiles directly with `swiftc` via `build.sh`, which produces a `.app` bundle in `build/`. The binary is code-signed with an Apple Development certificate to preserve macOS accessibility (TCC) permissions across rebuilds.

Use `./build_and_restart.sh` to kill, rebuild, and relaunch in one step.

`project.yml` exists for XcodeGen if an `.xcodeproj` is ever needed, but the primary build path is `build.sh`.

## Architecture

This is an AppKit menu bar app (`LSUIElement: true`, no dock icon). It uses `NSApplication` with `NSApplicationDelegate` — not SwiftUI App lifecycle. SwiftUI is only used for view content (onboarding).

The `AppDelegate` is stored as a `static let` on the `@main` struct because `NSApplication.delegate` is a weak reference.

### Key components

- **ControllerManager** — GCController discovery and 60Hz polling on a dedicated serial queue. Must set `shouldMonitorBackgroundEvents = true` since this is a background app.
- **InputMapper** — Maps ControllerState to SemanticActions with edge detection (previous vs current frame). Owns button-to-action mapping.
- **CursorEngine** — Pure velocity math: dead zone (0.18), gamma curve (1.6), precision mode (0.35x), max speed 1800 pt/s.
- **CursorMover** — 60Hz timer loop posting `CGEvent(.mouseMoved)` with screen edge clamping.
- **EventInjector** — Creates and posts CGEvents for clicks, keys, scroll, and browser back (Cmd+[).
- **AppState** — `@Observable` shared state. `canInject` is a computed property requiring: `injectionEnabled && controllerConnected && accessibilityGranted && !killSwitchActive`.

### Important gotchas

- CGEvent-injected `keyDown` events do trigger macOS key repeat, unlike what you might expect. The d-pad uses simple keyDown/keyUp edge detection.
- CGEvent scroll uses "positive = scroll up" convention.
- CG coordinate system has origin at top-left (Y inverted from AppKit).
- Accessibility permission is per-binary. Code signing with a stable identity (`Apple Development`) preserves it across rebuilds. Ad-hoc signing (`--sign -`) does not.

## Project Structure

```
Sources/
  App/           AppMain.swift, AppState.swift, AppDelegate
  MenuBar/       NSStatusItem menu bar controller
  Controller/    GCController discovery, polling, ControllerState
  Input/         InputMapper, SemanticAction, KillSwitch
  Cursor/        CursorEngine (velocity math), CursorMover (60Hz loop)
  Events/        EventInjector (CGEvent posting)
  Permissions/   Accessibility check/prompt, onboarding window
  Utilities/     Display/screen coordinate helpers
```
