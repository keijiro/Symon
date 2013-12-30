#import "SymonAppDelegate.h"
#import "SymonGLView.h"
#import <Syphon/Syphon.h>

@implementation SymonAppDelegate

#pragma mark Private methods

- (NSString *)makeServerDisplayName:(NSDictionary *)description
{
    NSString *appName = description[SyphonServerDescriptionAppNameKey];
    NSString *serverName = description[SyphonServerDescriptionNameKey];
    if (appName.length && serverName.length)
        return [NSString stringWithFormat:@"%@ (%@)", appName, serverName];
    else
        return appName.length ? appName : serverName;
}

- (void)connectServer:(NSDictionary *)description
{
    // If no server was given, try to connect to the first server.
    if (!description)
        description = SyphonServerDirectory.sharedDirectory.servers.firstObject;
    
    [_symonGLView connect:description];

    // Change the window title.
    if (description)
        self.window.title = [@"Symon - " stringByAppendingString:[self makeServerDisplayName:description]];
    else
        self.window.title = @"Symon";
}

#pragma mark UI actions

- (IBAction)selectServer:(id)sender
{
    [self connectServer:[sender representedObject]];
}

- (IBAction)toggleVSync:(id)sender
{
    _symonGLView.vSync = !_symonGLView.vSync;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if (menuItem.action == @selector(toggleVSync:))
        menuItem.title = _symonGLView.vSync ? @"Disable VSync" : @"Enable VSync";
    return YES;
}

#pragma mark Message handling

- (void)serverAnnounced:(NSNotification *)notification
{
    if (!_symonGLView.client) [self connectServer:notification.object];
}

- (void)serverRetired:(NSNotification *)notification
{
    // Is it the current server?
    NSString *retired = [notification.object objectForKey:SyphonServerDescriptionUUIDKey];
    NSString *current = _symonGLView.client.serverDescription[SyphonServerDescriptionUUIDKey];
    if ([retired isEqualToString:current])
    {
        // Reconnect to an available server.
        [self connectServer:nil];
    }
}

#pragma mark NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Notifications from Syphon.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serverAnnounced:) name:SyphonServerAnnounceNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serverRetired:) name:SyphonServerRetireNotification object:nil];
    
    // Connect to an available server.
    [self connectServer:nil];
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
        id currentUUID = _symonGLView.client.serverDescription[SyphonServerDescriptionUUIDKey];
        item.state = [uuid isEqualTo:currentUUID] ? NSOnState : NSOffState;
    }
    return YES;
}

@end
