# Makefile - build and release tooling for the kawa fork.
SHELL := /bin/bash

SCHEME := kawa
PROJECT := kawa.xcodeproj
BUILD_DIR := build
ARCHIVE := $(BUILD_DIR)/kawa.xcarchive
APP := $(BUILD_DIR)/Kawa.app
ZIP := $(BUILD_DIR)/Kawa.zip

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Build

.PHONY: bootstrap
bootstrap: ## fetch and build Carthage deps (universal: --no-use-binaries)
	XCODE_XCCONFIG_FILE="$(CURDIR)/carthage.xcconfig" carthage bootstrap --platform macOS --no-use-binaries --cache-builds

.PHONY: build
build: ## build the app (Release, universal arm64+x86_64)
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Release build ONLY_ACTIVE_ARCH=NO ARCHS="arm64 x86_64" -derivedDataPath $(BUILD_DIR)/DerivedData CODE_SIGN_IDENTITY=-

##@ Distribution

.PHONY: archive
archive: ## xcodebuild archive (universal arm64+x86_64)
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) archive -archivePath $(ARCHIVE) ONLY_ACTIVE_ARCH=NO ARCHS="arm64 x86_64"

.PHONY: export
export: archive ## extract Kawa.app from the archive
	rm -rf "$(APP)"
	ditto "$(ARCHIVE)/Products/Applications/Kawa.app" "$(APP)"

.PHONY: zip
zip: export ## zip Kawa.app with ditto
	ditto -c -k --sequesterRsrc --keepParent "$(APP)" "$(ZIP)"

.PHONY: sha256
sha256: zip ## write and print the zip's sha256 checksum
	shasum -a 256 "$(ZIP)" | awk '{ print $$1 }' > "$(ZIP).sha256"
	cat "$(ZIP).sha256"

.PHONY: verify-dist
verify-dist: ## check universal arch (arm64+x86_64) and codesign of the built app
	@arch_bin="$$(lipo -archs "$(APP)/Contents/MacOS/Kawa")"; \
	echo "$$arch_bin" | grep -q arm64 || { echo "FAIL: $(APP)/Contents/MacOS/Kawa missing arm64" >&2; exit 1; }; \
	echo "$$arch_bin" | grep -q x86_64 || { echo "FAIL: $(APP)/Contents/MacOS/Kawa missing x86_64" >&2; exit 1; }
	@arch_fw="$$(lipo -archs "$(APP)/Contents/Frameworks/MASShortcut.framework/MASShortcut")"; \
	echo "$$arch_fw" | grep -q arm64 || { echo "FAIL: MASShortcut.framework missing arm64" >&2; exit 1; }; \
	echo "$$arch_fw" | grep -q x86_64 || { echo "FAIL: MASShortcut.framework missing x86_64" >&2; exit 1; }
	codesign --verify --deep --strict "$(APP)"
	@echo "OK: verify-dist passed"

.PHONY: dist
dist: ## full release artifact chain: bootstrap+archive+export+zip+sha256+verify-dist
	$(MAKE) bootstrap
	$(MAKE) sha256
	$(MAKE) verify-dist

##@ Version

.PHONY: print-version
print-version: ## print current CFBundleShortVersionString
	@scripts/version.sh

.PHONY: bump-version
bump-version: ## set CFBundleShortVersionString (make bump-version VERSION=X.Y.Z)
	@if [ -z "$(VERSION)" ]; then \
		echo "Usage: make bump-version VERSION=X.Y.Z" >&2; \
		exit 1; \
	fi
	scripts/bump-version.sh "$(VERSION)"

.PHONY: status
status: ## compare info.plist, latest GitHub release and Homebrew cask versions
	@scripts/status.sh

##@ Quality

.PHONY: lint
lint: ## swiftlint + shellcheck
	swiftlint lint
	shellcheck scripts/*.sh

##@ Cleanup

.PHONY: clean
clean: ## remove build/
	rm -rf $(BUILD_DIR)
