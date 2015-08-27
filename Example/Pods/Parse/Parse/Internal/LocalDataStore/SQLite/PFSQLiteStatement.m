/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFSQLiteStatement.h"

#import <sqlite3.h>

@implementation PFSQLiteStatement

- (instancetype)initWithStatement:(sqlite3_stmt *)stmt {
    self = [super init];
    if (!stmt || !self) return nil;

    _sqliteStatement = stmt;

    return self;
}

- (void)dealloc {
    [self close];
}

- (BOOL)close {
    if (!_sqliteStatement) {
        return YES;
    }

    int resultCode = sqlite3_finalize(_sqliteStatement);
    _sqliteStatement = nil;

    return (resultCode == SQLITE_OK || resultCode == SQLITE_DONE);
}

- (BOOL)reset {
    if (!_sqliteStatement) {
        return YES;
    }

    int resultCode = sqlite3_reset(_sqliteStatement);
    return (resultCode == SQLITE_OK || resultCode == SQLITE_DONE);
}

@end
