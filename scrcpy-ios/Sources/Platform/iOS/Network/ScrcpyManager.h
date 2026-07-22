/**
 * ScrcpyManager.h
 *
 * Objective-C wrapper for scrcpy core functionality.
 */

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, ScrcpyState) {
    ScrcpyStateDisconnected = 0,
    ScrcpyStateConnecting,
    ScrcpyStateConnected,
    ScrcpyStateStreaming,
    ScrcpyStateError
};

typedef struct {
    int maxWidth;
    int bitRate;
    int maxFps;
    BOOL stayAwake;
    BOOL turnScreenOff;
} ScrcpyOptions;

@protocol ScrcpyManagerDelegate <NSObject>

- (void)scrcpyManager:(id)manager didChangeState:(ScrcpyState)state;
- (void)scrcpyManager:(id)manager didReceiveVideoData:(NSData *)data pts:(uint64_t)pts;
- (void)scrcpyManager:(id)manager didError:(NSError *)error;

@end

@interface ScrcpyManager : NSObject

@property (nonatomic, weak) id<ScrcpyManagerDelegate> delegate;
@property (nonatomic, readonly) ScrcpyState state;
@property (nonatomic, readonly) int deviceWidth;
@property (nonatomic, readonly) int deviceHeight;

- (instancetype)initWithOptions:(ScrcpyOptions)options;
- (BOOL)startWithHost:(NSString *)host port:(int)port;
- (void)stop;
- (BOOL)isStreaming;

// Control
- (void)sendTouchAt:(int)x y:(int)y action:(int)action;
- (void)sendKey:(int)keycode action:(int)action;
- (void)sendText:(NSString *)text;
- (void)sendScrollX:(int)x y:(int)y;

// Preset keys
- (void)sendBack;
- (void)sendHome;
- (void)sendPower;
- (void)sendVolumeUp;
- (void)sendVolumeDown;

@end
