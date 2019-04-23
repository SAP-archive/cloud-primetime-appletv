# PrimeTime - Apple TV
## Introduction
The PrimeTime Apple TV app is a companion application to [PrimeTime](https://github.com/SAP/cloud-primetime) to easily onboard new screens and show content.

## Description
The PrimeTime Apple TV app is the client to PrimeTime that can be remote controlled from the server for displaying changing screen content. It also reports status information from the app, like the current version, last errors, and also screenshots of what is currently displayed.

Note: The app uses UIWebView, which is a private API on tvOS.

## Requirements
AppleTV 4th Generation

## Download and installation
Use XCode to build the app. There are two build configurations:

* PrimeTime Config: Used for builds that embed the config file in the app package and do not require mobile device management
* PrimeTime MDM: Used for builds that do not include the config file but excpect it to be pushed by mobile device management

Usually you run the PrimeTime Apple TV app in single app mode to ensure automatic restart in case anything goes wrong.

## Configuration
You need to provide a config file, either included in the app package (PrimeTime Config build configuration) or pushed by an MDM solution (PrimeTime MDM build configuration). In both cases the file is named `config.plist` and has this content:

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

## How to obtain support
Please use GitHub [issues](https://github.com/SAP/cloud-primetime-appletv/issues/new) for any bugs to be reported.

## Contributing
Contributions are very welcome.

## License
Copyright (c) 2019 SAP SE or an SAP affiliate company. All rights reserved. This file is licensed under the Apache Software License v2, except as noted otherwise in the [LICENSE](/LICENSE) file.