/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import <Parse/PFObject.h>

#import <Bolts/BFTask.h>

#import "PFDecoder.h"
#import "PFEncoder.h"
#import "PFMulticastDelegate.h"
#import "PFObjectControlling.h"

@class BFTask;
@class PFCurrentUserController;
@class PFFieldOperation;
@class PFJSONCacheItem;
@class PFMultiCommand;
@class PFObjectEstimatedData;
@class PFObjectFileCodingLogic;
@class PFObjectState;
@class PFObjectSubclassingController;
@class PFOperationSet;
@class PFPinningObjectStore;
@class PFRESTCommand;
@class PFTaskQueue;

///--------------------------------------
#pragma mark - PFObjectPrivateSubclass
///--------------------------------------

@protocol PFObjectPrivateSubclass <NSObject>

///--------------------------------------
/// @name State
///--------------------------------------

+ (PFObjectState *)_newObjectStateWithParseClassName:(NSString *)className
                                            objectId:(NSString *)objectId
                                          isComplete:(BOOL)complete;

///--------------------------------------
/// @name Validation
///--------------------------------------

/*!
 Validate the save eventually operation with the current state.
 The result of this task is ignored. The error/cancellation/exception will prevent `saveEventually`.

 @returns Task that encapsulates the validtion.
 */
- (BFTask *)_validateSaveEventuallyAsync;

@end

///--------------------------------------
#pragma mark - PFObject
///--------------------------------------

// Extension for property methods.
@interface PFObject ()

/*!
 @returns Current object state.
 */
@property (nonatomic, copy) PFObjectState *_state;
@property (nonatomic, copy) NSMutableSet *_availableKeys;

- (instancetype)initWithObjectState:(PFObjectState *)state;
+ (instancetype)objectWithClassName:(NSString *)className
                           objectId:(NSString *)objectid
                       completeData:(BOOL)completeData;
+ (instancetype)objectWithoutDataWithClassName:(NSString *)className localId:(NSString *)localId;

- (PFTaskQueue *)taskQueue;

- (PFObjectEstimatedData *)_estimatedData;

#if PARSE_OSX_ONLY
// Not available publicly, but available for testing

- (void)refresh;
- (void)refresh:(NSError **)error;
- (void)refreshInBackgroundWithBlock:(PFObjectResultBlock)block;
- (void)refreshInBackgroundWithTarget:(id)target selector:(SEL)selector;

#endif

///--------------------------------------
/// @name Pin
///--------------------------------------
- (BFTask *)_pinInBackgroundWithName:(NSString *)name includeChildren:(BOOL)includeChildren;
+ (BFTask *)_pinAllInBackground:(NSArray *)objects withName:(NSString *)name includeChildren:(BOOL)includeChildren;

+ (PFPinningObjectStore *)pinningObjectStore;
+ (id<PFObjectControlling>)objectController;
+ (PFObjectFileCodingLogic *)objectFileCodingLogic;
+ (PFCurrentUserController *)currentUserController;

///--------------------------------------
#pragma mark - Subclassing
///--------------------------------------

+ (PFObjectSubclassingController *)subclassingController;

@end

@interface PFObject (Private)

/*!
 Returns the object that should be used to synchronize all internal data access.
 */
- (NSObject *)lock;

/*!
 Blocks until all outstanding operations have completed.
 */
- (void)waitUntilFinished;

- (NSDictionary *)_collectFetchedObjects;

///--------------------------------------
#pragma mark - Static methods for Subclassing
///--------------------------------------

/*!
 Unregisters a class registered using registerSubclass:
 If we ever expose thsi method publicly, we must change the underlying implementation
 to have stack behavior. Currently unregistering a custom class for a built-in will
 leave the built-in unregistered as well.
 @param subclass the subclass
 */
+ (void)unregisterSubclass:(Class<PFSubclassing>)subclass;

///--------------------------------------
#pragma mark - Children helpers
///--------------------------------------
- (BFTask *)_saveChildrenInBackgroundWithCurrentUser:(PFUser *)currentUser sessionToken:(NSString *)sessionToken;

///--------------------------------------
#pragma mark - Dirtiness helpers
///--------------------------------------
- (BOOL)isDirty:(BOOL)considerChildren;
- (void)_setDirty:(BOOL)dirty;

- (void)performOperation:(PFFieldOperation *)operation forKey:(NSString *)key;
- (void)setHasBeenFetched:(BOOL)fetched;
- (void)_setDeleted:(BOOL)deleted;

- (BOOL)isDataAvailableForKey:(NSString *)key;

- (BOOL)_hasChanges;
- (BOOL)_hasOutstandingOperations;
- (PFOperationSet *)unsavedChanges;

///--------------------------------------
#pragma mark - Validations
///--------------------------------------
- (void)checkDeleteParams;
- (void)_checkSaveParametersWithCurrentUser:(PFUser *)currentUser;
/*!
 Checks if Parse class name could be used to initialize a given instance of PFObject or it's subclass.
 */
+ (void)_assertValidInstanceClassName:(NSString *)className;

///--------------------------------------
#pragma mark - Serialization helpers
///--------------------------------------
- (NSString *)getOrCreateLocalId;
- (void)resolveLocalId;

+ (id)_objectFromDictionary:(NSDictionary *)dictionary
           defaultClassName:(NSString *)defaultClassName
               completeData:(BOOL)completeData;

+ (id)_objectFromDictionary:(NSDictionary *)dictionary
           defaultClassName:(NSString *)defaultClassName
               selectedKeys:(NSArray *)selectedKeys;

+ (id)_objectFromDictionary:(NSDictionary *)dictionary
           defaultClassName:(NSString *)defaultClassName
               completeData:(BOOL)completeData
                    decoder:(PFDecoder *)decoder;
+ (BFTask *)_migrateObjectInBackgroundFromFile:(NSString *)fileName toPin:(NSString *)pinName;
+ (BFTask *)_migrateObjectInBackgroundFromFile:(NSString *)fileName
                                         toPin:(NSString *)pinName
                           usingMigrationBlock:(BFContinuationBlock)block;

- (NSMutableDictionary *)_convertToDictionaryForSaving:(PFOperationSet *)changes
                                     withObjectEncoder:(PFEncoder *)encoder;

///--------------------------------------
#pragma mark - REST operations
///--------------------------------------
- (NSDictionary *)RESTDictionaryWithObjectEncoder:(PFEncoder *)objectEncoder
                                operationSetUUIDs:(NSArray **)operationSetUUIDs;
- (NSDictionary *)RESTDictionaryWithObjectEncoder:(PFEncoder *)objectEncoder
                                operationSetUUIDs:(NSArray **)operationSetUUIDs
                                            state:(PFObjectState *)state
                                operationSetQueue:(NSArray *)operationSetQueue;

- (void)mergeFromRESTDictionary:(NSDictionary *)object
                    withDecoder:(PFDecoder *)decoder;

///--------------------------------------
#pragma mark - Data helpers
///--------------------------------------
- (void)checkForChangesToMutableContainers;
- (void)rebuildEstimatedData;

///--------------------------------------
#pragma mark - Command handlers
///--------------------------------------
- (PFObject *)mergeFromObject:(PFObject *)other;

- (void)_mergeAfterSaveWithResult:(NSDictionary *)result decoder:(PFDecoder *)decoder;
- (void)_mergeAfterFetchWithResult:(NSDictionary *)result decoder:(PFDecoder *)decoder completeData:(BOOL)completeData;
- (void)_mergeFromServerWithResult:(NSDictionary *)result decoder:(PFDecoder *)decoder completeData:(BOOL)completeData;

- (BFTask *)handleSaveResultAsync:(NSDictionary *)result;

///--------------------------------------
#pragma mark - Asynchronous operations
///--------------------------------------
- (void)startSave;
- (BFTask *)_enqueueSaveEventuallyWithChildren:(BOOL)saveChildren;
- (BFTask *)saveAsync:(BFTask *)toAwait;
- (BFTask *)fetchAsync:(BFTask *)toAwait;
- (BFTask *)deleteAsync:(BFTask *)toAwait;

///--------------------------------------
#pragma mark - Command constructors
///--------------------------------------
- (PFRESTCommand *)_constructSaveCommandForChanges:(PFOperationSet *)changes
                                      sessionToken:(NSString *)sessionToken
                                     objectEncoder:(PFEncoder *)encoder;
- (PFRESTCommand *)_currentDeleteCommandWithSessionToken:(NSString *)sessionToken;

///--------------------------------------
#pragma mark - Misc helpers
///--------------------------------------
- (NSString *)displayClassName;
- (NSString *)displayObjectId;

- (void)registerSaveListener:(void (^)(id result, NSError *error))callback;
- (void)unregisterSaveListener:(void (^)(id result, NSError *error))callback;
- (PFACL *)ACLWithoutCopying;

///--------------------------------------
#pragma mark - Get and set
///--------------------------------------

- (void)_setObject:(id)object
            forKey:(NSString *)key
   onlyIfDifferent:(BOOL)onlyIfDifferent;

///--------------------------------------
#pragma mark - Subclass Helpers
///--------------------------------------

/*!
 This method is called by -[PFObject init]; changes made to the object during this
 method will not mark the object as dirty. PFObject uses this method to to apply the
 default ACL; subclasses which override this method shold be sure to call the super
 implementation if they want to honor the default ACL.
 */
- (void)setDefaultValues;

/*!
 This method allows subclasses to determine whether a default ACL should be applied
 to new instances.
 */
- (BOOL)needsDefaultACL;

@end

@interface PFObject () {
    PFMulticastDelegate *saveDelegate;
}

@property (nonatomic, strong) PFMulticastDelegate *saveDelegate;

@end
