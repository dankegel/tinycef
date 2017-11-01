# Hyperminimal demo of using CEF on Mac

## Prerequisites

```
$ brew install cmake ninja wget
$ sudo make prefix     # create /opt/tinycef
```

A recent enough xcode with commandline tools

## Quick start

```
$ make                 # download cef, build wrapper, install to /opt/tinycef/..., build app
$ open tiny.app        # run app
```

## Specifying branch

```
$ make cefbranch=3112
$ open tiny.app
```

As of this writing, it knows about branches 3112, 3163, and 3202.
To teach it about another branch, add the url to the list at the top of [buildwrapper.sh](buildwrapper.sh)

## Specifying tarball

If you've built your own tarball, you can skip download:

```
$ make cefbranch=cef_binary_3.3112.1659.gfef43e0_macosx64.tar.bz2
```

## Bonus non-cef test app

Also builds a tiny cocoa app that just shows a window and menu, since a truly minimal cocoa app lets you dissect cocoa app launching more conveniently.

## Origin
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
