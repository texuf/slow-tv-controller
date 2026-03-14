# SlowTV Controller

A macOS menu bar app that maps a DualSense (PS5) controller to desktop input — pointer movement, clicks, scrolling, and key presses.

## Requirements

- macOS 15+
- Xcode Command Line Tools with Swift 6

## Build & Run

```
./build.sh
open build/SlowTVController.app
```

On first launch, grant Accessibility permission in System Settings > Privacy & Security > Accessibility.

## Controls

| Button | Action |
|---|---|
| Right stick | Move cursor |
| Left stick | Scroll |
| Cross (A) | Left click |
| Circle (B) | Browser back |
| D-pad | Arrow keys |
| L1 | Escape |
| R1 | Enter |
| L2 | Precision mode |
| R2 | Click-and-drag |
| Start + Circle | Kill switch (5s disable) |
