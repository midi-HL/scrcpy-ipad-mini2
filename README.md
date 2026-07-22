# scrcpy-iOS for iPad mini 2

Scrcpy client ported to iOS 12 - remote control Android devices from iPad mini 2 (Chimera jailbreak).

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
- Android device with USB debugging enabled

## Installation

### Download Pre-built Deb

1. Go to [Actions](https://github.com/midi-HL/scrcpy-ipad-mini2/actions)
2. Click on the latest successful build
3. Download `iOS12-deb-package` artifact
4. Install the deb file on your iPad

### Build from Source

```bash
# Clone repository
git clone https://github.com/midi-HL/scrcpy-ipad-mini2.git
cd scrcpy-ipad-mini2/scrcpy-ios

# Install Theos (if not installed)
git clone --recursive https://github.com/theos/theos.git
export THEOS=~/theos

# Build
make clean
make package

# Install
scp packages/scrcpy-ios_*.deb root@<iPad-IP>:/tmp/
ssh root@<iPad-IP>
dpkg -i /tmp/scrcpy-ios_*.deb
killall SpringBoard
```

## Usage

1. Launch scrcpy-iOS on your iPad
2. Tap "+" to add Android device
3. Enter IP:Port (e.g., 192.168.1.100:5555)
4. Select device to connect
5. Start controlling Android!

## Settings

| Setting | Options | Default |
|---------|---------|---------|
| Resolution | 480p, 720p, 1080p, Original | 720p |
| Frame Rate | 15, 24, 30, 60 FPS | 30 FPS |
| Bitrate | 1, 2, 4, 8 Mbps | 2 Mbps |
| Scaling | Fit, Stretch, Crop | Fit |

## Architecture

```
scrcpy-ios/
├── Sources/
│   ├── Core/           # Official scrcpy core
│   │   ├── adb/        # ADB protocol
│   │   ├── control/    # Control messages
│   │   └── video/      # Video stream
│   │
│   └── Platform/iOS/   # iOS platform layer
│       ├── App/        # Application
│       ├── UI/         # Interface
│       ├── Renderer/   # OpenGL ES
│       ├── Decoder/    # VideoToolbox
│       └── Network/    # ADB/Server
│
└── Resources/          # Assets
```

## License

Based on [scrcpy](https://github.com/Genymobile/scrcpy) by Genymobile.

## Credits

- Genymobile for scrcpy
- Coolstar for Chimera jailbreak
- Theos team for build system
