#import "SymonAppDelegate.h"
#import "SymonWindowController.h"
#import <Syphon/Syphon.h>

@interface SymonAppDelegate ()
{
    NSMutableArray *_windowControllers;
}
@end

@implementation SymonAppDelegate

#pragma mark UI actions

- (void)newDocument:(id)sender
{
    SymonWindowController *newController = [[SymonWindowController alloc] initWithWindowNibName:@"SymonWindow"];
    [newController showWindow:self];
    [_windowControllers addObject:newController];
}

#pragma mark NSApplicationDelegate

+ (void)initialize
{
    // Register the initial values for the user defaults.
    NSString *path = [[NSBundle mainBundle] pathForResource:@"UserDefaults" ofType:@"plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
    [[NSUserDefaults standardUserDefaults] registerDefaults:dict];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    _windowControllers = [NSMutableArray array];

    // Create the initial window.
    [self newDocument:nil];
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
        
        // Make a title for the item.
        if (appName.length && serverName.length)
            item.title = [NSString stringWithFormat:@"%@ (%@)", appName, serverName];
        else
            item.title = appName.length ? appName : serverName;
        
        // Bind an action to the item.
        item.action = NSSelectorFromString(@"selectServer:");
        item.representedObject = description;
        
        // Numeric key shortcut.
        item.keyEquivalent = [@(index + 1) stringValue];
        item.keyEquivalentModifierMask = NSCommandKeyMask;
    }
    return YES;
}

@end
