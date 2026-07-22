/**
 * ScrcpyAppDelegate.m
 *
 * Application delegate implementation for scrcpy-iOS.
 * Handles application launch and window setup.
 */

#import "ScrcpyAppDelegate.h"
#import "RootViewController.h"

@implementation ScrcpyAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Initialize window
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];

    // Set root view controller
    RootViewController *rootVC = [[RootViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:rootVC];

    self.window.rootViewController = navController;
    [self.window makeKeyAndVisible];

    NSLog(@"[scrcpy-iOS] Application launched successfully");
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    NSLog(@"[scrcpy-iOS] Application will resign active");
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    NSLog(@"[scrcpy-iOS] Application did enter background");
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    NSLog(@"[scrcpy-iOS] Application will enter foreground");
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    NSLog(@"[scrcpy-iOS] Application did become active");
}

- (void)applicationWillTerminate:(UIApplication *)application {
    NSLog(@"[scrcpy-iOS] Application will terminate");
}

@end
