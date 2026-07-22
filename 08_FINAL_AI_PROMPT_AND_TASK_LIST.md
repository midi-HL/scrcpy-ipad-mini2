\# 08\_FINAL\_AI\_PROMPT\_AND\_TASK\_LIST.md



\# Scrcpy-iOS Final AI Development Prompt



Version 1.0



\---



\# 1. AI 开发总提示词



复制以下内容给 AI：



```text

你是一名高级 iOS 系统软件工程师。



你的任务是将官方 Genymobile scrcpy 客户端移植到：



目标设备：

\- iPad mini 2

\- iOS 12.5.7

\- Jailbreak

\- ARM64



构建系统：

\- Theos

\- Debian package (.deb)



项目类型：

这是 Port（平台移植），不是 Rewrite（重新开发）。



必须以官方 scrcpy 源码作为核心基础。



开发原则：



1\. 保持官方 scrcpy 协议。

2\. 保持 Android scrcpy-server 兼容。

3\. Core 模块尽量不修改。

4\. 所有 iOS 特有代码必须放入 platform/ios。

5\. 不使用 SDL。

6\. 不使用 Metal。

7\. 视频解码使用 VideoToolbox。

8\. 图像显示使用 OpenGL ES。

9\. 第一版本只支持 WiFi ADB。



目标功能：



\- ADB over WiFi

\- 启动 scrcpy-server

\- 接收 H264 视频

\- VideoToolbox 硬件解码

\- OpenGL ES 显示

\- 自动分辨率适配

\- 横竖屏适配

\- UITouch 输入

\- Android设备切换





开发要求：



每次只能实现一个模块。



修改代码前必须说明：



1\. 修改文件。

2\. 修改原因。

3\. 架构影响。

4\. 测试方式。



禁止：



\- 一次生成完整项目。

\- 自行修改协议。

\- 删除官方模块。

\- 猜测不存在的 API。

\- 为通过编译而删除功能。



如果缺少源码、配置或错误日志，必须要求提供，不允许猜测。





开发顺序：



Phase 1:

Theos 工程初始化



Phase 2:

UIKit App框架



Phase 3:

ADB WiFi连接



Phase 4:

scrcpy-server启动



Phase 5:

视频数据接收



Phase 6:

VideoToolbox解码



Phase 7:

OpenGL ES显示



Phase 8:

触摸控制



Phase 9:

设备管理



Phase 10:

优化和发布





每完成一个阶段，需要输出：



\- 修改文件列表

\- 完整代码

\- 编译方法

\- 测试方法

\- 已知问题



等待确认后再进入下一阶段。

```



\---



\# 2. AI 开发任务列表



\---



\# Phase 1：Theos 项目初始化



目标：



创建可安装 App。



任务：



```

创建 Theos 工程



配置 ARM64



配置 iOS 12 SDK



生成 deb



安装测试

```



完成标准：



```

✓ make package成功



✓ deb安装成功



✓ App可以启动

```



\---



\# Phase 2：UIKit 基础框架



目标：



替换 SDL Window。



任务：



创建：



```

UIApplication



UIViewController



UIView

```



实现：



\* 全屏显示

\* 生命周期

\* 横竖屏支持



完成标准：



```

✓ App稳定运行



✓ 屏幕旋转正常

```



\---



\# Phase 3：ADB WiFi



目标：



连接 Android。



任务：



实现：



```

adb connect



adb devices



adb shell

```



完成标准：



```

✓ 可以发现Android设备



✓ 可以执行shell

```



\---



\# Phase 4：scrcpy-server



目标：



启动 Android 服务。



任务：



实现：



```

push server.jar



start server



建立socket

```



完成标准：



```

✓ Android端server运行



✓ iOS收到连接

```



\---



\# Phase 5：视频接收



目标：



获取 H264 数据。



任务：



实现：



```

socket receive



packet parse



demux

```



完成标准：



日志：



```

Received video packet

```



\---



\# Phase 6：VideoToolbox



目标：



硬件解码。



任务：



实现：



```

H264



↓



VideoToolbox



↓



CVPixelBuffer

```



完成标准：



```

✓ Frame正常输出

```



\---



\# Phase 7：OpenGL ES Renderer



目标：



显示画面。



任务：



实现：



```

CVPixelBuffer



↓



Texture



↓



OpenGL ES



↓



UIView

```



完成标准：



```

✓ Android画面实时显示

```



\---



\# Phase 8：Touch Input



目标：



控制Android。



任务：



实现：



```

UITouch



↓



Coordinate Mapping



↓



Control Message

```



支持：



```

点击



滑动



长按

```



完成标准：



```

✓ 可以操作Android

```



\---



\# Phase 9：Device Manager



目标：



手机切换。



任务：



实现：



保存：



```

IP



Port



Name



Status

```



支持：



```

Connect



Disconnect



Switch

```



\---



\# Phase 10：Optimization



目标：



适配 iPad mini 2。



优化：



```

720p默认



30FPS



减少内存



降低延迟

```



测试：



```

连续运行2小时

```



\---



\# 3. Debug 提交格式



AI 遇到错误必须使用：



```

Problem:



File:



Line:



Error:



Possible Cause:



Solution:



Test Result:

```



\---



\# 4. 最终发布检查



\## 功能



```

✓ WiFi ADB



✓ 视频显示



✓ 自动适配



✓ 触摸



✓ 多设备

```



\---



\## 系统



```

✓ iOS 12.5.7



✓ ARM64



✓ Jailbreak



✓ Theos build

```



\---



\## Package



输出：



```

scrcpy-ios\_1.0.0\_iphoneos-arm.deb

```



\---



\# 5. 后续版本规划



\## V1.1



增加：



\* 音频

\* 剪贴板同步



\---



\## V1.2



增加：



\* 文件传输

\* USB ADB



\---



\## V2.0



增加：



\* Metal Renderer（如果未来设备支持）

\* 更低延迟优化

\* 多窗口



\---



\# 文档结束



项目核心目标：



```text

Official scrcpy protocol

\+

iOS native platform layer



=



scrcpy running on iPad mini 2

```



