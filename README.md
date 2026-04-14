# Interval Timer

<img src="ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png" width="128" alt="Interval Timer icon">

A minimal, distraction-free interval timer built for the gym. Designed to be visible from across the room with full-screen color states and oversized typography.

## Features

- **Full-screen color states** — green for GO, red for REST, amber for GET READY, blue for DONE
- **Large typography** — 180pt timer, readable from a distance (1.5x on iPad)
- **Configurable** — work/rest intervals (15s-2m), rounds (5-25)
- **Sound** — generated sine-wave beeps for phase transitions (toggle on/off)
- **Haptic feedback** — on transitions and last 3 seconds
- **Screen wake lock** — stays on during workouts
- **Tap to pause/resume**
- **Landscape only** — optimized for propping up at the gym

## Platforms

- iPhone
- iPad
- macOS

## Screenshots

| Setup | GET READY |
|-------|-----------|
| ![Setup](appstore_screenshots/iphone_6.7_setup.png?v=2) | ![Get Ready](appstore_screenshots/iphone_6.7_ready.png?v=2) |

| GO | REST |
|----|------|
| ![GO](appstore_screenshots/iphone_6.7_go.png?v=2) | ![REST](appstore_screenshots/iphone_6.7_rest.png?v=2) |

| DONE |
|------|
| ![DONE](appstore_screenshots/iphone_6.7_done.png?v=2) |

## Building

```bash
flutter pub get
flutter run
```

### iOS / TestFlight

See [Apple.md](Apple.md) for step-by-step TestFlight deployment instructions.

## Design

The app icon uses a Bauhaus-inspired geometric design — a green/red donut chart with a clock hand, reflecting the work/rest interval concept.

## Support

If you find this useful, [buy me a coffee](https://buymeacoffee.com/twitzelbos).

## License

MIT
