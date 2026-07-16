APP := QuickCmd.app
BIN := .build/release/QuickCmd

.PHONY: build bundle run clean

build:
	swift build -c release

bundle: build
	rm -rf $(APP)
	mkdir -p $(APP)/Contents/MacOS
	cp $(BIN) $(APP)/Contents/MacOS/QuickCmd
	cp Info.plist $(APP)/Contents/Info.plist
	/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $(shell git rev-parse --short HEAD)" $(APP)/Contents/Info.plist
	codesign --force --deep --sign - $(APP)

run: bundle
	open $(APP)

clean:
	rm -rf .build $(APP)
