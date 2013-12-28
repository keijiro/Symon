#import "SymonAppDelegate.h"
#import "SymonGLView.h"
#import <Syphon/Syphon.h>

@implementation SymonAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
}

- (IBAction)serverSelect:(id)sender
{
    NSInteger index = [sender tag];
    NSArray *servers = [[SyphonServerDirectory sharedDirectory] servers];
    [_symonGLView connect:servers[index]];
}

- (NSInteger)numberOfItemsInMenu:(NSMenu*)menu
{
    NSArray *servers = [[SyphonServerDirectory sharedDirectory] servers];
    return MAX(servers.count, 1);
}

- (BOOL)menu:(NSMenu*)menu updateItem:(NSMenuItem*)item atIndex:(NSInteger)index shouldCancel:(BOOL)shouldCancel
{
    NSArray *servers = [[SyphonServerDirectory sharedDirectory] servers];
    if (index >= servers.count)
    {
        item.title = @"No Server";
        item.action = nil;
    }
    else
    {
        NSDictionary *desc = servers[index];
        item.title = desc[SyphonServerDescriptionNameKey];
        item.action = @selector(serverSelect:);
        item.tag = index;
    }
    return YES;
}

@end
