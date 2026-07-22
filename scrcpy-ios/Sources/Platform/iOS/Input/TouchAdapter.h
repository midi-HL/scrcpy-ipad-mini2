/**
 * TouchAdapter.h
 *
 * Converts iOS touch events to Android control messages.
 */

#import <UIKit/UIKit.h>

@class IOSRenderer;

@interface TouchAdapter : NSObject

- (instancetype)initWithRenderer:(IOSRenderer *)renderer;

- (void)handleTouchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event;
- (void)handleTouchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event;
- (void)handleTouchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event;
- (void)handleTouchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event;

@end
