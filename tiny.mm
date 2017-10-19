// Trivial hyperminimal single-file demo of using CEF on Mac
// Launches and runs ok on osx 10.11 through 10.13
// For simplicity's sake, does not subclass NSApplication<CefAppProtocol>, so sometimes crashes on exit
// See cef-project/examples/shared/main_mac.mm for proper way to do it
// Written solely to explore problems related to
//
// To compile as minimal Cocoa app without CEF (useful for testing cocoa launching):
//   clang++ -DNOCEF -framework Cocoa tiny.mm -o tiny
// Thanks to
//   http://www.cocoawithlove.com/2010/09/minimalist-cocoa-programming.html
//   https://stackoverflow.com/questions/33345686/cocoa-application-menu-bar-not-clickable
//
// To compile as minimal Cocoa app with CEF:
// (FIXME: adjust or remove -I, -L, and -F options to taste, mine are strange)
//   clang++ -stdlib=libc++ --std=c++11 \
//      -I $(cefdir) \
//      -L $(cefdir)/$(kind)/lib \
//      -F$(cefdir)/$(kind)/cefclient.app/Contents/Frameworks -framework Chromium\ Embedded\ Framework \
//      -framework Cocoa tiny.mm -o tinycef -l cef_dll_wrapper
// Code linearized from https://bitbucket.org/chromiumembedded/cef-project
//
// Dan Kegel

#import <Cocoa/Cocoa.h>

#ifndef NOCEF
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
// Right place for setting up event loop level things.
-(void)applicationDidFinishLaunching:(NSNotification *)notification
{
    [NSApplication sharedApplication];
    // Push app to foreground
    [NSApp activateIgnoringOtherApps:YES];
}
@end

int main(int argc, char **argv) {
    [NSAutoreleasePool new];
    [NSApplication sharedApplication];

    // Newbie alert: new = alloc init.
    // See https://stackoverflow.com/questions/719877/use-of-alloc-init-instead-of-new
    SharedAppDelegate* delegate = [SharedAppDelegate new];
    [NSApp setDelegate:delegate];

#ifndef NOCEF
    // Go cef go!
    CefMainArgs main_args(argc, argv);
    CefRefPtr<CefApp> app = new BrowserApp();
    CefSettings settings;
    CefInitialize(main_args, settings, app, NULL);
    CefRunMessageLoop();
#else
    // Create a window here if you feel like it :-)

    [NSApp run];
#endif

    return 0;
}
