# Hyperminimal demo of using CEF on Linux

## Prerequisites

```
$ sudo apt build-dep chromium
$ sudo make prefix     # create /opt/tinycef
```

## Quick start

```
$ make                 # download cef if needed, build wrapper, install to /opt/tinycef/..., build app
$ ./tiny               # run app
```

## Specifying branch

```
$ make cefbranch=3112
$ ./tiny
```

As of this writing, it knows about branches 3112, 3163, 3202, ... 3396, and 3809.
To teach it about another branch, add the url to the list at the top of [buildwrapper.sh](buildwrapper.sh)

## Specifying tarball

If you've built your own tarball, you can skip download:

```
$ make cefbranch=cef_binary_3.3112.1659.gfef43e0_linux64.tar.bz2
```

## Origin

When upgrading a largish app to use a newer CEF, I ran into odd build problems.

I really wanted a simple demo of how to use cef properly.
Alas, cefsimple was a little too opaque, I needed something even more stripped down...
and I needed to demonstrate linking to an installed cef wrapper.

20 minutes of artless typing later, this popped out.  It illustrates
which symlinks are needed next to binaries that use an installed copy of cef.

FIXME: not happy on exit yet, it's probably a bit *too* simple.
