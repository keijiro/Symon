#import "SymonAppDelegate.h"
#import "SymonWindowController.h"
#import "SymonGLView.h"
#import <Syphon/Syphon.h>

@interface SymonAppDelegate ()
{
    SymonWindowController *_windowController;
}
@end

@implementation SymonAppDelegate

#pragma mark UI actions

- (IBAction)selectServer:(id)sender
{
    [_windowController connectServer:[sender representedObject]];
}

- (IBAction)toggleVSync:(id)sender
{
    _windowController.symonGLView.vSync = !_windowController.symonGLView.vSync;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if (menuItem.action == @selector(toggleVSync:))
        menuItem.title = _windowController.symonGLView.vSync ? @"Disable VSync" : @"Enable VSync";
    return YES;
}

#pragma mark NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Create a window.
    _windowController = [[SymonWindowController alloc] initWithWindowNibName:@"SymonWindow"];
    [_windowController showWindow:self];
}

#pragma mark NSMenuDelegate

- (NSInteger)numberOfItemsInMenu:(NSMenu*)menu
{
    return MAX(SyphonServerDirectory.sharedDirectory.servers.count, 1);
}

- (BOOL)menu:(NSMenu*)menu updateItem:(NSMenuItem*)item atIndex:(NSInteger)index shouldCancel:(BOOL)shouldCancel
{
    NSArray *servers = SyphonServerDirectory.sharedDirectory.servers;
    if (index >= servers.count)
    {
        // No server.
        item.title = @"No Server";
        item.action = nil;
        item.keyEquivalent = @"";
    }
    else
    {
        NSDictionary *description = servers[index];
        NSString *appName = description[SyphonServerDescriptionAppNameKey];
        NSString *serverName = description[SyphonServerDescriptionNameKey];
        NSString *uuid = description[SyphonServerDescriptionUUIDKey];
        
        // Make a title for the item.
        if (appName.length && serverName.length)
            item.title = [NSString stringWithFormat:@"%@ (%@)", appName, serverName];
        else
            item.title = appName.length ? appName : serverName;
        
        // Bind an action to the item.
        item.action = @selector(selectServer:);
        item.representedObject = description;
        
        // Numeric key shortcut.
        item.keyEquivalent = [@(index + 1) stringValue];
        item.keyEquivalentModifierMask = NSCommandKeyMask;
        
        // Put on-state mark if the server is currently used.
        NSString *currentUUID = _windowController.serverUUID;
        item.state = [uuid isEqualTo:currentUUID] ? NSOnState : NSOffState;
    }
    return YES;
}

@end
