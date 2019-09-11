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
3202) file=cef_binary_3.3202.1677.gd04a869_macosx64.tar.bz2;;
3282) file=cef_binary_3.3282.1742.g96f907e_macosx64.tar.bz2;;
3325) file=cef_binary_3.3325.1758.g9aea513_macosx64.tar.bz2;;
3359) file=cef_binary_3.3359.1774.gd49d25f_macosx64.tar.bz2;;
3396) file=cef_binary_3.3396.1779.g36f9eab_macosx64.tar.bz2;;
3497) file=cef_binary_3.3497.1841.g7f37a0a_macosx64.tar.bz2;;
3683) file=cef_binary_3.3683.1920.g9f41a27_macosx64.tar.bz2;;
3729) file=cef_binary_74.1.19+gb62bacf+chromium-74.0.3729.157_macosx64.tar.bz2;;
3770) file=cef_binary_75.1.14+gc81164e+chromium-75.0.3770.100_macosx64.tar.bz2;;
3809) file=cef_binary_76.1.13+gf19c584+chromium-76.0.3809.132_macosx64.tar.bz2;;
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
if test $cefbranch = 3396
then
   # Work around https://bitbucket.org/chromiumembedded/cef/issues/2465/3396-cefclient-build-failure-from-missing
   sed -i.bak -E '/void ReleaseBuffer/s/) {/) override {/' $dir/tests/ceftests/v8_unittest.cc
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
