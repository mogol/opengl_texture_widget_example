//
//  SampleRender.m
//  opengl_texture
//
//  Created by German Saprykin on 22/4/18.
//

#import "SampleRenderWorker.h"
#import <OpenGLES/ES2/gl.h>

@interface SampleRenderWorker() {
    CGFloat _tick;
}
@end
@implementation SampleRenderWorker

- (void)onCreate {
    
}

- (BOOL)onDraw {
    _tick = _tick + M_PI / 60;
    CGFloat green = (sin(_tick) + 1) / 2;
    glClearColor(0, green, 0, 1);
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    return YES;
}

- (void)onDispose {
    
}

@end
