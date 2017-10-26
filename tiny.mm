// Trivial hyperminimal single-file demo of using CEF on Mac
// Launches and runs ok on osx 10.11 through 10.13
// Written solely to explore problems related to launching on Mac.
// For simplicity's sake, does not subclass NSApplication<CefAppProtocol>, so sometimes crashes on exit
// See cef-project/examples/shared/main_mac.mm for proper way to do it
//
// To compile a minimal CEF app with a freshly downloaded CEF:
//   sudo make prefix
//   make
// Code linearized from https://bitbucket.org/chromiumembedded/cef-project
// FIXME Should add a define to use the external message pump
//
// To compile a minimal Cocoa app without CEF (useful for testing cocoa launching):
//   clang++ -framework Cocoa tiny.mm -o tiny
// To use the alternative DIY event loop, add -DDIYRUN to the compile commandline.
// Thanks to
//   http://www.cocoawithlove.com/2010/09/minimalist-cocoa-programming.html
//   https://stackoverflow.com/questions/33345686/cocoa-application-menu-bar-not-clickable
//
// Dan Kegel

#import <Cocoa/Cocoa.h>

// Global window variable
id g_window;

#ifdef CEF
#include "include/cef_app.h"
#include "include/cef_browser.h"
#include "include/cef_client.h"

const char kStartupURL[] = "https://www.google.com";

class MyCefClient : public CefClient {
  IMPLEMENT_REFCOUNTING (MyCefClient);
};

// Minimal implementation of CefApp for the browser process.
class BrowserApp : public CefApp, public CefBrowserProcessHandler {
 public:
  BrowserApp() {}

  // CefApp methods:
  CefRefPtr<CefBrowserProcessHandler> GetBrowserProcessHandler() OVERRIDE {
    return this;
  }

  // CefBrowserProcessHandler methods:
  void OnContextInitialized() OVERRIDE {
    CefWindowInfo window_info;
    CefBrowserHost::CreateBrowser(window_info, new MyCefClient(), kStartupURL, CefBrowserSettings(), NULL);
  }

 private:
  IMPLEMENT_REFCOUNTING(BrowserApp);
  DISALLOW_COPY_AND_ASSIGN(BrowserApp);
};

#endif

@interface SharedAppDelegate : NSObject <NSApplicationDelegate>
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification;
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;
@end

@implementation SharedAppDelegate

// Called immediately before the event loop starts.
// Right place for setting up app level things.
-(void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
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
// Right place for setting up event loop level things.
// Also right place for setting dock icon, since doing it earlier
// won't override the default one set by NSApp.
-(void)applicationDidFinishLaunching:(NSNotification *)notification
{
    // Set dock icon if desired
    NSImage *icon =[[NSImage alloc] initWithContentsOfFile:@"circle.png"];
    [NSApp setApplicationIconImage:icon];

    // Push app to foreground
    [g_window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
}
@end

// Four different styles of event loop
// 1) CEF   DIYRUN - DIY runloop that calls CefDoMessageLoopWork()
// 2)       DIYRUN - DIY runloop
// 3) CEF          - CefRunMessageLoop()
// 4)              - [NSApp run]
void runloop() {

#if defined(DIYRUN)
  #if defined(CEF)
  // CEF will call [NSAapp run] and break out of main loop when idle...
  // so [run] will take care of finishLaunching for us.
  // If you call finishLaunching here anyway, the app will abort with
  // _createMenuRef called with existing principal MenuRef already associated with menu
  #else
  // If you omit this, applicationWillFinishLaunching won't be called, and menus won't work.
  [NSApp finishLaunching];
  #endif

  // FIXME: sense quit somehow
  while (true) {
    NSEvent *event;
    event = [NSApp nextEventMatchingMask: NSAnyEventMask
                               untilDate: [NSDate distantPast]
                                  inMode: NSDefaultRunLoopMode
                                 dequeue: YES];
    if (event != nil)
      [NSApp sendEvent:event];

 #if defined(CEF)
    // FIXME: use external message pump integration
    CefDoMessageLoopWork();
 #endif

    // if you don't want to burn CPU, you could do this,
    // but then you need to handle cef's schedulework messages.
    //event = [NSApp nextEventMatchingMask: NSAnyEventMask
    //                           untilDate: [NSDate distantFuture]
    //                              inMode: NSDefaultRunLoopMode
    //                             dequeue: NO];
  }
#else
 #if defined(CEF)
    CefRunMessageLoop();
 #else
    [NSApp run];
 #endif
#endif
}

int main(int argc, char **argv) {
    [NSAutoreleasePool new];
    [NSApplication sharedApplication];

    // Newbie alert: new = alloc init.
    // See https://stackoverflow.com/questions/719877/use-of-alloc-init-instead-of-new
    SharedAppDelegate* delegate = [SharedAppDelegate new];
    [NSApp setDelegate:delegate];

#ifdef CEF
    // Go cef go!
    CefMainArgs main_args(argc, argv);
    CefRefPtr<CefApp> app = new BrowserApp();
    CefSettings settings;
    CefInitialize(main_args, settings, app, NULL);
#else
    // Create a window so we can verify it shows up properly (e.g. in front)
    g_window = [[[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 200, 200)
                 styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO]
                 autorelease];
    [g_window cascadeTopLeftFromPoint:NSMakePoint(20,20)];
    id appName = [[NSProcessInfo processInfo] processName];
    [g_window setTitle:appName];
#endif

    runloop();

    return 0;
}
