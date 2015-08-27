/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFObjectState.h"

@interface PFUserState : PFObjectState

@property (nonatomic, copy, readonly) NSString *sessionToken;
@property (nonatomic, copy, readonly) NSDictionary *authData;

@property (nonatomic, assign, readonly) BOOL isNew;

///--------------------------------------
/// @name Init
///--------------------------------------

- (instancetype)initWithState:(PFUserState *)state;
+ (instancetype)stateWithState:(PFUserState *)state;

@end
