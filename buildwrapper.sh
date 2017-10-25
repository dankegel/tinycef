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

set -e
set -x

PREFIX=${PREFIX:-/opt/tinycef}
cefbranch=${1:-3112}

case $cefbranch in
3112) url=http://opensource.spotify.com/cefbuilds/cef_binary_3.3112.1659.gfef43e0_macosx64.tar.bz2;;
3163) url=http://opensource.spotify.com/cefbuilds/cef_binary_3.3163.1671.g700dc25_macosx64.tar.bz2;;
*) echo "please update script with url for branch $cefbranch"; exit 1;;
esac

dir=$(basename $url .tar.bz2)

#---------------------- Download, unpack ----------------------

wget --continue $url
# Verify download complete
rm -f $dir.tar.bz2.sha1
wget $dir.tar.bz2.sha1
shasum -a 1 -c $dir.tar.bz2.sha1
 
rm -rf btmp
mkdir btmp
cd btmp
tar -xf ../${dir}.tar.bz2

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
cp -a $kind/cefclient/cefclient.app "$DESTDIR$SUBPREFIX/$kind"
# FIXME: we used cp -a to install a tree, so blanket fix file permissions to make executable files world executable
find "$DESTDIR$SUBPREFIX" -type f -perm +x -exec chmod 755 '{}' \;

# Install include files.  (Shared between Release and Debug, so no $kind in path.)
rm -rf "$DESTDIR$SUBPREFIX/include"
install -m755 -d "$DESTDIR$SUBPREFIX/include"
cp -a ${dir}/include/* "$DESTDIR$SUBPREFIX/include"
# FIXME: we used cp -a to install a tree, so blanket fix file permissions to make include files world readable
find "$DESTDIR$SUBPREFIX" -type f -exec chmod 644 '{}' \;

# Install the wrapper we built above
rm -rf "$DESTDIR$SUBPREFIX/$kind/lib"
install -m755 -d "$DESTDIR$SUBPREFIX/$kind/lib"
install -m644 $kind/libcef_dll*/libcef_dll_wrapper.a "$DESTDIR/$SUBPREFIX/$kind/lib"

# Install a .pc file so app can use pkg-config to get cc and ld options
# This goes up in $PREFIX/lib instead of $SUBPREFIX/lib, so app only needs to add one directory to PKG_CONFIG_PATH
# It coexists with other .pc files, so don't rm -rf destination directory
install -m755 -d "$DESTDIR$PREFIX/lib/pkgconfig"
sed -e "s,@PREFIX@,$PREFIX," \
    -e "s,@CEFBRANCH@,$cefbranch," \
    -e "s,@KIND@,$kind," \
    < ../libcef.pc.mac.in > libcef$cefbranch-$kind.pc
install -m644 libcef$cefbranch-$kind.pc "$DESTDIR$PREFIX/lib/pkgconfig/libcef$cefbranch-$kind.pc"

# FIXME: we used cp -a to install a tree, so blanket fix directory permissions to make product usable by world
find "$DESTDIR$SUBPREFIX" -type d -exec chmod 755 '{}' \;
