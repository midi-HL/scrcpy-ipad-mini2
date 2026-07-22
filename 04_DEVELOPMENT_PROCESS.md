\# 04\_DEVELOPMENT\_PROCESS.md



\# Scrcpy-iOS Development Process Specification



Version 1.0



\---



\# 1. Development Philosophy



本项目采用：



```

Incremental Development

```



（渐进式开发）



而不是：



```

Generate Everything First

```



（一次生成全部代码）



原因：



scrcpy 涉及：



\* C/C++

\* Android ADB

\* 网络通信

\* H264

\* VideoToolbox

\* OpenGL ES

\* UIKit

\* Theos

\* 越狱环境



一次生成整个工程会导致：



\* 编译错误难定位。

\* AI 容易修改错误方向。

\* 架构逐渐偏离官方。



\---



\# 2. Overall Development Flow



完整流程：



```

Phase 0

环境准备



↓



Phase 1

项目初始化



↓



Phase 2

Theos App 骨架



↓



Phase 3

ADB 移植



↓



Phase 4

Android Server 通信



↓



Phase 5

视频接收



↓



Phase 6

VideoToolbox 解码



↓



Phase 7

OpenGL ES 显示



↓



Phase 8

触摸控制



↓



Phase 9

设备管理



↓



Phase 10

性能优化



↓



Phase 11

Release

```



\---



\# Phase 0：开发环境准备



\## 目标



建立可编译环境。



\---



\## iOS 环境



设备：



```

iPad mini 2

```



系统：



```

iOS 12.5.7

```



越狱：



支持：



\* checkra1n

\* unc0ver



\---



\## Mac / Linux Build Host



推荐：



macOS 或 Linux。



原因：



Theos 原生支持。



Windows：



不推荐。



\---



\## 安装：



\### Theos



地址：



```

https://github.com/theos/theos

```



安装：



```bash

git clone --recursive https://github.com/theos/theos.git

```



\---



配置：



```bash

export THEOS=\~/theos

```



\---



\## 工具链



需要：



```

clang



make



git



ldid



dpkg

```



\---



\## 验证



创建测试：



```bash

nic.pl

```



生成：



```

iOS App Project

```



编译：



```bash

make package

```



必须成功。



\---



\# Phase 1：项目初始化



\## 目标



建立 scrcpy-iOS 基础结构。



\---



目录：



```

scrcpy-ios/



core/



platform/



resources/



docs/

```



\---



要求：



暂时不要移植功能。



先保证：



\* Theos 工程。

\* App 启动。

\* deb 生成。



\---



测试：



安装：



```

scrcpy-ios.deb

```



设备：



出现：



```

scrcpy-iOS

```



图标。



启动：



显示：



```

Hello scrcpy-iOS

```



\---



\# Phase 2：UIKit Application Layer



\## 目标



替换 SDL Window。



\---



实现：



```

UIApplication



↓



UIWindow



↓



UIViewController

```



\---



功能：



\* App 生命周期。

\* 全屏 View。

\* 状态栏控制。



\---



不要：



加入：



ADB。



不要：



加入：



视频。



\---



测试：



App：



\* 打开。

\* 关闭。

\* 横竖屏切换。



\---



\# Phase 3：ADB Integration



\## 目标



让 iPad 可以控制 Android。



\---



策略：



使用官方 ADB。



\---



支持：



```

adb devices



adb connect



adb shell

```



\---



第一阶段：



仅：



Wi-Fi。



例如：



Android：



```

192.168.1.100:5555

```



iPad：



连接。



\---



实现：



结构：



```

ADBManager



↓



ADB Process



↓



Socket

```



\---



测试：



iPad Terminal：



执行：



```

adb devices

```



看到：



```

device

```



\---



\# Phase 4：scrcpy Server Communication



\## 目标



启动 Android scrcpy server。



\---



流程：



```

iPad



adb push



scrcpy-server.jar



↓



adb shell



app\_process



↓



Android Server

```



\---



保持官方协议。



\---



测试：



Android：



出现：



```

scrcpy server started

```



\---



\# Phase 5：Video Stream Receiving



\## 目标



收到 Android 视频。



\---



流程：



```

Android



Screen Capture



↓



H264



↓



ADB socket



↓



iPad

```



\---



实现：



保留：



```

Demuxer

```



\---



测试：



打印：



```

Received H264 packet



size=xxxx

```



\---



\# Phase 6：VideoToolbox Decoder



\## 目标



硬件解码。



\---



输入：



```

H264 NALU

```



输出：



```

CVPixelBuffer

```



\---



流程：



```

NALU



↓



CMBlockBuffer



↓



CMSampleBuffer



↓



VideoToolbox



↓



CVPixelBuffer

```



\---



测试：



成功输出：



```

Decoded Frame

```



\---



\# Phase 7：OpenGL ES Renderer



\## 目标



显示 Android 画面。



\---



结构：



```

CVPixelBuffer



↓



Texture



↓



OpenGL ES



↓



UIView

```



\---



支持：



\* 自动比例。

\* 黑边。

\* 横竖屏。



\---



测试：



看到：



Android 实时画面。



\---



\# Phase 8：Touch Control



\## 目标



控制 Android。



\---



支持：



第一版：



\### Tap



```

点击

```



\---



\### Swipe



```

滑动

```



\---



\### Long Press



```

长按

```



\---



流程：



```

UITouch



↓



Coordinate Mapper



↓



scrcpy Control Message



↓



ADB



↓



Android

```



\---



测试：



打开：



Android App。



iPad 点击。



Android 响应。



\---



\# Phase 9：Device Manager



\## 目标



多手机切换。



\---



保存：



```

Device



IP



Port



Name



Last Connection

```



\---



UI：



例如：



```

Devices



Pixel 7

Connected





Redmi

Offline

```



\---



功能：



\* Connect

\* Disconnect

\* Switch



\---



\# Phase 10：Performance Optimization



目标：



适配：



```

A7

1GB RAM

```



\---



优化：



\## Resolution



默认：



```

720p

```



\---



\## FPS



默认：



```

30

```



\---



\## Decoder



必须：



```

Hardware

```



\---



\## Memory



检查：



```

Instruments

```



\---



目标：



连续运行：



> 2 小时无崩溃。



\---



\# Phase 11：Release



\## Release Checklist



\---



\## Build



确认：



```

make package

```



成功。



\---



\## Install



测试：



```

dpkg -i

```



\---



\## Basic Function



确认：



□ App 启动



□ ADB连接



□ 视频显示



□ 自动适配



□ 点击



□ 滑动



□ 手机切换



\---



\## Package



输出：



```

scrcpy-ios\_1.0.0\_iphoneos-arm.deb

```



\---



\# AI 开发执行流程



以后给 AI 开发时，必须要求：



\---



\## 每次只处理一个 Phase



例如：



不要：



> "帮我完成整个 scrcpy-iOS"



应该：



> "现在只执行 Phase 3：ADB Integration。不要修改 Video、Renderer、UI 模块。"



\---



\## 每个阶段输出：



AI 必须提供：



```

1\. 修改文件列表



2\. 修改原因



3\. 完整代码



4\. 编译方法



5\. 测试方法



6\. 已知问题

```



\---



\## 遇到错误：



AI 必须：



先分析：



```

Error



Cause



Solution



Risk

```



不能：



直接大规模重写。



\---



\# Final Development Order



最终执行顺序：



```

Theos App

&#x20;   ↓

UIKit

&#x20;   ↓

ADB

&#x20;   ↓

scrcpy Server

&#x20;   ↓

H264 Receive

&#x20;   ↓

VideoToolbox

&#x20;   ↓

OpenGL ES

&#x20;   ↓

Touch

&#x20;   ↓

Device Switch

&#x20;   ↓

Optimization

&#x20;   ↓

Release

```



\---



下一章：



\# 05\_AI\_DEVELOPMENT\_GUIDE.md



内容：



\* 给 Claude / Gemini / Codex 的完整自然语言 Prompt

\* AI 每次开发应该如何行动

\* 如何让 AI 阅读官方 scrcpy 源码

\* 如何避免 AI 自行创造不存在的 API

\* 如何要求 AI 输出代码和测试步骤

\* 最终完整开发指令模板



