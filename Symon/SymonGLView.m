#import "SymonGLView.h"
#import <Syphon/Syphon.h>
#import <OpenGL/OpenGL.h>

#pragma mark Private declaration

@interface SymonGLView ()
{
    SyphonClient *_client;
    BOOL _vSync;
}
@end

static NSString *vSyncDefaultKey = @"vSync";

#pragma mark
#pragma mark Class implementation

@implementation SymonGLView

#pragma mark Property accessors

- (BOOL)vSync
{
    return _vSync;
}

- (void)setVSync:(BOOL)flag
{
    _vSync = flag;
    [[NSUserDefaults standardUserDefaults] setBool:_vSync forKey:vSyncDefaultKey];
    
    GLint interval = _vSync ? 1 : 0;
    [self.openGLContext setValues:&interval forParameter:NSOpenGLCPSwapInterval];
}

#pragma mark Public methods

- (void)connect:(NSDictionary *)description;
{
    if (description)
    {
        // Create a new Syphon client with the server description.
        _client = [[SyphonClient alloc] initWithServerDescription:description options:nil newFrameHandler:^(SyphonClient *client){
            if (_vSync)
                self.needsDisplay = YES;
            else
                [self drawSyphonFrame];
        }];
    }
    else
    {
        _client = nil;
        self.needsDisplay = YES;
    }
}

#pragma mark NSOpenGLView methods

- (void)prepareOpenGL
{
    [super prepareOpenGL];
    
    // VSync setting.
    self.vSync = [[NSUserDefaults standardUserDefaults] boolForKey:vSyncDefaultKey];
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Clear the window if there is no valid connection.
    if (!_client || !_client.isValid)
    {
        glClearColor(0.5f, 0.5f, 0.5f, 0);
        glClear(GL_COLOR_BUFFER_BIT);
        [self.openGLContext flushBuffer];
    }
    else if (_vSync)
    {
        // Draw the frame if VSync is enabled.
        [self drawSyphonFrame];
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
