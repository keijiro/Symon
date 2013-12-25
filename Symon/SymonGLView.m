#import "SymonGLView.h"
#import "Syphon/Syphon.h"
#import <OpenGL/OpenGL.h>
#import <OpenGL/glu.h>

#pragma mark
#pragma mark Private members

@interface SymonGLView ()
{
    SyphonClient *_syphonClient;
    CVDisplayLinkRef _displayLink;
}

- (void)updateServerList:(id)sender;
- (void)startClient:(NSDictionary *)description;
- (void)drawView;

@end

#pragma mark
#pragma mark DisplayLink Callbacks

static CVReturn DisplayLinkOutputCallback(CVDisplayLinkRef displayLink,
                                          const CVTimeStamp *now,
                                          const CVTimeStamp *outputTime,
                                          CVOptionFlags flagsIn,
                                          CVOptionFlags *flagsOut,
                                          void *displayLinkContext)
{
    SymonGLView *view = (__bridge SymonGLView *)displayLinkContext;
    [view drawView];
	return kCVReturnSuccess;
}

#pragma mark
#pragma mark Class implementation

@implementation SymonGLView

#pragma mark Constructor and destructor

- (void)awakeFromNib
{
    NSOpenGLPixelFormatAttribute attributes[] = {
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFAPixelBuffer,
        NSOpenGLPFAColorSize, 32,
        0
    };
    
    self.pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
    self.openGLContext = [[NSOpenGLContext alloc] initWithFormat:self.pixelFormat shareContext:nil];
    
    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateServerList:) userInfo:self repeats:YES];
}

- (void)dealloc
{
    CVDisplayLinkStop(_displayLink);
    CVDisplayLinkRelease(_displayLink);
}

#pragma mark Server communication

- (void)updateServerList:(id)sender
{
    NSArray *servers = [[SyphonServerDirectory sharedDirectory] servers];
    if (servers.count > 0) [self startClient:[servers objectAtIndex:0]];
}

- (void)startClient:(NSDictionary *)description
{
    _syphonClient = [[SyphonClient alloc] initWithServerDescription:description options:nil newFrameHandler:nil];
}

#pragma mark NSOpenGLView methods

- (void)prepareOpenGL
{
    [super prepareOpenGL];
    
    // Maximize framerate.
    GLint interval = 1;
    [self.openGLContext setValues:&interval forParameter:NSOpenGLCPSwapInterval];
    
    // Initialize DisplayLink.
    CVDisplayLinkCreateWithActiveCGDisplays(&_displayLink);
    CVDisplayLinkSetOutputCallback(_displayLink, DisplayLinkOutputCallback, (__bridge void *)(self));
    
    CGLContextObj cglCtx = (CGLContextObj)(self.openGLContext.CGLContextObj);
    CGLPixelFormatObj cglPF = (CGLPixelFormatObj)(self.pixelFormat.CGLPixelFormatObj);
    CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(_displayLink, cglCtx, cglPF);
    
    CVDisplayLinkStart(_displayLink);
    
    // Add an observer for closing the window.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowWillClose:)
                                                 name:NSWindowWillCloseNotification
                                               object:self.window];
}

#pragma mark NSWindow methods

- (void)windowWillClose:(NSNotification *)notification
{
    // DisplayLink need to be stopped manually.
    CVDisplayLinkStop(_displayLink);
}

- (void)drawRect:(NSRect)dirtyRect
{
    [self drawView];
}

#pragma mark Private methods

- (void)drawView
{
    CGLContextObj cglCtx = (CGLContextObj)(self.openGLContext.CGLContextObj);
    
    CGSize size = self.frame.size;
    
    // Lock DisplayLink.
    CGLLockContext(cglCtx);
    
    
    [self.openGLContext makeCurrentContext];
    
    SyphonImage *image = nil;
    
    if (_syphonClient)
    {
        image = [_syphonClient newFrameImageForContext:cglCtx];
    }

    glViewport(0, 0, size.width, size.height);
    
    glClearColor(0.5f, 0.5f, 0.5f, 0);
    glClear(GL_COLOR_BUFFER_BIT);
    
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
    
    image = nil;
    
    // Flush and unlock DisplayLink.
    CGLFlushDrawable(cglCtx);
    CGLUnlockContext(cglCtx);
}

@end
