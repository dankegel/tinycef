# Hyperminimal demo of using CEF on Linux

When upgrading a largish app to use a newer CEF, I ran into odd build problems.

I really wanted a simple demo of how to use cef properly.
Alas, cefsimple was a little too opaque, I needed something even more stripped down...
and I needed to demonstrate linking to an installed cef wrapper.

20 minutes of artless typing later, this popped out.  It illustrates
which symlinks are needed next to binaries that use an installed copy of cef.

FIXME: not happy on exit yet, it's probably a bit *too* simple.
