#import "SymonGLView.h"
#import <Syphon/Syphon.h>
#import <OpenGL/OpenGL.h>

#pragma mark Private Interface

@interface SymonGLView ()
{
    BOOL _active;
    BOOL _shouldWaitInterval;
    BOOL _shouldClearScreen;
    NSColor *_clearColor;
    GLfloat _clearColorRGB[3];
    SyphonImage *_frameImage;
}

@property (assign) BOOL aspectRatioCorrection;
@property (assign) BOOL gammaCorrection;

@end

#pragma mark

@implementation SymonGLView

#pragma mark NSOpenGLView Methods

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // Bind checkbox preferences to the properties.
    NSUserDefaultsController *udc = [NSUserDefaultsController sharedUserDefaultsController];
    [self bind:@"shouldWaitInterval" toObject:udc withKeyPath:@"values.shouldWaitInterval" options:nil];
    [self bind:@"aspectRatioCorrection" toObject:udc withKeyPath:@"values.aspectRatioCorrection" options:nil];
    [self bind:@"shouldClearScreen" toObject:udc withKeyPath:@"values.shouldClearScreen" options:nil];
    [self bind:@"gammaCorrection" toObject:udc withKeyPath:@"values.gammaCorrection" options:nil];

    // Bind color preferences to the color properties.
    NSDictionary *options = [NSDictionary dictionaryWithObject:NSUnarchiveFromDataTransformerName
                                                        forKey:NSValueTransformerNameBindingOption];
    [self bind:@"clearColor" toObject:udc withKeyPath:@"values.clearColor" options:options];
}

- (void)prepareOpenGL
{
    [super prepareOpenGL];
    
    // Reapply the VSync option.
    self.shouldWaitInterval = _shouldWaitInterval;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [self drawFrameImage];
}

#pragma mark Public Properties

- (BOOL)active
{
    return _active;
}

- (void)setActive:(BOOL)flag
{
    _active = flag;
    
    // Dispose the last frame when disabled.
    if (!_active && _shouldClearScreen)
    {
        _frameImage = nil;
        self.needsDisplay = YES;
    }
}

#pragma mark Properties For Binding

- (BOOL)shouldWaitInterval
{
    return _shouldWaitInterval;
}

- (void)setShouldWaitInterval:(BOOL)flag
{
    _shouldWaitInterval = flag;
    
    // Change the VSync option on the GL context.
    GLint interval = flag ? 1 : 0;
    [self.openGLContext setValues:&interval forParameter:NSOpenGLCPSwapInterval];
}

- (BOOL)shouldClearScreen
{
    return _shouldClearScreen;
}

- (void)setShouldClearScreen:(BOOL)flag
{
    _shouldClearScreen = flag;
    
    // Clear screen immediately.
    if (flag && _frameImage)
    {
        _frameImage = nil;
        self.needsDisplay = YES;
    }
}

- (NSColor *)clearColor
{
    return _clearColor;
}

- (void)setClearColor:(NSColor *)color
{
    _clearColor = color;
    
    // Convert the colorspace.
    NSColor *rgb = [color colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]];
    _clearColorRGB[0] = rgb.redComponent;
    _clearColorRGB[1] = rgb.greenComponent;
    _clearColorRGB[2] = rgb.blueComponent;
    
    self.needsDisplay = !_active;
}

#pragma mark Public Methods

- (void)receiveFrameFrom:(SyphonClient *)syphonClient
{
    _frameImage = [syphonClient newFrameImageForContext:self.openGLContext.CGLContextObj];
    
    if (_shouldWaitInterval)
        self.needsDisplay = YES;
    else
        [self drawFrameImage];
}

#pragma mark Private Methods

- (void)drawFrameImage
{
    // Activate the GL context.
    [self.openGLContext makeCurrentContext];
    
    if (_frameImage)
    {
        // Set the viewport with proper aspect ratio.
        NSSize screenSize = [self convertSizeToBacking:self.bounds.size];
        NSSize textureSize = _frameImage.textureSize;
        
        if (_aspectRatioCorrection)
        {
            if (textureSize.width / textureSize.height > screenSize.width / screenSize.height)
            {
                GLfloat margin = screenSize.height - screenSize.width * textureSize.height / textureSize.width;
                glViewport(0, 0.5f * margin, screenSize.width, screenSize.height - margin);
            }
            else
            {
                GLfloat margin = screenSize.width - screenSize.height * textureSize.width / textureSize.height;
                glViewport(0.5f * margin, 0, screenSize.width - margin, screenSize.height);
            }
        }
        else
        {
            glViewport(0, 0, screenSize.width, screenSize.height);
        }
        
        // Clear the screen.
        if (_aspectRatioCorrection)
        {
            glClearColor(_clearColorRGB[0], _clearColorRGB[1], _clearColorRGB[2], 0);
            glClear(GL_COLOR_BUFFER_BIT);
        }
        
        // Gamma correction.
        if (_gammaCorrection)
            glEnable(GL_FRAMEBUFFER_SRGB);
        else
            glDisable(GL_FRAMEBUFFER_SRGB);
        
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
        
        vertices[12] = vertices[19] = textureSize.width;
        vertices[20] = vertices[27] = textureSize.height;
        
        glVertexPointer(2, GL_FLOAT, sizeof(GLfloat) * 7, vertices);
        glColorPointer(3, GL_FLOAT, sizeof(GLfloat) * 7, &vertices[2]);
        glTexCoordPointer(2, GL_FLOAT, sizeof(GLfloat) * 7, &vertices[5]);
        
        static GLuint indices[] = { 0, 1, 2, 3 };
        glDrawElements(GL_QUADS, 4, GL_UNSIGNED_INT, indices);
    }
    else
    {
        glClearColor(_clearColorRGB[0], _clearColorRGB[1], _clearColorRGB[2], 0);
        glClear(GL_COLOR_BUFFER_BIT);
    }
    
    // Finish drawing.
    [self.openGLContext flushBuffer];
}

@end
