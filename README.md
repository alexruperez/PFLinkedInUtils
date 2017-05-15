# PFLinkedInUtils
[![Twitter](http://img.shields.io/badge/contact-@alexruperez-blue.svg?style=flat)](http://twitter.com/alexruperez)
[![GitHub Issues](http://img.shields.io/github/issues/alexruperez/PFLinkedInUtils.svg?style=flat)](http://github.com/alexruperez/PFLinkedInUtils/issues)
[![Version](https://img.shields.io/cocoapods/v/PFLinkedInUtils.svg?style=flat)](http://cocoadocs.org/docsets/PFLinkedInUtils)
[![License](https://img.shields.io/cocoapods/l/PFLinkedInUtils.svg?style=flat)](http://cocoadocs.org/docsets/PFLinkedInUtils)
[![Platform](https://img.shields.io/cocoapods/p/PFLinkedInUtils.svg?style=flat)](http://cocoadocs.org/docsets/PFLinkedInUtils)
[![Build Status](https://travis-ci.org/alexruperez/PFLinkedInUtils.svg?branch=master)](https://travis-ci.org/alexruperez/PFLinkedInUtils)
[![No Maintenance Intended](http://unmaintained.tech/badge.svg)](http://unmaintained.tech/)
[![Analytics](https://ga-beacon.appspot.com/UA-55329295-1/PFLinkedInUtils/readme?pixel)](https://github.com/igrigorik/ga-beacon)

## Overview

The PFLinkedInUtils class provides utility functions for working with LinkedIn in a Parse application.

*UPDATE:* As of the 12´ May 2015 LinkedIn applied restrictions to API usage for all non partners:

https://developer.linkedin.com/blog/posts/2015/developer-program-changes

*UPDATE:* As of the 28´ Jun 2016 Facebook wind down the Parse service:

http://blog.parse.com/announcements/moving-on/

This class currently supports iOS only.

![PFLinkedInUtils Screenshot](https://raw.githubusercontent.com/alexruperez/PFLinkedInUtils/master/screenshot.png)

## Usage

### Installation

PFLinkedInUtils is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

    pod "PFLinkedInUtils"

#### Or you can add the following files to your project:
* `PFLinkedInUtils.m`
* `PFLinkedInUtils.h`

#### And its dependencies:
* [Parse](https://www.parse.com)
* [IOSLinkedInAPI](https://github.com/jeyben/IOSLinkedInAPI)
* [AFNetworking](https://github.com/AFNetworking/AFNetworking)

To run the example project, clone the repo, and run `pod install` from the Example directory first.

### Setup

You need to create and configure a [LinkedIn app](https://developer.linkedin.com/docs/ios-sdk) and configure your application to be able the use the native LinkedIn app.

#### Info.plist

Replace `{LINKEDIN_APP_ID}` with your LinkedIn app id that your acquired during the LinkedIn app creation.

```xml
<!--Add a url scheme to your app, so LinkedIn can call back after login-->
<key>CFBundleURLTypes</key>
<array>
	<dict>
		<key>CFBundleURLSchemes</key>
		<array>
			<string>li{LINKEDIN_APP_ID}</string>
		</array>
	</dict>
</array>

<!--Allow the SDK in your app to test for the LinkedIn app URLs-->
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>linkedin</string>
    <string>linkedin-sdk2</string>
    <string>linkedin-sdk</string>
</array>

<!--Allow your app to open the native LinkedIn app-->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>linkedin.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <false/>
        </dict>
    </dict>
</dict>

<!--Configure LinkedIn SDK-->
<key>LIAppId</key>
<string>{LINKEDIN_APP_ID}</string>
```

#### AppDelegate

Handle the app callback in your AppDelegate.

```objectivec
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if ([PFLinkedInUtils shouldHandleUrl:url]) {
        return [PFLinkedInUtils application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
    }
    return YES;
}
```

### Example

```objectivec
[Parse initializeWithConfiguration:
     [ParseClientConfiguration configurationWithBlock:
      ^(id<ParseMutableClientConfiguration>  _Nonnull configuration) {
          configuration.applicationId = @"PARSE_APP_ID";
          configuration.clientKey = @"PARSE_CLIENT_KEY";
          configuration.server = @"PARSE_SERVER_URL";
      }]];

[PFLinkedInUtils initializeWithRedirectURL:@"LINKEDIN_REDIRECT_URL"
                                      clientId:@"LINKEDIN_CLIENT_ID"
                                  clientSecret:@"LINKEDIN_CLIENT_SECRET"
                                         state:@"LINKEDIN_STATE"
                                 grantedAccess:@[@"r_basicprofile", @"r_emailaddress"]
                      presentingViewController:nil];

[PFLinkedInUtils logInWithBlock:^(PFUser *user, NSError *error) {
    NSLog(@"User: %@, Error: %@", user, error);
    
    [PFLinkedInUtils.linkedInHttpClient GET:@"LINKEDIN_API_URL" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
    NSLog(@"Response JSON: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    NSLog(@"Error: %@", error);
    }];
}];
```

# Etc.

* Contributions like [kadarandras](https://github.com/kadarandras) are very welcome.
* Attribution is appreciated (let's spread the word!), but not mandatory.

## Use it? Love/hate it?

Tweet the author [@alexruperez](http://twitter.com/alexruperez), and check out alexruperez's blog: http://alexruperez.com

## License

PFLinkedInUtils is available under the MIT license. See the LICENSE file for more info.

