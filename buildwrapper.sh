#!/bin/sh
# Download CEF and install a shared copy of it and its wrapper at $PREFIX/cef$cefbranch
# Usage:
#   [PREFIX=...][DESTDIR=...] sh buildwrapper.sh [branch]
#
# Normally, on Mac, CEF wants you to build its wrapper anew for each project, and bundle the wrapper into your project.
# Some shops prefer to have central installations of all libraries, so let's try that with Cef on mac.
# Directory layout:
# $PREFIX/cef$cefbranch
#   include
#   Release
#    lib
#    cefclient.app
#
# Tip for normal users: create directory $PREFIX/cef$cefbranch as current user beforehand to avoid need for root
# Tip for packagers: set $DESTDIR to the staging area
#
# Requires 'brew install cmake ninja wget' and a recent xcode with commandline tools

set -e
set -x

PREFIX=${PREFIX:-/opt/tinycef}
cefbranch=$1

case $cefbranch in
*bz2) file=$cefbranch; cefbranch=$(echo $cefbranch | sed 's/cef_binary_3.//;s/\..*//');;
3112) file=cef_binary_3.3112.1659.gfef43e0_macosx64.tar.bz2;;
3163) file=cef_binary_3.3163.1671.g700dc25_macosx64.tar.bz2;;
*) echo "please update script with url for branch $cefbranch"; exit 1;;
esac

dir=$(basename $file .tar.bz2)

#---------------------- Download, unpack ----------------------

if ! test -f $file
then
  url=http://opensource.spotify.com/cefbuilds/$file
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
   sed -i.bak -E '/void On(Take|Got)Focus/s/) {/) override {/' $dir/tests/ceftests/os_rendering_unittest.cc
fi

#---------------------- Configure, compile ----------------------

# Force libc++... is this needed anymore?
#sed -i.bak \
#  -e 's/-fobjc-call-cxx-cdtors/-fobjc-call-cxx-cdtors -stdlib=libc++/' \
#  -e 's/-Wl,-ObjC/-Wl,-ObjC -stdlib=libc++/' \
#  ${dir}/cmake/cef_variables.cmake

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
cp -a $kind/tests/cefclient/$kind/cefclient.app "$DESTDIR$SUBPREFIX/$kind"

# Install include files.  (Shared between Release and Debug, so no $kind in path.)
rm -rf "$DESTDIR$SUBPREFIX/include"
install -m755 -d "$DESTDIR$SUBPREFIX/include"
cp -a ${dir}/include/* "$DESTDIR$SUBPREFIX/include"

# Install the wrapper we built above
rm -rf "$DESTDIR$SUBPREFIX/$kind/lib"
install -m755 -d "$DESTDIR$SUBPREFIX/$kind/lib"
install -m644 $kind/libcef_dll*/libcef_dll_wrapper.a "$DESTDIR/$SUBPREFIX/$kind/lib"

# FIXME: permissions aren't quite right for some reason, fix them
chmod 755 "$DESTDIR$SUBPREFIX/$kind/cefclient.app/Contents/MacOS/cefclient"
chmod 755 "$DESTDIR$SUBPREFIX/$kind/cefclient.app/Contents/Frameworks/cefclient Helper.app/Contents/MacOS/cefclient Helper"
