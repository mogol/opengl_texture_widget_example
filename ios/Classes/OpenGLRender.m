//
//  OpenGLRender.m
//  opengl_texture
//
//  Created by German Saprykin on 22/4/18.
//

#import "OpenGLRender.h"
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface OpenGLRender()
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) id<OpenGLRenderWorker> worker;
@property (copy, nonatomic) void(^onNewFrame)(void);

@property (nonatomic) GLuint frameBuffer;
@property (nonatomic) GLuint depthBuffer;
@property (nonatomic) CVPixelBufferRef target;
@property (nonatomic) CVOpenGLESTextureCacheRef textureCache;
@property (nonatomic) CVOpenGLESTextureRef texture;
@property (nonatomic) CGSize renderSize;
@property (nonatomic) BOOL running;
@end

@implementation OpenGLRender

- (instancetype)initWithSize:(CGSize)renderSize
                      worker:(id<OpenGLRenderWorker>)worker
                  onNewFrame:(void(^)(void))onNewFrame {
    self = [super init];
    if (self){
        self.renderSize = renderSize;
        self.running = YES;
        self.onNewFrame = onNewFrame;
        self.worker = worker;
        
        NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(run) object:nil];
        thread.name = @"OpenGLRender";
        [thread start];
    }
    return self;
}

- (void)run {
    [self initGL];
    [_worker onCreate];
    
    while (_running) {
        CFTimeInterval loopStart = CACurrentMediaTime();
        
        if ([_worker onDraw]) {
            glFlush();
            dispatch_async(dispatch_get_main_queue(), self.onNewFrame);
        }
        
        CFTimeInterval waitDelta = 0.016 - (CACurrentMediaTime() - loopStart);
        if (waitDelta > 0) {
            [NSThread sleepForTimeInterval:waitDelta];
        }
    }
    [_worker onDispose];
    [self deinitGL];
}

#pragma mark - Public

- (void)dispose {
    _running = NO;
}

#pragma mark - FlutterTexture

- (nonnull CVPixelBufferRef)copyPixelBuffer {
    CVBufferRetain(_target);
    return _target;
}

#pragma mark - Private

- (void)initGL {
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    [EAGLContext setCurrentContext:_context];
    [self createCVBufferWithSize:_renderSize withRenderTarget:&_target withTextureOut:&_texture];
    
    glBindTexture(CVOpenGLESTextureGetTarget(_texture), CVOpenGLESTextureGetName(_texture));
    
    glTexImage2D(GL_TEXTURE_2D,
                 0, GL_RGBA,
                 _renderSize.width, _renderSize.height,
                 0, GL_RGBA,
                 GL_UNSIGNED_BYTE, NULL);
    
    glGenRenderbuffers(1, &_depthBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _depthBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, _renderSize.width, _renderSize.height);
    
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(_texture), 0);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthBuffer);
    
    if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    }
}

- (void)createCVBufferWithSize:(CGSize)size
              withRenderTarget:(CVPixelBufferRef *)target
                withTextureOut:(CVOpenGLESTextureRef *)texture {
    
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _context, NULL, &_textureCache);
    
    if (err) return;
    
    CFDictionaryRef empty;
    CFMutableDictionaryRef attrs;
    empty = CFDictionaryCreate(kCFAllocatorDefault,
                               NULL,
                               NULL,
                               0,
                               &kCFTypeDictionaryKeyCallBacks,
                               &kCFTypeDictionaryValueCallBacks);
    
    attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1,
                                      &kCFTypeDictionaryKeyCallBacks,
                                      &kCFTypeDictionaryValueCallBacks);
    
    CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
    CVPixelBufferCreate(kCFAllocatorDefault, size.width, size.height,
                        kCVPixelFormatType_32BGRA, attrs, target);
    
    CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                 _textureCache,
                                                 *target,
                                                 NULL, // texture attributes
                                                 GL_TEXTURE_2D,
                                                 GL_RGBA, // opengl format
                                                 size.width,
                                                 size.height,
                                                 GL_BGRA, // native iOS format
                                                 GL_UNSIGNED_BYTE,
                                                 0,
                                                 texture);
    
    CFRelease(empty);
    CFRelease(attrs);
}

- (void)deinitGL {
    glDeleteFramebuffers(1, &_frameBuffer);
    glDeleteFramebuffers(1, &_depthBuffer);
    CFRelease(_target);
    CFRelease(_textureCache);
    CFRelease(_texture);
}

@end
