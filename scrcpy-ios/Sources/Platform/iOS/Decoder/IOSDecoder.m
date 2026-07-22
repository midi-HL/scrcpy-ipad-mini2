/**
 * IOSDecoder.m
 *
 * VideoToolbox H264 hardware decoder implementation.
 * Receives H264 NAL units and outputs CVPixelBuffer frames.
 */

#import "IOSDecoder.h"
#import <VideoToolbox/VideoToolbox.h>

@interface IOSDecoder ()

@property (nonatomic, assign) VTDecompressionSessionRef decompressionSession;
@property (nonatomic, assign) CMVideoFormatDescriptionRef formatDescription;
@property (nonatomic, strong) NSMutableData *spsData;
@property (nonatomic, strong) NSMutableData *ppsData;
@property (nonatomic, assign) int maxSize;
@property (nonatomic, assign) int maxFps;
@property (nonatomic, assign) BOOL isStarted;

@end

@implementation IOSDecoder

- (instancetype)init {
    self = [super init];
    if (self) {
        _spsData = [NSMutableData data];
        _ppsData = [NSMutableData data];
    }
    return self;
}

- (void)dealloc {
    [self stop];
}

#pragma mark - Public Methods

- (void)startWithMaxSize:(int)maxSize maxFps:(int)maxFps {
    self.maxSize = maxSize;
    self.maxFps = maxFps;
    self.isStarted = YES;
    NSLog(@"[scrcpy-iOS] Decoder started with maxSize=%d, maxFps=%d", maxSize, maxFps);
}

- (void)stop {
    self.isStarted = NO;

    if (self.decompressionSession) {
        VTDecompressionSessionInvalidate(self.decompressionSession);
        CFRelease(self.decompressionSession);
        self.decompressionSession = NULL;
    }

    if (self.formatDescription) {
        CFRelease(self.formatDescription);
        self.formatDescription = NULL;
    }

    NSLog(@"[scrcpy-iOS] Decoder stopped");
}

- (void)decodeNALU:(const uint8_t *)nalu length:(size_t)length {
    if (!self.isStarted || length < 4) return;

    // Parse NALU type
    uint8_t naluType = nalu[0] & 0x1F;

    switch (naluType) {
        case 7: // SPS
            [self handleSPS:nalu length:length];
            break;
        case 8: // PPS
            [self handlePPS:nalu length:length];
            break;
        case 5: // IDR (key frame)
            [self handleIDR:nalu length:length];
            break;
        case 1: // Non-IDR (P/B frame)
            [self handleFrame:nalu length:length];
            break;
        default:
            NSLog(@"[scrcpy-iOS] Unknown NALU type: %d", naluType);
            break;
    }
}

#pragma mark - NALU Handling

- (void)handleSPS:(const uint8_t *)sps length:(size_t)length {
    [self.spsData setData:[NSData dataWithBytes:sps length:length]];
    NSLog(@"[scrcpy-iOS] SPS received, length=%zu", length);

    // Create format description if we have both SPS and PPS
    if (self.ppsData.length > 0) {
        [self createFormatDescription];
    }
}

- (void)handlePPS:(const uint8_t *)pps length:(size_t)length {
    [self.ppsData setData:[NSData dataWithBytes:pps length:length]];
    NSLog(@"[scrcpy-iOS] PPS received, length=%zu", length);

    // Create format description if we have both SPS and PPS
    if (self.spsData.length > 0) {
        [self createFormatDescription];
    }
}

- (void)handleIDR:(const uint8_t *)idr length:(size_t)length {
    if (!self.formatDescription) {
        NSLog(@"[scrcpy-iOS] IDR received but no format description");
        return;
    }

    [self decodeFrame:idr length:length];
}

- (void)handleFrame:(const uint8_t *)frame length:(size_t)length {
    if (!self.formatDescription) {
        return;
    }

    [self decodeFrame:frame length:length];
}

#pragma mark - Format Description

- (void)createFormatDescription {
    // Clean up existing session
    if (self.decompressionSession) {
        VTDecompressionSessionInvalidate(self.decompressionSession);
        CFRelease(self.decompressionSession);
        self.decompressionSession = NULL;
    }

    if (self.formatDescription) {
        CFRelease(self.formatDescription);
        self.formatDescription = NULL;
    }

    // Create parameter set pointers
    const uint8_t *parameterSetPointers[2] = {
        self.spsData.bytes,
        self.ppsData.bytes
    };
    const size_t parameterSetSizes[2] = {
        self.spsData.length,
        self.ppsData.length
    };

    // Create format description
    OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(
        kCFAllocatorDefault,
        2,
        parameterSetPointers,
        parameterSetSizes,
        4,
        &self.formatDescription
    );

    if (status != noErr) {
        NSLog(@"[scrcpy-iOS] Error creating format description: %d", (int)status);
        return;
    }

    NSLog(@"[scrcpy-iOS] Format description created successfully");

    // Create decompression session
    [self createDecompressionSession];
}

- (void)createDecompressionSession {
    // Configure decoder
    NSDictionary *destinationAttributes = @{
        (NSString *)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA),
        (NSString *)kCVPixelBufferOpenGLESCompatibilityKey: @YES
    };

    VTDecompressionOutputCallbackRecord callbackRecord;
    callbackRecord.decompressionOutputCallback = decompressionOutputCallback;
    callbackRecord.decompressionOutputRefCon = (__bridge void *)self;

    OSStatus status = VTDecompressionSessionCreate(
        kCFAllocatorDefault,
        self.formatDescription,
        NULL,
        (__bridge CFDictionaryRef)destinationAttributes,
        &callbackRecord,
        &self.decompressionSession
    );

    if (status != noErr) {
        NSLog(@"[scrcpy-iOS] Error creating decompression session: %d", (int)status);
        return;
    }

    NSLog(@"[scrcpy-iOS] Decompression session created successfully");
}

#pragma mark - Frame Decoding

- (void)decodeFrame:(const uint8_t *)frame length:(size_t)length {
    // Create block buffer
    CMBlockBufferRef blockBuffer = NULL;
    OSStatus status = CMBlockBufferCreateWithMemoryBlock(
        kCFAllocatorDefault,
        NULL,
        length,
        kCFAllocatorDefault,
        NULL,
        0,
        length,
        0,
        &blockBuffer
    );

    if (status != noErr || !blockBuffer) {
        NSLog(@"[scrcpy-iOS] Error creating block buffer: %d", (int)status);
        return;
    }

    // Copy data to block buffer
    status = CMBlockBufferReplaceDataBytes(frame, blockBuffer, 0, length);
    if (status != noErr) {
        NSLog(@"[scrcpy-iOS] Error copying data to block buffer: %d", (int)status);
        CFRelease(blockBuffer);
        return;
    }

    // Create sample buffer
    CMSampleBufferRef sampleBuffer = NULL;
    const size_t sampleSizeArray[] = { length };

    status = CMSampleBufferCreateReady(
        kCFAllocatorDefault,
        blockBuffer,
        self.formatDescription,
        1,
        0, NULL,
        1, sampleSizeArray,
        &sampleBuffer
    );

    CFRelease(blockBuffer);

    if (status != noErr || !sampleBuffer) {
        NSLog(@"[scrcpy-iOS] Error creating sample buffer: %d", (int)status);
        return;
    }

    // Decode
    VTDecodeFrameFlags flags = kVTDecodeFrame_EnableAsynchronousDecompression;
    VTDecodeInfoFlags flagOut;

    status = VTDecompressionSessionDecodeFrame(
        self.decompressionSession,
        sampleBuffer,
        flags,
        NULL,
        &flagOut
    );

    CFRelease(sampleBuffer);

    if (status != noErr) {
        NSLog(@"[scrcpy-iOS] Error decoding frame: %d", (int)status);
    }
}

#pragma mark - Callback

void decompressionOutputCallback(void *decompressionOutputRefCon,
                                 void *sourceFrameRefCon,
                                 OSStatus status,
                                 VTDecodeInfoFlags infoFlags,
                                 CVImageBufferRef imageBuffer,
                                 CMTime presentationTimeStamp,
                                 CMTime presentationDuration) {
    if (status != noErr || !imageBuffer) {
        NSLog(@"[scrcpy-iOS] Decompression error: %d", (int)status);
        return;
    }

    IOSDecoder *decoder = (__bridge IOSDecoder *)decompressionOutputRefCon;

    // Retain the pixel buffer for rendering
    CVPixelBufferRetain(imageBuffer);

    // Send to renderer
    if ([decoder.delegate respondsToSelector:@selector(renderPixelBuffer:)]) {
        [decoder.delegate renderPixelBuffer:imageBuffer];
    }

    CVPixelBufferRelease(imageBuffer);
}

@end
