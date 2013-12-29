#import <Cocoa/Cocoa.h>

@class SyphonClient;

@interface SymonGLView : NSOpenGLView

@property (readonly) SyphonClient *client;
@property (assign) BOOL enableVSync;

- (void)connect:(NSDictionary *)description;

@end
