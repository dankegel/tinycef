# Hyperminimal demo of using CEF on Mac

When upgrading a largish app to use a newer CEF and run on newer Mac OS, I ran into three problems:

1) _createMenuRef called with existing principal MenuRef already associated with menu

2) when fixing the above by removing the app's call to [NSApplication finishLaunching],
   menus stopped working

3) occasional crash on exit

To debug them, I needed a tiny test case, so I borrowed one from
http://www.cocoawithlove.com/2010/09/minimalist-cocoa-programming.html

Straight off that reproduced the "menus and cmd-Q don't work" problem on osx1013;
moving a few calls into later callbacks as suggested by
https://stackoverflow.com/questions/33345686/cocoa-application-menu-bar-not-clickable
resolved that.

This demo does *not* subclass NSApplication as required by CEF,
but surprisingly it doesn't crash on every exit... which may
explain why the real app only occasionally crashes on exit.
