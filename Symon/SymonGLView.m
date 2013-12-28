#import "SymonGLView.h"
#import <Syphon/Syphon.h>
#import <OpenGL/OpenGL.h>

#pragma mark Private variables

@interface SymonGLView ()
{
    SyphonClient *_syphonClient;
}
@end

#pragma mark
#pragma mark Class implementation

@implementation SymonGLView

#pragma mark Public methods

- (void)connect:(NSDictionary *)description;
{
    // Create a new Syphon client with the server description.
    _syphonClient = [[SyphonClient alloc] initWithServerDescription:description options:nil newFrameHandler:^(SyphonClient *client){
        [self drawSyphonFrame];
    }];
}

#pragma mark NSOpenGLView methods

- (void)prepareOpenGL
{
    [super prepareOpenGL];
    
    // Disable VSync.
    GLint interval = 0;
    [self.openGLContext setValues:&interval forParameter:NSOpenGLCPSwapInterval];
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Clear the window if there is no valid connection.
    if (!_syphonClient || _syphonClient.isValid)
    {
        glClearColor(0.5f, 0.5f, 0.5f, 0);
        glClear(GL_COLOR_BUFFER_BIT);
        [self.openGLContext flushBuffer];
    }
}

#pragma mark Private methods

- (void)drawSyphonFrame
{
    // Activate the GL context.
    [self.openGLContext makeCurrentContext];
    
    // Try to retrieve a frame image from the Syphon client.
    SyphonImage *image = [_syphonClient newFrameImageForContext:self.openGLContext.CGLContextObj];
    
    // Do nothing if it failed.
    if (image == nil) return;
    
    // Retrieve the actual screen size and set it to the viewport.
    CGSize screenSize = [self convertSizeToBacking:self.bounds.size];
    glViewport(0, 0, screenSize.width, screenSize.height);
    
    // Draw context settings.
    glDisable(GL_BLEND);
    glEnable(GL_TEXTURE_RECTANGLE_ARB);
    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, image.textureName);
    
    // Draw a quad.
    NSSize frameSize = image.textureSize;
    glBegin(GL_QUADS);
    glColor3f(1, 1, 1);
    glTexCoord2f(0, 0);
    glVertex2f(-1, -1);
    glTexCoord2f(frameSize.width, 0);
    glVertex2f(1, -1);
    glTexCoord2f(frameSize.width, frameSize.height);
    glVertex2f(1, 1);
    glTexCoord2f(0, frameSize.height);
    glVertex2f(-1, 1);
    glEnd();
    
    // Finish drawing.
    [self.openGLContext flushBuffer];
}

@end
