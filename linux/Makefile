# Download and install cef
#
# Example:
#   sudo make prefix
#   make
#   ./tiny

prefix    = /opt/tinycef
cefbranch = 3112
kind      = Release

subprefix       := $(prefix)/cef$(cefbranch)
PKG_CONFIG_PATH := $(prefix)/lib/pkgconfig:$(PKG_CONFIG_PATH)
REALUSER        := $(shell logname)

all: tiny

clean:
	rm -rf tiny btmp *.tmp chrome-sandbox icudtl.dat natives_blob.bin snapshot_blob.bin

#--- Rule to build cef demo ---

tiny: tiny.cpp $(subprefix)
	g++ \
            -fdiagnostics-show-option \
            -std=c++11 \
            -I$(subprefix) \
	    -DCEFCLIENT_DIR=\"$(subprefix)/$(kind)/cefclient/$(kind)\" \
            tiny.cpp \
            -Wl,-rpath $(subprefix)/$(kind)/cefclient/Release -L$(subprefix)/$(kind)/cefclient/Release -lcef \
            -L$(subprefix)/$(kind)/lib -lcef_dll_wrapper \
            -lX11 \
            -o tiny
	ln -sf $(subprefix)/$(kind)/cefclient/$(kind)/icudtl.dat .
	ln -sf $(subprefix)/$(kind)/cefclient/$(kind)/chrome-sandbox .
	ln -sf $(subprefix)/$(kind)/cefclient/$(kind)/natives_blob.bin .
	ln -sf $(subprefix)/$(kind)/cefclient/$(kind)/snapshot_blob.bin .

#--- Rules to build and install cef wrapper ---

# Manual rule to create empty install directory
prefix:
	rm -rf $(prefix)
	make $(prefix)

$(prefix):
	echo "Creating empty $(prefix) owned by you.  If this fails, read Makefile, then run manually with 'sudo make prefix'"
	mkdir $(prefix)
	chown $(REALUSER) $(prefix)

$(subprefix): $(prefix)
	echo "Building, downloading, installing cefwrapper to $(prefix)"
	PREFIX=$(prefix) sh buildwrapper.sh $(cefbranch)
