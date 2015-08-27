/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFLocationManager.h"

#import <CoreLocation/CoreLocation.h>

#import "PFConstants.h"
#import "PFGeoPoint.h"

#if !TARGET_OS_IPHONE

// To let us compile for OSX.
@compatibility_alias UIApplication NSApplication;

#endif

@interface PFLocationManager () <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSBundle *bundle;
@property (nonatomic, strong) UIApplication *application;

// We use blocks and not BFTasks because Tasks don't gain us much - we still
// have to manually hold onto them so that they can be resolved in the
// CLLocationManager callback.
@property (nonatomic, strong) NSMutableSet *blockSet;

@end

@implementation PFLocationManager

///--------------------------------------
#pragma mark - CLLocationManager
///--------------------------------------

+ (CLLocationManager *)_newSystemLocationManager {
    __block CLLocationManager *manager = nil;

    // CLLocationManager should be created only on main thread, as it needs a run loop to serve delegate callbacks
    dispatch_block_t block = ^{
        manager = [[CLLocationManager alloc] init];
    };
    if ([[NSThread currentThread] isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
    return manager;
}

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init {
    CLLocationManager *manager = [[self class] _newSystemLocationManager];
    return [self initWithSystemLocationManager:manager];
}

- (instancetype)initWithSystemLocationManager:(CLLocationManager *)manager {
    return [self initWithSystemLocationManager:manager
                                   application:[UIApplication sharedApplication]
                                        bundle:[NSBundle mainBundle]];
}

- (instancetype)initWithSystemLocationManager:(CLLocationManager *)manager
                                  application:(UIApplication *)application
                                       bundle:(NSBundle *)bundle {
    self = [super init];
    if (!self) return nil;

    _blockSet = [NSMutableSet setWithCapacity:1];
    _locationManager = manager;
    _locationManager.delegate = self;
    _bundle = bundle;
    _application = application;

    return self;
}

///--------------------------------------
#pragma mark - Dealloc
///--------------------------------------

- (void)dealloc {
    _locationManager.delegate = nil;
}

///--------------------------------------
#pragma mark - Public
///--------------------------------------

- (void)addBlockForCurrentLocation:(PFLocationManagerLocationUpdateBlock)handler {
    @synchronized (self.blockSet) {
        [self.blockSet addObject:[handler copy]];
    }

#if TARGET_OS_IPHONE
    if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {

        if (self.application.applicationState != UIApplicationStateBackground &&
            [self.bundle objectForInfoDictionaryKey:@"NSLocationWhenInUseUsageDescription"] != nil) {
            [self.locationManager requestWhenInUseAuthorization];
        } else {
            [self.locationManager requestAlwaysAuthorization];
        }
    }
#endif

    [self.locationManager startUpdatingLocation];
}

///--------------------------------------
#pragma mark - CLLocationManagerDelegate
///--------------------------------------

// TODO: (nlutsenko) Remove usage of this method, when we drop support for OSX 10.8
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
    [manager stopUpdatingLocation];

    NSMutableSet *callbacks = [NSMutableSet setWithCapacity:1];
    @synchronized (self.blockSet) {
        [callbacks setSet:self.blockSet];
        [self.blockSet removeAllObjects];
    }
    for (void(^block)(CLLocation *, NSError *) in callbacks) {
        block(newLocation, nil);
    }
}
#pragma clang diagnostic pop

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *location = [locations lastObject];
    CLLocation *oldLocation = [locations count] > 1 ? [locations objectAtIndex:[locations count] - 2] : nil;

    // TODO: (nlutsenko) Remove usage of this method, when we drop support for OSX 10.8 (didUpdateLocations is 10.9+)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [self locationManager:manager didUpdateToLocation:location fromLocation:oldLocation];
#pragma clang diagnostic pop
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [manager stopUpdatingLocation];

    NSMutableSet *callbacks = nil;
    @synchronized (self.blockSet) {
        callbacks = [self.blockSet copy];
        [self.blockSet removeAllObjects];
    }
    for (PFLocationManagerLocationUpdateBlock block in callbacks) {
        block(nil, error);
    }
}

@end
