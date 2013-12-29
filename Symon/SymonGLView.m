#import "SymonGLView.h"
#import <Syphon/Syphon.h>
#import <OpenGL/OpenGL.h>

#pragma mark Private variables

@interface SymonGLView ()
{
    SyphonClient *_client;
}
@end

#pragma mark
#pragma mark Class implementation

@implementation SymonGLView

#pragma mark Public methods

- (void)connect:(NSDictionary *)description;
{
    if (description)
    {
        // Create a new Syphon client with the server description.
        _client = [[SyphonClient alloc] initWithServerDescription:description options:nil newFrameHandler:^(SyphonClient *client){
            [self drawSyphonFrame];
        }];
    }
    else
    {
        _client = nil;
    }
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
    if (!_client || _client.isValid)
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
    SyphonImage *image = [_client newFrameImageForContext:self.openGLContext.CGLContextObj];
    
    // Do nothing if it failed.
    if (image == nil) return;
    
    // Retrieve the actual screen size and set it to the viewport.
    CGSize screenSize = [self convertSizeToBacking:self.bounds.size];
    glViewport(0, 0, screenSize.width, screenSize.height);
    
    // Draw context settings.
    glDisable(GL_BLEND);
    glEnable(GL_TEXTURE_RECTANGLE_ARB);
    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, image.textureName);
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_COLOR_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    
    // Draw a quad.
    static GLfloat vertices[] = {
        -1, -1, 1, 1, 1, 0, 0,
        +1, -1, 1, 1, 1, 0, 0,
        +1, +1, 1, 1, 1, 0, 0,
        -1, +1, 1, 1, 1, 0, 0
    };
    
    vertices[12] = vertices[19] = image.textureSize.width;
    vertices[20] = vertices[27] = image.textureSize.height;
    
    glVertexPointer(2, GL_FLOAT, sizeof(GLfloat) * 7, vertices);
    glColorPointer(3, GL_FLOAT, sizeof(GLfloat) * 7, &vertices[2]);
    glTexCoordPointer(2, GL_FLOAT, sizeof(GLfloat) * 7, &vertices[5]);
    
    static GLuint indices[] = { 0, 1, 2, 3 };
    glDrawElements(GL_QUADS, 4, GL_UNSIGNED_INT, indices);
    
    // Finish drawing.
    [self.openGLContext flushBuffer];
}

@end
