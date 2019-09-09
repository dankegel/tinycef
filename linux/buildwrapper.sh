#!/bin/sh
# Download CEF and install a shared copy of it and its wrapper at $PREFIX/cef$cefbranch
# Usage:
#   [PREFIX=...][DESTDIR=...] sh buildwrapper.sh [branch]
#
# Directory layout:
# $PREFIX/cef$cefbranch
#   include
#   Release
#    lib
#    cefclient
#
# Tip for normal users: create directory $PREFIX/cef$cefbranch as current user beforehand to avoid need for root
# Tip for packagers: set $DESTDIR to the staging area
#
# Requires something like 'sudo apt install cmake ninja wget build-essential'

set -e
set -x

PREFIX=${PREFIX:-/opt/tinycef}
cefbranch=$1

case $cefbranch in
*bz2) file=$cefbranch; cefbranch=$(echo $cefbranch | sed 's/cef_binary_3.//;s/\..*//');;
3112) file=cef_binary_3.3112.1659.gfef43e0_linux64.tar.bz2;;
3163) file=cef_binary_3.3163.1671.g700dc25_linux64.tar.bz2;;
3202) file=cef_binary_3.3202.1677.gd04a869_linux64.tar.bz2;;
3225) file=cef_binary_3.3325.1758.g9aea513_linux64.tar.bz2;;
3359) file=cef_binary_3.3359.1774.gd49d25f_linux64.tar.bz2;;
3396) file=cef_binary_3.3396.1779.g36f9eab_linux64.tar.bz2;;
3809) file=cef_binary_76.1.13+gf19c584+chromium-76.0.3809.132_linux64.tar.bz2;;
*) echo "please update script with url for branch $cefbranch"; exit 1;;
esac

dir=$(basename $file .tar.bz2)

#---------------------- Download, unpack ----------------------

if ! test -f $file
then
  url=http://opensource.spotify.com/cefbuilds/$file
  # Server rejects wget, to discourage bots; you'll have to do it in a browser these days.
  wget $url
  # Verify download complete
  rm -f $dir.tar.bz2.sha1
  wget --continue $url.sha1
  sha1=$(cat $dir.tar.bz2.sha1)
  echo "$sha1  $dir.tar.bz2" > sha1.tmp
  shasum -a 1 -c sha1.tmp
fi

rm -rf btmp
mkdir btmp
cd btmp
tar -xf ../${dir}.tar.bz2

#---------------------- Patch ----------------------

echo cefbranch is $cefbranch
if test $cefbranch -lt 3163
then
   # Work around CEF issue 2224
   sed -i.bak -E '/void On(Take|Got)Focus/s/\) \{/) override {/' $dir/tests/ceftests/os_rendering_unittest.cc
fi
if test $cefbranch -ge 3202
then
   # Work around CEF issue 2293 (if not already fixed)
   sed -i.bak -E 's/pos GREATER_EQUAL 0/pos GREATER -1/' $dir/cmake/cef_macros.cmake
fi

#---------------------- Configure, compile ----------------------

kind=Release
mkdir $kind
cd $kind
cmake ../${dir} -GNinja -DCMAKE_BUILD_TYPE=$kind
ninja -v
cd ..

#---------------------- Install ----------------------

SUBPREFIX=$PREFIX/cef$cefbranch
# Disable group and world writability of newly created files
umask 022

# Install cefclient:
# ... so app can use its helper subexecutable
# ... so app can link to its cef framework
# ... so developer can run cefclient manually as sanity check
rm -rf "$DESTDIR$SUBPREFIX/$kind"
install -m755 -d "$DESTDIR$SUBPREFIX/$kind"
cp -a $kind/tests/cefclient "$DESTDIR$SUBPREFIX/$kind"

# Install include files.  (Shared between Release and Debug, so no $kind in path.)
rm -rf "$DESTDIR$SUBPREFIX/include"
install -m755 -d "$DESTDIR$SUBPREFIX/include"
cp -a ${dir}/include/* "$DESTDIR$SUBPREFIX/include"

# Install the wrapper we built above
rm -rf "$DESTDIR$SUBPREFIX/$kind/lib"
install -m755 -d "$DESTDIR$SUBPREFIX/$kind/lib"
install -m644 $kind/libcef_dll*/libcef_dll_wrapper.a "$DESTDIR/$SUBPREFIX/$kind/lib"

# Do what the last message in the ninja log says, and mark chrome-sandbox setuid...
# this is required for a usable chromium.
sudo chmod 4755 "$DESTDIR$SUBPREFIX/$kind/cefclient/$kind/chrome-sandbox"
