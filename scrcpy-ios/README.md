# scrcpy-iOS

Scrcpy client ported to iOS - remote control Android devices from your iPad.

## Features

- WiFi ADB connection
- H264 video streaming
- VideoToolbox hardware decoding
- OpenGL ES 2.0 rendering
- Touch input (tap, swipe, long press)
- Resolution and FPS settings
- Virtual display support
- Multiple device management

## Requirements

- iPad mini 2 or later
- iOS 12.5.7
- Chimera jailbreak
- Theos build system

## Building

### Prerequisites

1. Install Theos:
```bash
git clone --recursive https://github.com/theos/theos.git
export THEOS=~/theos
```

2. Clone this repository

### Build

```bash
cd scrcpy-ios
make clean
make package
```

The `.deb` file will be generated in the `packages/` directory.

## Installation

1. Transfer the `.deb` file to your iPad:
```bash
scp packages/scrcpy-ios_*.deb root@<iPad-IP>:/tmp/
```

2. SSH into your iPad and install:
```bash
ssh root@<iPad-IP>
dpkg -i /tmp/scrcpy-ios_*.deb
```

3. Respring or reboot your device.

## Usage

1. Enable USB debugging on your Android device
2. Enable WiFi debugging and note the IP:Port
3. Launch scrcpy-iOS on your iPad
4. Tap "Add Device" and enter the IP:Port
5. Select the device to connect

## Settings

### Video Settings
- **Resolution**: 480p, 720p, 1080p, or Original
- **Frame Rate**: 15, 24, 30, 60 FPS, or Original
- **Bitrate**: 1, 2, 4, or 8 Mbps

### Display Settings
- **Scaling Mode**: Fit (keep aspect ratio), Stretch, or Crop
- **Fullscreen**: Enable/disable fullscreen mode

### Connection Settings
- **ADB Port**: Default 5555
- **Auto Reconnect**: Enable/disable automatic reconnection

## Architecture

```
scrcpy-ios/
├── Sources/
│   ├── Core/               # Official scrcpy core (unchanged)
│   │   ├── adb/
│   │   ├── control/
│   │   ├── video/
│   │   ├── demuxer/
│   │   ├── common/
│   │   └── util/
│   │
│   └── Platform/
│       └── iOS/            # iOS platform layer
│           ├── App/
│           ├── UI/
│           ├── Renderer/
│           ├── Decoder/
│           ├── Input/
│           ├── Network/
│           ├── VirtualDisplay/
│           └── Settings/
│
├── Resources/
└── Makefile
```

## Technical Details

### Video Pipeline
```
Android Screen
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

### Touch Input
```
UITouch
    ↓
Coordinate Mapping
    ↓
Control Message
    ↓
ADB
    ↓
Android Input
```

## Performance

- Target: 720p @ 30 FPS
- Memory usage: < 200MB
- Latency: < 120ms

## License

This project is based on [scrcpy](https://github.com/Genymobile/scrcpy) by Genymobile.

## Credits

- Genymobile for scrcpy
- Coolstar for Chimera jailbreak
- Theos team for the build system
