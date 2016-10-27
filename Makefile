
UNAME = ${shell uname}
ifneq ($(findstring CYGWIN,$(UNAME)),)  
  UNAME := CYGWIN
endif

ifeq ($(UNAME), Darwin)
PREFIX = $(shell pwd)/libroot/macos
SWIFT_FLAGS =
endif

ifeq ($(UNAME), CYGWIN)
PREFIX = $(shell pwd)/libroot/cygwin
SWIFT_FLAGS =
endif

all: debug

debug:
	@echo "Compiling for $(UNAME) (DEBUG)"
	swift build -c debug $(SWIFT_FLAGS)

release:
	@echo "Compiling for $(UNAME) (RELEASE)"
	swift build -c release $(SWIFT_FLAGS)

xcodeproj:
	mkdir -p "$(PREFIX)"
	swift package generate-xcodeproj $(SWIFT_FLAGS)

clean:
	swift build --clean

distclean: clean
	rm -rf libroot

.PHONY: all debug release xcodeproj clean distclean
