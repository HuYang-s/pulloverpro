# Changelog

## 3.0.3~codex13

- Separate explicit floating keyboard sessions from gesture recognition, with a 32-bit per-open lease, 500 ms focus/status probes, bounded timeout and automatic re-handshake. No background key capture or global input injection.
- Resolve first responders in hosted normal windows before responder-chain fallback; distinguish no focus, unsupported input, secure input, timeout, busy and acknowledged input. Never read input text or write to secure fields. Remove obsolete keyboard v2 channel.
- Close the keyboard lease on drawer closure, app switching, or manual adjustment. Retain minimal layout and native composer fallback. Device acceptance pending.

## 3.0.3~codex12

- Full-height content: hide toolbar and bottom gesture status by default. Long-press the open drawer handle to toggle temporary tools; manual adjustment still exposes controls. No permanent reserved rows.
- Add a compact draggable floating ASCII keyboard independent of scene scale. Explicit key buttons deliver a single acknowledged character or delete to a focused non-secure UIKeyInput in the supported hosted app, only during an active session; no return/send or global key capture. Existing native composer remains an explicit clipboard fallback for IME. Chinese direct input is not implemented; app responder compatibility needs device validation.

## 3.0.3~codex11.1

- Fix device-observed composer overlap: anchor the input panel to the top safe area and pass outside touches through the composer window. Keep keyboard region unobstructed.

## 3.0.3~codex11

- Add a separate native UIKit keyboard composer window in SpringBoard, outside the scaled app scene. Available via 大键盘 in portrait and landscape. Supports system IME and multiline editing. Explicit Copy and Return places text on the local pasteboard for 120 seconds; paste manually into the target app. No automatic message submission or background clipboard reading.
- Keep the original landscape input zoom as 放大 and suspend direct transform gestures while composing. Dismiss the composer on drawer closure and teardown.
- Device keyboard visibility and landscape behavior require acceptance testing.

## 3.0.3~codex10

- Freeze the coordinate mapping during each remote gesture; do not multiply a delayed UIKit sample by the latest host output. Publish geometry only between remote gestures.
- Deduplicate IPC events, limit samples to 30 Hz, filter logarithmic scale and translation with time-based deadbands and slew limits, and update center/scale without implicit animations. End events retain the last filtered live state.
- Add optional release-only transform mode (off by default) to avoid visual feedback while fingers are down. Manual adjustment and local gesture bar remain unchanged. Device jitter validation pending.

## 3.0.3~codex9 (local experimental build)

- Add a narrowly filtered app-side gesture companion for ChatGPT and JD. Recognize two-finger transforms only during an active hosted session, using a local state channel that carries bounded transform parameters, not raw touches or text. No global HID interception or input injection.
- Use a per-session token and heartbeat; stop on layout, manual edit, host closure or lease expiry. Preserve Codex 7/8 manual and grip controls. Other apps retain the previous best-effort direct path.
- Device verification of app injection, local notification permission and coordinates remains required.

## 3.0.3~codex8 (local development)

- Add an opt-out experimental direct two-finger recognizer on the hosted presentation view, using a stable coordinate space. Delivery of remote-scene touches remains device dependent.
- Add an always-ready local gesture bar with pinch, two-finger translation, single-finger drag and scale feedback. No edit-mode button required. Reserve a separate row to avoid covering app content.
- Preserve proven manual edit mode. Scope touches to the host or local controls; arbitrate concurrent transforms and cancel on layout/teardown. No global touch interception or event injection.

## 3.0.3~codex7 (local development)

- Move transforms to an explicit SpringBoard-owned editing surface above the hosted application; bypass dependence on remote UIKit gesture delivery.
- Enter Adjust, pinch/pan (or drag with one finger), then Done to return input to the app. Add +/- zoom fallback and percentage feedback. Restore host interaction on exit or teardown.
- Include edit surface in landscape touch routing while preserving outside pass-through. Device verification required.

## 3.0.3~codex6 (local development build)

- Separate two-finger gesture recognition and testable transform math from the view controller; recognize intentional motion only, and fail early on ordinary single-finger dragging.
- Add toolbar controls for enabling native app gestures instead of overlay gestures, and resetting zoom and position.
- Keep smaller content inside the viewport and larger content covering it; preserve normalized offsets across layout changes and remember up to 32 per-app transforms during the controller lifetime.
- Add host-side geometry regression tests. Cross-process touch delivery and keyboard behavior still require real-device verification.

## 3.0.3~codex5

- Add a two-finger transform gesture for the hosted app. Pinch to zoom from 0.5× to 3.0× and move both fingers to pan, including combined zoom-and-pan in one gesture.
- Keep single-finger interaction available to the hosted app. The overlay transform is applied to the hosted scene and retained when the drawer is closed or the device rotates. Selecting a different app resets its transform.
- Clamp panning so at least a small part of the hosted scene remains reachable, and pass unused landscape drawer space through to the app underneath when touch-through is enabled.
- Two-finger routing, app-specific gesture interaction and game touch-through still require on-device verification.

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
