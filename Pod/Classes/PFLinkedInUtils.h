//
//  PFLinkedInUtils.h
//  Pods
//
//  Created by alexruperez on 15/11/14.
//
//

#import <Foundation/Foundation.h>

#import <Parse/Parse.h>

#import <IOSLinkedInAPI/LIALinkedInHttpClient.h>


/*! @abstract 308: An existing LinkedIn account already linked to another user. */
extern NSInteger const kPFErrorLinkedInAccountAlreadyLinked;
/*! @abstract 350: LinkedIn id missing from request */
extern NSInteger const kPFErrorLinkedInIdMissing;
/*! @abstract 351: Invalid LinkedIn session */
extern NSInteger const kPFErrorLinkedInInvalidSession;

/*!
 The `PFLinkedInUtils` class provides utility functions for working with LinkedIn in a Parse application.
 
 This class is currently for iOS only.
 */
@interface PFLinkedInUtils : NSObject

///--------------------------------------
/// @name Interacting With LinkedIn
///--------------------------------------

/*!
 @abstract Gets the instance of the <LIALinkedInHttpClient> object.
 
 @returns An instance of <LIALinkedInHttpClient> object.
 */
+ (LIALinkedInHttpClient *)linkedInHttpClient;

/*!
 @abstract Initializes the LinkedIn singleton.
 
 @warning You must invoke this in order to use the LinkedIn functionality in Parse.
 
 @param redirectURL Has to be a http or https url (required by LinkedIn), but other than that, the endpoint doesn't have to respond anything. The library only uses the endpoint to know when to intercept calls in the UIWebView.
 @param clientId The id which is provided by LinkedIn upon registering an application.
 @param clientSecret The secret which is provided by LinkedIn upon registering an application.
 @param state The state used to prevent Cross Site Request Forgery. Should be something that is hard to guess.
 @param grantedAccess An array telling which access the application would like to be granted by the enduser. See full list here: http://developer.linkedin.com/documents/authentication
 @param presentingViewController The view controller that the UIWebView will be modally presented from. Passing nil assumes the root view controller.
 */
+ (void)initializeWithRedirectURL:(NSString *)redirectURL clientId:(NSString *)clientId clientSecret:(NSString *)clientSecret state:(NSString *)state grantedAccess:(NSArray *)grantedAccess presentingViewController:(id)presentingViewController;

/*!
 @abstract Whether the user has their account linked to LinkedIn.
 
 @param user User to check for a LinkedIn link. The user must be logged in on this device.
 
 @returns `YES` if the user has their account linked to LinkedIn, otherwise `NO`.
 */
+ (BOOL)isLinkedWithUser:(PFUser *)user;

///--------------------------------------
/// @name Logging In & Creating LinkedIn-Linked Users
///--------------------------------------

/*!
 @abstract *Asynchronously* logs in a user using LinkedIn.
 
 @discussion This method delegates to LinkedIn to authenticate the user,
 and then automatically logs in (or creates, in the case where it is a new user) <PFUser>.
 
 @param block The block to execute.
 It should have the following argument signature: `^(PFUser *user, NSError *error)`.
 */
+ (void)logInWithBlock:(PFUserResultBlock)block;

///--------------------------------------
/// @name Linking Users with LinkedIn
///--------------------------------------

/*!
 @abstract *Asynchronously* links LinkedIn to an existing <PFUser>.
 
 @discussion This method delegates to LinkedIn to authenticate the user,
 and then automatically links the account to the <PFUser>.
 
 @param user User to link to LinkedIn.
 @param block The block to execute.
 It should have the following argument signature: `^(BOOL *success, NSError *error)`.
 */
+ (void)linkUser:(PFUser *)user block:(PFBooleanResultBlock)block;

///--------------------------------------
/// @name Unlinking Users from LinkedIn
///--------------------------------------

/*!
 @abstract Makes an *asynchronous* request to unlink a user from a LinkedIn account.
 
 @param user User to unlink from LinkedIn.
 @param block The block to execute.
 It should have the following argument signature: `^(BOOL succeeded, NSError *error)`.
 */
+ (void)unlinkUser:(PFUser *)user block:(PFBooleanResultBlock)block;

///--------------------------------------
/// @name Logging Out
///--------------------------------------

/*!
 @abstract *Synchronously* logs out the currently logged in user on disk.
 */
+ (BOOL)logOut;

@end
