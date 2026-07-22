\# 03\_PORTING\_RULES.md



\# Scrcpy-iOS Porting Development Rules



Version 1.0



\---



\# 1. Purpose



本文档定义：



\* 开发过程中的技术规则。

\* AI 辅助开发规则。

\* 源码修改规则。

\* 架构保护规则。



目标：



防止开发过程中出现：



\* 随意重构。

\* 偏离官方 scrcpy。

\* 删除功能。

\* 引入不必要依赖。

\* 产生无法维护的代码。



\---



\# 2. Core Development Philosophy



\## Rule 2.1



本项目是：



```

Porting Project

```



不是：



```

Rewrite Project

```



开发者必须始终优先考虑：



> "如何让官方 scrcpy 在 iOS 工作"



而不是：



> "如何重新设计一个更简单的软件"



\---



\# 3. Source Code Priority Rules



\## Rule 3.1



官方 scrcpy 源码具有最高优先级。



来源：



```

Genymobile/scrcpy

```



所有核心功能必须基于官方实现。



\---



\## Rule 3.2



禁止：



直接删除官方模块。



例如：



禁止：



```

删除 control 模块

```



理由：



"暂时不用"



\---



禁止：



```

删除 packet 结构

```



理由：



"重新设计更简单"



\---



\## Rule 3.3



新增代码优先放入：



```

platform/ios/

```



例如：



正确：



```

platform/ios/renderer/

```



错误：



直接修改：



```

video/renderer.c

```



\---



\# 4. Platform Isolation Rule



\## Rule 4.1



Core Layer 禁止依赖 iOS Framework。



Core 不允许出现：



```objective-c

\#import <UIKit/UIKit.h>

```



禁止：



```objective-c

\#import <VideoToolbox/VideoToolbox.h>

```



禁止：



```objective-c

\#import <OpenGLES/ES2/gl.h>

```



\---



原因：



Core 必须保持：



```

Platform Independent

```



\---



\# 5. Dependency Rules



\## Rule 5.1



禁止随意增加第三方库。



新增依赖必须说明：



\* 为什么需要。

\* 是否可以使用系统 API 替代。

\* 对 iOS 12 是否兼容。

\* 对体积和性能影响。



\---



\## Rule 5.2



优先使用 Apple Framework。



例如：



视频：



优先：



```

VideoToolbox

```



而不是：



```

FFmpeg software decoder

```



\---



图形：



优先：



```

OpenGL ES

```



而不是：



```

Metal

```



\---



\# 6. ADB Rules



\## Rule 6.1



禁止重新实现 ADB 协议。



错误：



```

自己写 adb client

```



正确：



```

移植官方 adb client

```



\---



\## Rule 6.2



ADB 层必须保持：



```

adb devices



adb connect



adb shell



adb exec-out



adb push



adb pull

```



兼容。



\---



\## Rule 6.3



ADB 相关代码不能依赖 UIKit。



错误：



```

ADBManager.m

直接更新 UI

```



正确：



```

ADB Layer



↓



Callback



↓



UI Layer

```



\---



\# 7. Video Rules



\## Rule 7.1



视频数据流必须保持：



```

Android



↓



H264



↓



Demuxer



↓



Decoder



↓



Renderer

```



\---



禁止：



修改：



```

Control Protocol

```



来适配 iOS。



\---



\# 8. Decoder Rules



\## Rule 8.1



Decoder 必须抽象。



例如：



接口：



```c

decoder\_init()



decoder\_decode()



decoder\_release()

```



\---



实现：



```

decoder\_ffmpeg



decoder\_videotoolbox

```



\---



不要：



把：



```c

VideoToolbox

```



代码直接写进：



```

video.c

```



\---



\# 9. Renderer Rules



\## Rule 9.1



Renderer 必须独立。



接口：



例如：



```c

renderer\_init()



renderer\_resize()



renderer\_draw()



renderer\_destroy()

```



\---



实现：



```

renderer\_sdl



renderer\_ios

```



\---



\# 10. UIKit Rules



\## Rule 10.1



UIKit 只负责：



\* 界面。

\* 生命周期。

\* 用户输入。



UIKit 不负责：



\* ADB。

\* H264。

\* 协议。



\---



错误：



```

ViewController.m



里面直接：



adb shell input tap

```



\---



正确：



```

UIViewController



↓



Input Manager



↓



Control Layer

```



\---



\# 11. Memory Rules



目标设备：



```

iPad mini 2

A7

1GB RAM

```



因此：



\---



\## Rule 11.1



禁止无限缓存。



例如：



错误：



```c

NSArray \*frames;

```



无限保存。



\---



正确：



循环使用：



```

Frame Pool

```



\---



\## Rule 11.2



视频 Frame 优先：



```

CVPixelBuffer

```



避免：



```

CPU memcpy

```



\---



\# 12. Thread Rules



必须保持线程隔离。



\---



\## Main Thread



负责：



```

UIKit

UI update

```



\---



\## ADB Thread



负责：



```

socket

command

connection

```



\---



\## Video Thread



负责：



```

receive packet

decode

```



\---



\## Render Thread



负责：



```

OpenGL ES

```



\---



禁止：



视频线程调用：



```

UIView update

```



\---



禁止：



UI线程等待：



```

ADB response

```



\---



\# 13. Error Handling Rules



所有错误必须：



分类。



例如：



```

ADB\_ERROR



VIDEO\_ERROR



DECODER\_ERROR



RENDER\_ERROR



NETWORK\_ERROR

```



\---



禁止：



直接：



```

return -1

```



没有日志。



\---



\# 14. Logging Rules



统一：



```

SCRCPY\_LOG\_INFO()



SCRCPY\_LOG\_DEBUG()



SCRCPY\_LOG\_ERROR()

```



\---



日志必须包含：



例如：



```

\[Decoder]



VideoToolbox initialization failed



status=-12905

```



\---



不要：



```

error

```



这种无信息日志。



\---



\# 15. Git Rules



每个功能：



独立 Commit。



例如：



正确：



```

Add iOS OpenGL renderer



Add VideoToolbox decoder



Add UIKit touch adapter

```



\---



错误：



```

update code

```



\---



\# 16. AI Development Rules



以下规则专门针对 AI 开发。



\---



\## Rule 16.1



AI 不允许一次生成整个项目。



必须：



```

Module by Module

```



\---



流程：



```

分析



↓



设计



↓



实现



↓



编译



↓



测试



↓



下一模块

```



\---



\## Rule 16.2



AI 修改代码前必须：



说明：



1\. 修改文件。

2\. 修改原因。

3\. 对架构影响。

4\. 是否影响 upstream。



\---



\## Rule 16.3



AI 不允许：



自行改变：



\* 文件结构。

\* API 名称。

\* 模块职责。



\---



\## Rule 16.4



如果发现官方代码无法直接移植：



必须：



先提出：



```

Problem



Possible Solutions



Recommended Solution



Reason

```



然后等待确认。



\---



\# 17. Testing Rules



每个阶段必须验证。



\---



\## Build Test



必须：



```

make package

```



成功。



\---



\## Runtime Test



必须：



App：



\* 启动。

\* 不崩溃。



\---



\## Connection Test



ADB：



```

adb devices

```



成功。



\---



\## Video Test



确认：



\* 有画面。

\* 无严重延迟。

\* 旋转正常。



\---



\# 18. Code Review Checklist



提交前检查：



\## Architecture



□ Core 是否被污染？



□ iOS代码是否在 platform/ios？



□ 是否破坏官方结构？



\---



\## Performance



□ 是否产生大量内存？



□ 是否使用硬件解码？



□ 是否重复创建 Texture？



\---



\## Compatibility



□ iOS 12 是否支持？



□ ARM64 是否支持？



□ Theos 是否能编译？



\---



\# 19. Final Rule



如果一个设计：



\* 更容易开发；

\* 但是破坏 scrcpy 架构；



禁止采用。



如果一个设计：



\* 开发更复杂；

\* 但是保持官方兼容；



优先采用。



\---



\# Summary



本项目最高优先级：



```

Compatibility

>

Maintainability

>

Performance

>

Development Speed

```



任何开发决定都必须围绕：



> "让 scrcpy 核心能够长期运行在 iOS 平台，并保持未来同步官方版本的能力"



\---



下一章：



\# 04\_DEVELOPMENT\_PROCESS.md



内容：



\* 完整 AI 开发流程

\* 从零环境搭建

\* 第一个可运行版本

\* 每阶段目标

\* 测试方法

\* 如何让 AI 按阶段持续开发

\* 每个 Milestone 的详细任务列表



