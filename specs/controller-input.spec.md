# Controller Input Utility for macOS

## Purpose

Build a macOS utility inspired by Controller Companion: a lightweight background app that lets a Bluetooth game controller drive the Mac desktop, move the pointer, click, scroll, type, and surface a couch-friendly on-screen keyboard. The utility is intended to make a Mac connected to a TV usable from the sofa, especially for browser-based entertainment and media-center workflows.

The app should prioritize:

- low idle CPU usage
- reliable background controller capture
- predictable pointer and typing behavior
- a polished TV / 10-foot UX
- direct distribution outside the Mac App Store

Controller Companion’s Steam page describes the product as allowing desktop mouse/keyboard control from a gamepad and notes that clicking the left thumbstick can bring up “a nice arcade-style keyboard spiral.” citeturn735680search4turn735680search14 This spec includes a macOS implementation for a similar controller-first spiral keyboard.

---

## Product Summary

The product is a signed, notarized macOS menu bar utility with an optional companion full-screen overlay. It listens for controller input system-wide, translates that input into semantic actions, injects mouse/keyboard/scroll events, and displays specialized overlays such as a spiral keyboard and a radial command menu.

The app has two primary modes:

1. **Desktop Companion Mode**
   - left stick moves mouse
   - buttons click / right-click / back / expose shortcuts
   - right stick scrolls or performs alternate actions
   - can be used while browsing, launching apps, or controlling streaming sites

2. **Overlay Input Mode**
   - opens a keyboard or command overlay
   - temporarily captures controller input for text entry or discrete actions
   - supports couch-friendly typing without a physical keyboard

---

## Goals

### Primary goals

- Use a Bluetooth controller to drive the macOS pointer and keyboard globally.
- Support mainstream controllers first through Apple’s Game Controller framework.
- Offer a high-quality on-screen keyboard optimized for analog sticks and D-pad.
- Work while the utility is in the background.
- Let users launch browser-based entertainment apps and navigate them from the couch.

### Secondary goals

- Per-app mappings
- Custom profiles
- Radial menus
- Media controls
- Browser-specific presets
- Accessibility-friendly focus and text scaling

### Non-goals for v1

- Full UI automation of arbitrary apps
- OCR or semantic understanding of websites
- Deep integration with DRM streaming services
- App Store distribution
- Support for every obscure HID controller on day one

---

## Recommended Stack

### Language and frameworks

- **Swift**
- **AppKit** for menu bar app behavior, overlays, window management
- **SwiftUI** for settings UI and parts of the overlay UI where convenient
- **Game Controller** framework for controller input
- **Core Graphics / Quartz Event Services** for mouse and keyboard event injection
- **Accessibility APIs** for trust checking and limited UI-awareness features
- **SQLite** or lightweight persistence for settings and profiles

### Why native instead of Electron

A native implementation fits the problem better because it needs:

- menu bar lifecycle behavior
- input capture in the background
- synthetic event injection
- tight control over overlays and window levels
- lower CPU use than a browser runtime

---

## Architecture

Split the app into the following modules.

### 1. `ControllerManager`

Responsibilities:
- discover controllers
- monitor connect/disconnect state
- normalize device profiles
- expose button, axis, trigger, and battery state

Implementation notes:
- Prefer Apple’s Game Controller framework for standard Xbox / PlayStation / Switch-style controllers. Apple documents `GCController` and background monitoring behavior through `shouldMonitorBackgroundEvents`. citeturn735680search4
- For unsupported generic controllers, a later phase may add an `IOHIDManager` fallback path.

### 2. `InputMapper`

Responsibilities:
- map raw controller state to semantic actions
- support profiles, dead zones, repeat timing, long press, combos
- apply context-sensitive mappings

Example semantic actions:
- `movePointer(dx, dy)`
- `scroll(dx, dy)`
- `leftClick`
- `rightClick`
- `middleClick`
- `keyPress(.return)`
- `toggleSpiralKeyboard`
- `toggleRadialMenu`
- `home`
- `back`
- `mediaPlayPause`

### 3. `CursorEngine`

Responsibilities:
- convert analog values into cursor velocity
- apply acceleration curves
- smooth pointer motion
- support precision mode and snap behavior

Behavior requirements:
- configurable dead zone
- nonlinear acceleration
- optional friction / easing for stick release
- optional “precision hold” on trigger or shoulder button

### 4. `EventInjector`

Responsibilities:
- synthesize keyboard events
- synthesize mouse click / drag / scroll events
- post events into the system stream

Implementation notes:
- Use Core Graphics event creation and posting.
- Event injection should be centralized so the rest of the app never directly touches Quartz APIs.

### 5. `OverlayManager`

Responsibilities:
- show and hide overlay windows
- own z-ordering and display routing
- present the spiral keyboard, radial menu, status HUD, and settings flyouts

Requirements:
- overlays must appear on the active display or preferred TV display
- overlays must remain legible at living-room distances
- overlays should not steal focus more than necessary

### 6. `SpiralKeyboardEngine`

Responsibilities:
- manage the controller-friendly on-screen keyboard
- handle ring layout, focus selection, prediction hooks, and modifier states
- emit text-entry actions into the EventInjector

### 7. `ProfileStore`

Responsibilities:
- save/load global and per-app mappings
- save pointer speed and keyboard preferences
- persist active browser and media presets

### 8. `PermissionManager`

Responsibilities:
- detect Accessibility trust status
- guide the user through permissions onboarding
- explain degraded behavior if permission is missing

### 9. `MenubarController`

Responsibilities:
- expose app status
- allow enabling/disabling control injection
- choose profile
- show connected controller status
- launch settings

---

## Permissions and Distribution

### Required permissions

The app should request and explain:

- **Accessibility permission** for synthetic input and some system-wide event behavior

The app should not depend on Screen Recording permission for v1 unless a future feature explicitly needs screen analysis.

### Distribution model

Ship as:

- direct-download `.app`
- signed and notarized
- auto-update via Sparkle or equivalent

Do not target Mac App Store first. Global input utilities are significantly easier to ship and support outside App Store sandbox constraints.

---

## Controller Support Strategy

### Tier 1 controllers

Support first:
- Xbox Wireless Controller
- PlayStation DualSense / DualShock
- Switch Pro Controller where Game Controller support is acceptable

### Tier 2 controllers

- Generic Bluetooth retro controllers
- 8BitDo-like devices with variable mappings

### Device support policy

V1 should document:
- “best experience with Xbox / PlayStation controllers”
- generic controllers may need manual remapping

### Connection behavior

- auto-detect controller connect/disconnect
- show a small toast when controller becomes active
- if multiple controllers are connected, allow one active desktop controller at a time
- support battery reporting where available

---

## Default Mappings

These are the recommended defaults for Desktop Companion Mode.

### Pointer + mouse

- Left stick: pointer move
- A / South button: left click
- B / East button: right click
- X / West button: toggle keyboard
- Y / North button: expose action menu / app switcher
- Left trigger: precision pointer mode
- Right trigger: left click and hold
- Left bumper: browser back / Escape
- Right bumper: browser forward / Enter
- Right stick Y: vertical scroll
- Right stick X: horizontal scroll or disabled by default
- D-pad: arrow keys
- Start / Menu: open home overlay
- Select / Share: media controls overlay
- Left stick click: toggle spiral keyboard
- Right stick click: toggle scroll-lock / drag-lock mode

### Text / navigation helpers

- Hold A: click-and-drag
- Hold B: secondary context menu hold
- Double-tap Y: Mission Control or app switcher preset
- Start + B: emergency disable controls for 5 seconds
- Start + X: open settings overlay

---

## Pointer Behavior Specification

### Motion model

Use velocity-based cursor movement, not direct position mapping.

Recommended formula:

1. read normalized stick values in range `[-1, 1]`
2. apply dead zone
3. remap surviving input to `[0, 1]`
4. apply response curve `v = sign(x) * pow(abs(x), gamma)`
5. multiply by per-profile max speed
6. integrate over frame delta

Suggested defaults:
- dead zone: `0.18`
- gamma: `1.6`
- max speed: tuned to traverse a 4K TV comfortably
- precision multiplier when holding LT: `0.35`

### Update cadence

- use display-synced timing when possible
- fallback to a steady 60 Hz timer
- clamp frame delta when app stalls to prevent jumpy cursor motion

### Edge behavior

- stop cleanly at display bounds
- optionally slow slightly near edges to improve clicking accuracy

---

## Scroll Behavior Specification

Two possible implementations:

1. **Stick-as-scroll-wheel**
   - right stick continuously emits scroll deltas
   - ideal for web browsing

2. **Flick scroll**
   - quick stick deflection emits momentum burst
   - ideal for TV browsing in rows

V1 should implement stick-as-scroll-wheel.

Suggested defaults:
- right stick vertical -> vertical scroll
- shift modifier or RB hold -> horizontal scroll
- dead zone slightly larger than pointer dead zone to avoid accidental scroll

---

## Event Injection Specification

### Mouse actions

Must support:
- left down/up/click
- right down/up/click
- drag
- move
- wheel scroll

### Keyboard actions

Must support:
- virtual key press/release
- modifier combinations
- text insertion via discrete key events
- navigation keys (arrows, return, escape, tab, delete)

### Safety features

- global kill-switch hotkey and menu bar toggle
- pause event injection when app is disabled
- visible indicator when controller is controlling the desktop
- optional “suspend while game is frontmost” mode

---

## Overlay Design

### Overlay principles

- large text and hit targets
- high contrast
- focused item always obvious
- safe margins for TV overscan
- animated but restrained
- should feel more like a console UI than a desktop app dialog

### Overlay windows

Implement:
- spiral keyboard overlay
- radial actions overlay
- media overlay
- connection / battery toast
- profile quick-switch overlay

### Display targeting

- if external display is connected, use that display by default
- if user chooses otherwise, persist preferred display id
- if active pointer display differs from overlay display, optionally follow pointer display

---

## Spiral Keyboard Specification

### Design goal

Implement a couch-friendly text entry system inspired by the “arcade-style keyboard spiral” described for Controller Companion. citeturn735680search4turn735680search14 The macOS version should preserve the same spirit: quick controller typing without a physical keyboard, optimized for repeated use on a TV.

### Why spiral instead of a flat keyboard grid

A standard QWERTY grid is familiar but awkward on a gamepad because:
- focus travel is long
- analog precision is poor for dense grids
- diagonal / radial stick movement is underutilized

A spiral layout gives:
- compact navigation
- radial motor memory
- fast pathing from center to common characters
- a stronger “classic console / arcade” feel

### Visual inspiration

Aim for a hybrid of:
- retro arcade attract-screen typography
- 16-bit / Dreamcast / Sega-channel energy
- neon ring segmentation with clear focus state
- modern readability over strict nostalgia

The user specifically asked for a classic-games-inspired keyboard. That should influence visual theming, not core usability.

### Layout model

Use concentric rings around a center hub.

#### Structure

- **Center hub**: confirm, backspace, space, shift, mode switch
- **Ring 1**: high-frequency letters
- **Ring 2**: remaining letters
- **Ring 3**: numbers and punctuation
- **Ring 4 optional**: symbols, emoji shortcuts, app macros

### Recommended character placement

Use frequency-biased placement rather than alphabetical placement.

#### Ring 1: most common letters
`E T A O I N S H R`

#### Ring 2: next most common letters
`D L U C M F Y W G P B`

#### Ring 3: least common letters + digits + punctuation
`V K X J Q Z 0 1 2 3 4 5 6 7 8 9 . , ? ! @ - _`

This is intentionally optimized for English couch typing, especially search queries, emails, URLs, and streaming titles.

### Navigation model

Two supported navigation styles:

#### Mode A: D-pad ring stepping
- up/down moves between rings
- left/right steps around the active ring
- A selects focused item
- B backspace
- X space
- Y shift / caps

This is the safest and most accessible default.

#### Mode B: Analog sector aiming
- stick angle chooses sector
- stick magnitude chooses ring depth
- release-to-preview, A-to-confirm

This is faster after practice but harder to implement well.

### Recommendation

Ship v1 with **D-pad ring stepping** plus optional analog preview mode in labs settings.

### Center hub actions

At minimum include:
- `SPACE`
- `BACKSPACE`
- `SHIFT`
- `ENTER`
- `123` / `ABC` mode toggle
- `CLOSE`

Optional:
- `.com`
- `@`
- `CLEAR`
- `MIC` placeholder for later dictation

### Keyboard states

Support these states:
- lowercase
- uppercase one-shot
- caps lock
- numbers/punctuation
- URL mode
- email mode
- search mode

#### URL mode
Prioritize:
- `/`
- `.`
- `:`
- `-`
- `_`
- `.com`
- `.net`

#### Search mode
Prioritize:
- space
- apostrophe
- dash
- question mark

### Prediction and completion

V1 prediction is optional. If implemented, it should be conservative.

Useful completions:
- `.com`
- `www.`
- `netflix`
- `youtube`
- `max`
- recently typed app / profile names

Do not allow prediction UI to dominate the keyboard. The core interaction should remain one-button-per-character.

### Rendering details

- render as concentric segmented arcs
- each segment should have a large focus wedge
- focused wedge grows slightly and brightens
- center hub remains stable
- include subtle radial animation when moving between rings
- no tiny text
- minimum 44pt-equivalent target sizes, but visually tuned for TV viewing

### Theme specification: classic-games-inspired

Create a default visual theme called **Arcade Spiral**.

#### Arcade Spiral theme
- background: translucent smoked black panel
- rings: cyan / magenta / amber neon accents
- focus: bright scanline glow
- text: bold geometric sans or pixel-adjacent display font
- sound: optional soft menu blips inspired by 90s console UI
- transitions: quick but readable, around 120–180ms

Optional alternate themes for later:
- `Vector Grid`
- `Dream Console`
- `CRT Terminal`

### Spiral keyboard activation

Default triggers:
- click left stick to open/close
- if already open, clicking left stick accepts current string and closes
- long-press left stick opens in search mode

### Text commit behavior

Two commit modes:

1. **Live typing mode**
   - each selected character is emitted immediately as a key event
   - best for browser text fields

2. **Buffered mode**
   - keyboard collects a string in overlay
   - pressing ENTER injects the full string
   - safer for some apps and web views

Recommendation:
- support both
- default to **live typing** for standard desktop fields
- allow per-app override to buffered mode

### Accessibility rules

- high-contrast option
- reduced motion option
- optional speech feedback for selected character
- button-hold repeat for left/right stepping
- optional enlarged center hub

---

## Radial Command Menu Specification

In addition to the spiral keyboard, support a simple radial command menu for high-frequency actions.

Suggested entries:
- Home
- Back
- Enter
- Escape
- Tab
- Play/Pause
- Mute
- Browser Back
- Browser Forward
- Search
- Toggle Keyboard
- Settings

Activation:
- Y press or Start press depending on profile

---

## App Awareness and Per-App Profiles

### Global profile first

Ship one strong global profile before adding app-specific complexity.

### Per-app support for v1.5+

Allow matching by bundle id or process name.

Examples:
- Safari profile
- Chrome profile
- VLC profile
- Finder profile
- custom entertainment shell profile

### Example browser profile adjustments

For browsers:
- RB -> Enter
- LB -> Escape / Back
- Y -> address bar shortcut
- Start -> reopen app launcher

---

## Background Behavior

### Requirements

- the utility should continue to receive controller input when not frontmost, as much as macOS and controller support allow
- should clearly communicate to the user if their device or OS version does not fully support background monitoring

### Strategy

- prefer Game Controller’s background event monitoring for supported devices
- maintain a compatibility matrix by macOS version and controller family
- include diagnostics screen for controller event visibility

### Suspend rules

Optional settings:
- suspend when a fullscreen game is active
- suspend for specific bundle ids
- suspend when Steam Big Picture is frontmost

---

## Settings UI Specification

### General
- launch at login
- show controller status in menu bar
- enable/disable desktop control
- suspend while game is frontmost
- preferred display for overlays

### Pointer
- speed
- acceleration
- dead zone
- precision mode multiplier
- invert X/Y optional

### Buttons
- remap buttons
- long-press behavior
- repeat rates
- drag-lock toggle

### Keyboard
- keyboard style: spiral / simple grid
- live vs buffered input
- theme selection
- URL mode defaults
- sounds on/off
- prediction on/off

### Profiles
- active global profile
- per-app override table
- import/export profile JSON

### Diagnostics
- connected controller data
- raw axis values
- event injection test
- accessibility permission status

---

## Persistence Schema

A lightweight JSON or SQLite-backed model is sufficient.

Example conceptual schema:

```json
{
  "globalProfile": "default",
  "profiles": [
    {
      "id": "default",
      "name": "Default TV",
      "pointer": {
        "deadZone": 0.18,
        "gamma": 1.6,
        "maxSpeed": 1800,
        "precisionMultiplier": 0.35
      },
      "bindings": {
        "buttonSouth": "leftClick",
        "buttonEast": "rightClick",
        "leftThumbstickClick": "toggleSpiralKeyboard"
      },
      "keyboard": {
        "layout": "spiral",
        "theme": "arcadeSpiral",
        "inputMode": "live"
      }
    }
  ]
}
```

---

## Telemetry and Logging

V1 should keep telemetry minimal and local-first.

Recommended:
- local debug logs
- explicit opt-in for crash reporting
- no raw keystroke content logging
- no storage of typed text except explicit user settings export

Never log full text entered through the spiral keyboard.

---

## Security and Privacy

Because this app injects system input, it must be explicit and trustworthy.

Requirements:
- clear onboarding explaining why Accessibility permission is needed
- visible enabled/disabled state
- quick suspend action
- no hidden network dependency for core functionality
- local-only operation by default

---

## Performance Targets

### Idle
- negligible CPU use when controller disconnected
- low single-digit MB memory use beyond frameworks where practical

### Active pointer mode
- smooth cursor motion at 60 Hz
- no noticeable input lag on modern MacBook hardware

### Overlay open
- keyboard opens in under 150 ms target on warmed app state

---

## V1 Implementation Plan

### Milestone 1: Core controller + pointer
- menu bar app shell
- controller connect/disconnect
- left stick pointer movement
- A/B click mapping
- right stick scroll
- accessibility onboarding

### Milestone 2: Overlay infrastructure
- overlay windows
- radial command menu
- home/status HUD
- settings window

### Milestone 3: Spiral keyboard
- segmented ring renderer
- center hub actions
- D-pad navigation
- live typing mode
- buffered typing mode
- Arcade Spiral theme

### Milestone 4: Profiles and polish
- save/load profiles
- per-app mappings
- suspend rules
- diagnostics screen
- better generic controller support

---

## Example Pseudocode

```swift
final class ControllerRuntime {
    let controllerManager: ControllerManager
    let mapper: InputMapper
    let cursorEngine: CursorEngine
    let injector: EventInjector
    let overlays: OverlayManager

    func start() {
        PermissionManager.ensureAccessibilityPrompted()
        controllerManager.start()
    }

    func handle(_ event: ControllerEvent) {
        let actions = mapper.map(event)
        for action in actions {
            perform(action)
        }
    }

    func perform(_ action: SemanticAction) {
        switch action {
        case .movePointer(let dx, let dy):
            cursorEngine.apply(dx: dx, dy: dy)
        case .leftClick:
            injector.leftClick()
        case .rightClick:
            injector.rightClick()
        case .scroll(let dx, let dy):
            injector.scroll(dx: dx, dy: dy)
        case .toggleSpiralKeyboard:
            overlays.toggle(.spiralKeyboard)
        case .emitKey(let key):
            injector.keyPress(key)
        case .insertText(let text):
            injector.insertText(text)
        default:
            break
        }
    }
}
```

---

## Spiral Keyboard Interaction Example

### User flow: search for “netflix” on the couch

1. user clicks left stick
2. spiral keyboard opens centered on TV display
3. D-pad moves around Ring 1 and Ring 2
4. user selects `n`, `e`, `t`, `f`, `l`, `i`, `x`
5. text appears in the focused browser field in live mode
6. user selects `ENTER` from center hub or presses RB
7. keyboard closes automatically

### User flow: enter email address

1. long-press left stick
2. keyboard opens in email mode
3. center hub surfaces `@` and `.com`
4. user types using ring stepping
5. enter commits and closes

---

## Open Questions

These should be resolved during implementation:

1. Which macOS versions are required for launch?
2. Do we want analog-stick sector targeting in v1 or only D-pad stepping?
3. Should buffered text mode be default in browsers for reliability?
4. Do we want optional haptics / controller rumble where supported?
5. Should the overlay follow the display containing the pointer, or always stay on the TV display?
6. Do we need a fallback simple grid keyboard for accessibility and familiarity?
7. Should the app ship with browser-specific presets for Netflix, Max, YouTube, Plex, and Safari navigation?

---

## Recommendation

Build v1 as a native, direct-download macOS utility focused on controller-driven mouse, clicks, scroll, and a polished spiral keyboard. Treat the spiral keyboard as a flagship feature: highly visible, fast, playful, and unmistakably designed for couch use. Keep streaming-site automation minimal, but make browser navigation feel good enough that the utility meaningfully improves a Mac-on-TV setup.
