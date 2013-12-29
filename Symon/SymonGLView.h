#import <Cocoa/Cocoa.h>

@class SyphonClient;

@interface SymonGLView : NSOpenGLView

@property (readonly) SyphonClient *client;
@property (assign) BOOL vSync;

- (void)connect:(NSDictionary *)description;

@end
