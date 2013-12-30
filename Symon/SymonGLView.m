#import "SymonGLView.h"
#import <Syphon/Syphon.h>
#import <OpenGL/OpenGL.h>

#pragma mark Private declaration

@interface SymonGLView ()
{
    BOOL _active;
    BOOL _vSync;
    SyphonImage *_frameImage;
}
@end

static NSString *vSyncDefaultKey = @"vSync";

#pragma mark
#pragma mark Class implementation

@implementation SymonGLView

#pragma mark Property accessors

- (BOOL)active
{
    return _active;
}

- (void)setActive:(BOOL)flag
{
    _active = flag;
    
    // Dispose the last frame when disabled.
    if (!_active)
    {
        _frameImage = nil;
        self.needsDisplay = YES;
    }
}

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

- (void)retrieveFrameFrom:(SyphonClient *)syphonClient
{
    _frameImage = [syphonClient newFrameImageForContext:self.openGLContext.CGLContextObj];
    
    if (_vSync)
        self.needsDisplay = YES;
    else
        [self drawFrameImage];
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
    [self drawFrameImage];
}

#pragma mark Private methods

- (void)drawFrameImage
{
    // Activate the GL context.
    [self.openGLContext makeCurrentContext];
    
    if (_frameImage)
    {
        // Retrieve the actual screen size and set it to the viewport.
        CGSize screenSize = [self convertSizeToBacking:self.bounds.size];
        glViewport(0, 0, screenSize.width, screenSize.height);
        
        // Draw context settings.
        glDisable(GL_BLEND);
        glEnable(GL_TEXTURE_RECTANGLE_ARB);
        glBindTexture(GL_TEXTURE_RECTANGLE_ARB, _frameImage.textureName);
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
        
        vertices[12] = vertices[19] = _frameImage.textureSize.width;
        vertices[20] = vertices[27] = _frameImage.textureSize.height;
        
        glVertexPointer(2, GL_FLOAT, sizeof(GLfloat) * 7, vertices);
        glColorPointer(3, GL_FLOAT, sizeof(GLfloat) * 7, &vertices[2]);
        glTexCoordPointer(2, GL_FLOAT, sizeof(GLfloat) * 7, &vertices[5]);
        
        static GLuint indices[] = { 0, 1, 2, 3 };
        glDrawElements(GL_QUADS, 4, GL_UNSIGNED_INT, indices);
    }
    else
    {
        glClearColor(0.5f, 0.5f, 0.5f, 0);
        glClear(GL_COLOR_BUFFER_BIT);
    }
    
    // Finish drawing.
    [self.openGLContext flushBuffer];
}

@end
