.PHONY: gen open build run clean

gen:
	xcodegen generate

open: gen
	open TouchDeck.xcodeproj

build: gen
	xcodebuild -project TouchDeck.xcodeproj -scheme TouchDeck -configuration Debug -derivedDataPath build -allowProvisioningUpdates build

run: build
	open build/Build/Products/Debug/TouchDeck.app

clean:
	rm -rf build TouchDeck.xcodeproj
