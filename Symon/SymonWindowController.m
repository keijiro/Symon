#import "SymonWindowController.h"
#import "SymonGLView.h"
#import <Syphon/Syphon.h>

#pragma mark Private Interface

@interface SymonWindowController ()
{
    IBOutlet SymonGLView *_symonGLView;
    SyphonClient *_syphonClient;
    BOOL _keepTop;
}

@property (assign) BOOL keepTop;
@property (assign) BOOL autoConnect;

@end

@implementation SymonWindowController

#pragma mark NSWindowController Methods

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Bind checkbox preferences to the properties.
    NSUserDefaultsController *udc = [NSUserDefaultsController sharedUserDefaultsController];
    [self bind:@"keepTop" toObject:udc withKeyPath:@"values.keepTop" options:nil];
    [self bind:@"autoConnect" toObject:udc withKeyPath:@"values.autoConnect" options:nil];
    
    // Notifications from Syphon.
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(serverAnnounced:) name:SyphonServerAnnounceNotification object:nil];
    [nc addObserver:self selector:@selector(serverRetired:) name:SyphonServerRetireNotification object:nil];
    
    // Connect to an available server.
    [self connectServer:nil];
}

- (BOOL)windowShouldClose:(id)sender
{
    // Stop the Syphon client on closing.
    _syphonClient = nil;
    return YES;
}

#pragma mark Window Properties

- (BOOL)keepTop
{
    return _keepTop;
}

- (void)setKeepTop:(BOOL)keepTop
{
    _keepTop = keepTop;
    [self.window setLevel:(keepTop ? NSFloatingWindowLevel : NSNormalWindowLevel)];
}

#pragma mark Syphon Server Notifications

- (void)serverAnnounced:(NSNotification *)notification
{
    // A new server is announced; try to connect if it isn't connected to any server yet.
    if (!_syphonClient && _autoConnect) [self connectServer:notification.object];
}

- (void)serverRetired:(NSNotification *)notification
{
    // A server is retired; if it's the current one, try to connect to an available server.
    NSString *uuid = [notification.object objectForKey:SyphonServerDescriptionUUIDKey];
    if ([uuid isEqualToString:self.serverUUID]) [self connectServer:nil];
}

#pragma mark UI Actions

- (void)selectServer:(id)sender
{
    [self connectServer:[sender representedObject]];
}

- (BOOL)validateMenuItem:(NSMenuItem *)item {
    if (_syphonClient)
    {
        NSDictionary *description = item.representedObject;
        NSString *uuid = description[SyphonServerDescriptionUUIDKey];
        item.state = [uuid isEqualToString:self.serverUUID] ? NSOnState : NSOffState;
    }
    else
    {
        item.state = NSOffState;
    }
    return YES;
}

#pragma mark Private Methods

- (NSString *)serverUUID
{
    return _syphonClient.serverDescription[SyphonServerDescriptionUUIDKey];
}

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
    // If auto-connect is enabled, try to connect to the first server.
    if (!description && _autoConnect)
        description = SyphonServerDirectory.sharedDirectory.servers.firstObject;
    
    if (description)
    {
        // Activate the GL view.
        _symonGLView.active = YES;
        
        // Create a new Syphon client with the server description.
        _syphonClient = [[SyphonClient alloc] initWithServerDescription:description options:nil newFrameHandler:^(SyphonClient *client){
            [_symonGLView receiveFrameFrom:_syphonClient];
        }];
        
        // Change the window title.
        self.window.title = [@"Symon - " stringByAppendingString:[self makeServerDisplayName:description]];
    }
    else
    {
        // Failed to connect; deactivate itself.
        _syphonClient = nil;
        _symonGLView.active = NO;
        self.window.title = @"Symon";
        return;
    }
}

@end
