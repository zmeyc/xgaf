UNAME = ${shell uname}
ifneq ($(findstring CYGWIN,$(UNAME)),)  
  UNAME := CYGWIN
endif

ifeq ($(UNAME), Darwin)
PREFIX = $(shell pwd)/libroot/macos
SWIFT_FLAGS =
endif

ifeq ($(UNAME), CYGWIN)
CYGWIN_DIR = c:\cygwin64
PREFIX = $(shell pwd)/libroot/cygwin
STANDALONE_PREFIX = $(shell pwd)/standalone/cygwin
SWIFT_FLAGS =
endif

SWIFT_BIN_DIR = $(shell dirname $(shell where swift))

all: debug

debug:
	@echo "Compiling for $(UNAME) (DEBUG)"
	swift build -c debug $(SWIFT_FLAGS)

release:
	@echo "Compiling for $(UNAME) (RELEASE)"
	swift build -c release $(SWIFT_FLAGS)

ifeq ($(UNAME), CYGWIN)
standalone-release: release
	mkdir -p "$(STANDALONE_PREFIX)"	
	cp "$(CYGWIN_DIR)/bin/cyggcc_s-seh-1.dll" "$(STANDALONE_PREFIX)"
	cp "$(CYGWIN_DIR)/bin/cygicudata57.dll" "$(STANDALONE_PREFIX)"
	cp "$(CYGWIN_DIR)/bin/cygicui18n57.dll" "$(STANDALONE_PREFIX)"
	cp "$(CYGWIN_DIR)/bin/cygicuuc57.dll" "$(STANDALONE_PREFIX)"
	cp "$(CYGWIN_DIR)/bin/cygstdc++-6.dll" "$(STANDALONE_PREFIX)"
	cp "$(CYGWIN_DIR)/bin/cygwin1.dll" "$(STANDALONE_PREFIX)"
	cp "$(SWIFT_BIN_DIR)/cygswiftCore.dll" "$(STANDALONE_PREFIX)"
	cp "$(SWIFT_BIN_DIR)/cygswiftGlibc.dll" "$(STANDALONE_PREFIX)"
	cp "$(SWIFT_BIN_DIR)/cygswiftSwiftOnoneSupport.dll" "$(STANDALONE_PREFIX)"
endif

xcodeproj:
	swift package generate-xcodeproj $(SWIFT_FLAGS)

clean:
	swift build --clean

distclean: clean
	rm -rf libroot standalone

.PHONY: all debug release standalone-release xcodeproj clean distclean
