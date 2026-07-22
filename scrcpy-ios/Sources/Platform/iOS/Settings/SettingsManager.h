/**
 * SettingsManager.h
 *
 * Manages application settings and preferences.
 */

#import <Foundation/Foundation.h>

@interface SettingsManager : NSObject

+ (instancetype)sharedManager;

- (NSString *)valueForKey:(NSString *)key;
- (void)setValue:(NSString *)value forKey:(NSString *)key;

- (BOOL)boolValueForKey:(NSString *)key;
- (void)setBool:(BOOL)value forKey:(NSString *)key;

- (NSArray *)savedDevices;
- (void)setSavedDevices:(NSArray *)devices;

@end
