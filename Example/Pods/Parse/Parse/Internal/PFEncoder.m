/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFEncoder.h"

#import "PFACLPrivate.h"
#import "PFAssert.h"
#import "PFBase64Encoder.h"
#import "PFDateFormatter.h"
#import "PFFieldOperation.h"
#import "PFFile.h"
#import "PFGeoPointPrivate.h"
#import "PFObjectPrivate.h"
#import "PFOfflineStore.h"
#import "PFRelationPrivate.h"

@implementation PFEncoder

+ (instancetype)objectEncoder {
    static PFEncoder *encoder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        encoder = [[PFEncoder alloc] init];
    });
    return encoder;
}

- (id)encodeObject:(id)object {
    if ([object isKindOfClass:[PFObject class]]) {
        return [self encodeParseObject:object];
    } else if ([object isKindOfClass:[NSData class]]) {
        return @{
                 @"__type" : @"Bytes",
                 @"base64" : [PFBase64Encoder base64StringFromData:object]
                 };

    } else if ([object isKindOfClass:[NSDate class]]) {
        return @{
                 @"__type" : @"Date",
                 @"iso" : [[PFDateFormatter sharedFormatter] preciseStringFromDate:object]
                 };

    } else if ([object isKindOfClass:[PFFile class]]) {
        if (((PFFile *)object).isDirty) {
            // TODO: (nlutsenko) Figure out what to do with things like an unsaved file
            // in a mutable container, where we don't normally want to allow serializing
            // such a thing inside an object.
            //
            // Returning this empty object is strictly wrong, but we have to have *something*
            // to put into an object's mutable container cache, and this is just about the
            // best we can do right now.
            //
            // [NSException raise:NSInternalInconsistencyException
            //             format:@"Tried to serialize an unsaved file."];
            return @{ @"__type" : @"File" };
        }
        return @{
                 @"__type" : @"File",
                 @"url" : ((PFFile *)object).url,
                 @"name" : ((PFFile *)object).name
                 };

    } else if ([object isKindOfClass:[PFFieldOperation class]]) {
        // Always encode PFFieldOperation with PFPointerOrLocalId
        return [object encodeWithObjectEncoder:[PFPointerOrLocalIdObjectEncoder objectEncoder]];
    } else if ([object isKindOfClass:[PFACL class]]) {
        // TODO (hallucinogen): pass object encoder here
        return [object encodeIntoDictionary];

    } else if ([object isKindOfClass:[PFGeoPoint class]]) {
        // TODO (hallucinogen): pass object encoder here
        return [object encodeIntoDictionary];

    } else if ([object isKindOfClass:[PFRelation class]]) {
        // TODO (hallucinogen): pass object encoder here
        return [object encodeIntoDictionary];

    } else if ([object isKindOfClass:[NSArray class]]) {
        NSMutableArray *newArray = [NSMutableArray arrayWithCapacity:[object count]];
        for (id elem in object) {
            [newArray addObject:[self encodeObject:elem]];
        }
        return newArray;

    } else if ([object isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:[object count]];
        [object enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            dict[key] = [self encodeObject:obj];
        }];
        return dict;
    }

    return object;
}

- (id)encodeParseObject:(PFObject *)object {
    // Do nothing here
    return nil;
}

@end

///--------------------------------------
#pragma mark - PFNoObjectEncoder
///--------------------------------------

@implementation PFNoObjectEncoder

+ (instancetype)objectEncoder {
    static PFNoObjectEncoder *encoder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        encoder = [[PFNoObjectEncoder alloc] init];
    });
    return encoder;
}

- (id)encodeParseObject:(PFObject *)object {
    [NSException raise:NSInternalInconsistencyException format:@"PFObjects are not allowed here."];
    return nil;
}

@end

///--------------------------------------
#pragma mark - PFPointerOrLocalIdObjectEncoder
///--------------------------------------

@implementation PFPointerOrLocalIdObjectEncoder

+ (instancetype)objectEncoder {
    static PFPointerOrLocalIdObjectEncoder *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PFPointerOrLocalIdObjectEncoder alloc] init];
    });
    return instance;
}

- (id)encodeParseObject:(PFObject *)object {
    if (object.objectId) {
        return @{
                 @"__type" : @"Pointer",
                 @"objectId" : object.objectId,
                 @"className" : object.parseClassName
                 };
    }
    return @{
             @"__type" : @"Pointer",
             @"localId" : [object getOrCreateLocalId],
             @"className" : object.parseClassName
             };
}

@end

///--------------------------------------
#pragma mark - PFPointerObjectEncoder
///--------------------------------------

@implementation PFPointerObjectEncoder

+ (instancetype)objectEncoder {
    static PFPointerObjectEncoder *encoder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        encoder = [[self alloc] init];
    });
    return encoder;
}

- (id)encodeParseObject:(PFObject *)object {
    PFConsistencyAssert(object.objectId, @"Tried to save an object with a new, unsaved child.");
    return [super encodeParseObject:object];
}

@end

///--------------------------------------
#pragma mark - PFOfflineObjectEncoder
///--------------------------------------

@interface PFOfflineObjectEncoder ()

@property (nonatomic, assign) PFOfflineStore *store;
@property (nonatomic, assign) PFSQLiteDatabase *database;
@property (nonatomic, strong) NSMutableArray *tasks;
@property (nonatomic, strong) NSObject *tasksLock; // TODO: (nlutsenko) Avoid using @synchronized

@end

@implementation PFOfflineObjectEncoder

+ (instancetype)objectEncoder {
    PFNotDesignatedInitializer();
    return nil;
}

+ (instancetype)objectEncoderWithOfflineStore:(PFOfflineStore *)store database:(PFSQLiteDatabase *)database {
    PFOfflineObjectEncoder *encoder = [[self alloc] init];
    encoder.store = store;
    encoder.database = database;
    encoder.tasks = [NSMutableArray array];
    encoder.tasksLock = [[NSObject alloc] init];
    return encoder;
}

- (id)encodeParseObject:(PFObject *)object {
    if (object.objectId) {
        return @{
                 @"__type" : @"Pointer",
                 @"objectId" : object.objectId,
                 @"className" : object.parseClassName
                 };
    } else {
        NSMutableDictionary *result = [@{ @"__type" : @"OfflineObject" } mutableCopy];
        @synchronized(self.tasksLock) {
            BFTask *uuidTask = [self.store getOrCreateUUIDAsyncForObject:object database:self.database];
            [uuidTask continueWithSuccessBlock:^id(BFTask *task) {
                result[@"uuid"] = task.result;
                return nil;
            }];
            [self.tasks addObject:uuidTask];
        }
        return result;
    }
}

- (BFTask *)encodeFinished {
    return [[BFTask taskForCompletionOfAllTasks:self.tasks] continueWithBlock:^id(BFTask *ignore) {
        @synchronized (self.tasksLock) {
            // TODO (hallucinogen) It might be better to return an aggregate error here
            for (BFTask *task in self.tasks) {
                if (task.cancelled || task.error != nil) {
                    return task;
                }
            }
            [self.tasks removeAllObjects];
            return [BFTask taskWithResult:nil];
        }
    }];
}

@end
