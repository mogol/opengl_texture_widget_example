//
//  OpenGLRender.h
//  opengl_texture
//
//  Created by German Saprykin on 22/4/18.
//

#import <Flutter/Flutter.h>

@protocol OpenGLRenderWorker<NSObject>
- (void)onCreate;
- (BOOL)onDraw;
- (void)onDispose;
@end

@interface OpenGLRender : NSObject<FlutterTexture>

- (instancetype)initWithSize:(CGSize)renderSize
                      worker:(id<OpenGLRenderWorker>)worker
                  onNewFrame:(void(^)(void))onNewFrame;

- (void)dispose;

@end
