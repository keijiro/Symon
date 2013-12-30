#import <Cocoa/Cocoa.h>

@class SyphonClient;

@interface SymonGLView : NSOpenGLView

@property (assign) BOOL active;

- (void)receiveFrameFrom:(SyphonClient *)syphonClient;

@end
