/**
 * ScrcpyServer.h
 *
 * Manages scrcpy-server lifecycle on Android device.
 */

#import <Foundation/Foundation.h>

@protocol ScrcpyServerDelegate <NSObject>

- (void)serverDidStart;
- (void)serverDidFailWithError:(NSError *)error;
- (void)didReceiveVideoData:(NSData *)data pts:(uint64_t)pts;
- (void)didReceiveConfigWidth:(int)width height:(int)height;

@end

@interface ScrcpyServer : NSObject

@property (nonatomic, weak) id<ScrcpyServerDelegate> delegate;
@property (nonatomic, readonly) int videoSocket;
@property (nonatomic, readonly) int controlSocket;

- (BOOL)startWithHost:(NSString *)host
                 port:(int)port
             maxSize:(int)maxSize
             bitRate:(int)bitRate
              maxFps:(int)maxFps;

- (void)stop;
- (BOOL)isRunning;
- (int)getVideoSocket;
- (int)getControlSocket;

@end
