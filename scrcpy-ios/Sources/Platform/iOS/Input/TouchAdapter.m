/**
 * TouchAdapter.m
 *
 * Converts iOS touch events to Android control messages.
 * Supports tap, long press, and swipe gestures.
 */

#import "TouchAdapter.h"
#import "IOSRenderer.h"

static const NSTimeInterval kLongPressDuration = 0.5;
static const CGFloat kSwipeThreshold = 20.0;

@interface TouchAdapter ()

@property (nonatomic, weak) IOSRenderer *renderer;
@property (nonatomic, strong) NSMutableDictionary *touchStartTime;
@property (nonatomic, strong) NSMutableDictionary *touchStartPoint;
@property (nonatomic, assign) CGSize androidScreenSize;

@end

@implementation TouchAdapter

- (instancetype)initWithRenderer:(IOSRenderer *)renderer {
    self = [super init];
    if (self) {
        _renderer = renderer;
        _touchStartTime = [NSMutableDictionary dictionary];
        _touchStartPoint = [NSMutableDictionary dictionary];
        _androidScreenSize = CGSizeMake(1080, 1920); // Default, will be updated
    }
    return self;
}

#pragma mark - Touch Handling

- (void)handleTouchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        NSValue *key = [NSValue valueWithPointer:(__bridge const void *)touch];
        CGPoint location = [touch locationInView:touch.view];

        self.touchStartTime[key] = [NSDate date];
        self.touchStartPoint[key] = [NSValue valueWithCGPoint:location];
    }
}

- (void)handleTouchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        NSValue *key = [NSValue valueWithPointer:(__bridge const void *)touch];
        CGPoint location = [touch locationInView:touch.view];
        CGPoint startPoint = [self.touchStartPoint[key] CGPointValue];

        // Check if movement exceeds swipe threshold
        CGFloat distance = hypot(location.x - startPoint.x, location.y - startPoint.y);
        if (distance > kSwipeThreshold) {
            // Send swipe action
            [self sendSwipeFrom:startPoint to:location];
            // Update start point for continuous swipe
            self.touchStartPoint[key] = [NSValue valueWithCGPoint:location];
        }
    }
}

- (void)handleTouchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        NSValue *key = [NSValue valueWithPointer:(__bridge const void *)touch];
        NSDate *startTime = self.touchStartTime[key];
        CGPoint startPoint = [self.touchStartPoint[key] CGPointValue];
        CGPoint endPoint = [touch locationInView:touch.view];

        NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:startTime];
        CGFloat distance = hypot(endPoint.x - startPoint.x, endPoint.y - startPoint.y);

        if (distance < kSwipeThreshold) {
            if (duration >= kLongPressDuration) {
                // Long press
                [self sendLongPressAt:startPoint];
            } else {
                // Tap
                [self sendTapAt:startPoint];
            }
        }

        // Cleanup
        [self.touchStartTime removeObjectForKey:key];
        [self.touchStartPoint removeObjectForKey:key];
    }
}

- (void)handleTouchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        NSValue *key = [NSValue valueWithPointer:(__bridge const void *)touch];
        [self.touchStartTime removeObjectForKey:key];
        [self.touchStartPoint removeObjectForKey:key];
    }
}

#pragma mark - Actions

- (void)sendTapAt:(CGPoint)point {
    CGPoint androidPoint = [self.renderer mapTouchPoint:point toAndroidScreen:self.androidScreenSize];
    if (androidPoint.x < 0 || androidPoint.y < 0) return;

    NSLog(@"[scrcpy-iOS] Tap at (%.0f, %.0f) -> Android (%.0f, %.0f)",
          point.x, point.y, androidPoint.x, androidPoint.y);

    // TODO: Send tap control message via ADB
    [self sendControlMessageWithType:@"tap" x:androidPoint.x y:androidPoint.y];
}

- (void)sendLongPressAt:(CGPoint)point {
    CGPoint androidPoint = [self.renderer mapTouchPoint:point toAndroidScreen:self.androidScreenSize];
    if (androidPoint.x < 0 || androidPoint.y < 0) return;

    NSLog(@"[scrcpy-iOS] Long press at (%.0f, %.0f) -> Android (%.0f, %.0f)",
          point.x, point.y, androidPoint.x, androidPoint.y);

    // TODO: Send long press control message via ADB
    [self sendControlMessageWithType:@"longpress" x:androidPoint.x y:androidPoint.y];
}

- (void)sendSwipeFrom:(CGPoint)from to:(CGPoint)to {
    CGPoint androidFrom = [self.renderer mapTouchPoint:from toAndroidScreen:self.androidScreenSize];
    CGPoint androidTo = [self.renderer mapTouchPoint:to toAndroidScreen:self.androidScreenSize];

    if (androidFrom.x < 0 || androidTo.x < 0) return;

    NSLog(@"[scrcpy-iOS] Swipe from (%.0f, %.0f) to (%.0f, %.0f) -> Android (%.0f, %.0f) to (%.0f, %.0f)",
          from.x, from.y, to.x, to.y,
          androidFrom.x, androidFrom.y, androidTo.x, androidTo.y);

    // TODO: Send swipe control message via ADB
    [self sendControlMessageWithType:@"swipe"
                                  x1:androidFrom.x y1:androidFrom.y
                                  x2:androidTo.x y2:androidTo.y];
}

#pragma mark - Control Message

- (void)sendControlMessageWithType:(NSString *)type x:(CGFloat)x y:(CGFloat)y {
    // Placeholder for actual scrcpy control message implementation
    // This will be connected to the core ADB/control module
    NSLog(@"[scrcpy-iOS] Control message: %@ at (%.0f, %.0f)", type, x, y);
}

- (void)sendControlMessageWithType:(NSString *)type
                                x1:(CGFloat)x1 y1:(CGFloat)y1
                                x2:(CGFloat)x2 y2:(CGFloat)y2 {
    // Placeholder for swipe control message
    NSLog(@"[scrcpy-iOS] Control message: %@ from (%.0f, %.0f) to (%.0f, %.0f)", type, x1, y1, x2, y2);
}

@end
