APP_NAME = SleepBlocker
BUNDLE_ID = com.cacheventures.SleepBlocker
BUILD_DIR = build
VERSION = $(shell /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Resources/Info.plist)
DMG_PATH = $(BUILD_DIR)/$(APP_NAME)-$(VERSION).dmg
APP_DIR = $(BUILD_DIR)/$(APP_NAME).app
CONTENTS = $(APP_DIR)/Contents
MACOS_DIR = $(CONTENTS)/MacOS
RES_DIR = $(CONTENTS)/Resources

SWIFT_SOURCES = $(wildcard Sources/*.swift)
SDK = $(shell xcrun --sdk macosx --show-sdk-path)
ARCH = $(shell uname -m)
DEPLOYMENT = 13.0

SWIFTC = swiftc
SWIFT_FLAGS = \
	-O \
	-target $(ARCH)-apple-macos$(DEPLOYMENT) \
	-sdk $(SDK) \
	-framework AppKit \
	-framework SwiftUI \
	-framework IOKit \
	-framework UserNotifications \
	-framework ServiceManagement

all: $(APP_DIR)

$(APP_DIR): $(SWIFT_SOURCES) Resources/Info.plist $(BUILD_DIR)/AppIcon.icns
	@mkdir -p $(MACOS_DIR) $(RES_DIR)
	$(SWIFTC) $(SWIFT_FLAGS) -o $(MACOS_DIR)/$(APP_NAME) $(SWIFT_SOURCES)
	cp Resources/Info.plist $(CONTENTS)/Info.plist
	cp $(BUILD_DIR)/AppIcon.icns $(RES_DIR)/AppIcon.icns
	@codesign --force --deep --sign - $(APP_DIR) 2>/dev/null || true
	@touch $(APP_DIR)
	@echo ""
	@echo "Built $(APP_DIR)"
	@echo "Run with:  make run"

$(BUILD_DIR)/icon-1024.png: scripts/make_icon.swift
	@mkdir -p $(BUILD_DIR)
	swift scripts/make_icon.swift $(BUILD_DIR)/icon-1024.png

$(BUILD_DIR)/AppIcon.icns: $(BUILD_DIR)/icon-1024.png
	@rm -rf $(BUILD_DIR)/AppIcon.iconset
	@mkdir -p $(BUILD_DIR)/AppIcon.iconset
	sips -z 16 16     $(BUILD_DIR)/icon-1024.png --out $(BUILD_DIR)/AppIcon.iconset/icon_16x16.png > /dev/null
	sips -z 32 32     $(BUILD_DIR)/icon-1024.png --out $(BUILD_DIR)/AppIcon.iconset/icon_16x16@2x.png > /dev/null
	sips -z 32 32     $(BUILD_DIR)/icon-1024.png --out $(BUILD_DIR)/AppIcon.iconset/icon_32x32.png > /dev/null
	sips -z 64 64     $(BUILD_DIR)/icon-1024.png --out $(BUILD_DIR)/AppIcon.iconset/icon_32x32@2x.png > /dev/null
	sips -z 128 128   $(BUILD_DIR)/icon-1024.png --out $(BUILD_DIR)/AppIcon.iconset/icon_128x128.png > /dev/null
	sips -z 256 256   $(BUILD_DIR)/icon-1024.png --out $(BUILD_DIR)/AppIcon.iconset/icon_128x128@2x.png > /dev/null
	sips -z 256 256   $(BUILD_DIR)/icon-1024.png --out $(BUILD_DIR)/AppIcon.iconset/icon_256x256.png > /dev/null
	sips -z 512 512   $(BUILD_DIR)/icon-1024.png --out $(BUILD_DIR)/AppIcon.iconset/icon_256x256@2x.png > /dev/null
	sips -z 512 512   $(BUILD_DIR)/icon-1024.png --out $(BUILD_DIR)/AppIcon.iconset/icon_512x512.png > /dev/null
	cp $(BUILD_DIR)/icon-1024.png $(BUILD_DIR)/AppIcon.iconset/icon_512x512@2x.png
	iconutil -c icns $(BUILD_DIR)/AppIcon.iconset -o $(BUILD_DIR)/AppIcon.icns

run: $(APP_DIR)
	@pkill -x $(APP_NAME) 2>/dev/null || true
	open $(APP_DIR)

stop:
	@pkill -x $(APP_NAME) 2>/dev/null && echo "Stopped" || echo "Not running"

clean:
	rm -rf $(BUILD_DIR)

install: $(APP_DIR)
	@pkill -x $(APP_NAME) 2>/dev/null || true
	rm -rf /Applications/$(APP_NAME).app
	cp -R $(APP_DIR) /Applications/
	@echo "Installed to /Applications/$(APP_NAME).app"

dmg: $(APP_DIR)
	./scripts/make_dmg.sh $(APP_DIR) $(DMG_PATH) $(APP_NAME)

release: dmg
	@command -v gh >/dev/null 2>&1 || { echo "gh CLI not installed. brew install gh"; exit 1; }
	@test -n "$(TAG)" || { echo "Usage: make release TAG=v0.1.0"; exit 1; }
	@echo "Creating GitHub release $(TAG) with $(DMG_PATH)"
	gh release create $(TAG) $(DMG_PATH) \
		--title "SleepBlocker $(TAG)" \
		--generate-notes

.PHONY: all run stop clean install dmg release
