// http://www.cocoawithlove.com/2010/09/minimalist-cocoa-programming.html

// Includes osx1012 menu fix from
// https://stackoverflow.com/questions/33345686/cocoa-application-menu-bar-not-clickable

#import <Cocoa/Cocoa.h>

@interface SharedAppDelegate : NSObject <NSApplicationDelegate>
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification;
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;
@end


@implementation SharedAppDelegate

// Called immediately before the event loop starts.
// Right place for setting up app level things.
-(void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
    [NSApplication sharedApplication];
    id menubar = [[NSMenu new] autorelease];
    id appMenuItem = [[NSMenuItem new] autorelease];
    [menubar addItem:appMenuItem];
    [NSApp setMainMenu:menubar];
    id appMenu = [[NSMenu new] autorelease];
    id appName = [[NSProcessInfo processInfo] processName];
    id quitTitle = [@"Quit " stringByAppendingString:appName];
    id quitMenuItem = [[[NSMenuItem alloc] initWithTitle:quitTitle
                         action:@selector(terminate:) keyEquivalent:@"q"]
                         autorelease];
    [appMenu addItem:quitMenuItem];
    [appMenuItem setSubmenu:appMenu];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
}

// Called when the event loop has been started,
// document double clicks have already been processed,
// but no events have been executed yet.
// [The window may be created after this method is executed in some apps.]
// Right place for setting up event loop level things.
-(void)applicationDidFinishLaunching:(NSNotification *)notification
{
    [NSApplication sharedApplication];
    // Push app to foreground
    [NSApp activateIgnoringOtherApps:YES];
}
@end

int main() {
    [NSAutoreleasePool new];
    [NSApplication sharedApplication];

    // Newbie alert: new = alloc init.
    // See https://stackoverflow.com/questions/719877/use-of-alloc-init-instead-of-new
    SharedAppDelegate* delegate = [SharedAppDelegate new];
    [NSApp setDelegate:delegate];

    [NSApp run];
    return 0;
}
