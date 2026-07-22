/**
 * ConnectionViewController.m
 *
 * Displays Android device screen and handles touch input.
 * Uses ScrcpyServer for complete connection management.
 */

#import "ConnectionViewController.h"
#import "ScrcpyServer.h"
#import "IOSRenderer.h"
#import "IOSDecoder.h"
#import "SettingsManager.h"

@interface ConnectionViewController () <ScrcpyServerDelegate>

@property (nonatomic, strong) ScrcpyServer *server;
@property (nonatomic, strong) IOSRenderer *renderer;
@property (nonatomic, strong) IOSDecoder *decoder;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *statsLabel;
@property (nonatomic, strong) UIButton *disconnectButton;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIButton *homeButton;
@property (nonatomic, strong) UIButton *recentButton;
@property (nonatomic, strong) UIView *videoContainer;
@property (nonatomic, assign) BOOL isConnected;
@property (nonatomic, assign) int frameCount;
@property (nonatomic, strong) NSDate *lastStatsUpdate;
@property (nonatomic, assign) CGSize androidScreenSize;

@end

@implementation ConnectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self setupComponents];
    [self connectToDevice];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self disconnect];
}

- (void)setupUI {
    self.view.backgroundColor = [UIColor blackColor];
    self.navigationController.navigationBarHidden = YES;

    // Status Label
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.textColor = [UIColor whiteColor];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.font = [UIFont systemFontOfSize:14];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.statusLabel];

    // Stats Label
    self.statsLabel = [[UILabel alloc] init];
    self.statsLabel.textColor = [UIColor lightGrayColor];
    self.statsLabel.textAlignment = NSTextAlignmentCenter;
    self.statsLabel.font = [UIFont systemFontOfSize:12];
    self.statsLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.statsLabel];

    // Video Container
    self.videoContainer = [[UIView alloc] init];
    self.videoContainer.backgroundColor = [UIColor blackColor];
    self.videoContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.videoContainer];

    // Control buttons container
    UIView *controlContainer = [[UIView alloc] init];
    controlContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:controlContainer];

    // Back Button
    self.backButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.backButton setTitle:@"Back" forState:UIControlStateNormal];
    [self.backButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.backButton.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0];
    self.backButton.layer.cornerRadius = 8;
    self.backButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.backButton addTarget:self action:@selector(backButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [controlContainer addSubview:self.backButton];

    // Home Button
    self.homeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.homeButton setTitle:@"Home" forState:UIControlStateNormal];
    [self.homeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.homeButton.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0];
    self.homeButton.layer.cornerRadius = 8;
    self.homeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.homeButton addTarget:self action:@selector(homeButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [controlContainer addSubview:self.homeButton];

    // Recent Button
    self.recentButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.recentButton setTitle:@"Recent" forState:UIControlStateNormal];
    [self.recentButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.recentButton.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0];
    self.recentButton.layer.cornerRadius = 8;
    self.recentButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.recentButton addTarget:self action:@selector(recentButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [controlContainer addSubview:self.recentButton];

    // Disconnect Button
    self.disconnectButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.disconnectButton setTitle:@"Disconnect" forState:UIControlStateNormal];
    [self.disconnectButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.disconnectButton.backgroundColor = [UIColor colorWithRed:0.8 green:0.2 blue:0.2 alpha:1.0];
    self.disconnectButton.layer.cornerRadius = 8;
    self.disconnectButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.disconnectButton addTarget:self action:@selector(disconnectTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.disconnectButton];

    // Layout
    [NSLayoutConstraint activateConstraints:@[
        // Status Label
        [self.statusLabel.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:40],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [self.statusLabel.heightAnchor constraintEqualToConstant:20],

        // Stats Label
        [self.statsLabel.topAnchor constraintEqualToAnchor:self.statusLabel.bottomAnchor constant:4],
        [self.statsLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.statsLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [self.statsLabel.heightAnchor constraintEqualToConstant:16],

        // Video Container
        [self.videoContainer.topAnchor constraintEqualToAnchor:self.statsLabel.bottomAnchor constant:10],
        [self.videoContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.videoContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.videoContainer.bottomAnchor constraintEqualToAnchor:controlContainer.topAnchor constant:-10],

        // Control Container
        [controlContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:10],
        [controlContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-10],
        [controlContainer.bottomAnchor constraintEqualToAnchor:self.disconnectButton.topAnchor constant:-10],
        [controlContainer.heightAnchor constraintEqualToConstant:44],

        // Back Button
        [self.backButton.leadingAnchor constraintEqualToAnchor:controlContainer.leadingAnchor],
        [self.backButton.topAnchor constraintEqualToAnchor:controlContainer.topAnchor],
        [self.backButton.widthAnchor constraintEqualToConstant:80],
        [self.backButton.heightAnchor constraintEqualToConstant:44],

        // Home Button
        [self.homeButton.centerXAnchor constraintEqualToAnchor:controlContainer.centerXAnchor],
        [self.homeButton.topAnchor constraintEqualToAnchor:controlContainer.topAnchor],
        [self.homeButton.widthAnchor constraintEqualToConstant:80],
        [self.homeButton.heightAnchor constraintEqualToConstant:44],

        // Recent Button
        [self.recentButton.trailingAnchor constraintEqualToAnchor:controlContainer.trailingAnchor],
        [self.recentButton.topAnchor constraintEqualToAnchor:controlContainer.topAnchor],
        [self.recentButton.widthAnchor constraintEqualToConstant:80],
        [self.recentButton.heightAnchor constraintEqualToConstant:44],

        // Disconnect Button
        [self.disconnectButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.disconnectButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [self.disconnectButton.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-30],
        [self.disconnectButton.heightAnchor constraintEqualToConstant:44],
    ]];
}

- (void)setupComponents {
    // Initialize renderer
    self.renderer = [[IOSRenderer alloc] initWithView:self.videoContainer];

    // Initialize decoder
    self.decoder = [[IOSDecoder alloc] init];
    self.decoder.delegate = self.renderer;

    // Initialize server
    self.server = [[ScrcpyServer alloc] init];
    self.server.delegate = self;

    // Default screen size
    self.androidScreenSize = CGSizeMake(1080, 1920);

    // Update status
    NSString *deviceName = self.device[@"name"] ?: @"Unknown";
    self.statusLabel.text = [NSString stringWithFormat:@"Connecting to %@...", deviceName];
    self.statsLabel.text = @"";
}

- (void)connectToDevice {
    // Parse IP and port
    NSString *ip = self.device[@"ip"];
    NSArray *components = [ip componentsSeparatedByString:@":"];
    NSString *host = components[0];
    int port = 5555;
    if (components.count > 1) {
        port = [components[1] intValue];
    }

    // Get settings
    SettingsManager *settings = [SettingsManager sharedManager];
    int maxSize = [settings maxSize];
    int maxFps = [settings maxFps];
    int bitRate = [settings bitRate];

    // Start server
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL started = [self.server startWithHost:host port:port
                                        maxSize:maxSize bitRate:bitRate maxFps:maxFps];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (!started) {
                self.statusLabel.text = @"Failed to start server";
            }
        });
    });
}

- (void)disconnect {
    self.isConnected = NO;
    [self.server stop];
    [self.decoder stop];
}

- (void)disconnectTapped {
    [self disconnect];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - ScrcpyServerDelegate

- (void)serverDidStart {
    NSLog(@"[ConnectionVC] Server started");
    self.statusLabel.text = @"Connected, waiting for video...";
    self.lastStatsUpdate = [NSDate date];
    self.frameCount = 0;
}

- (void)serverDidFailWithError:(NSError *)error {
    NSLog(@"[ConnectionVC] Server failed: %@", error.localizedDescription);
    self.statusLabel.text = [NSString stringWithFormat:@"Error: %@", error.localizedDescription];
}

- (void)didReceiveVideoData:(NSData *)data pts:(uint64_t)pts {
    // Decode video frame
    if (data.length > 0) {
        [self.decoder decodeNALU:data.bytes length:data.length];
    }

    // Update stats
    self.frameCount++;
    NSDate *now = [NSDate date];
    NSTimeInterval elapsed = [now timeIntervalSinceDate:self.lastStatsUpdate];

    if (elapsed >= 1.0) {
        int fps = (int)(self.frameCount / elapsed);
        self.statsLabel.text = [NSString stringWithFormat:@"FPS: %d | %dx%d",
                                fps, (int)self.androidScreenSize.width, (int)self.androidScreenSize.height];
        self.frameCount = 0;
        self.lastStatsUpdate = now;
        self.isConnected = YES;
    }
}

- (void)didReceiveConfigWidth:(int)width height:(int)height {
    NSLog(@"[ConnectionVC] Device size: %dx%d", width, height);
    self.androidScreenSize = CGSizeMake(width, height);
}

#pragma mark - Control Buttons

- (void)backButtonTapped {
    NSLog(@"[ConnectionVC] Back button tapped");
    // Send KEYCODE_BACK (4)
    [self sendKey:4];
}

- (void)homeButtonTapped {
    NSLog(@"[ConnectionVC] Home button tapped");
    // Send KEYCODE_HOME (3)
    [self sendKey:3];
}

- (void)recentButtonTapped {
    NSLog(@"[ConnectionVC] Recent button tapped");
    // Send KEYCODE_APP_SWITCH (187)
    [self sendKey:187];
}

- (void)sendKey:(int)keycode {
    int controlSock = [self.server getControlSocket];
    if (controlSock < 0) return;

    // Build key message
    uint8_t msg[9];
    msg[0] = 0; // TYPE_KEYCODE
    uint32_t action = htonl(1); // ACTION_DOWN
    uint32_t key = htonl(keycode);
    memcpy(msg + 1, &action, 4);
    memcpy(msg + 5, &key, 4);

    send(controlSock, msg, sizeof(msg), 0);

    // Send ACTION_UP
    action = htonl(0); // ACTION_UP
    memcpy(msg + 1, &action, 4);
    send(controlSock, msg, sizeof(msg), 0);
}

#pragma mark - Touch Handling

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInView:self.videoContainer];
        [self sendTouchAt:location action:0]; // ACTION_DOWN
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInView:self.videoContainer];
        [self sendTouchAt:location action:2]; // ACTION_MOVE
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInView:self.videoContainer];
        [self sendTouchAt:location action:1]; // ACTION_UP
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInView:self.videoContainer];
        [self sendTouchAt:location action:1]; // ACTION_UP
    }
}

- (void)sendTouchAt:(CGPoint)point action:(int)action {
    int controlSock = [self.server getControlSocket];
    if (controlSock < 0) return;

    // Map touch point to Android coordinates
    CGPoint androidPoint = [self.renderer mapTouchPoint:point toAndroidScreen:self.androidScreenSize];
    if (androidPoint.x < 0 || androidPoint.y < 0) return;

    // Build touch message
    uint8_t msg[14];
    msg[0] = 2; // TYPE_MOUSE
    uint32_t x = htonl((uint32_t)androidPoint.x);
    uint32_t y = htonl((uint32_t)androidPoint.y);
    uint16_t w = htons((uint16_t)self.androidScreenSize.width);
    uint16_t h = htons((uint16_t)self.androidScreenSize.height);
    uint8_t buttons = (action == 0 || action == 2) ? 1 : 0;

    memcpy(msg + 1, &x, 4);
    memcpy(msg + 5, &y, 4);
    memcpy(msg + 9, &w, 2);
    memcpy(msg + 11, &h, 2);
    msg[13] = buttons;

    send(controlSock, msg, sizeof(msg), 0);
}

#pragma mark - IOSDecoderDelegate (via renderer)

- (void)renderPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    [self.renderer renderPixelBuffer:pixelBuffer];
}

#pragma mark - Status Bar

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

@end
