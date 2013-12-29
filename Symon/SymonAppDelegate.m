#import "SymonAppDelegate.h"
#import "SymonGLView.h"
#import <Syphon/Syphon.h>

@implementation SymonAppDelegate

#pragma mark Private methods

- (void)connectToAvailableServer
{
    NSArray *servers = SyphonServerDirectory.sharedDirectory.servers;
    if (servers.count > 0)
    {
        [_symonGLView connect:servers.lastObject];
    }
    else
    {
        [_symonGLView connect:nil];
    }
}

#pragma mark UI actions

- (IBAction)selectServer:(id)sender
{
    [_symonGLView connect:[sender representedObject]];
}

#pragma mark Message handling

- (void)serverAnnounced:(NSNotification *)notification
{
    if (!_symonGLView.client)
    {
        [_symonGLView connect:notification.object];
    }
}

- (void)serverRetired:(NSNotification *)notification
{
    NSDictionary *desc = notification.object;
    NSString *uuid = desc[SyphonServerDescriptionUUIDKey];
    NSString *currentUUID = _symonGLView.client.serverDescription[SyphonServerDescriptionUUIDKey];
    if ([uuid isEqualToString:currentUUID])
    {
        [self connectToAvailableServer];
    }
}

#pragma mark NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serverAnnounced:) name:SyphonServerAnnounceNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serverRetired:) name:SyphonServerRetireNotification object:nil];
    [self connectToAvailableServer];
}

#pragma mark NSMenuDelegate

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
        // No server case.
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
        {
            item.title = [NSString stringWithFormat:@"%@ (%@)", appName, serverName];
        }
        else
        {
            item.title = appName.length ? appName : serverName;
        }
        
        // Bind an action to the item.
        item.action = @selector(selectServer:);
        item.representedObject = description;
        
        // Numeric key shortcut.
        item.keyEquivalent = [@(index + 1) stringValue];
        item.keyEquivalentModifierMask = NSCommandKeyMask;
        
        // Put on-state mark if the server is currently used.
        id currentUUID = _symonGLView.client.serverDescription[SyphonServerDescriptionUUIDKey];
        item.state = [uuid isEqualTo:currentUUID] ? NSOnState : NSOffState;
    }
    return YES;
}

@end
