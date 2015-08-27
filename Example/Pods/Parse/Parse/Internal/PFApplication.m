/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFApplication.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

@implementation PFApplication

///--------------------------------------
#pragma mark - Init
///--------------------------------------

+ (instancetype)currentApplication {
    static PFApplication *application;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        application = [[self alloc] init];
    });
    return application;
}

///--------------------------------------
#pragma mark - Accessors
///--------------------------------------

- (BOOL)isAppStoreEnvironment {
#if TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR
    return ([[NSBundle mainBundle] pathForResource:@"embedded" ofType:@"mobileprovision"] == nil);
#endif

    return NO;
}

- (BOOL)isExtensionEnvironment {
    return [[[NSBundle mainBundle] bundlePath] hasSuffix:@".appex"];
}

- (NSInteger)iconBadgeNumber {
#if TARGET_OS_IPHONE
    return [UIApplication sharedApplication].applicationIconBadgeNumber;
#else
    // Make sure not to use `NSApp` here, because it doesn't work sometimes,
    // `NSApplication +sharedApplication` does though.
    NSString *badgeLabel = [[NSApplication sharedApplication] dockTile].badgeLabel;
    if (badgeLabel.length == 0) {
        return 0;
    }

    NSScanner *scanner = [NSScanner localizedScannerWithString:badgeLabel];

    NSInteger number = 0;
    [scanner scanInteger:&number];
    if (scanner.scanLocation != badgeLabel.length) {
        return 0;
    }

    return number;
#endif
}

- (void)setIconBadgeNumber:(NSInteger)iconBadgeNumber {
    if (self.iconBadgeNumber != iconBadgeNumber) {
#if TARGET_OS_IPHONE
        [UIApplication sharedApplication].applicationIconBadgeNumber = iconBadgeNumber;
#else
        [[NSApplication sharedApplication] dockTile].badgeLabel = [@(iconBadgeNumber) stringValue];
#endif
    }
}

@end
