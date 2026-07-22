/**
 * VirtualDisplay.h
 *
 * Virtual display framebuffer for Android screen mirroring.
 */

#import <UIKit/UIKit.h>
#import <CoreVideo/CoreVideo.h>

@interface VirtualDisplay : NSObject

@property (nonatomic, assign) int width;
@property (nonatomic, assign) int height;
@property (nonatomic, assign) int format;

- (instancetype)initWithWidth:(int)width height:(int)height;
- (void)updateFrame:(CVPixelBufferRef)pixelBuffer;
- (CVPixelBufferRef)getCurrentFrame;
- (void)renderToView:(UIView *)view;

@end
