/**
 * IOSRenderer.h
 *
 * OpenGL ES renderer for displaying video frames.
 */

#import <UIKit/UIKit.h>
#import <CoreVideo/CoreVideo.h>

@interface IOSRenderer : NSObject

@property (nonatomic, weak) UIView *targetView;
@property (nonatomic, assign) CGSize videoSize;

- (instancetype)initWithView:(UIView *)view;
- (void)renderPixelBuffer:(CVPixelBufferRef)pixelBuffer;
- (void)resize;
- (CGPoint)mapTouchPoint:(CGPoint)touchPoint toAndroidScreen:(CGSize)androidSize;

@end
