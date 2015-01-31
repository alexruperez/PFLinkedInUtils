//
//  PFLinkedInUtils.m
//  Pods
//
//  Created by alexruperez on 15/11/14.
//
//

#import "PFLinkedInUtils.h"

#import <IOSLinkedInAPI/LIALinkedInApplication.h>


NSInteger const kPFErrorLinkedInAccountAlreadyLinked = 308;
NSInteger const kPFErrorLinkedInIdMissing = 350;
NSInteger const kPFErrorLinkedInInvalidSession = 351;


NSString *kPFLinkedInTokenKey = @"linkedin_token";
NSString *kPFLinkedInExpirationKey = @"linkedin_expiration";
NSString *kPFLinkedInCreationKey = @"linkedin_token_created_at";


@interface PFLinkedInUtils ()

@property (strong, nonatomic) LIALinkedInHttpClient *linkedInHttpClient;

@end

@implementation PFLinkedInUtils

+ (LIALinkedInHttpClient *)linkedInHttpClient
{
    return self.sharedInstance.linkedInHttpClient;
}

+ (void)initializeWithRedirectURL:(NSString *)redirectURL clientId:(NSString *)clientId clientSecret:(NSString *)clientSecret state:(NSString *)state grantedAccess:(NSArray *)grantedAccess presentingViewController:(id)presentingViewController
{
    self.sharedInstance.linkedInHttpClient = [LIALinkedInHttpClient clientForApplication:[LIALinkedInApplication applicationWithRedirectURL:redirectURL clientId:clientId clientSecret:clientSecret state:state grantedAccess:grantedAccess] presentingViewController:presentingViewController];
}

+ (BOOL)isLinkedWithUser:(PFUser *)user
{
    return user && [user isAuthenticated] && [user objectForKey:@"linkedInUser"];
}

+ (void)logInWithBlock:(PFUserResultBlock)block
{
    NSString *accessToken = self.linkedInAccessToken;
    NSDate *expirationDate = self.linkedInAccessTokenExpirationDate;
    if (accessToken && expirationDate && [self.linkedInHttpClient validToken])
    {
        [self getProfileIDWithAccessToken:accessToken block:^(NSString *profileID, NSError *profileError) {
            if (profileID && !profileError)
            {
                [self logInOrSignUpUserWithAccessToken:accessToken expirationDate:expirationDate profileID:profileID block:block];
            }
            else if (block)
            {
                block(nil, profileError);
            }
        }];
    }
    else
    {
        [self getAccessTokenWithBlock:^(NSString *accessToken, NSError *accessTokenError) {
            if (accessToken && !accessTokenError)
            {
                [self getProfileIDWithAccessToken:accessToken block:^(NSString *profileID, NSError *profileError) {
                    if (profileID && !profileError)
                    {
                        NSDate *expirationDate = self.linkedInAccessTokenExpirationDate;
                        [self logInOrSignUpUserWithAccessToken:accessToken expirationDate:expirationDate profileID:profileID block:block];
                    }
                    else if (block)
                    {
                        block(nil, profileError);
                    }
                }];
            }
            else if (block)
            {
                block(nil, accessTokenError);
            }
        }];
    }
}

+ (void)linkUser:(PFUser *)user block:(PFBooleanResultBlock)block
{
    NSString *accessToken = self.linkedInAccessToken;
    NSDate *expirationDate = self.linkedInAccessTokenExpirationDate;
    if (accessToken && expirationDate && [self.linkedInHttpClient validToken])
    {
        [self getProfileIDWithAccessToken:accessToken block:^(NSString *profileID, NSError *profileError) {
            if (profileID && !profileError)
            {
                [self linkUser:user accessToken:accessToken expirationDate:expirationDate profileID:profileID block:block];
            }
            else if (block)
            {
                block(nil, profileError);
            }
        }];
    }
    else
    {
        [self getAccessTokenWithBlock:^(NSString *accessToken, NSError *accessTokenError) {
            if (accessToken && !accessTokenError)
            {
                [self getProfileIDWithAccessToken:accessToken block:^(NSString *profileID, NSError *profileError) {
                    if (profileID && !profileError)
                    {
                        NSDate *expirationDate = self.linkedInAccessTokenExpirationDate;
                        [self linkUser:user accessToken:accessToken expirationDate:expirationDate profileID:profileID block:block];
                    }
                    else if (block)
                    {
                        block(nil, profileError);
                    }
                }];
            }
            else if (block)
            {
                block(nil, accessTokenError);
            }
        }];
    }
}

+ (void)unlinkUser:(PFUser *)user block:(PFBooleanResultBlock)block
{
    PFObject *linkedInUser = [user objectForKey:@"linkedInUser"];
    if (linkedInUser)
    {
        [user removeObjectForKey:@"linkedInUser"];
        [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *userError) {
            if (succeeded)
            {
                [linkedInUser deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (succeeded)
                    {
                        BOOL clearResult = [self clearUserDefaults];
                        
                        if (block)
                        {
                            block(clearResult, nil);
                        }
                    }
                    else if (block)
                    {
                        block(NO, error);
                    }
                }];
            }
            else if (block)
            {
                block(NO, userError);
            }
        }];
    }
    else if (block)
    {
        block(YES, nil);
    }
}

+ (BOOL)logOut
{
    [PFUser logOut];
    return [self clearUserDefaults];
}

#pragma mark - Private

+ (BOOL)clearUserDefaults
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey:kPFLinkedInTokenKey];
    [userDefaults removeObjectForKey:kPFLinkedInExpirationKey];
    [userDefaults removeObjectForKey:kPFLinkedInCreationKey];
    return [userDefaults synchronize];
}

+ (PFLinkedInUtils *)sharedInstance
{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });

    return sharedInstance;
}

+ (void)getAccessTokenWithBlock:(PFStringResultBlock)block
{
    [self.linkedInHttpClient getAuthorizationCode:^(NSString *authorizationCode) {
        [self.linkedInHttpClient getAccessToken:authorizationCode success:^(NSDictionary *accessTokenDictionary) {
            if (block)
            {
                block(accessTokenDictionary[@"access_token"], nil);
            }
        } failure:^(NSError *accessTokenError) {
            if (block)
            {
                block(nil, accessTokenError);
            }
        }];
    } cancel:^{
        if (block)
        {
            block(nil, [NSError errorWithDomain:PFParseErrorDomain code:kPFErrorLinkedInInvalidSession userInfo:@{NSLocalizedDescriptionKey : @"LinkedIn Invalid Session"}]);
        }
    } failure:^(NSError *authorizationCodeError) {
        if (block)
        {
            block(nil, authorizationCodeError);
        }
    }];
}

+ (void)getProfileIDWithAccessToken:(NSString *)accessToken block:(PFStringResultBlock)block
{
    [self.linkedInHttpClient GET:[NSString stringWithFormat:@"https://api.linkedin.com/v1/people/~?oauth2_access_token=%@&format=json", accessToken] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *profileID = nil;
        NSString *profileURL = responseObject[@"siteStandardProfileRequest"][@"url"];
        if (profileURL)
        {
            NSString *params = [[profileURL componentsSeparatedByString:@"?"] lastObject];
            if (params)
            {
                for (NSString *param in [params componentsSeparatedByString:@"&"])
                {
                    NSArray *keyVal = [param componentsSeparatedByString:@"="];
                    if (keyVal.count > 1)
                    {
                        if ([keyVal[0] isEqualToString:@"id"])
                        {
                            profileID = keyVal[1];
                            break;
                        }
                    }
                }
            }
        }
        if (profileID)
        {
            if (block)
            {
                block(profileID, nil);
            }
        }
        else if (block)
        {
                block(nil, [NSError errorWithDomain:PFParseErrorDomain code:kPFErrorLinkedInIdMissing userInfo:@{NSLocalizedDescriptionKey : @"LinkedIn Id Missing"}]);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (block)
        {
            block(nil, error);
        }
    }];
}

+ (void)logInOrSignUpUserWithAccessToken:(NSString *)accessToken expirationDate:(NSDate *)expirationDate profileID:(NSString *)profileID block:(PFUserResultBlock)block
{
    if (accessToken && expirationDate && profileID)
    {
        PFQuery *profileQuery = [PFQuery queryWithClassName:@"LinkedInUser"];
        [profileQuery whereKey:@"userId" equalTo:profileID];
        
        [profileQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *queryError) {
            if (!queryError)
            {
                if (objects.count == 0)
                {
                    [self signUpUserWithAccessToken:accessToken expirationDate:expirationDate profileID:profileID block:block];
                }
                else
                {
                    PFObject *linkedInUser = objects.firstObject;
                    PFObject *userObject = [linkedInUser objectForKey:@"user"];
                    [userObject fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                        PFUser *user = (PFUser *)object;
                        [PFUser logInWithUsernameInBackground:user.username password:profileID block:block];
                    }];
                }
            }
            else if (block)
            {
                block(nil, queryError);
            }
        }];
    }
    else if (block)
    {
        block(nil, [NSError errorWithDomain:PFParseErrorDomain code:kPFErrorLinkedInIdMissing userInfo:@{NSLocalizedDescriptionKey : @"LinkedIn Id Missing"}]);
    }
}

+ (void)signUpUserWithAccessToken:(NSString *)accessToken expirationDate:(NSDate *)expirationDate profileID:(NSString *)profileID block:(PFUserResultBlock)block
{
    if (accessToken && expirationDate && profileID)
    {
        PFUser *user = [PFUser user];
        user.username = [self randomStringWithLength:25];
        user.password = profileID;
        [user signUpInBackgroundWithBlock:^(BOOL signUpSucceeded, NSError *signUpError) {
            if (signUpSucceeded && !signUpError)
            {
                [self linkUser:user accessToken:accessToken expirationDate:expirationDate profileID:profileID block:^(BOOL linkSucceeded, NSError *linkError) {
                    if (linkSucceeded && !linkError)
                    {
                        if (block)
                        {
                            block(user, nil);
                        }
                    }
                    else
                    {
                        [user deleteInBackgroundWithBlock:^(BOOL deleteSucceeded, NSError *deleteError) {
                            if (block)
                            {
                                block(nil, linkError);
                            }
                        }];
                    }
                }];
            }
            else if (block)
            {
                block(nil, signUpError);
            }
        }];
    }
    else if (block)
    {
        block(nil, [NSError errorWithDomain:PFParseErrorDomain code:kPFErrorLinkedInIdMissing userInfo:@{NSLocalizedDescriptionKey : @"LinkedIn Id Missing"}]);
    }
}

+ (void)linkUser:(PFUser *)user accessToken:(NSString *)accessToken expirationDate:(NSDate *)expirationDate profileID:(NSString *)profileID block:(PFBooleanResultBlock)block
{
    if (accessToken && expirationDate && profileID)
    {
        PFQuery *userQuery = [PFQuery queryWithClassName:@"LinkedInUser"];
        [userQuery whereKey:@"user" equalTo:user];
        PFQuery *profileQuery = [PFQuery queryWithClassName:@"LinkedInUser"];
        [profileQuery whereKey:@"userId" equalTo:profileID];
        PFQuery *orQuery = [PFQuery orQueryWithSubqueries:@[userQuery, profileQuery]];

        [orQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *queryError) {
            if (!queryError)
            {
                if (objects.count == 0)
                {
                    PFObject *linkedInUser = [PFObject objectWithClassName:@"LinkedInUser" dictionary:@{@"userId" : profileID, @"accessToken" : accessToken, @"expirationDate" : expirationDate, @"user" : user}];
                    [linkedInUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *saveError) {
                        if (succeeded)
                        {
                            [user setObject:linkedInUser forKey:@"linkedInUser"];
                            user.password = profileID;
                            [user saveInBackgroundWithBlock:block];
                        }
                        else if (block)
                        {
                            block(NO, saveError);
                        }
                    }];
                }
                else if (block)
                {
                    block(NO, [NSError errorWithDomain:PFParseErrorDomain code:kPFErrorLinkedInAccountAlreadyLinked userInfo:@{NSLocalizedDescriptionKey : @"LinkedIn Account Already Linked"}]);
                }
            }
            else if (block)
            {
                block(NO, queryError);
            }
        }];
    }
    else if (block)
    {
        block(NO, [NSError errorWithDomain:PFParseErrorDomain code:kPFErrorLinkedInIdMissing userInfo:@{NSLocalizedDescriptionKey : @"LinkedIn Id Missing"}]);
    }
}

+ (NSString *)randomStringWithLength:(int)length
{
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity:length];

    for (int i = 0; i < length; i++)
    {
        [randomString appendFormat:@"%C", [letters characterAtIndex:arc4random_uniform((unsigned int)[letters length])]];
    }

    return randomString;
}

+ (NSString *)linkedInAccessToken
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:kPFLinkedInTokenKey];
}

+ (NSDate *)linkedInAccessTokenExpirationDate
{
    return [NSDate dateWithTimeIntervalSince1970:([[NSUserDefaults standardUserDefaults] doubleForKey:kPFLinkedInCreationKey] + [[NSUserDefaults standardUserDefaults] doubleForKey:kPFLinkedInExpirationKey])];
}

@end
