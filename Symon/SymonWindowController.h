#import <Cocoa/Cocoa.h>

@interface SymonWindowController : NSWindowController

@property (readonly) NSString *serverUUID;

- (void)connectServer:(NSDictionary *)description;

@end
