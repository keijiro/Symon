#import <Cocoa/Cocoa.h>

@class SyphonClient;

@interface SymonGLView : NSOpenGLView

@property (assign) BOOL active;
@property (assign) BOOL vSync;

- (void)retrieveFrameFrom:(SyphonClient *)syphonClient;

@end
