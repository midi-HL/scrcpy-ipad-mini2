## Makefile for scrcpy-iOS
## Target: iPad mini 2 (iOS 12.5.7, Chimera jailbreak)
## Architecture: arm64

# Architecture
ARCHS = arm64

# Target SDK - use 12.0 for iOS 12 compatibility
TARGET = iphone:clang:12.0:12.0

# Include Theos
include $(THEOS)/makefiles/common.mk

# Application Name
APPLICATION_NAME = scrcpy-ios

# Source Files - find all .m, .c, .cpp files automatically
$(APPLICATION_NAME)_FILES = $(shell find Sources -name "*.m" -o -name "*.c" -o -name "*.cpp" | sort)

# Frameworks
$(APPLICATION_NAME)_FRAMEWORKS = \
 UIKit \
 Foundation \
 OpenGLES \
 VideoToolbox \
 CoreMedia \
 CoreVideo \
 QuartzCore

# Compiler Flags
$(APPLICATION_NAME)_CFLAGS = \
	-fobjc-arc \
	-ISources/Core \
	-ISources/Core/adb \
	-ISources/Core/control \
	-ISources/Core/video \
	-ISources/Core/demuxer \
	-ISources/Core/common \
	-ISources/Core/util \
	-ISources/Platform/iOS \
	-ISources/Platform/iOS/App \
	-ISources/Platform/iOS/UI \
	-ISources/Platform/iOS/Renderer \
	-ISources/Platform/iOS/Decoder \
	-ISources/Platform/iOS/Input \
	-ISources/Platform/iOS/Network \
	-ISources/Platform/iOS/VirtualDisplay \
	-ISources/Platform/iOS/Settings

# Linker Flags
$(APPLICATION_NAME)_LDFLAGS = -ObjC

# Debug mode (set to 1 for debug builds)
DEBUG ?= 0

ifeq ($(DEBUG),1)
$(APPLICATION_NAME)_CFLAGS += -DDEBUG -g -O0
endif

# Optimization for release
ifeq ($(DEBUG),0)
$(APPLICATION_NAME)_CFLAGS += -O2
endif

# Include Theos application rules
include $(THEOS_MAKE_PATH)/application.mk
