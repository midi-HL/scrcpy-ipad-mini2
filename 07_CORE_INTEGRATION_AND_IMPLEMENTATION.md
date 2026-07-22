


\# 07\_CORE\_INTEGRATION\_AND\_IMPLEMENTATION.md



\# Scrcpy Core 集成与实现方案



Version 1.0



\---



\# 1. 导入官方 scrcpy Core



目标：



保留：



\* ADB

\* Control Protocol

\* Video Protocol

\* Demuxer

\* Common Utility



删除/替换：



\* SDL

\* Desktop Window

\* FFmpeg Renderer



结构：



```

scrcpy-ios



├── core

│

├── platform/ios

│

└── server

```



\---



\# 2. Core 保留模块



直接移植：



```

core/



├── adb

├── control

├── video

├── demuxer

├── util

└── common

```



原则：



不修改协议。



\---



\# 3. Android Server



Android 端继续使用官方：



```

scrcpy-server.jar

```



流程：



```

iPad



↓



ADB WiFi



↓



push server.jar



↓



adb shell启动



↓



Android发送视频

```



\---



\# 4. ADB WiFi 连接



V1 只支持：



```

ADB over TCP/IP

```



流程：



```

输入 Android IP



↓



adb connect IP:5555



↓



adb devices



↓



建立 scrcpy 通信

```



\---



\# 5. 视频流程



完整流程：



```

Android Surface



↓



H264 Encoder



↓



ADB Socket



↓



iOS Demuxer



↓



VideoToolbox



↓



CVPixelBuffer



↓



OpenGL ES



↓



UIView

```



\---



\# 6. Decoder 实现



接口保持：



```c

decoder\_init()



decoder\_decode()



decoder\_close()

```



iOS 实现：



```

VideoDecoder



↓



VideoToolbox

```



功能：



\* H264 硬解

\* SPS/PPS处理

\* Frame输出



\---



\# 7. Renderer 实现



替换：



```

SDL Renderer

```



为：



```

OpenGL ES Renderer

```



流程：



```

CVPixelBuffer



↓



Texture Cache



↓



OpenGL Texture



↓



显示

```



支持：



\* 自动缩放

\* 保持比例

\* 横竖屏



\---



\# 8. Touch 控制



输入：



```

UITouch

```



转换：



```

iPad坐标



↓



Android分辨率坐标



↓



scrcpy Control Message



↓



ADB



↓



Android

```



支持：



V1：



\* 点击

\* 长按

\* 滑动



\---



\# 9. 坐标适配



例如：



Android：



```

1080×2400

```



iPad：



```

1536×2048

```



计算：



```

view size



↓



scale



↓



offset



↓



Android coordinate

```



必须处理：



\* 黑边

\* 比例变化

\* 旋转



\---



\# 10. UI结构



简单设计：



```

MainViewController



├── Device List



├── Connect Button



└── Video View

```



视频区域：



```

GLView

```



\---



\# 11. 多设备切换



保存：



```

DeviceInfo



IP



Port



Name



Status

```



切换：



```

Disconnect old



↓



Reset Decoder



↓



Connect new



↓



Start stream

```



\---



\# 12. V1 完成标准



必须实现：



```

✓ WiFi ADB



✓ scrcpy server启动



✓ 视频显示



✓ 自动分辨率适配



✓ 触摸控制



✓ Android设备切换

```



暂不实现：



```

× Audio



× File Transfer



× Clipboard



× USB ADB

```



\---



\# 13. 开发顺序



实际编码：



```

1\. Theos App



↓



2\. UIKit窗口



↓



3\. ADB连接



↓



4\. Server启动



↓



5\. 视频接收



↓



6\. VideoToolbox



↓



7\. OpenGL显示



↓



8\. Touch



↓



9\. Device管理

```



\---



下一章：



\# 08\_FINAL\_AI\_PROMPT\_AND\_TASK\_LIST.md



包含：



\* 最终给 AI 的完整开发提示词

\* 分阶段任务列表

\* 每阶段输入输出要求

\* 开发检查表



