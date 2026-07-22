# 02_PORTING_MAP.md

# Scrcpy-iOS Porting Mapping Specification

Version 1.0

---

# 1. Purpose

本文档用于定义：

**官方 Genymobile scrcpy → iOS 12.5.7 越狱环境**

的源码移植策略。

目标：

* 保留官方核心逻辑。
* 明确每个模块的修改范围。
* 避免 AI 或开发者随意重构。
* 保证未来可以同步官方 scrcpy 更新。

---

# 2. Porting Strategy

每个源码模块分为三种处理方式：

---

## Type A：Keep

定义：

> 完全保留官方实现。

原因：

该模块与平台无关。

例如：

* 协议
* 数据结构
* ADB 调用逻辑

---

## Type B：Adapt

定义：

> 保留接口，替换平台相关实现。

例如：

官方：

```text
SDL Renderer
```

替换：

```text
OpenGL ES Renderer
```

---

## Type C：Replace

定义：

> iOS 无对应环境，需要重新实现。

例如：

官方：

```text
SDL Window
```

替换：

```text
UIKit Window
```

---

# 3. Official Scrcpy Main Structure Mapping

官方结构：

```text
scrcpy/

├── app/
├── server/
├── libavcodec/
├── app/src/
├── common/
├── control/
├── video/
├── audio/
├── adb/
├── util/
└── build/
```

iOS Port：

```text
scrcpy-ios/

├── core/
│
│   ├── adb/
│   ├── control/
│   ├── video/
│   ├── demuxer/
│   ├── common/
│   └── util/
│
├── platform/
│
│   └── ios/
│
│       ├── UIKit/
│       ├── Renderer/
│       ├── Decoder/
│       ├── Input/
│       ├── Network/
│       └── Theos/
│
└── resources/
```

---

# 4. Module Mapping

---

# 4.1 ADB Module

## Official

功能：

负责：

* adb server communication
* device detection
* connection

---

## Decision

类型：

```
Type A + Minor Adapt
```

---

## 保留

保留：

* adb command execution
* device listing
* socket communication

---

## 修改

原因：

桌面系统：

```text
fork()
exec()
```

iOS：

限制较多。

需要：

替换进程启动方式。

---

## iOS 实现

目录：

```text
platform/ios/adb/
```

负责：

* adb binary integration
* process launch
* socket forwarding

---

## API 保持

例如：

```c
adb_connect()

adb_disconnect()

adb_execute()

adb_get_devices()
```

不要修改上层调用。

---

# 4.2 Control Module

## Official

负责：

发送：

* touch
* keyboard
* clipboard
* command

---

## Decision

类型：

```
Type A
```

---

原因：

Control Message 是 scrcpy 核心协议。

与平台无关。

---

## 保留：

```text
control_msg.c
control_msg.h
```

---

## iOS Input:

新增：

```text
platform/ios/input/
```

负责：

转换：

```
UITouch

↓

Control Message

↓

Android
```

---

# 4.3 Video Module

## Official

负责：

视频流：

```
H264

↓

Packet

↓

Frame
```

---

## Decision

类型：

```
Type A + Type B
```

---

保留：

* packet structure
* demuxer

---

替换：

Decoder。

---

# 4.4 Demuxer

## Decision

```
Type A
```

---

原因：

Demuxer 只负责：

* 读取 packet
* 分离 stream

不依赖：

* SDL
* Window
* GPU

---

保持：

```
Packet

↓

Decoder
```

---

# 4.5 Decoder Module

## Official

桌面：

```
FFmpeg
```

---

## Decision

类型：

```
Type C
```

---

原因：

iOS 已有：

```
VideoToolbox
```

硬件解码。

---

## 新结构

```text
decoder/

├── decoder_interface.h

├── ffmpeg_decoder.c

└── ios/

    └── videotoolbox_decoder.mm
```

---

接口：

保持：

```c
decoder_open()

decoder_decode()

decoder_close()
```

---

内部：

替换：

FFmpeg

↓

VideoToolbox

---

# 4.6 Renderer Module

## Official

依赖：

```
SDL Renderer
```

---

## Decision

类型：

```
Type C
```

---

原因：

SDL Window 不存在。

---

新结构：

```text
platform/ios/renderer/
```

---

使用：

```
OpenGL ES 2.0
```

---

流程：

```
CVPixelBuffer

↓

CVOpenGLESTextureCache

↓

OpenGL Texture

↓

UIView
```

---

# 4.7 Window Module

## Official

SDL Window

---

## Decision

类型：

```
Replace
```

---

iOS:

```
UIWindow

↓

UIViewController

↓

GLKView
```

---

负责：

* 生命周期
* 屏幕旋转
* 全屏

---

# 4.8 Input Module

## Official

输入：

```
SDL Event
```

---

## Decision

类型：

```
Replace
```

---

iOS:

```
UITouch

UIGestureRecognizer

```

---

支持：

V1:

* tap
* long press
* swipe

---

# 4.9 Options Module

## Decision

```
Type A
```

---

保留：

例如：

```
--max-size

--bit-rate

--max-fps
```

---

新增：

iOS UI:

映射：

```
Settings

↓

Options
```

---

# 4.10 Audio Module

## Decision

V1:

```
Disabled
```

---

原因：

增加：

* AudioUnit
* AAC decode
* sync

复杂度。

---

预留：

```
platform/ios/audio/
```

---

# 5. Dependency Mapping

| Official            | iOS Replacement              |
| ------------------- | ---------------------------- |
| SDL2                | UIKit                        |
| SDL Window          | UIWindow                     |
| SDL Event           | UITouch                      |
| SDL Renderer        | OpenGL ES                    |
| FFmpeg Decoder      | VideoToolbox                 |
| pthread             | pthread / NSThread           |
| Desktop File System | iOS Sandbox / Jailbreak Path |
| CMake               | Theos Makefile               |

---

# 6. Third Party Libraries

---

## FFmpeg

用途：

官方：

* Decoder
* Demux

iOS：

V1：

不用于视频解码。

保留：

可能用于：

* NAL parsing
* future audio

---

## SDL2

状态：

删除。

原因：

SDL 在 iOS 可编译，但：

* 依赖过多
* 不符合越狱 App 架构
* 增加内存

---

## OpenGL ES

状态：

使用。

原因：

iOS 12 支持。

iPad mini 2 GPU 支持。

---

## VideoToolbox

状态：

核心依赖。

原因：

硬件 H264 解码。

---

# 7. File Modification Rules

任何修改必须遵守：

---

## Rule 1

优先新增：

```text
platform/ios/
```

而不是修改：

```text
core/
```

---

## Rule 2

如果修改官方文件：

必须记录：

```text
PORTING_NOTE.md
```

内容：

* 原因
* 修改位置
* 是否可回 upstream

---

## Rule 3

禁止：

为了编译通过：

删除功能。

---

# 8. Expected Final Architecture

最终：

```
                Android

                   │

             scrcpy-server

                   │

                 ADB

                   │

        ┌─────────────────┐
        │   Core Layer    │
        │                 │
        │ ADB             │
        │ Control         │
        │ Demuxer         │
        │ Video           │
        └─────────────────┘

                   │

        ┌─────────────────┐
        │ iOS Platform    │
        │                 │
        │ UIKit           │
        │ VideoToolbox    │
        │ OpenGL ES       │
        │ Touch           │
        │ Theos           │
        └─────────────────┘

                   │

              iPad mini 2
```

---

# 9. Summary

本项目不是：

```
重新写一个类似 scrcpy 的 App
```

而是：

```
scrcpy Core
+
iOS Platform Adapter
```

最终目标：

* 最大化复用官方代码。
* 最小化维护成本。
* 保持协议兼容。
* 保证未来可同步官方更新。

---

下一章：

# 03_PORTING_RULES.md

内容：

* AI 开发行为规则
* 禁止事项
* 代码修改规则
* Git 管理规范
* 如何避免 AI 自行重构项目
* 如何让 AI 分阶段开发整个项目
