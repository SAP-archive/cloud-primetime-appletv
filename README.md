# PrimeTime - Apple TV
## Introduction
The PrimeTime Apple TV app is a companion application to [PrimeTime](https://github.com/SAP/cloud-primetime) to easily onboard new screens and show content.

## Description
The PrimeTime Apple TV app is the client to PrimeTime that can be remote controlled from the server for displaying changing screen content. It also reports status information from the app, like the current version, last errors, and also screenshots of what is currently displayed.

Note: The app uses UIWebView, which is a private API on tvOS.

## Requirements
* AppleTV 4th Generation
* [`Apple Developer Enterprise Program`](https://developer.apple.com/programs/enterprise/) membership for in-house distribution

## Configuration
The PrimeTime Apple TV app needs to be configured to connect and authenticate to PrimeTime. Depending on the used XCode scheme (see also section `Schemes` for more details) there are different options on how to configure the app:
* `PrimeTimeConfig` scheme
  * A `config.plist` file has to be included in the app package by placing the file under the path `cloud-primetime-appletv/PrimeTime/config.plist`
* `PrimeTimeMDM` scheme
  * Configuration pushed by a mobile device management (MDM) solution

The configuration should have the following content:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>homepageURL</key>
	<string>https://[primetime hostname]/?screenKey=%@&amp;onboard=true</string>
	<key>screenshotURL</key>
	<string>https://[primetime hostname]/c/api/fileservice/screenkey/%@</string>
	<key>configURL</key>
	<string>https://[primetime hostname]/c/api/systemservice/info?screenKey=%@</string>
	<key>reportingURL</key>
	<string>https://[primetime hostname]/c/api/screenservice/screenkey/%@/appliancestart</string>
	<key>certificate</key>
	<string>[base64 encoded .p12 client certificate]</string>
	<key>passphrase</key>
	<string>[client certificate passphrase]</string>
</dict>
</plist>
```

## Build
Use [XCode](https://itunes.apple.com/de/app/xcode/id497799835) to build the app with one of the two schemes:

### Schemes
* `PrimeTimeConfig`
  * Use this scheme to build and run the app in the tvOS simulator or on an AppleTV for testing purposes
  * This scheme embeds the `config.plist` file in the app package and does not require mobile device management
* `PrimeTimeMDM`
  * This is the preferred scheme for builds signed with an enterprise certificate for distribution in-house
  * This scheme does not include the `config.plist` file but expect the configuration to be pushed by MDM

For productive usage it is recommended to run the PrimeTime Apple TV app in single app mode to ensure automatic restart in case anything goes wrong.

### How to test in tvOS simulator
1. Place `config.plist` under `cloud-primetime-appletv/PrimeTime/config.plist` as described under `Configuration`
2. Open `PrimeTime.xcodeproj` with XCode
3. Select `PrimeTimeConfig` scheme and choose one of the tvOS simulators as device
4. Press the `Run` button to run the app in the simulator
5. Follow the instructions displayed in the app

## How to obtain support
Please use GitHub [issues](https://github.com/SAP/cloud-primetime-appletv/issues/new) for any bugs to be reported.

## Contributing
Contributions are very welcome.

## License
Copyright (c) 2019 SAP SE or an SAP affiliate company. All rights reserved. This file is licensed under the Apache Software License v2, except as noted otherwise in the [LICENSE](/LICENSE) file.