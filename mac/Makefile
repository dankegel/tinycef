# Download and install cef, and build a tiny example app that uses it.
#
# Example:
#   sudo make prefix
#   make
#   open tiny.app

prefix    = /opt/tinycef
cefbranch = 3112
kind      = Release

subprefix       := $(prefix)/cef$(cefbranch)
PKG_CONFIG_PATH := $(prefix)/lib/pkgconfig:$(PKG_CONFIG_PATH)
REALUSER        := $(shell who am i | awk '{print $$1}')
cefwrapper_h    := $(subprefix)/include/cef_app.h

all: tiny tiny-cocoa tiny-cocoa-diy

clean:
	rm -rf tiny tiny.app tiny-cocoa tiny-cocoa-diy btmp *.tmp

#--- Rule to build cef demo ---

# Edit to add or remove -DDIYRUN depending on what code path you want to test

tiny: tiny.mm $(cefwrapper_h)
	clang++ --std=c++11 -Wno-deprecated-declarations \
            -DCEF \
            -DDIYRUN \
	    -I$(subprefix) \
	    -rpath @executable_path/.. \
            -F$(subprefix)/$(kind)/cefclient.app/Contents/Frameworks -framework 'Chromium Embedded Framework' \
            -L$(subprefix)/$(kind)/lib -lcef_dll_wrapper \
            -framework Cocoa tiny.mm -o tiny
	# Appify it
	rm -rf tiny.app
	mkdir -p "tiny.app/Contents/Frameworks"
	mkdir -p "tiny.app/Contents/MacOS"
	install -m 755 tiny "tiny.app/Contents/MacOS"
	install -m644 circle.png tiny.app/circle.png
	# Borrow cefclient's helper app
	ln -sf "$(subprefix)/$(kind)/Chromium Embedded Framework.framework/Resources" "tiny.app/Contents/."
	ln -s "$(subprefix)/$(kind)/cefclient.app/Contents/Frameworks/Chromium Embedded Framework.framework" "tiny.app/Contents/Frameworks"
	cp -a "$(subprefix)/$(kind)/cefclient.app/Contents/Frameworks/cefclient Helper.app" "tiny.app/Contents/Frameworks/tiny Helper.app"
	sed -i.bak "s/cefclient/tiny/"  "tiny.app/Contents/Frameworks/tiny Helper.app/Contents/Info.plist"
	mv "tiny.app/Contents/Frameworks/tiny Helper.app/Contents/MacOS/cefclient Helper" "tiny.app/Contents/Frameworks/tiny Helper.app/Contents/MacOS/tiny Helper"
	chmod 755 "tiny.app/Contents/Frameworks/tiny Helper.app/Contents/MacOS/tiny Helper"

#--- Rules to build non-cef demos ---

# Tiny cocoa app
tiny-cocoa: tiny.mm
	clang++          -framework Cocoa tiny.mm -o tiny-cocoa

# Tiny cocoa app with DIY runloop
tiny-cocoa-diy: tiny.mm
	clang++ -DDIYRUN -framework Cocoa tiny.mm -o tiny-cocoa-diy

#--- Rules to build and install cef wrapper ---

# Manual rule to create empty install directory
prefix:
	rm -rf $(prefix)
	make $(prefix)

$(prefix):
	echo "Creating empty $(prefix) owned by you.  If this fails, read Makefile, then run manually with 'sudo make prefix'"
	mkdir $(prefix)
	chown $(REALUSER) $(prefix)

$(cefwrapper_h): $(prefix)
	echo "Building, downloading, installing cefwrapper to $(prefix)"
	PREFIX=$(prefix) sh buildwrapper.sh $(cefbranch)
