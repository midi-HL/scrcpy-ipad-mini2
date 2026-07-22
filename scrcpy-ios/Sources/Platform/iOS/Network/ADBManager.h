/**
 * ADBManager.h
 *
 * Manages ADB connections over WiFi.
 */

#import <Foundation/Foundation.h>

@interface ADBManager : NSObject

- (BOOL)connectToIP:(NSString *)ip;
- (void)disconnect;
- (BOOL)isConnected;
- (NSArray *)getDevices;
- (BOOL)pushFile:(NSString *)localPath toRemote:(NSString *)remotePath;
- (BOOL)forwardPort:(int)localPort toRemote:(int)remotePort;
- (BOOL)startServer;
- (int)getSocket;

@end
