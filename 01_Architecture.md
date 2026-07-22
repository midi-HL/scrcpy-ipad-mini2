\# 01\_Architecture.md



\# Scrcpy-iOS Architecture Specification



Version 1.0



\---



\# 1. Architecture Goal



本项目属于 \*\*Platform Port（平台移植）\*\*。



目标不是重新开发 Android Remote Client，而是在最大程度保留官方 scrcpy 架构的基础上，将客户端运行环境迁移到 iOS。



整个项目遵循以下原则：



> \*\*保持 Core（核心）不变，仅替换 Platform（平台层）。\*\*



换句话说：



```

Official scrcpy Core

&#x20;       │

&#x20;       ▼

Platform Layer



Windows

Linux

macOS



↓



iOS

```



\---



\# 2. Overall Architecture



官方 scrcpy：



```

Android



Scrcpy Server

&#x20;       │

ADB

&#x20;       │

Desktop Client

&#x20;       │

SDL

```



移植后：



```

Android



Scrcpy Server

&#x20;       │

ADB over Wi-Fi

&#x20;       │

scrcpy Core

&#x20;       │

iOS Platform Layer

&#x20;       │

UIKit

```



整个数据流保持一致。



\---



\# 3. Layer Design



整个项目划分为四层。



```

Application Layer



Platform Layer



Core Layer



Android Server

```



\---



\## 3.1 Application Layer



负责：



\* UI

\* Device List

\* Settings

\* Navigation



不处理：



\* 视频

\* ADB

\* 网络协议



Application Layer 永远不能直接访问 Android。



只能调用：



```

Core API

```



\---



\## 3.2 Platform Layer



这是本项目新增部分。



目录：



```

platform/ios/

```



负责：



UIKit



OpenGL ES



VideoToolbox



Touch



Theos



Network



这里只允许出现：



Objective-C



UIKit



CoreFoundation



OpenGLES



VideoToolbox



绝不能修改：



Core Protocol



ADB



Packet



Frame



Control



\---



\## 3.3 Core Layer



Core Layer 尽量保持官方源码。



负责：



ADB



Video



Control



Packet



Demuxer



Decoder Interface



Options



Util



Common



这一层：



禁止加入：



UIKit



UIView



Objective-C



UIViewController



任何 iOS API。



必须保持平台无关。



\---



\## 3.4 Android Layer



Android 继续使用：



官方：



```

scrcpy-server

```



原则：



V1：



不修改。



\---



\# 4. Core Principle



整个 Port 最重要的一句话：



```

Platform depends on Core.



Core never depends on Platform.

```



例如：



允许：



```

UIKit



↓



Renderer



↓



Core

```



禁止：



```

Core



↓



UIKit

```



否则以后无法同步官方更新。



\---



\# 5. Module Dependency



推荐：



```

UI



↓



Platform



↓



Core



↓



ADB



↓



Android

```



禁止：



```

UI



↓



ADB

```



UI 永远不知道：



ADB



Socket



Packet



NALU



这些细节。



\---



\# 6. Video Pipeline



官方：



```

Android



↓



Video Encoder



↓



ADB



↓



Demuxer



↓



Decoder



↓



Renderer



↓



Window

```



iOS：



```

Android



↓



Video Encoder



↓



ADB



↓



Demuxer



↓



VideoToolbox



↓



OpenGL ES



↓



UIView

```



只有：



```

Decoder



Renderer



Window

```



发生变化。



\---



\# 7. Control Pipeline



官方：



```

Mouse



↓



Keyboard



↓



Control Message



↓



ADB



↓



Android

```



iOS：



```

UITouch



↓



Gesture



↓



Control Message



↓



ADB



↓



Android

```



Control Message：



保持官方实现。



不要重新设计。



\---



\# 8. Renderer Architecture



官方：



```

Renderer



↓



SDL



↓



OpenGL

```



移植：



```

Renderer



↓



OpenGL ES



↓



CAEAGLLayer

```



Renderer Interface：



保持一致。



例如：



```

renderer\_create()



renderer\_destroy()



renderer\_resize()



renderer\_render()



renderer\_present()

```



平台不同。



接口不变。



\---



\# 9. Decoder Architecture



官方：



```

Packet



↓



FFmpeg Decoder



↓



Frame

```



iOS：



```

Packet



↓



VideoToolbox



↓



Frame

```



Packet：



不要修改。



NALU：



不要修改。



Decoder：



替换。



\---



\# 10. Window System



官方：



SDL Window



↓



Desktop Window



iOS：



```

UIWindow



↓



UIViewController



↓



GLKView

```



不要模拟 SDL。



直接使用 UIKit。



\---



\# 11. Touch Architecture



官方：



```

SDL Event

```



↓



```

Mouse Event

```



↓



Control



iOS：



```

UITouch



↓



Gesture



↓



Coordinate Mapper



↓



Control Message

```



其中：



Coordinate Mapper：



属于：



```

platform/ios/input/

```



\---



\# 12. Coordinate Mapping



Android：



例如：



```

1080×2400

```



iPad：



```

1536×2048

```



触摸：



```

UIKit Point



↓



Video View



↓



Video Coordinate



↓



Android Coordinate



↓



Control Message

```



必须支持：



LetterBox。



例如：



```

██████



██████



██████

```



上下黑边：



触摸：



自动扣除：



黑边高度。



再计算。



禁止：



直接按 UIView 比例发送。



否则：



点击位置错误。



\---



\# 13. Rotation



Android：



旋转：



```

Portrait



↓



Landscape

```



系统：



必须：



重新：



计算：



```

Viewport



Projection



Coordinate



Aspect Ratio

```



但：



Decoder：



尽量保持。



只有：



SPS/PPS



变化时：



重新初始化。



\---



\# 14. Device Manager



负责：



保存：



```

Device Name



Serial



IP



Port



Status



Reconnect

```



例如：



```

Pixel 7



192.168.1.12



Connected

```



切换：



```

Disconnect



↓



Connect New



↓



Decoder Reset



↓



Renderer Reset



↓



Continue

```



整个 App：



不退出。



\---



\# 15. Thread Model



建议：



至少四个线程。



```

Main Thread



UI

```



```

ADB Thread



Socket

```



```

Video Thread



Decoder

```



```

Renderer Thread



OpenGL ES

```



禁止：



UI：



等待：



ADB。



禁止：



Decoder：



运行：



UIKit。



\---



\# 16. Memory Management



由于：



A7



1GB RAM。



要求：



所有：



Frame：



使用：



```

CVPixelBuffer

```



禁止：



大量：



malloc。



禁止：



每帧：



重新创建：



Texture。



应：



复用：



```

CVOpenGLESTextureCache

```



降低：



GPU：



上传成本。



\---



\# 17. Logging



所有模块：



统一：



```

SCRCPY\_LOG\_INFO()



SCRCPY\_LOG\_WARN()



SCRCPY\_LOG\_ERROR()



SCRCPY\_LOG\_DEBUG()

```



不要：



```

printf()



NSLog()



cout

```



混用。



统一：



日志系统。



\---



\# 18. Architecture Summary



整个项目必须遵守以下架构原则：



1\. \*\*Core 优先\*\*：保持官方 scrcpy 的核心模块和数据流，不因平台迁移而重新设计协议。

2\. \*\*Platform 隔离\*\*：所有 iOS 特有实现（UIKit、OpenGL ES、VideoToolbox、触摸、Theos 等）集中在 `platform/ios/`。

3\. \*\*单向依赖\*\*：Platform 可以依赖 Core，Core 不得依赖 Platform。

4\. \*\*最小修改\*\*：只有无法在 iOS 上工作的代码才允许修改或替换，其余保持与官方一致。

5\. \*\*可同步上游\*\*：任何改动都应尽量降低未来同步官方 scrcpy 更新时的冲突和维护成本。



\---



\*\*下一章：`02\_PORTING\_MAP.md`\*\*



这一章将逐个分析官方 \*\*scrcpy\*\* 仓库中的目录和源文件，明确：



\* 哪些文件原样保留；

\* 哪些文件仅修改少量平台相关代码；

\* 哪些文件完全替换为 iOS 实现；

\* SDL、FFmpeg、窗口系统、输入系统等依赖如何映射到 iOS 平台。



