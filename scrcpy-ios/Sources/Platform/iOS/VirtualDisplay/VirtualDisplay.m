/**
 * VirtualDisplay.m
 *
 * Virtual display framebuffer implementation.
 * Maintains a copy of the current frame for external display output.
 */

#import "VirtualDisplay.h"

@interface VirtualDisplay ()

@property (nonatomic, assign) CVPixelBufferRef currentFrame;
@property (nonatomic, strong) dispatch_queue_t queue;

@end

@implementation VirtualDisplay

- (instancetype)initWithWidth:(int)width height:(int)height {
    self = [super init];
    if (self) {
        _width = width;
        _height = height;
        _format = kCVPixelFormatType_32BGRA;
        _queue = dispatch_queue_create("com.scrcpy.virtualdisplay", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)dealloc {
    if (_currentFrame) {
        CVPixelBufferRelease(_currentFrame);
    }
}

#pragma mark - Public Methods

- (void)updateFrame:(CVPixelBufferRef)pixelBuffer {
    dispatch_sync(self.queue, ^{
        if (self.currentFrame) {
            CVPixelBufferRelease(self.currentFrame);
            self.currentFrame = NULL;
        }

        if (pixelBuffer) {
            self.currentFrame = CVPixelBufferRetain(pixelBuffer);

            // Update dimensions if changed
            size_t newWidth = CVPixelBufferGetWidth(pixelBuffer);
            size_t newHeight = CVPixelBufferGetHeight(pixelBuffer);
            if (self.width != newWidth || self.height != newHeight) {
                self.width = (int)newWidth;
                self.height = (int)newHeight;
            }
        }
    });
}

- (CVPixelBufferRef)getCurrentFrame {
    __block CVPixelBufferRef frame = NULL;
    dispatch_sync(self.queue, ^{
        frame = self.currentFrame ? CVPixelBufferRetain(self.currentFrame) : NULL;
    });
    return frame;
}

- (void)renderToView:(UIView *)view {
    CVPixelBufferRef frame = [self getCurrentFrame];
    if (!frame) return;

    // Get pixel buffer dimensions
    size_t width = CVPixelBufferGetWidth(frame);
    size_t height = CVPixelBufferGetHeight(frame);

    // Create CGContext from pixel buffer
    CVPixelBufferLockBaseAddress(frame, kCVPixelBufferLock_ReadOnly);
    void *baseAddress = CVPixelBufferGetBaseAddress(frame);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(frame);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(
        baseAddress,
        width,
        height,
        8,
        bytesPerRow,
        colorSpace,
        kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst
    );

    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    UIImage *image = [UIImage imageWithCGImage:quartzImage];

    // Update view on main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 0);
        [image drawInRect:view.bounds];
        UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        // Set as background (placeholder - would use proper rendering in real app)
        view.layer.contents = (__bridge id)scaledImage.CGImage;
    });

    // Cleanup
    CGImageRelease(quartzImage);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    CVPixelBufferUnlockBaseAddress(frame, kCVPixelBufferLock_ReadOnly);
    CVPixelBufferRelease(frame);
}

#pragma mark - Configuration

- (void)setWidth:(int)width height:(int)height {
    self.width = width;
    self.height = height;
}

- (CGSize)getSize {
    return CGSizeMake(self.width, self.height);
}

@end
