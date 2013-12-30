#import <Cocoa/Cocoa.h>

@class SymonGLView;

@interface SymonWindowController : NSWindowController

@property (readonly) NSString *serverUUID;

@property (assign) IBOutlet SymonGLView *symonGLView;

- (void)connectServer:(NSDictionary *)description;

@end
