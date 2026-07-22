/**
 * ADBManager.m
 *
 * ADB connection manager implementation.
 * Handles WiFi ADB connections and command execution.
 */

#import "ADBManager.h"

@interface ADBManager ()

@property (nonatomic, assign) int socket;
@property (nonatomic, strong) NSString *connectedIP;
@property (nonatomic, assign) BOOL connected;
@property (nonatomic, assign) int localId;

@end

@implementation ADBManager

- (instancetype)init {
    self = [super init];
    if (self) {
        _socket = -1;
        _connected = NO;
        _localId = 1;
    }
    return self;
}

- (void)dealloc {
    [self disconnect];
}

#pragma mark - Connection

- (BOOL)connectToIP:(NSString *)ip {
    if (self.connected) {
        [self disconnect];
    }

    NSLog(@"[ADBManager] Connecting to %@", ip);

    // Parse IP and port
    NSArray *components = [ip componentsSeparatedByString:@":"];
    NSString *host = components[0];
    int port = 5555;
    if (components.count > 1) {
        port = [components[1] intValue];
    }

    // Create socket
    self.socket = socket(AF_INET, SOCK_STREAM, 0);
    if (self.socket < 0) {
        NSLog(@"[ADBManager] Failed to create socket");
        return NO;
    }

    // Set socket options
    int reuse = 1;
    setsockopt(self.socket, SOL_SOCKET, SO_REUSEADDR, &reuse, sizeof(reuse));

    // Resolve host
    struct hostent *server = gethostbyname([host UTF8String]);
    if (!server) {
        NSLog(@"[ADBManager] Failed to resolve host: %@", host);
        close(self.socket);
        self.socket = -1;
        return NO;
    }

    // Connect
    struct sockaddr_in serverAddr;
    memset(&serverAddr, 0, sizeof(serverAddr));
    serverAddr.sin_family = AF_INET;
    serverAddr.sin_port = htons(port);
    memcpy(&serverAddr.sin_addr.s_addr, server->h_addr, server->h_length);

    if (connect(self.socket, (struct sockaddr *)&serverAddr, sizeof(serverAddr)) < 0) {
        NSLog(@"[ADBManager] Failed to connect to %@:%d", host, port);
        close(self.socket);
        self.socket = -1;
        return NO;
    }

    self.connectedIP = ip;
    self.connected = YES;
    NSLog(@"[ADBManager] Connected to %@", ip);

    return YES;
}

- (void)disconnect {
    if (self.socket >= 0) {
        close(self.socket);
        self.socket = -1;
    }
    self.connected = NO;
    self.connectedIP = nil;
    NSLog(@"[ADBManager] Disconnected");
}

- (BOOL)isConnected {
    return self.connected;
}

- (int)getSocket {
    return self.socket;
}

#pragma mark - ADB Commands

- (NSArray *)getDevices {
    if (!self.connected) return @[];

    // Execute adb devices
    NSString *output = [self executeCommand:@"devices"];
    NSMutableArray *devices = [NSMutableArray array];

    NSArray *lines = [output componentsSeparatedByString:@"\n"];
    for (NSString *line in lines) {
        if ([line containsString:@"device"] && ![line containsString:@"List"]) {
            NSArray *parts = [line componentsSeparatedByString:@"\t"];
            if (parts.count >= 2) {
                [devices addObject:@{
                    @"serial": parts[0],
                    @"status": parts[1]
                }];
            }
        }
    }

    return devices;
}

- (BOOL)pushFile:(NSString *)localPath toRemote:(NSString *)remotePath {
    if (!self.connected) return NO;

    // Check if file exists
    if (![[NSFileManager defaultManager] fileExistsAtPath:localPath]) {
        NSLog(@"[ADBManager] Local file not found: %@", localPath);
        return NO;
    }

    // Read file data
    NSData *fileData = [NSData dataWithContentsOfFile:localPath];
    if (!fileData) {
        NSLog(@"[ADBManager] Failed to read file: %@", localPath);
        return NO;
    }

    NSLog(@"[ADBManager] Pushing file: %@ (%lu bytes)", localPath, (unsigned long)fileData.length);

    // TODO: Implement actual ADB SYNC protocol for file push
    // For now, return success as placeholder
    return YES;
}

- (BOOL)forwardPort:(int)localPort toRemote:(int)remotePort {
    if (!self.connected) return NO;

    NSLog(@"[ADBManager] Forwarding TCP:%d to TCP:%d", localPort, remotePort);

    // Build forward command
    NSString *forwardKey = [NSString stringWithFormat:@"tcp:%d", localPort];
    NSString *forwardValue = [NSString stringWithFormat:@"tcp:%d", remotePort];

    // Send forward command
    NSString *command = [NSString stringWithFormat:@"forward:%@:%@", forwardKey, forwardValue];
    NSString *output = [self executeCommand:command];

    NSLog(@"[ADBManager] Forward result: %@", output);
    return YES;
}

- (BOOL)startServer {
    if (!self.connected) return NO;

    // Push scrcpy-server.jar
    NSString *serverPath = [[NSBundle mainBundle] pathForResource:@"scrcpy-server" ofType:@"jar"];
    if (!serverPath) {
        NSLog(@"[ADBManager] scrcpy-server.jar not found in bundle");
        return NO;
    }

    BOOL pushed = [self pushFile:serverPath toRemote:@"/sdcard/scrcpy-server.jar"];
    if (!pushed) {
        NSLog(@"[ADBManager] Failed to push scrcpy-server.jar");
        return NO;
    }

    // Start server
    NSString *startCommand = @"shell CLASSPATH=/sdcard/scrcpy-server.jar app_process / com.genymobile.scrcpy.Server 1.24 720 2000000 30 - false - -";
    NSString *output = [self executeCommand:startCommand];

    NSLog(@"[ADBManager] Server started: %@", output);
    return YES;
}

#pragma mark - Command Execution

- (NSString *)executeCommand:(NSString *)command {
    if (!self.connected) return @"";

    NSLog(@"[ADBManager] Executing command: %@", command);

    // TODO: Implement actual ADB protocol communication
    // For now, return placeholder
    return @"OK";
}

@end
