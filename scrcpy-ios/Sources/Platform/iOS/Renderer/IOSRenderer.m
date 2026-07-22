/**
 * IOSRenderer.m
 *
 * OpenGL ES renderer implementation for displaying video frames.
 * Uses CVOpenGLESTextureCache for efficient pixel buffer to texture conversion.
 */

#import "IOSRenderer.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface IOSRenderer ()

@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic, assign) GLuint framebuffer;
@property (nonatomic, assign) GLuint colorRenderbuffer;
@property (nonatomic, assign) GLuint program;
@property (nonatomic, assign) GLint uniformTexture;
@property (nonatomic, assign) CGRect displayRect;
@property (nonatomic, assign) CGRect videoRect;
@property (nonatomic, strong) CVOpenGLESTextureCacheRef textureCache;

@end

@implementation IOSRenderer

- (instancetype)initWithView:(UIView *)view {
    self = [super init];
    if (self) {
        _targetView = view;
        [self setupGL];
    }
    return self;
}

- (void)dealloc {
    [self cleanupGL];
}

#pragma mark - Setup

- (void)setupGL {
    // Create OpenGL ES context
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:self.context];

    // Create framebuffer
    glGenFramebuffers(1, &_framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, self.framebuffer);

    // Create color renderbuffer
    glGenRenderbuffers(1, &_colorRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, self.colorRenderbuffer);
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.targetView.layer];
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.colorRenderbuffer);

    // Check framebuffer status
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"[scrcpy-iOS] Framebuffer incomplete: %x", status);
    }

    // Create texture cache
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, self.context, NULL, &_textureCache);
    if (err != kCVReturnSuccess) {
        NSLog(@"[scrcpy-iOS] Error creating texture cache: %d", err);
    }

    // Setup shader program
    [self setupShaders];

    NSLog(@"[scrcpy-iOS] OpenGL ES renderer initialized");
}

- (void)setupShaders {
    // Vertex shader
    const char *vertexShaderSource =
        "attribute vec4 position;\n"
        "attribute vec2 texCoord;\n"
        "varying vec2 vTexCoord;\n"
        "void main() {\n"
        "    gl_Position = position;\n"
        "    vTexCoord = texCoord;\n"
        "}\n";

    // Fragment shader
    const char *fragmentShaderSource =
        "precision mediump float;\n"
        "varying vec2 vTexCoord;\n"
        "uniform sampler2D texture;\n"
        "void main() {\n"
        "    gl_FragColor = texture2D(texture, vTexCoord);\n"
        "}\n";

    // Compile shaders
    GLuint vertexShader = [self compileShader:vertexShaderSource type:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:fragmentShaderSource type:GL_FRAGMENT_SHADER];

    // Create program
    self.program = glCreateProgram();
    glAttachShader(self.program, vertexShader);
    glAttachShader(self.program, fragmentShader);
    glLinkProgram(self.program);

    // Check link status
    GLint linkStatus;
    glGetProgramiv(self.program, GL_LINK_STATUS, &linkStatus);
    if (linkStatus == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(self.program, sizeof(messages), 0, &messages[0]);
        NSLog(@"[scrcpy-iOS] Shader link error: %s", messages);
    }

    // Get uniform location
    self.uniformTexture = glGetUniformLocation(self.program, "texture");

    // Cleanup shaders
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
}

- (GLuint)compileShader:(const char *)source type:(GLenum)type {
    GLuint shader = glCreateShader(type);
    glShaderSource(shader, 1, &source, NULL);
    glCompileShader(shader);

    GLint compileStatus;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compileStatus);
    if (compileStatus == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shader, sizeof(messages), 0, &messages[0]);
        NSLog(@"[scrcpy-iOS] Shader compile error: %s", messages);
    }

    return shader;
}

#pragma mark - Rendering

- (void)renderPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    if (!pixelBuffer) return;

    [EAGLContext setCurrentContext:self.context];

    // Get pixel buffer dimensions
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);

    // Update video size if changed
    CGSize newSize = CGSizeMake(width, height);
    if (!CGSizeEqualToSize(self.videoSize, newSize)) {
        self.videoSize = newSize;
        [self calculateDisplayRect];
    }

    // Create texture from pixel buffer
    CVOpenGLESTextureRef texture = NULL;
    CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(
        kCFAllocatorDefault,
        self.textureCache,
        pixelBuffer,
        NULL,
        GL_TEXTURE_2D,
        GL_RGBA,
        (GLsizei)width,
        (GLsizei)height,
        GL_BGRA,
        GL_UNSIGNED_BYTE,
        0,
        &texture
    );

    if (err != kCVReturnSuccess || !texture) {
        NSLog(@"[scrcpy-iOS] Error creating texture: %d", err);
        return;
    }

    // Bind texture
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, CVOpenGLESTextureGetName(texture));
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    // Render
    [self render];

    // Cleanup
    CFRelease(texture);
    CVOpenGLESTextureCacheFlush(self.textureCache, 0);

    // Present
    glBindRenderbuffer(GL_RENDERBUFFER, self.colorRenderbuffer);
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)render {
    // Set viewport to display rect
    glViewport(
        self.displayRect.origin.x,
        self.displayRect.origin.y,
        self.displayRect.size.width,
        self.displayRect.size.height
    );

    // Clear
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);

    // Use program
    glUseProgram(self.program);

    // Vertex data
    GLfloat vertices[] = {
        -1.0f, -1.0f,
         1.0f, -1.0f,
        -1.0f,  1.0f,
         1.0f,  1.0f,
    };

    GLfloat texCoords[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
    };

    // Set vertex attribute
    GLint positionAttr = glGetAttribLocation(self.program, "position");
    glEnableVertexAttribArray(positionAttr);
    glVertexAttribPointer(positionAttr, 2, GL_FLOAT, GL_FALSE, 0, vertices);

    // Set texture coordinate attribute
    GLint texCoordAttr = glGetAttribLocation(self.program, "texCoord");
    glEnableVertexAttribArray(texCoordAttr);
    glVertexAttribPointer(texCoordAttr, 2, GL_FLOAT, GL_FALSE, 0, texCoords);

    // Set texture uniform
    glUniform1i(self.uniformTexture, 0);

    // Draw
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    // Cleanup
    glDisableVertexAttribArray(positionAttr);
    glDisableVertexAttribArray(texCoordAttr);
}

#pragma mark - Display Rect Calculation

- (void)calculateDisplayRect {
    if (self.videoSize.width == 0 || self.videoSize.height == 0) return;

    CGFloat viewWidth = self.targetView.bounds.size.width;
    CGFloat viewHeight = self.targetView.bounds.size.height;
    CGFloat videoWidth = self.videoSize.width;
    CGFloat videoHeight = self.videoSize.height;

    CGFloat viewRatio = viewWidth / viewHeight;
    CGFloat videoRatio = videoWidth / videoHeight;

    CGFloat displayX, displayY, displayWidth, displayHeight;

    if (videoRatio > viewRatio) {
        // Video is wider, fit height
        displayWidth = viewWidth;
        displayHeight = viewWidth / videoRatio;
        displayX = 0;
        displayY = (viewHeight - displayHeight) / 2;
    } else {
        // Video is taller, fit width
        displayHeight = viewHeight;
        displayWidth = viewHeight * videoRatio;
        displayX = (viewWidth - displayWidth) / 2;
        displayY = 0;
    }

    self.displayRect = CGRectMake(displayX, displayY, displayWidth, displayHeight);
    self.videoRect = CGRectMake(displayX, displayY, displayWidth, displayHeight);
}

- (void)resize {
    [EAGLContext setCurrentContext:self.context];

    // Recreate renderbuffer
    glBindRenderbuffer(GL_RENDERBUFFER, self.colorRenderbuffer);
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.targetView.layer];

    // Recalculate display rect
    [self calculateDisplayRect];
}

#pragma mark - Touch Mapping

- (CGPoint)mapTouchPoint:(CGPoint)touchPoint toAndroidScreen:(CGSize)androidSize {
    // Check if touch is in valid area
    if (!CGRectContainsPoint(self.videoRect, touchPoint)) {
        return CGPointMake(-1, -1);
    }

    // Calculate relative position within video rect
    CGFloat relX = touchPoint.x - self.videoRect.origin.x;
    CGFloat relY = touchPoint.y - self.videoRect.origin.y;

    // Scale to Android screen size
    CGFloat scaleX = androidSize.width / self.videoRect.size.width;
    CGFloat scaleY = androidSize.height / self.videoRect.size.height;

    return CGPointMake(relX * scaleX, relY * scaleY);
}

#pragma mark - Cleanup

- (void)cleanupGL {
    if (self.textureCache) {
        CFRelease(self.textureCache);
        self.textureCache = NULL;
    }

    if (self.program) {
        glDeleteProgram(self.program);
    }

    if (self.colorRenderbuffer) {
        glDeleteRenderbuffers(1, &_colorRenderbuffer);
    }

    if (self.framebuffer) {
        glDeleteFramebuffers(1, &_framebuffer);
    }

    [EAGLContext setCurrentContext:nil];
}

@end
