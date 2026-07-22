/**
 * SettingsManager.m
 *
 * Manages application settings and preferences using NSUserDefaults.
 */

#import "SettingsManager.h"

static NSString * const kSettingsKeyResolution = @"resolution";
static NSString * const kSettingsKeyFrameRate = @"framerate";
static NSString * const kSettingsKeyBitrate = @"bitrate";
static NSString * const kSettingsKeyScaling = @"scaling";
static NSString * const kSettingsKeyFullscreen = @"fullscreen";
static NSString * const kSettingsKeyADBPort = @"adbport";
static NSString * const kSettingsKeyAutoReconnect = @"autoreconnect";
static NSString * const kSettingsKeySavedDevices = @"savedDevices";

@implementation SettingsManager

+ (instancetype)sharedManager {
    static SettingsManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[SettingsManager alloc] init];
        [sharedManager registerDefaults];
    });
    return sharedManager;
}

- (void)registerDefaults {
    NSDictionary *defaults = @{
        kSettingsKeyResolution: @"720p",
        kSettingsKeyFrameRate: @"30 FPS",
        kSettingsKeyBitrate: @"2 Mbps",
        kSettingsKeyScaling: @"Fit",
        kSettingsKeyFullscreen: @YES,
        kSettingsKeyADBPort: @"5555",
        kSettingsKeyAutoReconnect: @YES,
        kSettingsKeySavedDevices: @[]
    };
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

- (NSString *)valueForKey:(NSString *)key {
    return [[NSUserDefaults standardUserDefaults] objectForKey:key];
}

- (void)setValue:(NSString *)value forKey:(NSString *)key {
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)boolValueForKey:(NSString *)key {
    return [[NSUserDefaults standardUserDefaults] boolForKey:key];
}

- (void)setBool:(BOOL)value forKey:(NSString *)key {
    [[NSUserDefaults standardUserDefaults] setBool:value forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSArray *)savedDevices {
    NSArray *devices = [[NSUserDefaults standardUserDefaults] objectForKey:kSettingsKeySavedDevices];
    return devices ?: @[];
}

- (void)setSavedDevices:(NSArray *)devices {
    [[NSUserDefaults standardUserDefaults] setObject:devices forKey:kSettingsKeySavedDevices];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Convenience Methods

- (int)maxSize {
    NSString *resolution = [self valueForKey:kSettingsKeyResolution];
    if ([resolution isEqualToString:@"480p"]) return 480;
    if ([resolution isEqualToString:@"720p"]) return 720;
    if ([resolution isEqualToString:@"1080p"]) return 1080;
    return 0; // Original
}

- (int)maxFps {
    NSString *framerate = [self valueForKey:kSettingsKeyFrameRate];
    if ([framerate isEqualToString:@"15 FPS"]) return 15;
    if ([framerate isEqualToString:@"24 FPS"]) return 24;
    if ([framerate isEqualToString:@"30 FPS"]) return 30;
    if ([framerate isEqualToString:@"60 FPS"]) return 60;
    return 0; // Original
}

- (int)bitRate {
    NSString *bitrate = [self valueForKey:kSettingsKeyBitrate];
    if ([bitrate isEqualToString:@"1 Mbps"]) return 1000000;
    if ([bitrate isEqualToString:@"2 Mbps"]) return 2000000;
    if ([bitrate isEqualToString:@"4 Mbps"]) return 4000000;
    if ([bitrate isEqualToString:@"8 Mbps"]) return 8000000;
    return 2000000; // Default 2 Mbps
}

- (NSString *)adbPort {
    return [self valueForKey:kSettingsKeyADBPort] ?: @"5555";
}

@end
