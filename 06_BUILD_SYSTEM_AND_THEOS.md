\# 06\_BUILD\_SYSTEM\_AND\_THEOS.md



\# Scrcpy-iOS Build System Specification



Version 1.0



\---



\# 1. Purpose



本文档定义：



\* Theos 工程结构。

\* 编译流程。

\* iOS 12.5.7 兼容配置。

\* ARM64 构建方式。

\* `.deb` 打包流程。

\* 第三方库集成方式。



目标：



建立稳定、可重复的开发环境。



\---



\# 2. Build Environment



\## Target Device



```text

Device:



iPad mini 2



System:



iOS 12.5.7



Architecture:



arm64

```



\---



\## Jailbreak Package Target



```text

iphoneos-arm

```



\---



\## Build Host



推荐：



\* macOS

\* Linux



不推荐：



\* Windows



原因：



Theos、clang、ldid、dpkg 工具链主要针对 Unix 环境。



\---



\# 3. Required Tools



必须安装：



\---



\## Git



用途：



获取：



\* scrcpy source

\* Theos

\* dependencies



\---



\## Clang



用途：



编译：



\* C

\* C++

\* Objective-C

\* Objective-C++



\---



\## Make



用途：



Theos 构建。



\---



\## ldid



用途：



代码签名。



\---



\## dpkg



用途：



生成 Debian package。



\---



\# 4. Theos Installation



官方：



```text

https://github.com/theos/theos

```



安装：



```bash

git clone --recursive https://github.com/theos/theos.git

```



设置：



```bash

export THEOS=\~/theos

```



检查：



```bash

echo $THEOS

```



应该输出：



```text

/home/user/theos

```



\---



\# 5. Project Structure



最终结构：



```text

scrcpy-ios/



├── Makefile

├── control

│

├── Sources/

│

│   ├── Core/

│   │

│   │   ├── adb/

│   │   ├── control/

│   │   ├── video/

│   │   ├── demuxer/

│   │   └── util/

│   │

│   └── Platform/

│

│       └── iOS/

│

│           ├── App/

│           ├── Renderer/

│           ├── Decoder/

│           ├── Input/

│           └── ADB/

│

├── Resources/

│

└── docs/

```



\---



\# 6. Theos Makefile Design



示例：



```makefile

ARCHS = arm64



TARGET = iphone:clang:12.0:12.5



include $(THEOS)/makefiles/common.mk





APPLICATION\_NAME = scrcpy-ios





scrcpy-ios\_FILES = \\

Sources/Platform/iOS/App/main.m \\

Sources/Platform/iOS/App/AppDelegate.m \\

Sources/Platform/iOS/Renderer/Renderer.mm \\

Sources/Platform/iOS/Decoder/VideoToolboxDecoder.mm \\

Sources/Core/video/video.c





scrcpy-ios\_FRAMEWORKS = \\

UIKit \\

Foundation \\

OpenGLES \\

VideoToolbox \\

CoreMedia





scrcpy-ios\_CFLAGS = \\

\-fobjc-arc





include $(THEOS\_MAKE\_PATH)/application.mk

```



\---



\# 7. SDK Compatibility



目标：



iOS 12.5.7



因此：



Deployment Target:



```text

12.0

```



\---



禁止使用：



iOS 13+



API。



例如：



禁止：



```objective-c

UIScene

```



因为：



iOS 12 不支持。



\---



\# 8. Language Configuration



项目混合：



\---



\## C



用于：



Core scrcpy。



例如：



```text

adb



control



packet

```



\---



\## C++



用于：



部分官方模块。



文件：



```text

.cpp

```



\---



\## Objective-C



用于：



UIKit。



文件：



```text

.m

```



\---



\## Objective-C++



用于：



Core + iOS Bridge。



文件：



```text

.mm

```



例如：



```text

VideoToolboxDecoder.mm

```



\---



\# 9. Framework Linking



使用：



\## UIKit



用途：



\* Window

\* ViewController

\* Touch



\---



\## Foundation



用途：



\* NSString

\* NSArray

\* NSObject



\---



\## OpenGLES



用途：



GPU Rendering。



\---



\## VideoToolbox



用途：



H264 Hardware Decode。



\---



\## CoreMedia



用途：



CMSampleBuffer。



\---



\## CoreVideo



用途：



CVPixelBuffer。



\---



\# 10. Source Organization Rules



禁止：



所有代码放：



```text

main.m

```



\---



必须：



模块化。



例如：



```text

Renderer/



Renderer.h



Renderer.mm

```



\---



接口：



```objective-c

@interface IOSRenderer : NSObject



\-(void)initialize;



\-(void)renderFrame:(CVPixelBufferRef)frame;



\-(void)resize:(CGSize)size;



\-(void)destroy;



@end

```



\---



\# 11. Build Commands



\## Clean



```bash

make clean

```



\---



\## Build



```bash

make

```



\---



\## Package



```bash

make package

```



\---



生成：



```text

packages/



scrcpy-ios\_1.0.0\_iphoneos-arm.deb

```



\---



\# 12. Installation



复制：



```bash

scp package.deb root@ipad:/tmp/

```



\---



SSH：



```bash

ssh root@ipad

```



安装：



```bash

dpkg -i /tmp/package.deb

```



\---



重启 SpringBoard：



```bash

killall SpringBoard

```



\---



\# 13. Debug Build



开发阶段：



开启：



```makefile

DEBUG = 1

```



\---



增加：



```text

\-DDEBUG

```



\---



日志：



```text

/var/log/syslog

```



查看：



```bash

tail -f /var/log/syslog

```



\---



\# 14. Dependency Management



每个依赖：



必须记录：



```text

Dependency:



Version:



Purpose:



License:



Build Method:



iOS Compatibility:

```



\---



例如：



\## OpenGL ES



```text

Version:

System Framework



Purpose:

Renderer



License:

Apple SDK



Compatibility:

iOS 12+

```



\---



\# 15. Cross Compilation Rules



编译目标：



```text

arm64

```



禁止：



```text

armv7



x86\_64

```



\---



检查：



```bash

file binary

```



结果：



应该：



```text

Mach-O 64-bit executable arm64

```



\---



\# 16. Binary Size Control



iPad mini 2：



1GB RAM。



要求：



Release：



开启：



```text

\-O2

```



\---



禁止：



携带：



\* 无用 FFmpeg codec

\* SDL

\* Debug symbols



\---



\# 17. Continuous Build Rule



每个 Phase 完成：



必须：



执行：



```bash

make clean

make package

```



确认：



可以重新构建。



\---



\# 18. Build Failure Handling



遇到：



编译错误。



AI 必须输出：



```

Error:



File:



Line:



Cause:



Solution:



Verification:

```



\---



禁止：



直接：



修改大量文件。



\---



\# 19. First Build Milestone



Phase 1 完成标准：



必须达到：



```

✓ Theos project created



✓ arm64 build success



✓ deb generated



✓ package installed



✓ app launches



✓ no crash

```



\---



\# 20. Build System Summary



最终目标：



```text

Source Code



↓



Theos Makefile



↓



clang



↓



ARM64 Binary



↓



ldid



↓



dpkg



↓



scrcpy-ios.deb



↓



iPad mini 2

```



\---



下一章：



\# 07\_SCRCPY\_CORE\_INTEGRATION.md



内容：



\* 如何导入官方 scrcpy 源码

\* Android Server 保持方式

\* ADB 集成详细方案

\* Client/Server 通信流程

\* iOS 如何启动 scrcpy-server

\* V1 网络连接实现

\* Core 层适配步骤



