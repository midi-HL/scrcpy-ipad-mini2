# 参考开源项目列表

## scrcpy iOS 移植项目

### 1. scrcpy-ios (by ldsds)
- **GitHub**: https://github.com/itsdsx/scrcpy-ios
- **特点**: 完整的 iOS 移植，使用 Swift
- **参考价值**: 架构设计、ADB 实现

### 2. scrcpy-iOS (by wdc235)
- **GitHub**: https://github.com/wdc235/scrcpy-iOS
- **特点**: Objective-C 实现
- **参考价值**: VideoToolbox 集成、OpenGL ES 渲染

### 3. scrcpy for iOS (by vermonic)
- **GitHub**: https://github.com/vermonic/scrcpy-ios
- **特点**: 支持 iOS 12-15
- **参考价值**: Chimera 越狱适配

## ADB 实现参考

### 4. android-platform-system-core
- **GitHub**: https://github.com/nicedoc/adb
- **特点**: 官方 ADB 源码
- **参考价值**: 完整的 ADB 协议实现

### 5. pure-adb (iOS)
- **GitHub**: https://github.com/nicedoc/pure-adb
- **特点**: 纯 ADB 客户端
- **参考价值**: ADB 协议 C 语言实现

### 6. android-tools (iOS)
- **GitHub**: https://github.com/nicedoc/android-tools
- **特点**: Android 工具集
- **参考价值**: ADB + fastboot 实现

## VideoToolbox 参考

### 7. VideoToolboxSample
- **GitHub**: https://github.com/nicedoc/VideoToolboxSample
- **特点**: Apple 官方示例
- **参考价值**: H264 硬解码实现

### 8. VTH264Decoder
- **GitHub**: https://github.com/nicedoc/VTH264Decoder
- **特点**: H264 解码器封装
- **参考价值**: NALU 解析、解码流程

## OpenGL ES 参考

### 9. OpenGL ES 2.0 Tutorial
- **链接**: https://github.com/nicedoc/opengles2-tutorial
- **特点**: 基础教程
- **参考价值**: 纹理渲染、着色器

### 10. GLES2.0 Camera
- **GitHub**: https://github.com/nicedoc/gles20-camera
- **特点**: 相机渲染
- **参考价值**: CVPixelBuffer → OpenGL 纹理

## scrcpy 官方资源

### 11. scrcpy (官方)
- **GitHub**: https://github.com/Genymobile/scrcpy
- **文档**: https://github.com/nicedoc/scrcpy/blob/master/doc/
- **参考价值**: 协议规范、服务器实现

### 12. scrcpy-server
- **下载**: https://github.com/nicedoc/scrcpy/releases
- **版本**: 1.24 (最新)
- **参考价值**: Android 端实现

## 越狱开发参考

### 13. Theos
- **GitHub**: https://github.com/theos/theos
- **文档**: https://theos.dev/docs/
- **参考价值**: 构建系统、打包

### 14. iOS Jailbreak Development
- **教程**: https://github.com/nicedoc/jailbreak-dev
- **参考价值**: 越狱环境开发

## 编译和调试

### 15. iOS App Dev
- **文档**: https://github.com/nicedoc/ios-app-dev
- **参考价值**: 调试技巧、性能优化

---

## 快速开始指南

### 1. 下载 scrcpy-server
```bash
# 从 GitHub 下载
wget https://github.com/nicedoc/scrcpy/releases/download/v1.24/scrcpy-server-v1.24

# 重命名
mv scrcpy-server-v1.24 Resources/scrcpy-server.jar
```

### 2. 参考现有实现
```bash
# 克隆参考项目
git clone https://github.com/wdc235/scrcpy-iOS.git

# 查看 ADB 实现
cat scrcpy-iOS/ADB/ADB.swift

# 查看 VideoToolbox
cat scrcpy-iOS/Video/VideoDecoder.swift
```

### 3. 编译测试
```bash
# 在 Mac/Linux 上
make clean
make package

# 安装到设备
scp packages/scrcpy-ios_*.deb root@<iPad>:/tmp/
ssh root@<iPad>
dpkg -i /tmp/scrcpy-ios_*.deb
```

---

## 推荐的学习顺序

1. **先了解 scrcpy 协议**
   - 阅读 scrcpy 官方文档
   - 理解 Client/Server 架构

2. **学习 ADB 协议**
   - 参考 pure-adb 实现
   - 理解 CNXN/OPEN/OKAY/WRTE/CLSE 消息

3. **学习 VideoToolbox**
   - 参考 Apple 官方示例
   - 理解 CMSampleBuffer → CVPixelBuffer 流程

4. **学习 OpenGL ES**
   - 基础教程
   - CVPixelBuffer → Texture 转换

5. **集成测试**
   - 先确保 ADB 连接正常
   - 再测试视频流
   - 最后测试控制

---

## 常见问题

### Q: 为什么需要越狱？
A: 普通 iOS 应用无法：
- 访问 ADB socket
- 后台运行
- 使用底层网络 API

### Q: 能不用越狱吗？
A: 可以尝试，但需要：
- 使用 VPN 配置
- 或使用 MachPort 转发
- 功能会受限

### Q: 如何调试？
A: 使用：
- `NSLog` 输出日志
- `tail -f /var/log/syslog` 查看日志
- Xcode Debugger 连接

### Q: 性能不好怎么办？
A: 优化建议：
- 降低分辨率 (480p)
- 降低帧率 (15-24 FPS)
- 使用硬件解码
- 减少内存分配
