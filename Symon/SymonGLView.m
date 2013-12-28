#import "SymonGLView.h"
#import "Syphon/Syphon.h"
#import <OpenGL/OpenGL.h>
#import <OpenGL/glu.h>

#pragma mark
#pragma mark Private members

@interface SymonGLView ()
{
    SyphonClient *_syphonClient;
}
@end

#pragma mark
#pragma mark Class implementation

@implementation SymonGLView

#pragma mark Server communication

- (void)connect:(NSDictionary *)description;
{
    _syphonClient = [[SyphonClient alloc] initWithServerDescription:description options:nil newFrameHandler:^(SyphonClient *client){
        [self drawView];
    }];
}

#pragma mark NSOpenGLView methods

- (void)prepareOpenGL
{
    [super prepareOpenGL];
    
    // Disable vsync.
    GLint interval = 0;
    [self.openGLContext setValues:&interval forParameter:NSOpenGLCPSwapInterval];
}

#pragma mark NSWindow methods

- (void)drawRect:(NSRect)dirtyRect
{
    [self drawView];
}

#pragma mark Private methods

- (void)drawView
{
    CGLContextObj cglCtx = (CGLContextObj)(self.openGLContext.CGLContextObj);
    
    CGSize size = [self convertSizeToBacking:self.bounds.size];
    
    [self.openGLContext makeCurrentContext];
    
    SyphonImage *image = nil;
    
    if (_syphonClient && _syphonClient.isValid)
    {
        image = [_syphonClient newFrameImageForContext:cglCtx];
    }

    glViewport(0, 0, size.width, size.height);
    
    if (image)
    {
        glDisable(GL_BLEND);
        glEnable(GL_TEXTURE_RECTANGLE_ARB);
        glBindTexture(GL_TEXTURE_RECTANGLE_ARB, image.textureName);
        
        glBegin(GL_QUADS);
        
        glColor3f(1, 1, 1);
        
        NSSize size = image.textureSize;
        glTexCoord2f(0, 0);
        glVertex2f(-1, -1);
        
        glTexCoord2f(size.width, 0);
        glVertex2f(1, -1);
        
        glTexCoord2f(size.width, size.height);
        glVertex2f(1, 1);
        
        glTexCoord2f(0, size.height);
        glVertex2f(-1, 1);
        
        glEnd();
        
        glDisable(GL_TEXTURE_RECTANGLE_ARB);
        glEnable(GL_BLEND);
    }
    else
    {
        glClearColor(0.5f, 0.5f, 0.5f, 0);
        glClear(GL_COLOR_BUFFER_BIT);
    }
    
    image = nil;
    
    CGLFlushDrawable(cglCtx);
}

@end
