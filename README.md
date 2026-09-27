# TVSlider

[![CI](https://github.com/CreatureSurvive/TVSlider/actions/workflows/ci.yml/badge.svg)](https://github.com/CreatureSurvive/TVSlider/actions/workflows/ci.yml)
[![Swift 6.0+](https://img.shields.io/badge/Swift-6.0+-F05138?logo=swift&logoColor=white)](https://swift.org)
[![Platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20visionOS-blue)](#requirements)
[![Swift Package Manager](https://img.shields.io/badge/SwiftPM-compatible-brightgreen)](#installation)
[![License: MIT](https://img.shields.io/badge/license-MIT-lightgrey)](LICENSE)

`Slider` and `Stepper` for tvOS SwiftUI, which has neither, with one API that falls back to the
native controls on iOS, iPadOS, macOS and visionOS.

```swift
import TVSlider

TVSlider(value: $volume, in: 0...1) {
    Text("Volume")
} valueLabel: {
    Text(volume, format: .percent)
}

TVStepper("Subtitle Delay", value: $delay, in: -5...5, step: 0.5)
```

## Why

SwiftUI marks `Slider` and `Stepper` as unavailable on tvOS. Every Apple TV app with a settings
screen, audio or subtitle options, or a volume control ends up hand-building a focusable control.
It has to handle the focus engine, D-pad presses, the Siri Remote touch surface and accessibility,
and it's usually done slightly differently in each app.

## Features

- **Focus-native**: lifts and highlights when focused, dims when disabled, and doesn't trap
  up/down focus movement.
- **D-pad stepping with acceleration**: a single press moves one increment, and held or rapid
  presses speed up (1× → 2× → 4× → 8×). Reversing direction or pausing resets the speed.
- **Siri Remote touch-surface scrubbing**: horizontal swipes scrub continuously while the slider is
  focused, and vertical swipes still move focus.
- **Snapping** to `step`, anchored at the range's lower bound. A press always moves at least one
  step.
- `onEditingChanged` callbacks for pausing previews or committing values.
- **Accessibility**: adjustable action (VoiceOver swipe up/down), a combined label and value.
- **Cross-platform**: the same call site renders a native `Slider`/`Stepper` elsewhere.
- **`SliderModel`**: the pure value logic (clamping, snapping, acceleration, scrubbing), public and
  unit tested, for building custom controls such as a playback scrubber.
- **Styling** through `.tvSliderStyle(TVSliderStyle(...))`: track height, thumb size, focus scale,
  corner radius, padding. The track tint follows `.tint(_:)`.

## Installation

Add TVSlider to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/CreatureSurvive/TVSlider.git", from: "1.0.0"),
],
targets: [
    .target(name: "MyApp", dependencies: ["TVSlider"]),
]
```

Or in Xcode, choose **File › Add Package Dependencies…** and enter
`https://github.com/CreatureSurvive/TVSlider`.

### Requirements

| Platform | Minimum |
| --- | --- |
| iOS | 17.0 |
| macOS | 14.0 |
| tvOS | 17.0 |
| visionOS | 1.0 |

Swift 6.0 (Xcode 16) or later, in Swift 6 language mode. No third-party dependencies.

## Usage

```swift
TVSlider(value: $brightness, in: 0...100, step: 5, onEditingChanged: { editing in
    isAdjusting = editing
}) {
    Label("Brightness", systemImage: "sun.max")
} valueLabel: {
    Text("\(Int(brightness))")
}
.tint(.orange)
.tvSliderStyle({
    var style = TVSliderStyle()
    style.trackHeight = 14
    return style
}())
```

Custom controls can reuse the logic:

```swift
var model = SliderModel(range: 0...duration, step: 1)
model.accelerationCurve = [1, 2, 5, 10, 30]        // seconds per press for a seek bar
position = model.press(+1, from: position, at: ProcessInfo.processInfo.systemUptime)
```

## Testing

- `swift test` covers `SliderModel`: clamping, snapping, fractions, acceleration and its resets,
  and scrubbing.
- `Example/` contains a tvOS demo app and an XCUITest that drives it with `XCUIRemote`. It checks
  focus, D-pad stepping, clamping, snapping, the stepper and up/down focus movement on the tvOS
  simulator:

  ```sh
  cd Example && xcodegen generate
  xcodebuild test -project TVSliderDemo.xcodeproj -scheme TVSliderDemo \
    -destination "platform=tvOS Simulator,name=Apple TV 4K (3rd generation) (at 1080p)"
  ```

Touch-surface scrubbing uses a `UIPanGestureRecognizer` for indirect touches. The simulator's
remote can't generate those pans, so verify scrubbing on hardware.

## Changelog

See [CHANGELOG.md](CHANGELOG.md). Releases follow [Semantic Versioning](https://semver.org).

## Contributing

Issues and pull requests are welcome. Please run `swift test` before opening a pull request, and
add tests for new behavior.

## License

Available under the MIT license. See [LICENSE](LICENSE) for details.
