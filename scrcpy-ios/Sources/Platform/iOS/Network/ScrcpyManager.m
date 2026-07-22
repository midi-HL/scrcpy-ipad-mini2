/**
 * ScrcpyManager.m
 *
 * Objective-C wrapper implementation for scrcpy core.
 */

#import "ScrcpyManager.h"
#include "scrcpy_core.h"

// Scrcpy keycodes (Android KeyEvent)
#define KEYCODE_HOME            3
#define KEYCODE_BACK            4
#define KEYCODE_POWER           26
#define KEYCODE_VOLUME_UP       24
#define KEYCODE_VOLUME_DOWN     25
#define KEYCODE_APP_SWITCH      187

// Touch actions
#define TOUCH_ACTION_DOWN       0
#define TOUCH_ACTION_UP         1
#define TOUCH_ACTION_MOVE       2

@interface ScrcpyManager ()

@property (nonatomic, assign) ScrcpyState currentState;
@property (nonatomic, assign) int deviceW;
@property (nonatomic, assign) int deviceH;

@end

@implementation ScrcpyManager

- (instancetype)initWithOptions:(ScrcpyOptions)options {
    self = [super init];
    if (self) {
        _currentState = ScrcpyStateDisconnected;

        // Initialize scrcpy core
        scrcpy_init();

        // Set options
        scrcpy_set_max_size(options.maxWidth);
        scrcpy_set_bit_rate(options.bitRate);
        scrcpy_set_max_fps(options.maxFps);
    }
    return self;
}

- (void)dealloc {
    [self stop];
}

#pragma mark - Public Methods

- (BOOL)startWithHost:(NSString *)host port:(int)port {
    if (self.currentState != ScrcpyStateDisconnected) {
        [self stop];
    }

    NSString *serial = [NSString stringWithFormat:@"%@:%d", host, port];

    // Set up options
    scrcpy_options_t options;
    options.max_size = 720;
    options.bit_rate = 2000000;
    options.max_fps = 30;
    options.crop_width = 0;
    options.crop_height = 0;
    options.crop_x = 0;
    options.crop_y = 0;
    options.lock_video_orientation = -1;
    options.stay_awake = 0;
    options.turn_screen_off = 0;
    options.power_off_on_close = 0;
    options.clipboard_autosync = 1;

    // Start scrcpy
    int result = scrcpy_start([serial UTF8String], &options,
                              video_callback, NULL, state_callback,
                              (__bridge void *)self);

    return (result == 0);
}

- (void)stop {
    scrcpy_stop();
    self.currentState = ScrcpyStateDisconnected;
}

- (BOOL)isStreaming {
    return (self.currentState == ScrcpyStateStreaming);
}

#pragma mark - Control Methods

- (void)sendTouchAt:(int)x y:(int)y action:(int)action {
    scrcpy_send_touch(action, x, y, self.deviceWidth, self.deviceHeight);
}

- (void)sendKey:(int)keycode action:(int)action {
    scrcpy_send_key(keycode, action);
}

- (void)sendText:(NSString *)text {
    scrcpy_send_text([text UTF8String]);
}

- (void)sendScrollX:(int)x y:(int)y {
    scrcpy_send_scroll(x, y);
}

- (void)sendBack {
    [self sendKey:KEYCODE_BACK action:1];
    [self sendKey:KEYCODE_BACK action:0];
}

- (void)sendHome {
    [self sendKey:KEYCODE_HOME action:1];
    [self sendKey:KEYCODE_HOME action:0];
}

- (void)sendPower {
    [self sendKey:KEYCODE_POWER action:1];
    [self sendKey:KEYCODE_POWER action:0];
}

- (void)sendVolumeUp {
    [self sendKey:KEYCODE_VOLUME_UP action:1];
    [self sendKey:KEYCODE_VOLUME_UP action:0];
}

- (void)sendVolumeDown {
    [self sendKey:KEYCODE_VOLUME_DOWN action:1];
    [self sendKey:KEYCODE_VOLUME_DOWN action:0];
}

#pragma mark - Properties

- (ScrcpyState)state {
    return self.currentState;
}

- (int)deviceWidth {
    return self.deviceW;
}

- (int)deviceHeight {
    return self.deviceH;
}

#pragma mark - C Callbacks

static void video_callback(const scrcpy_video_packet_t *packet, void *user_data) {
    ScrcpyManager *manager = (__bridge ScrcpyManager *)user_data;

    if (packet && packet->data && packet->size > 0) {
        NSData *data = [NSData dataWithBytes:packet->data length:packet->size];

        dispatch_async(dispatch_get_main_queue(), ^{
            [manager.delegate scrcpyManager:manager didReceiveVideoData:data pts:packet->pts];
        });
    }
}

static void state_callback(int state, void *user_data) {
    ScrcpyManager *manager = (__bridge ScrcpyManager *)user_data;

    ScrcpyState objcState;
    switch (state) {
        case SCRCPY_STATE_DISCONNECTED:
            objcState = ScrcpyStateDisconnected;
            break;
        case SCRCPY_STATE_CONNECTING:
            objcState = ScrcpyStateConnecting;
            break;
        case SCRCPY_STATE_CONNECTED:
            objcState = ScrcpyStateConnected;
            break;
        case SCRCPY_STATE_STREAMING:
            objcState = ScrcpyStateStreaming;
            break;
        case SCRCPY_STATE_ERROR:
            objcState = ScrcpyStateError;
            break;
        default:
            objcState = ScrcpyStateError;
    }

    manager.currentState = objcState;

    dispatch_async(dispatch_get_main_queue(), ^{
        [manager.delegate scrcpyManager:manager didChangeState:objcState];
    });
}

@end
