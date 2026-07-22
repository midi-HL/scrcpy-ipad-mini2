/**
 * IOSDecoder.h
 *
 * VideoToolbox H264 hardware decoder.
 */

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>

@protocol IOSDecoderDelegate <NSObject>

- (void)renderPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

@interface IOSDecoder : NSObject

@property (nonatomic, weak) id<IOSDecoderDelegate> delegate;

- (void)startWithMaxSize:(int)maxSize maxFps:(int)maxFps;
- (void)stop;
- (void)decodeNALU:(const uint8_t *)nalu length:(size_t)length;

@end
