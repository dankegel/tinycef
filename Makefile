# Download and install cef, and build a tiny example app that uses it.
#
# Example:
#   sudo make cleanprefix
#   make
#   open tiny.app

prefix = /opt/tinycef
cefbranch = 3112     # or 3163
kind = Release

all: tiny tiny-cocoa tiny-cocoa-diy

run: tiny
	tiny.app/Contents/MacOS/tiny

debug: tiny
	lldb tiny.app/Contents/MacOS/tiny
clean:
	rm -rf tiny tiny.app tiny-cocoa tiny-cocoa-diy

subprefix := $(prefix)/cef$(cefbranch)

cleanprefix:
	echo "Nuking and recreating empty $(prefix) owned by you, run with sudo if you're sure"
	rm -rf $(prefix)
	mkdir $(prefix)
	# Could use $LOGNAME or $(id -u) instead of $USER
	chown $USER $(prefix)

$(prefix)/lib/pkg-config/cef$(cefbranch)-$(kind).pc:
	echo "Building, downloading, installing cefwrapper to $(prefix)"
	PREFIX=$(prefix) sh buildwrapper.sh $(cefbranch)

PKG_CONFIG_PATH := $(prefix)/lib/pkgconfig:$(PKG_CONFIG_PATH)
export PKG_CONFIG_PATH
CEFFLAGS := $(shell pkg-config --cflags --libs cef$(cefbranch)-$(kind))

# Tiny cef app
tiny: tiny.mm $(prefix)/lib/pkg-config/cef$(cefbranch)-$(kind).pc:
	clang++ --std=c++11 -Wno-deprecated-declarations \
            -DCEF \
            -DDIYRUN \
            $(CEFFLAGS) \
            -framework Cocoa tiny.mm -o tiny
	# Appify it
	rm -rf tiny.app
	mkdir -p "tiny.app/Contents/Frameworks"
	mkdir -p "tiny.app/Contents/MacOS"
	install -m 755 tiny "tiny.app/Contents/MacOS"
	# Borrow cefclient's helper app
	ln -sf "$(cefdir)/$(kind)/Chromium Embedded Framework.framework/Resources" "tiny.app/Contents/."
	ln -s "$(cefdir)/$(kind)/cefclient.app/Contents/Frameworks/Chromium Embedded Framework.framework" "tiny.app/Contents/Frameworks"
	cp -a "$(cefdir)/$(kind)/cefclient.app/Contents/Frameworks/cefclient Helper.app" "tiny.app/Contents/Frameworks/tiny Helper.app"
	sed -i.bak "s/cefclient/tiny/"  "tiny.app/Contents/Frameworks/tiny Helper.app/Contents/Info.plist"
	mv "tiny.app/Contents/Frameworks/tiny Helper.app/Contents/MacOS/cefclient Helper" "tiny.app/Contents/Frameworks/tiny Helper.app/Contents/MacOS/tiny Helper"

# Alternate builds, not involving cef, useful for debugging launch problems

# Tiny cocoa app
tiny-cocoa: tiny.mm
	clang++          -framework Cocoa tiny.mm -o tiny-cocoa

# Tiny cocoa app with DIY runloop
tiny-cocoa-diy: tiny.mm
	clang++ -DDIYRUN -framework Cocoa tiny.mm -o tiny-cocoa-diy
