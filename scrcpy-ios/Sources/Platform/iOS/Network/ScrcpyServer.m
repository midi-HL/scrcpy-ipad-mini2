/**
 * ScrcpyServer.m
 *
 * Complete scrcpy-server management implementation.
 * Uses full ADB protocol to push and start the server.
 */

#import "ScrcpyServer.h"
#include "adb_full.h"
#include "scrcpy_core.h"

// Video and control ports used by scrcpy-server
#define SCRCPY_VIDEO_PORT   7100
#define SCRCPY_CONTROL_PORT 7101

@interface ScrcpyServer ()

@property (nonatomic, assign) adb_handle_t *adbHandle;
@property (nonatomic, assign) int videoSock;
@property (nonatomic, assign) int controlSock;
@property (nonatomic, assign) BOOL running;
@property (nonatomic, strong) NSThread *videoThread;
@property (nonatomic, strong) NSThread *controlThread;

@end

@implementation ScrcpyServer

- (instancetype)init {
    self = [super init];
    if (self) {
        _videoSock = -1;
        _controlSock = -1;
        _running = NO;

        // Initialize ADB library
        adb_init();
    }
    return self;
}

- (void)dealloc {
    [self stop];
    adb_cleanup();
}

#pragma mark - Public Methods

- (BOOL)startWithHost:(NSString *)host
                 port:(int)port
             maxSize:(int)maxSize
             bitRate:(int)bitRate
              maxFps:(int)maxFps {

    if (self.running) {
        [self stop];
    }

    NSLog(@"[ScrcpyServer] Starting with host=%@, port=%d", host, port);

    // Connect to ADB daemon
    self.adbHandle = adb_connect([host UTF8String], port);
    if (!self.adbHandle) {
        [self notifyError:@"Failed to connect to ADB daemon"];
        return NO;
    }

    NSLog(@"[ScrcpyServer] ADB connected");

    // Push scrcpy-server.jar
    NSString *serverPath = [[NSBundle mainBundle] pathForResource:@"scrcpy-server" ofType:@"jar"];
    if (!serverPath) {
        [self notifyError:@"scrcpy-server.jar not found in bundle"];
        return NO;
    }

    NSLog(@"[ScrcpyServer] Pushing server to device...");

    // Push to /data/local/tmp/scrcpy-server.jar
    if (adb_push(self.adbHandle, [serverPath UTF8String], "/data/local/tmp/scrcpy-server.jar") < 0) {
        [self notifyError:@"Failed to push scrcpy-server.jar"];
        return NO;
    }

    NSLog(@"[ScrcpyServer] Server pushed successfully");

    // Build server start command
    NSString *serverCmd = [NSString stringWithFormat:
        @"CLASSPATH=/data/local/tmp/scrcpy-server.jar "
        @"app_process / com.genymobile.scrcpy.Server "
        @"%d "           // version
        @"%d "           // maxSize
        @"%d "           // bitRate
        @"%d "           // maxFps
        @"0 "            // lockVideoOrientation
        @"false "        // tunnelForward
        @"- "            // crop
        @"- "            // sendFrameMeta
        @"false",        // control
        SCRCPY_SERVER_VERSION ? 124 : 124,
        maxSize,
        bitRate,
        maxFps];

    NSLog(@"[ScrcpyServer] Starting server: %@", serverCmd);

    // Start server in background
    char output[4096];
    int result = adb_shell(self.adbHandle, [serverCmd UTF8String], output, sizeof(output));

    if (result < 0) {
        [self notifyError:@"Failed to start scrcpy-server"];
        return NO;
    }

    NSLog(@"[ScrcpyServer] Server output: %s", output);

    // Forward ports for video and control
    NSLog(@"[ScrcpyServer] Setting up port forwarding...");

    if (adb_forward(self.adbHandle, SCRCPY_VIDEO_PORT, SCRCPY_VIDEO_PORT) < 0) {
        [self notifyError:@"Failed to forward video port"];
        return NO;
    }

    if (adb_forward(self.adbHandle, SCRCPY_CONTROL_PORT, SCRCPY_CONTROL_PORT) < 0) {
        [self notifyError:@"Failed to forward control port"];
        return NO;
    }

    NSLog(@"[ScrcpyServer] Ports forwarded");

    // Connect to video and control sockets
    self.videoSock = [self connectToLocalPort:SCRCPY_VIDEO_PORT];
    if (self.videoSock < 0) {
        [self notifyError:@"Failed to connect to video socket"];
        return NO;
    }

    self.controlSock = [self connectToLocalPort:SCRCPY_CONTROL_PORT];
    if (self.controlSock < 0) {
        [self notifyError:@"Failed to connect to control socket"];
        return NO;
    }

    NSLog(@"[ScrcpyServer] Connected to video and control sockets");

    self.running = YES;

    // Start video receive thread
    self.videoThread = [[NSThread alloc] initWithTarget:self selector:@selector(videoReceiveLoop) object:nil];
    [self.videoThread start];

    // Start control thread
    self.controlThread = [[NSThread alloc] initWithTarget:self selector:@selector(controlReceiveLoop) object:nil];
    [self.controlThread start];

    [self notifyStarted];
    return YES;
}

- (void)stop {
    if (!self.running) return;

    NSLog(@"[ScrcpyServer] Stopping...");

    self.running = NO;

    // Stop threads
    if (self.videoThread) {
        [self.videoThread cancel];
        self.videoThread = nil;
    }

    if (self.controlThread) {
        [self.controlThread cancel];
        self.controlThread = nil;
    }

    // Close sockets
    if (self.videoSock >= 0) {
        close(self.videoSock);
        self.videoSock = -1;
    }

    if (self.controlSock >= 0) {
        close(self.controlSock);
        self.controlSock = -1;
    }

    // Kill server on device
    if (self.adbHandle) {
        adb_shell(self.adbHandle, "pkill -f scrcpy-server", NULL, 0);
        adb_disconnect(self.adbHandle);
        self.adbHandle = NULL;
    }

    NSLog(@"[ScrcpyServer] Stopped");
}

- (BOOL)isRunning {
    return self.running;
}

- (int)getVideoSocket {
    return self.videoSock;
}

- (int)getControlSocket {
    return self.controlSock;
}

#pragma mark - Private Methods

- (int)connectToLocalPort:(int)port {
    int sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0) return -1;

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    addr.sin_addr.s_addr = inet_addr("127.0.0.1");

    // Retry connection a few times
    for (int i = 0; i < 10; i++) {
        if (connect(sock, (struct sockaddr *)&addr, sizeof(addr)) == 0) {
            NSLog(@"[ScrcpyServer] Connected to port %d", port);
            return sock;
        }
        usleep(100000); // 100ms
    }

    close(sock);
    return -1;
}

- (void)videoReceiveLoop {
    @autoreleasepool {
        NSLog(@"[ScrcpyServer] Video thread started");

        uint8_t header[12]; // 4 size + 8 pts

        while (self.running && ![[NSThread currentThread] isCancelled]) {
            // Receive packet header
            ssize_t received = recv(self.videoSock, header, sizeof(header), MSG_WAITALL);

            if (received <= 0) {
                if (self.running) {
                    NSLog(@"[ScrcpyServer] Video connection lost");
                }
                break;
            }

            // Parse header
            uint32_t packetSize = ntohl(*(uint32_t *)header);
            uint64_t pts = ((uint64_t)ntohl(*(uint32_t *)(header + 4)) << 32) |
                           ntohl(*(uint32_t *)(header + 8));

            // Validate size
            if (packetSize > 10 * 1024 * 1024) {
                NSLog(@"[ScrcpyServer] Invalid packet size: %u", packetSize);
                break;
            }

            // Allocate and receive data
            uint8_t *buffer = malloc(packetSize);
            if (!buffer) continue;

            ssize_t dataReceived = recv(self.videoSock, buffer, packetSize, MSG_WAITALL);
            if (dataReceived != packetSize) {
                free(buffer);
                continue;
            }

            // Check if this is a config packet (first packet with device info)
            static BOOL gotConfig = NO;
            if (!gotConfig && packetSize > 0) {
                // Parse device size from config
                // Config format: [width:2][height:2][cropLeft:2][cropTop:2][cropRight:2][cropBottom:2][rotation:2]
                if (packetSize >= 12) {
                    uint16_t width = ntohs(*(uint16_t *)buffer);
                    uint16_t height = ntohs(*(uint16_t *)(buffer + 2));

                    NSLog(@"[ScrcpyServer] Device size: %dx%d", width, height);

                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.delegate didReceiveConfigWidth:width height:height];
                    });
                }
                gotConfig = YES;
            }

            // Send to delegate
            NSData *videoData = [NSData dataWithBytesNoCopy:buffer length:packetSize freeWhenDone:YES];

            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate didReceiveVideoData:videoData pts:pts];
            });
        }

        NSLog(@"[ScrcpyServer] Video thread stopped");
    }
}

- (void)controlReceiveLoop {
    @autoreleasepool {
        NSLog(@"[ScrcpyServer] Control thread started");

        while (self.running && ![[NSThread currentThread] isCancelled]) {
            // Control thread mainly listens for responses
            usleep(100000); // 100ms
        }

        NSLog(@"[ScrcpyServer] Control thread stopped");
    }
}

#pragma mark - Delegate Notifications

- (void)notifyStarted {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate serverDidStart];
    });
}

- (void)notifyError:(NSString *)message {
    NSError *error = [NSError errorWithDomain:@"ScrcpyServer"
                                         code:-1
                                     userInfo:@{NSLocalizedDescriptionKey: message}];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate serverDidFailWithError:error];
    });
}

@end
