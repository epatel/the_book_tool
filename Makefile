info: menu select

menu:
	echo "1 make reset           - flutter clean ; flutter pub get"
	echo "2 make update_phony    - update .PHONY in Makefile"
	echo "3 make build           - flutter build macos"
	echo "4 make xcode           - open project in Xcode (for archiving and export)"
	echo "5 make release         - archive and export a Developer ID signed .app"
	echo "6 make notarize        - release, submit to Apple, staple and verify"
	echo "7 make notary_creds    - store notarization credentials in the keychain"

select:
	read -p ">>> " P ; make menu | grep "^$$P " | cut -d ' ' -f2-3 ; make menu | grep "^$$P " | cut -d ' ' -f2-3 | bash

.SILENT:

.PHONY: info menu select reset update_phony build xcode release notary_check notarize notary_creds 

# Signing and notarization. Override on the command line if these change,
# e.g. make notarize NOTARY_PROFILE=other-profile
TEAM_ID        ?= 67Y4XH38L7
NOTARY_PROFILE ?= the-book-tool
ARCHIVE        := build/macos/TheBookTool.xcarchive
DIST           := build/dist
EXPORT_OPTIONS := build/ExportOptions.plist

reset:
	flutter clean ; flutter pub get

update_phony:
	@echo "##### Updating .PHONY targets #####"
	@targets=$$(grep -E '^[a-zA-Z_][a-zA-Z0-9_-]*:' Makefile | grep -v '=' | cut -d: -f1 | tr '\n' ' '); \
	sed -i.bak "s/^\.PHONY:.*/.PHONY: $$targets/" Makefile && \
	echo "Updated .PHONY: $$targets" && \
	rm -f Makefile.bak

build:
	echo "##### Clean build #####"
	flutter clean
	rm -fvr build
	echo "##### Build for macos #####"
	flutter build macos --release

xcode:
	open macos/Runner.xcworkspace

# Goes through xcodebuild archive/exportArchive rather than re-signing the
# flutter build output. That is what gets us a distributable app: the Release
# config signs with "Apple Development", which injects get-task-allow (Apple
# rejects notarization for it), and Release.entitlements uses
# $(AppIdentifierPrefix), which only expands during an Xcode build.
release:
	echo "##### Flutter release build #####"
	flutter build macos --release
	echo "##### Archiving #####"
	rm -rf $(ARCHIVE) $(DIST)
	xcodebuild -workspace macos/Runner.xcworkspace \
		-scheme Runner \
		-configuration Release \
		-archivePath $(ARCHIVE) \
		-destination 'generic/platform=macOS' \
		archive
	echo "##### Exporting Developer ID build #####"
	mkdir -p $(DIST)
	printf '%s\n' \
		'<?xml version="1.0" encoding="UTF-8"?>' \
		'<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' \
		'<plist version="1.0">' \
		'<dict>' \
		'	<key>method</key><string>developer-id</string>' \
		'	<key>teamID</key><string>$(TEAM_ID)</string>' \
		'	<key>signingStyle</key><string>automatic</string>' \
		'	<key>destination</key><string>export</string>' \
		'</dict>' \
		'</plist>' > $(EXPORT_OPTIONS)
	xcodebuild -exportArchive \
		-archivePath $(ARCHIVE) \
		-exportOptionsPlist $(EXPORT_OPTIONS) \
		-exportPath $(DIST)
	echo "##### Checking the export is notarizable #####"
	APP=$$(ls -d $(DIST)/*.app | head -1) ; \
	if codesign -d --entitlements :- "$$APP" 2>/dev/null | grep -q get-task-allow ; then \
		echo "ERROR: $$APP still has get-task-allow; it was not signed with Developer ID." ; \
		exit 1 ; \
	fi ; \
	codesign -dvv "$$APP" 2>&1 | grep -E "Authority|TeamIdentifier|flags" ; \
	echo "##### Exported $$APP #####"

# Checked before `release` runs, so a missing profile fails in seconds
# instead of after a full archive and export. notarytool stores profiles in a
# keychain the `security` CLI cannot search, so ask notarytool itself; that
# costs a network round trip but is the only reliable answer.
notary_check:
	if xcrun notarytool history --keychain-profile "$(NOTARY_PROFILE)" 2>&1 \
		| grep -q "No Keychain password item found" ; then \
		echo "No notarization profile '$(NOTARY_PROFILE)' found. Run: make notary_creds" ; \
		exit 1 ; \
	fi

# Uploads the app to Apple. Needs credentials stored by `make notary_creds`.
notarize: notary_check release
	APP=$$(ls -d $(DIST)/*.app | head -1) ; \
	ZIP="$(DIST)/$$(basename "$$APP" .app).zip" ; \
	echo "##### Zipping for submission #####" ; \
	ditto -c -k --keepParent "$$APP" "$$ZIP" ; \
	echo "##### Submitting to Apple - this uploads the app and may take minutes #####" ; \
	xcrun notarytool submit "$$ZIP" --keychain-profile "$(NOTARY_PROFILE)" --wait ; \
	echo "##### Stapling the ticket #####" ; \
	xcrun stapler staple "$$APP" ; \
	echo "##### Verifying #####" ; \
	spctl -a -vvv -t exec "$$APP" ; \
	codesign --verify --deep --strict --verbose=2 "$$APP" ; \
	rm -f "$$ZIP" ; \
	echo "##### Notarized $$APP #####"

# Prompts for an app-specific password from appleid.apple.com
# (Sign-In and Security -> App-Specific Passwords).
#
# Reads the Apple ID here and binds notarytool's stdin to the terminal, so only
# the password uses notarytool's own secure prompt. Without the /dev/tty
# redirect notarytool traps (SIGTRAP) instead of erroring whenever stdin is not
# a terminal, which is what happens when this runs through the piped `select`
# menu.
notary_creds:
	echo "##### Storing notarization credentials as '$(NOTARY_PROFILE)' #####"
	echo "Needs your Apple ID and an app-specific password from appleid.apple.com"
	echo "(Sign-In and Security -> App-Specific Passwords)"
	printf "Apple ID: " > /dev/tty ; \
	read APPLE_ID < /dev/tty ; \
	xcrun notarytool store-credentials "$(NOTARY_PROFILE)" \
		--apple-id "$$APPLE_ID" \
		--team-id $(TEAM_ID) < /dev/tty
