#import <Cocoa/Cocoa.h>

@class SyphonClient;

@interface SymonGLView : NSOpenGLView

@property (readonly) SyphonClient *client;

- (void)connect:(NSDictionary *)description;

@end
