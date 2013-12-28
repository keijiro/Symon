#import <Cocoa/Cocoa.h>

@class SymonGLView;

@interface SymonAppDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet SymonGLView *symonGLView;

@end
