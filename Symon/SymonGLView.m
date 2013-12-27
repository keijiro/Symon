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

- (void)updateServerList:(id)sender;
- (void)startClient:(NSDictionary *)description;

@end

#pragma mark
#pragma mark Class implementation

@implementation SymonGLView

#pragma mark Constructor and destructor

- (void)awakeFromNib
{
    NSOpenGLPixelFormatAttribute attributes[] = {
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFAColorSize, 24,
        0
    };
    
    self.pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
    self.openGLContext = [[NSOpenGLContext alloc] initWithFormat:self.pixelFormat shareContext:nil];
    
    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateServerList:) userInfo:self repeats:YES];
}

#pragma mark Server communication

- (void)updateServerList:(id)sender
{
    NSArray *servers = [[SyphonServerDirectory sharedDirectory] servers];
    if (servers.count > 0)
    {
        if (_syphonClient == nil)
        {
            [self startClient:[servers objectAtIndex:0]];
        }
    }
    else
    {
        if (_syphonClient)
        {
            [_syphonClient stop];
            _syphonClient = nil;
        }
    }
}

- (void)startClient:(NSDictionary *)description
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
    
    CGSize size = self.frame.size;
    
    [self.openGLContext makeCurrentContext];
    
    SyphonImage *image = nil;
    
    if (_syphonClient)
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
