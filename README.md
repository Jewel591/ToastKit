# ToastKit

Transient, non-interactive, auto-dismissing in-app feedback for our Apple apps.
One shared implementation of the toast layer that MONO, CodeCat, and Filmo each
used to carry as copy-pasted source.

Public repository, internal audience: the API is deliberately narrow and the
visual design, placement, animation, and default duration are house-standard
constants baked into the kit. There is nothing to configure.

## Requirements

- iOS 17+ / macOS 14+
- Swift 6

## Installation

Add the package with an automatic compatible version range (`Up to Next Major
Version` in Xcode, `from:` in `Package.swift`):

```
https://github.com/Jewel591/ToastKit
```

## Usage

Install the presentation surface once, on the root view of the scene:

```swift
import ToastKit

WindowGroup {
    RootView()
        .toastHost()
}
```

Show feedback from anywhere on the main actor:

```swift
ToastCenter.shared.showSuccess(title: "Saved")
ToastCenter.shared.showError(title: "Export failed", subtitle: "Check storage space")

// Longer reading time for dense messages (default is 2 seconds):
ToastCenter.shared.show(
    title: "Session expired",
    subtitle: "Sign in again to keep syncing",
    style: .warning,
    duration: 10
)

// Icon is off by default; pass showsIcon when the style mark helps:
ToastCenter.shared.showWarning(
    title: "Free quota used up",
    subtitle: "Upgrade for unlimited use",
    showsIcon: true
)
```

`show(title:subtitle:style:duration:showsIcon:)` accepts both `String` and
`LocalizedStringResource`; localized text lives in the host's catalog — the kit
itself contains no user-visible strings.

## Design

- **Zero config.** Style (`success` / `error` / `warning` / `info`), colors,
  placement, animation, and the 2-second default duration are kit-level
  decisions. Hosts provide text and pick a semantic style. The only
  per-call extras are `duration` and `showsIcon` (default `false`).
- **Burst-safe.** At most three toasts are visible at once; when a fourth
  arrives, the oldest yields immediately. A batch operation failing item by
  item can never wallpaper the screen.
- **Renders above sheets (iOS).** Toasts live in a dedicated touch-transparent
  `UIWindow` above the alert level, one per `UIWindowScene` (iPad multi-window
  and Stage Manager safe), mirroring the host's effective color scheme. macOS
  has no competing modal window layer, so a plain overlay is used there.
- **Non-interactive by contract.** Every tap falls through to the app. Toasts
  are for feedback that requires no decision; anything needing action belongs
  in an alert or sheet.
- **Accessible.** Each toast posts a VoiceOver announcement; the transient
  visual alone would be missed entirely.
- **System-preset visuals.** Dynamic Type text styles and semantic colors —
  no hard-coded hex values or fixed point sizes. On iOS 26 and later, toast
  capsules use system Liquid Glass; earlier iOS versions and macOS retain the
  semantic system background.

## Testing

```sh
swift test
```

Tests cover queueing, style mapping, duration defaults, auto-dismissal,
cancellation on `dismissAll()`, and — per house discipline — that `show`
actually fires an Observation notification, not merely that the value is
correct.
