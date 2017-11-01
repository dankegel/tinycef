// Copyright (c) 2013 The Chromium Embedded Framework Authors. All rights
// reserved. Use of this source code is governed by a BSD-style license that
// can be found in the LICENSE file.

#include <X11/Xlib.h>

#include "include/base/cef_logging.h"
#include "include/cef_app.h"
#include "include/cef_browser.h"
#include "include/cef_client.h"
#include "include/wrapper/cef_helpers.h"

const char kStartupURL[] = "https://www.google.com";

class MyCefClient : public CefClient {

  ;

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
//----- cefsimple/simple_app.h
// Implement application-level callbacks for the browser process.
class SimpleApp : public CefApp, public CefBrowserProcessHandler {
 public:
  SimpleApp();

  // CefApp methods:
  virtual CefRefPtr<CefBrowserProcessHandler> GetBrowserProcessHandler()
      OVERRIDE {
    return this;
  }

  // CefBrowserProcessHandler methods:
  virtual void OnContextInitialized() OVERRIDE;

 private:
  // Include the default reference counting implementation.
  IMPLEMENT_REFCOUNTING(SimpleApp);
};

//----- cefsimple/simple_app.cc, simplified

SimpleApp::SimpleApp() {}

void SimpleApp::OnContextInitialized() {
  CEF_REQUIRE_UI_THREAD();

  CefRefPtr<CefCommandLine> command_line =
      CefCommandLine::GetGlobalCommandLine();

  // MyCefClient implements browser-level callbacks.
  CefRefPtr<MyCefClient> handler(new MyCefClient());

  // Specify CEF browser settings here.
  CefBrowserSettings browser_settings;

  std::string url;

  // Check if a "--url=" value was provided via the command-line. If so, use
  // that instead of the default URL.
  url = command_line->GetSwitchValue("url");
  if (url.empty())
    url = "http://www.google.com";

  // Information used when creating the native window.
  CefWindowInfo window_info;

  // Create the first browser window.
  CefBrowserHost::CreateBrowser(window_info, handler, url, browser_settings,
                                NULL);
}
//----- end cefsimple/simple_app

namespace {

int XErrorHandlerImpl(Display* display, XErrorEvent* event) {
  LOG(WARNING) << "X error received: "
               << "type " << event->type << ", "
               << "serial " << event->serial << ", "
               << "error_code " << static_cast<int>(event->error_code) << ", "
               << "request_code " << static_cast<int>(event->request_code)
               << ", "
               << "minor_code " << static_cast<int>(event->minor_code);
  return 0;
}

int XIOErrorHandlerImpl(Display* display) {
  return 0;
}

}  // namespace

// Entry point function for all processes.
int main(int argc, char* argv[]) {
  // Provide CEF with command-line arguments.
  CefMainArgs main_args(argc, argv);

  // CEF applications have multiple sub-processes (render, plugin, GPU, etc)
  // that share the same executable. This function checks the command-line and,
  // if this is a sub-process, executes the appropriate logic.
  int exit_code = CefExecuteProcess(main_args, NULL, NULL);
  if (exit_code >= 0) {
    // The sub-process has completed so return here.
    return exit_code;
  }

  // Install xlib error handlers so that the application won't be terminated
  // on non-fatal errors.
  XSetErrorHandler(XErrorHandlerImpl);
  XSetIOErrorHandler(XIOErrorHandlerImpl);

  // Specify CEF global settings here.
  CefSettings settings;

  //---- data file whereart thou?

  // Don't rely on .pak files etc. to be in same directory as binary.
  // FIXME: prune this search path down some
  std::string cefclient_path = CEFCLIENT_DIR;
  CefString (&settings.browser_subprocess_path) = cefclient_path + "/cefclient";
  CefString (&settings.resources_dir_path) = cefclient_path;
  CefString (&settings.locales_dir_path) = cefclient_path + "/locales";

  // SimpleApp implements application-level callbacks for the browser process.
  // It will create the first browser instance in OnContextInitialized() after
  // CEF has initialized.
  CefRefPtr<SimpleApp> app(new SimpleApp);

  // Initialize CEF for the browser process.
  CefInitialize(main_args, settings, app.get(), NULL);

  // Run the CEF message loop. This will block until CefQuitMessageLoop() is
  // called.
  CefRunMessageLoop();

  // Shut down CEF.
  CefShutdown();

  return 0;
}
