/**
 * scrcpy-iOS Main Entry Point
 *
 * This file contains the main function for the scrcpy-iOS application.
 * The application is built using Theos for iOS 12.5.7 (Chimera jailbreak).
 */

#import <UIKit/UIKit.h>
#import "ScrcpyAppDelegate.h"

int main(int argc, char * argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([ScrcpyAppDelegate class]));
    }
}
