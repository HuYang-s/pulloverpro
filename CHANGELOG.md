# Changelog

## 3.0.2~codex4

- Add a tappable, scrollable app-switching menu while the drawer is open, accessible from its toolbar or the handle.
- Keep the current foreground app in place when selected from the open drawer, and avoid duplicate scene teardown when switching hosted apps.
- Add a reversible landscape input zoom mode, with a wider drawer and width-based scaling anchored to the bottom of the hosted scene.
- Enable landscape touch-through by default for fresh preferences, preserve saved preferences, and remove the dimming overlay when touch-through is enabled.
- Device touch routing and embedded/system keyboard behavior require on-device verification.

## 3.0.2~codex3

- Translate plugin-owned settings, QuickSwitch instructions, and hosting failure messages into Simplified Chinese while preserving stored preference keys and values.
- Increase the compact handle from 10 to 30 pt of visible width and expand its nominal touch area to 44 × 52 pt.
- Keep the handle visible at 55% opacity when dimming is enabled, with full opacity while the drawer opens.
- Allow direct tap and long press while compact, reduce animation duration, and defer automatic collapse during active interaction.
- Make the dimming setting available without a Triggr add-on.
- RootHide and Rootless builds passed; on-device interaction testing remains pending.

## 3.0.2~codex2 (local optimized build)

- Enable landscape by default for new preferences, with a compact side panel and optional touch-through outside the panel. Preserve saved preferences.
- Respect safe-area insets and preserve drawer progress across size changes. Prevent drawer panning from starting inside the hosted content.
- Validate private API availability and scene/presenter lifecycle. Bound launch retries and invalidate stale asynchronous callbacks. Restore foreground state only when changed by the tweak.
- Harden QuickSwitch bounds, reuse, deduplication, scrolling, and drag cleanup.
- Debounce preference changes, normalize saved settings, cache icons, and close hosting for system overlays and locking.
- Build Rootless and native RootHide variants using their respective Theos schemes and path APIs.
- Device-level performance, keyboard, scene orientation, and touch routing still require testing on iOS 17.

## 3.0.1

- **Fixed:** on some phones the handle never appeared after a respring until the phone was locked and unlocked again. PullOver Pro now checks whether the phone is unlocked as it starts, not only when that changes. Reported on an iPhone 13 Pro on iOS 17 ([#1](https://github.com/Jond-ie/pulloverpro/issues/1)).

## 3.0.0

Out of beta. For iOS 15 to 27 on Rootless and RootHide jailbreaks.

- **Closes for Control Center and Notification Center:** the pulled-over app closes as soon as either starts coming down.
- **Slider values** are no longer cut off on iOS 16.
- **Help & Support** rows in settings: report a problem, contact, donate.

## 3.0.0 Beta 1

- c1d3r's PullOver Pro, updated for iOS 15 to 27 on Rootless and RootHide jailbreaks.
