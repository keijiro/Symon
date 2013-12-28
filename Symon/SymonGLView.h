#import <Cocoa/Cocoa.h>

@class SyphonClient;

@interface SymonGLView : NSOpenGLView

- (void)connect:(NSDictionary *)description;

@property (readonly) SyphonClient *client;

@end
