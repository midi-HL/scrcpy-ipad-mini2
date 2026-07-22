

\# Scrcpy-iOS Port Development Specification



\## Version 1.0



目标：



将官方 \*\*Genymobile scrcpy\*\* 客户端移植到：



\* iPad mini 2

\* iOS 12.5.7

\* Jailbreak 环境

\* ARM64

\* Theos 构建系统



最终输出：



```

scrcpy-ios.deb

```



通过：



\* Sileo

\* Zebra

\* Cydia

\* dpkg



安装。



\---



\# 00\_README.md



\# 项目简介



\## 项目名称



```

scrcpy-iOS

```



\## 项目类型



Platform Port（平台移植）



不是：



\* 新开发 Android 控制软件

\* 重写 scrcpy

\* 创建新的远程控制协议



项目核心目标：



> 在保持官方 scrcpy 架构、协议和数据流一致的情况下，将客户端运行环境从桌面系统迁移到 iOS 越狱环境。



\---



\# 项目背景



官方 scrcpy 支持：



\* Windows

\* Linux

\* macOS



通过：



```

PC Client

&#x20;   |

ADB

&#x20;   |

Android Server

```



实现：



\* 实时画面显示

\* 键鼠控制

\* 文件传输

\* 剪贴板同步

\* 音频转发



但是官方客户端依赖：



\* SDL2

\* FFmpeg

\* Desktop Window System



无法直接运行于 iOS。



因此本项目目标：



替换桌面平台相关部分，同时保留核心逻辑。



\---



\# V1.0 功能范围



\## 必须实现



\### Android 连接



支持：



```

ADB over Wi-Fi

```



功能：



\* adb devices

\* adb connect

\* adb disconnect

\* adb shell

\* adb exec-out



\---



\### 视频显示



支持：



Android：



```

scrcpy server

```



输出：



```

H264 stream

```



iOS：



```

ADB

&#x20;↓

H264

&#x20;↓

VideoToolbox

&#x20;↓

OpenGL ES

&#x20;↓

UIView

```



\---



\### 自动适配



支持：



\* 不同分辨率

\* 横屏

\* 竖屏

\* 屏幕旋转

\* 自动比例调整



要求：



禁止：



\* 拉伸

\* 裁剪

\* 错误比例



\---



\### 输入控制



支持：



\* 单击

\* 长按

\* 滑动



转换：



```

UITouch



↓



scrcpy Control Message



↓



ADB



↓



Android

```



\---



\### 设备切换



支持：



多个 Android：



例如：



```

192.168.1.10



192.168.1.20



192.168.1.30

```



快速切换。



\---



\# V1.0 不实现



暂时删除：



\* USB ADB

\* 音频

\* 文件传输

\* 剪贴板

\* 摄像头

\* HID

\* 游戏手柄

\* 多窗口



原因：



这些功能会增加 iOS 平台适配复杂度。



\---



\# 开发原则



\## 原则 1：保持官方 scrcpy



官方源码：



```

https://github.com/Genymobile/scrcpy

```



是唯一核心来源。



禁止：



重新设计：



\* 通信协议

\* 控制协议

\* 视频协议

\* Android Server



\---



\## 原则 2：核心代码优先保持不变



以下模块尽量直接使用：



```

app/

common/

adb/

control/

video/

demuxer/

util/

```



\---



\## 原则 3：新增 iOS 平台层



所有 iOS 特殊代码：



必须放：



```

platform/ios/

```



例如：



```

platform/



&#x20;└── ios/



&#x20;     ├── UIKit/



&#x20;     ├── Renderer/



&#x20;     ├── VideoToolbox/



&#x20;     ├── Input/



&#x20;     ├── Network/



&#x20;     └── Theos/

```



\---



\# 目标设备限制分析



\## iPad mini 2



硬件：



```

CPU:

Apple A7



Architecture:

ARM64



RAM:

1GB

```



限制：



\* 内存少

\* CPU 性能有限

\* GPU 较旧



因此：



必须：



\* 使用硬件解码

\* 避免大量缓存

\* 避免软件渲染



\---



\# 性能目标



| 项目  | 目标           |

| --- | ------------ |

| 分辨率 | 720p 默认      |

| 最大  | 1080p        |

| FPS | 30 FPS 稳定    |

| 延迟  | <120ms       |

| 内存  | <200MB       |

| 解码  | VideoToolbox |

| 渲染  | OpenGL ES 2  |



\---



\# 软件环境



\## iOS



```

iOS 12.5.7

```



\---



\## 越狱



支持：



\* unc0ver

\* checkra1n



\---



\## 构建



使用：



```

Theos

```



官方：



```

https://github.com/theos/theos/

```



\---



\## 编译输出



```

make package

```



生成：



```

packages/



scrcpy-ios\_1.0.0\_iphoneos-arm.deb

```



\---



\# 项目最终结构



```

scrcpy-ios/



├── app/

├── common/

├── adb/

├── control/

├── video/

├── demuxer/

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

├── Resources/

│

├── Makefile

├── control

└── README.md

```



\---





下一部分继续：



\## 01\_Architecture.md



内容：



\* scrcpy 原始架构分析

\* Client/Server 通信流程

\* 视频数据流

\* 控制数据流

\* iOS 移植后的完整架构图

\* 每个模块保留/替换方案

