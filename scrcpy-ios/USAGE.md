# scrcpy-iOS 使用说明

## 环境要求

### iOS 设备
- iPad mini 2 或更新设备
- iOS 12.5.7
- Chimera 越狱

### Android 设备
- 已开启 USB 调试
- 已开启无线调试 (Android 11+)
- 或已通过 USB 启用 TCP/IP 模式 (adb tcpip 5555)

## 安装步骤

### 1. 构建项目

```bash
# 在 Mac/Linux 上
cd scrcpy-ios
make clean
make package
```

### 2. 安装到 iPad

```bash
# 通过 SSH
scp packages/scrcpy-ios_*.deb root@<iPad-IP>:/tmp/

# SSH 到 iPad
ssh root@<iPad-IP>

# 安装
dpkg -i /tmp/scrcpy-ios_*.deb

# 重启 SpringBoard
killall SpringBoard
```

### 3. 准备 scrcpy-server

从 GitHub 下载 scrcpy-server.jar:
https://github.com/Genymobile/scrcpy/releases

将文件放到 `Resources/` 目录，然后重新构建。

## 使用方法

### 1. 启动应用

在 iPad 上找到并打开 scrcpy-iOS 应用。

### 2. 添加 Android 设备

1. 在 Android 设备上启用无线调试
2. 获取 IP 地址和端口 (例如: 192.168.1.100:5555)
3. 在 scrcpy-iOS 中点击 "+" 按钮
4. 输入 IP:Port
5. 点击 "Add Device"

### 3. 连接设备

1. 在设备列表中选择要连接的设备
2. 点击设备名称
3. 等待连接成功

### 4. 控制 Android

- **点击**: 单指点击屏幕
- **滑动**: 单指滑动
- **长按**: 长按屏幕 0.5 秒
- **返回键**: 点击 "Back" 按钮
- **Home键**: 点击 "Home" 按钮
- **最近任务**: 点击 "Recent" 按钮

## 设置选项

### 视频设置

| 选项 | 说明 | 推荐值 |
|------|------|--------|
| Resolution | 视频分辨率 | 720p |
| Frame Rate | 帧率 | 30 FPS |
| Bitrate | 比特率 | 2 Mbps |

### 显示设置

| 选项 | 说明 | 推荐值 |
|------|------|--------|
| Scaling Mode | 缩放模式 | Fit (保持比例) |
| Fullscreen | 全屏显示 | 开启 |

### 连接设置

| 选项 | 说明 | 推荐值 |
|------|------|--------|
| ADB Port | ADB 端口 | 5555 |
| Auto Reconnect | 自动重连 | 开启 |

## 性能优化

### iPad mini 2 优化设置

```
Resolution: 480p
Frame Rate: 30 FPS
Bitrate: 1 Mbps
```

### 高性能设备设置

```
Resolution: 1080p
Frame Rate: 60 FPS
Bitrate: 4 Mbps
```

## 故障排除

### 连接失败

1. 确认 Android 设备已开启无线调试
2. 确认 iPad 和 Android 在同一网络
3. 检查 IP 地址和端口是否正确
4. 尝试重启 Android 的 ADB 服务

### 画面卡顿

1. 降低分辨率 (480p)
2. 降低帧率 (15-24 FPS)
3. 降低比特率 (1 Mbps)

### 无画面显示

1. 确认 scrcpy-server.jar 已正确放置
2. 检查 Android 设备是否支持 H264 编码
3. 查看日志排查问题

## 已知问题

- 音频传输暂不支持
- 文件传输暂不支持
- 键盘输入暂不支持
- 部分游戏可能无法正常操作

## 技术支持

如遇到问题，请提供:
- iPad 型号和 iOS 版本
- Android 设备型号和系统版本
- 错误日志
