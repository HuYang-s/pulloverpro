<div align="center">
  <img src="Prefs/Resources/icon@3x.png" width="88" alt="PullOver Pro 图标">

  <h1>PullOver Pro</h1>
  <p><strong>面向越狱 iPhone 的实时应用侧边浮窗插件</strong></p>
  <p>通过屏幕边缘手柄访问常用应用，支持横屏多任务场景。</p>

  <a href="https://github.com/HuYang-s/pulloverpro/releases/tag/v3.0.3-codex13"><img alt="版本 3.0.3 codex13" src="https://img.shields.io/badge/release-3.0.3%7Ecodex13-blue"></a>
  <img alt="RootHide 与 Rootless" src="https://img.shields.io/badge/jailbreak-RootHide%20%7C%20Rootless-6759C8">
  <img alt="目标系统 iOS 15 至 27" src="https://img.shields.io/badge/target-iOS%2015%E2%80%9327-333333">
  <a href="LICENSE"><img alt="GPL-3.0 许可证" src="https://img.shields.io/badge/license-GPL--3.0-green"></a>

  <p><a href="README.md">English</a> · <strong>简体中文</strong></p>
  <p><a href="#下载安装包">下载</a> · <a href="#主要功能">功能</a> · <a href="#安装与使用">使用</a> · <a href="#源码编译">编译</a> · <a href="CHANGELOG.md">更新日志</a></p>

  <img src="screenshots/promo.gif" width="320" alt="原版 PullOver Pro 浮窗演示">
  <p><sub>演示来自上游项目，优化版的具体显示与操作可能有所不同。</sub></p>
</div>

## 3.0.3~codex13 更新亮点

- 极简浮窗：默认隐藏顶部菜单和底部手势状态条，展开后长按手柄显示临时工具。
- 实验性直接双指缩放与平移，加入固定坐标映射、平滑滤波；保留手动调整和松手应用备用模式。
- 独立可拖动的浮动英文键盘，采用单独连接、自动握手及输入框焦点诊断。目前仅配置 ChatGPT 和京东，排除安全输入框；中文可通过系统输入、主动复制并手动粘贴。
- 已在 iPhone 14 Pro、iOS 17.0、RootHide 上确认安装、ChatGPT 键盘握手和焦点识别。实际字符写入、连续打字、横屏体验及京东兼容性仍待验证。

本机通知会话标识仅用于关联消息，不构成身份认证。不进行全局触摸拦截或后台按键采集。历史改动见 [CHANGELOG.md](CHANGELOG.md)。

## 项目简介

PullOver Pro 通过 SpringBoard 和 iOS Scene 私有接口，将应用的实时界面托管到侧边抽屉中。用户可以点击或滑动边缘手柄打开固定应用，也可以长按手柄进入 QuickSwitch，快速选择其他应用。

本项目基于 [Jond-ie/pulloverpro](https://github.com/Jond-ie/pulloverpro) 进行优化，重点改善横屏使用体验、应用托管生命周期、手势交互和 RootHide 原生适配。适合在使用其他应用时临时查资料、阅读消息或打开 ChatGPT 等场景。

## 下载安装包

**当前版本：[v3.0.3-codex13](https://github.com/HuYang-s/pulloverpro/releases/tag/v3.0.3-codex13)（预发布版）。**

| 越狱环境 | 软件包架构 | 下载 |
| --- | --- | --- |
| Dopamine RootHide 等兼容 RootHide 环境 | `iphoneos-arm64e` | [**RootHide 原生 DEB**](https://github.com/HuYang-s/pulloverpro/releases/download/v3.0.3-codex13/PullOverPro-3.0.3-codex13-roothide.deb) |
| 普通 Rootless 无根越狱 | `iphoneos-arm64` | [**Rootless DEB**](https://github.com/HuYang-s/pulloverpro/releases/download/v3.0.3-codex13/PullOverPro-3.0.3-codex13-rootless.deb) |

两个安装包内均包含 arm64 和 arm64e 二进制切片，软件包标识均为 `com.johndie.pulloverpro-rootless`。根据越狱环境选择其中一个版本安装即可。

其他发布文件：[完整源码](https://github.com/HuYang-s/pulloverpro/releases/download/v3.0.3-codex13/PullOverPro-3.0.3-codex13-source.zip) · [中文使用说明](https://github.com/HuYang-s/pulloverpro/releases/download/v3.0.3-codex13/INSTALL-ZH.md) · [构建验证报告](https://github.com/HuYang-s/pulloverpro/releases/download/v3.0.3-codex13/BUILD-VALIDATION.txt) · [SHA-256 校验值](https://github.com/HuYang-s/pulloverpro/releases/download/v3.0.3-codex13/SHA256SUMS.txt)。

## 主要功能

| 功能 | 说明 |
| --- | --- |
| 实时应用浮窗 | 通过可移动的边缘手柄访问固定应用。 |
| QuickSwitch 快速切换 | 支持最近应用和收藏应用，也可拖动应用至屏幕中央全屏打开。 |
| 横屏紧凑布局 | 横屏采用紧凑侧栏，并可切换到更宽的输入模式。 |
| 双指缩放与移动 | 双指捏合可将应用画面缩放至 0.5×–3.0×，双指移动可调整画面位置，两种操作可同时进行。 |
| 横屏触摸穿透 | 新设置默认开启，浮窗、工具栏及手柄之外的区域尝试向底层应用传递触摸。 |
| 个性化设置 | 支持左手模式、深色手柄、触觉反馈、菜单缩放和自动缩小手柄。 |
| 生命周期管理 | 锁屏及部分系统界面切换时清理托管状态，设置修改无需 Respring。 |

<div align="center">
  <img src="screenshots/over.png" width="30%" alt="原版实时浮窗">
  <img src="screenshots/quickswitch.png" width="30%" alt="原版 QuickSwitch">
  <img src="screenshots/settings.png" width="30%" alt="原版设置界面">
  <p><sub>上游项目截图：实时浮窗、快速切换和设置页面。</sub></p>
</div>

## 安装与使用

### 安装步骤

运行环境需要兼容的越狱 iPhone、Substrate 兼容注入层（`mobilesubstrate`）和 [AltList](https://github.com/opa334/AltList)。设置页面还需要 PreferenceLoader。

1. 在 [Release 页面](https://github.com/HuYang-s/pulloverpro/releases/tag/v3.0.3-codex13) 下载对应的 DEB。
2. 使用 Sileo 等兼容包管理器打开，确认依赖正常后安装或升级。
3. 执行 Respring（重启 SpringBoard）。
4. 进入 **设置 → PullOver Pro**，开启“启用插件”。

### 横屏游戏推荐设置

| 设置项 | 推荐配置 |
| --- | --- |
| 启用插件 | 开启插件 |
| 横屏时隐藏插件 | 关闭横屏隐藏 |
| 快速切换 | 选择收藏应用 |
| 收藏应用 | 添加 ChatGPT、京东等常用应用 |
| 横屏触摸穿透 | 开启（旧版已保存的关闭值需手动开启） |
| 闲置时自动收起 | 可选，闲置时缩小手柄 |
| 自动收起延时（秒） | 默认 5 秒 |

点击或向屏幕内拉动手柄打开浮窗。展开后长按手柄显示工具，点击「切换应用」选择应用，点击「键盘」打开独立浮动键盘。先聚焦普通输入框，再尝试按键；拖动键盘顶部移动位置。「系统输入」提供原生输入、复制并手动粘贴的备用方案。「放大」用于横屏扩大场景。

ChatGPT 和京东可尝试直接双指缩放和平移，其他应用的触摸传递取决于 iOS。需要时长按手柄进入「调整」，完成后点「完成」；「复位」恢复画面。

## 兼容性与验证状态

| 验证项目 | Codex 13 状态 |
| --- | --- |
| 软件包声明系统范围 | iOS 15.0 至低于 28.0，非实测兼容矩阵 |
| RootHide / Rootless Release 编译 | 已通过 |
| 主机回归测试与安装包检查 | 已通过 |
| iPhone 14 Pro / iOS 17.0 / RootHide 安装 | 已确认 |
| 极简浮窗、浮动键盘显示、ChatGPT 握手与焦点识别 | 真机已观察 |
| 实际字符写入、连续打字、横屏、京东 | 待验证 |
| 帧率、内存、耗电 | 暂无基准测试 |

系统范围为软件包的声明目标，实际兼容性仍受私有接口和越狱环境影响。编译及安装成功不代表所有功能已经通过真机验证。

## 源码编译

需要 [Theos](https://theos.dev/)、iPhoneOS SDK、Clang 和 ldid。最低编译部署目标为 iOS 15.0。

```sh
git clone https://github.com/HuYang-s/pulloverpro.git
cd pulloverpro
```

### 普通 Rootless

将 `THEOS` 指向普通 Theos 安装目录：

```sh
make clean THEOS_PACKAGE_SCHEME=rootless
make package THEOS_PACKAGE_SCHEME=rootless FINALPACKAGE=1 DEBUG=0
```

### 原生 RootHide

将 `THEOS` 指向 [RootHide Theos](https://github.com/roothide/theos) 安装目录，并初始化其递归子模块：

```sh
make clean THEOS_PACKAGE_SCHEME=roothide
make package THEOS_PACKAGE_SCHEME=roothide FINALPACKAGE=1 DEBUG=0
```

如果所选 SDK 缺少 Preferences 私有框架的链接描述文件，可在打包命令中增加 `ADDITIONAL_LDFLAGS="-F/path/to/frameworks"`，指定兼容的框架目录。该描述文件仅在构建时使用。

编译完成的 DEB 位于 `packages/`。工具链与构建验证细节见 [构建报告](https://github.com/HuYang-s/pulloverpro/releases/download/v3.0.3-codex13/BUILD-VALIDATION.txt)。

### 项目结构

| 目录或文件 | 作用 |
| --- | --- |
| [Tweak/](Tweak/) | SpringBoard 注入、应用托管、浮窗界面及 QuickSwitch |
| [Prefs/](Prefs/) | 系统设置页面和配置交互 |
| [GestureClient/](GestureClient/) | 应用端手势及键盘模块 |
| [tests/](tests/) | 主机回归测试 |
| [Shared/](Shared/) | 共享配置标识和越狱路径适配 |
| [layout/](layout/) | 打包资源及 PreferenceLoader 注册 |
| [control](control) | 软件包信息与依赖声明 |

## 常见问题

- **手柄不显示：**解锁手机，确认“启用插件”已开启、横屏隐藏已关闭，必要时重新 Respring。
- **没有设置入口：**检查适配当前越狱环境的 PreferenceLoader 和 AltList。
- **应用无法加载：**关闭浮窗并尝试其他应用，部分应用或系统版本可能不支持当前 Scene 托管方式。
- **游戏操作或键盘异常：**关闭“横屏触摸穿透” 后重新测试。
- **SpringBoard 异常：**使用越狱环境的恢复功能禁用或卸载插件，再重新 Respring。

欢迎贡献代码或提供可复现的测试反馈。反馈时请注明设备型号、iOS 版本、越狱环境、插件版本、复现步骤，并移除崩溃日志中的个人信息。

## 致谢与许可证

本项目遵循 [GPL-3.0 开源许可证](LICENSE)。

- [c1d3r / Will Smillie](https://github.com/c1d3rdev/PullOver-Pro)：原始 PullOver Pro。
- [akusio_RR](https://x.com/akusio_RR)：iOS 13 支持。
- [Jond-ie](https://github.com/Jond-ie/pulloverpro)：现代 iOS 移植及上游维护。
- [HuYang-s](https://github.com/HuYang-s)：本优化分支。
