<div align="center">
  <img src="Prefs/Resources/icon@3x.png" width="88" alt="PullOver Pro icon">

  <h1>PullOver Pro</h1>
  <p><strong>Live app multitasking for jailbroken iPhones.</strong></p>
  <p>Open your favorite apps from the edge of the screen, even in landscape.</p>

  <a href="https://github.com/HuYang-s/pulloverpro/releases/tag/v3.0.3-codex13"><img alt="Release 3.0.3 codex13" src="https://img.shields.io/badge/release-3.0.3%7Ecodex13-blue"></a>
  <img alt="RootHide and Rootless" src="https://img.shields.io/badge/jailbreak-RootHide%20%7C%20Rootless-6759C8">
  <img alt="Target iOS 15 through 27" src="https://img.shields.io/badge/target-iOS%2015%E2%80%9327-333333">
  <a href="LICENSE"><img alt="GPL-3.0 license" src="https://img.shields.io/badge/license-GPL--3.0-green"></a>

  <p><strong>English</strong> · <a href="README.zh-CN.md">简体中文</a></p>
  <p><a href="#download">Download</a> · <a href="#features">Features</a> · <a href="#installation">Installation</a> · <a href="#building-from-source">Build</a> · <a href="CHANGELOG.md">Changelog</a></p>

  <img src="screenshots/promo.gif" width="320" alt="Original PullOver Pro live drawer demonstration">
  <p><sub>Upstream demonstration. Appearance and behavior may vary in the optimized build.</sub></p>
</div>

## What's new in 3.0.3~codex13

- Minimal drawer: no permanent top toolbar or bottom gesture status row. Long-press the open handle to reveal temporary tools.
- Experimental direct two-finger zoom and pan, stabilized with frozen gesture mapping and smoothing. Manual Adjust and optional release-only transforms remain available.
- Draggable floating ASCII keyboard with a separate app-scoped connection, automatic handshake and focus diagnostics. Direct input is limited to ChatGPT and JD; secure fields are excluded. Native system input with explicit copy and manual paste remains a fallback.
- RootHide installation and ChatGPT keyboard handshake/focus detection were observed on iPhone 14 Pro, iOS 17.0. Character delivery, rapid typing, landscape behavior and JD compatibility remain to be validated.

The local notification session identifiers correlate messages; they are not authentication. No global touch interception or background key capture is intended. See [CHANGELOG.md](CHANGELOG.md) for earlier versions.

## Overview

PullOver Pro is a SpringBoard tweak that hosts a live application interface in a drawer over your current screen. Tap or swipe the edge handle to access a pinned app, or long-press it to choose another app with QuickSwitch.

This fork of [Jond-ie/pulloverpro](https://github.com/Jond-ie/pulloverpro) focuses on landscape multitasking, scene lifecycle reliability, gesture handling and native RootHide compatibility. Typical use cases include looking up information, reading messages or using ChatGPT while another app is on screen.

## Download

**Current release: [v3.0.3-codex13](https://github.com/HuYang-s/pulloverpro/releases/tag/v3.0.3-codex13) (pre-release).**

| Jailbreak environment | Package architecture | Download |
| --- | --- | --- |
| Dopamine RootHide / compatible RootHide environments | `iphoneos-arm64e` | [**RootHide DEB**](https://github.com/HuYang-s/pulloverpro/releases/download/v3.0.3-codex13/PullOverPro-3.0.3-codex13-roothide.deb) |
| Ordinary Rootless jailbreak | `iphoneos-arm64` | [**Rootless DEB**](https://github.com/HuYang-s/pulloverpro/releases/download/v3.0.3-codex13/PullOverPro-3.0.3-codex13-rootless.deb) |

Both packages contain arm64 and arm64e Mach-O slices and share the package identifier `com.johndie.pulloverpro-rootless`. Install only the package matching your jailbreak.

Release resources: [Source ZIP](https://github.com/HuYang-s/pulloverpro/releases/download/v3.0.3-codex13/PullOverPro-3.0.3-codex13-source.zip) · [Chinese installation guide](https://github.com/HuYang-s/pulloverpro/releases/download/v3.0.3-codex13/INSTALL-ZH.md) · [Build validation](https://github.com/HuYang-s/pulloverpro/releases/download/v3.0.3-codex13/BUILD-VALIDATION.txt) · [SHA-256 checksums](https://github.com/HuYang-s/pulloverpro/releases/download/v3.0.3-codex13/SHA256SUMS.txt).

## Features

| Feature | Description |
| --- | --- |
| Live app drawer | Access a pinned app using the movable edge handle. |
| QuickSwitch | Pick recent or favorite apps, or drag a selection toward the center to launch it full screen. |
| Compact landscape layout | A compact side drawer with an optional wider input mode. |
| Two-finger view control | Pinch the hosted app from 0.5× to 3.0× and drag with two fingers to reposition it. Zooming and panning work together. |
| Landscape touch-through | Enabled by default for fresh preferences; routes touches outside the drawer, controls and handle to the underlying app. |
| Personalization | Left-handed mode, dark handle, haptics, QuickSwitch sizing and automatic handle shrinking. |
| Lifecycle handling | Closes or clears hosting on lock and selected system transitions; settings reload without a respring. |

<div align="center">
  <img src="screenshots/over.png" width="30%" alt="Original live app drawer screenshot">
  <img src="screenshots/quickswitch.png" width="30%" alt="Original QuickSwitch screenshot">
  <img src="screenshots/settings.png" width="30%" alt="Original preferences screenshot">
  <p><sub>Upstream screenshots: drawer, QuickSwitch and preferences.</sub></p>
</div>

## Installation

Requirements: a compatible jailbroken iPhone, a substrate-compatible injection layer (`mobilesubstrate`), [AltList](https://github.com/opa334/AltList) and PreferenceLoader for the Settings page.

1. Download the matching DEB from the [release page](https://github.com/HuYang-s/pulloverpro/releases/tag/v3.0.3-codex13).
2. Open it in a compatible package manager, such as Sileo, and resolve any missing dependencies.
3. Install or upgrade the package and respring.
4. Open **Settings → PullOver Pro** and enable **启用插件**.

### Using it in landscape

1. Turn **横屏时隐藏插件** (Hide in Landscape) off, especially when upgrading from an older version.
2. In **快速切换**, choose **收藏应用** and add the desired apps in **收藏应用**.
3. Tap or pull the handle to open the pinned app. While open, long-press the handle to show tools, then tap **切换应用** and select an app.
4. Enable **横屏触摸穿透** (Landscape Touch Through) if an older saved setting disabled it. Use the handle to close the drawer.
5. Long-press the open handle, tap **键盘**, and focus a normal input field. Drag the keyboard header to move it. **系统输入** opens the native composer fallback. **放大** enlarges the scene in landscape.
6. Try direct two-finger zoom/pan in ChatGPT or JD. If needed, use **调整** and **完成** for manual editing; **复位** resets the transform.

The layout is designed for landscape use. Simultaneous input in two apps, keyboard focus and game background behavior still depend on iOS and the apps involved.

## Compatibility and testing

| Check | Codex 13 status |
| --- | --- |
| Declared firmware range | iOS 15.0 to below 28.0; not a tested matrix |
| RootHide and Rootless release builds | Passed |
| Host-side regression tests and package checks | Passed |
| iPhone 14 Pro / iOS 17.0 / RootHide installation | Confirmed |
| Minimal drawer, floating keyboard display, ChatGPT handshake and focus detection | Observed on device |
| Direct character delivery, rapid typing, landscape behavior, JD | Pending |
| FPS, memory and battery | Not benchmarked |

The firmware range describes the package's declared target, rather than a tested compatibility matrix. The tweak uses private iOS APIs, whose availability and behavior can vary by system version. Static validation cannot guarantee device loading or stability.

## Building from source

Requires a working [Theos](https://theos.dev/) installation, an iPhoneOS SDK, Clang and ldid. The minimum deployment target is iOS 15.0.

```sh
git clone https://github.com/HuYang-s/pulloverpro.git
cd pulloverpro
```

### Rootless

Set `THEOS` to your standard Theos installation and run:

```sh
make clean THEOS_PACKAGE_SCHEME=rootless
make package THEOS_PACKAGE_SCHEME=rootless FINALPACKAGE=1 DEBUG=0
```

### RootHide

Set `THEOS` to the [RootHide fork of Theos](https://github.com/roothide/theos), with its recursive submodules initialized, and run:

```sh
make clean THEOS_PACKAGE_SCHEME=roothide
make package THEOS_PACKAGE_SCHEME=roothide FINALPACKAGE=1 DEBUG=0
```

If the SDK lacks the private Preferences framework linker stub, provide a compatible framework directory with `ADDITIONAL_LDFLAGS="-F/path/to/frameworks"` on the package command. The stub is only required at build time.

The resulting DEB is written to `packages/`. For reproducibility, see the [release build report](https://github.com/HuYang-s/pulloverpro/releases/download/v3.0.3-codex13/BUILD-VALIDATION.txt).

### Project structure

| Path | Responsibility |
| --- | --- |
| [Tweak/](Tweak/) | SpringBoard hooks, app hosting, drawer UI and QuickSwitch |
| [Prefs/](Prefs/) | Settings bundle and configuration UI |
| [GestureClient/](GestureClient/) | App-scoped gesture and keyboard client |
| [tests/](tests/) | Host regression tests |
| [Shared/](Shared/) | Shared preference identifiers and jailbreak-aware paths |
| [layout/](layout/) | Packaged resources and PreferenceLoader registration |
| [control](control) | Debian package metadata and dependencies |

## Troubleshooting

- **Handle missing:** unlock the device, confirm the tweak is enabled, check Hide in Landscape, and respring if needed.
- **Settings page missing:** check PreferenceLoader and AltList installation for your jailbreak.
- **App fails to load:** close the drawer and try another app. Some applications or iOS versions may be incompatible with scene hosting.
- **Game input or keyboard behaves unexpectedly:** disable Landscape Touch Through, close the drawer and retest.
- **SpringBoard instability:** disable or uninstall the tweak using your jailbreak's recovery facilities, then respring.

Contributions and reproducible test reports are welcome. Include the device model, iOS version, jailbreak, package version, steps to reproduce and relevant crash logs with personal information removed.

## Credits and license

This project is a fork released under the [GNU General Public License v3.0](LICENSE).

- [c1d3r / Will Smillie](https://github.com/c1d3rdev/PullOver-Pro) — original PullOver Pro.
- [akusio_RR](https://x.com/akusio_RR) — iOS 13 support.
- [Jond-ie](https://github.com/Jond-ie/pulloverpro) — modern iOS port and upstream maintenance.
- [HuYang-s](https://github.com/HuYang-s) — optimized fork.
