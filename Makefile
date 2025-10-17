info: menu select

menu:
	echo "1 make reset           - flutter clean ; flutter pub get"
	echo "2 make update_phony    - update .PHONY in Makefile"
	echo "3 make build           - flutter build macos"
	echo "4 make xcode           - open project in Xcode (for archiving and export)"

select:
	read -p ">>> " P ; make menu | grep "^$$P " | cut -d ' ' -f2-3 ; make menu | grep "^$$P " | cut -d ' ' -f2-3 | bash

.SILENT:

.PHONY: info menu select reset update_phony build xcode 

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
