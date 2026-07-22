# scrcpy-iOS 架构文档

## 项目概述

scrcpy-iOS 是官方 scrcpy 客户端的 iOS 移植版本，专为 iPad mini 2 (iOS 12.5.7, Chimera 越狱) 设计。

## 架构分层

```
┌─────────────────────────────────────────────────┐
│            Application Layer (UI)               │
│  RootViewController, DeviceListVC, SettingsVC   │
│  ConnectionViewController                       │
└─────────────────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────┐
│            iOS Platform Layer                   │
│  ScrcpyManager, IOSRenderer, IOSDecoder         │
│  TouchAdapter, VirtualDisplay, SettingsManager  │
└─────────────────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────┐
│            Core Layer (scrcpy)                  │
│  scrcpy_core, adb_protocol, control_msg         │
│  video_stream, demuxer, common, util            │
└─────────────────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────┐
│            Android Device                       │
│  scrcpy-server.jar, MediaCodec, SurfaceFlinger  │
└─────────────────────────────────────────────────┘
```

## 模块详解

### 1. Core Layer

#### adb_protocol
- **文件**: `adb_protocol.h`, `adb_protocol.c`
- **功能**: ADB TCP/IP 协议实现
- **接口**:
  - `adb_connect()` - 连接 ADB
  - `adb_shell()` - 执行 shell 命令
  - `adb_push()` - 推送文件
  - `adb_forward()` - 端口转发

#### control_msg
- **文件**: `control.h`, `control_msg.c`
- **功能**: Scrcpy 控制消息协议
- **接口**:
  - `control_send_key()` - 发送按键
  - `control_send_touch()` - 发送触摸
  - `control_send_text()` - 发送文本
  - `control_send_scroll()` - 发送滚动

#### video_stream
- **文件**: `video_stream.h`, `video_stream.c`
- **功能**: 视频流接收和解析
- **接口**:
  - `video_stream_start()` - 开始接收
  - `video_stream_stop()` - 停止接收

#### scrcpy_core
- **文件**: `scrcpy_core.h`, `scrcpy_core.c`
- **功能**: Scrcpy 核心会话管理
- **接口**:
  - `scrcpy_start()` - 启动会话
  - `scrcpy_stop()` - 停止会话
  - `scrcpy_send_key()` - 发送按键
  - `scrcpy_send_touch()` - 发送触摸

### 2. iOS Platform Layer

#### ScrcpyManager
- **文件**: `ScrcpyManager.h`, `ScrcpyManager.m`
- **功能**: Objective-C 封装器，桥接 Core 和 UI
- **接口**:
  - `startWithHost:port:` - 启动连接
  - `stop` - 停止连接
  - `sendTouchAt:y:action:` - 发送触摸
  - `sendBack/Home/Power` - 预设按键

#### IOSRenderer
- **文件**: `IOSRenderer.h`, `IOSRenderer.m`
- **功能**: OpenGL ES 2.0 视频渲染
- **接口**:
  - `initWithView:` - 初始化渲染器
  - `renderPixelBuffer:` - 渲染帧
  - `mapTouchPoint:toAndroidScreen:` - 坐标映射

#### IOSDecoder
- **文件**: `IOSDecoder.h`, `IOSDecoder.m`
- **功能**: VideoToolbox H264 硬解码
- **接口**:
  - `startWithMaxSize:maxFps:` - 开始解码
  - `stop` - 停止解码
  - `decodeNALU:length:` - 解码 NALU

#### TouchAdapter
- **文件**: `TouchAdapter.h`, `TouchAdapter.m`
- **功能**: iOS 触摸事件转换
- **支持手势**:
  - 点击 (Tap)
  - 滑动 (Swipe)
  - 长按 (Long Press)

#### VirtualDisplay
- **文件**: `VirtualDisplay.h`, `VirtualDisplay.m`
- **功能**: 虚拟显示屏 framebuffer
- **接口**:
  - `initWithWidth:height:` - 初始化
  - `updateFrame:` - 更新帧
  - `renderToView:` - 渲染到视图

#### SettingsManager
- **文件**: `SettingsManager.h`, `SettingsManager.m`
- **功能**: 用户设置管理
- **设置项**:
  - 分辨率 (480p/720p/1080p)
  - 帧率 (15/24/30/60 FPS)
  - 比特率 (1/2/4/8 Mbps)

### 3. UI Layer

#### RootViewController
- **功能**: 应用主界面，导航入口

#### DeviceListViewController
- **功能**: 设备列表管理
- **操作**: 添加、删除、连接设备

#### SettingsViewController
- **功能**: 设置界面
- **配置**: 视频、显示、连接设置

#### ConnectionViewController
- **功能**: 视频显示和控制界面
- **特性**: 实时视频、触摸控制、虚拟按钮

## 数据流

### 视频流
```
Android Screen
    ↓
MediaCodec (H264 编码)
    ↓
scrcpy-server
    ↓
ADB Socket
    ↓
video_stream (接收)
    ↓
IOSDecoder (VideoToolbox 解码)
    ↓
CVPixelBuffer
    ↓
IOSRenderer (OpenGL ES 渲染)
    ↓
UIView 显示
```

### 触摸流
```
UITouch 事件
    ↓
ConnectionViewController
    ↓
坐标映射 (iOS → Android)
    ↓
ScrcpyManager
    ↓
scrcpy_core (控制消息)
    ↓
ADB Socket
    ↓
scrcpy-server
    ↓
Android InputManager
```

## 线程模型

| 线程 | 功能 | 优先级 |
|------|------|--------|
| Main Thread | UI 更新 | 高 |
| Video Thread | 视频接收 | 高 |
| Decoder Thread | H264 解码 | 高 |
| Render Thread | OpenGL 渲染 | 中 |
| Control Thread | 控制消息 | 中 |

## 内存管理

- 使用 `CVPixelBuffer` 避免 CPU 拷贝
- 使用 `CVOpenGLESTextureCache` 高效纹理转换
- 及时释放已完成的帧缓冲
- 避免无限缓存，使用循环缓冲区

## 性能优化

1. **硬件解码**: VideoToolbox 利用 A7 芯片硬件解码
2. **零拷贝**: CVPixelBuffer 直接传递到 OpenGL
3. **异步处理**: 视频接收和解码在后台线程
4. **自适应码率**: 根据网络状况调整

## 兼容性

- **iOS**: 12.0 - 12.5.7
- **越狱**: Chimera (Substitute)
- **架构**: ARM64
- **设备**: iPad mini 2 及以上

## 已知限制

1. 暂不支持音频传输
2. 暂不支持文件传输
3. 暂不支持剪贴板同步
4. 部分游戏可能无法正常操作
