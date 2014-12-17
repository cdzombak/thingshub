//
//  CDZGithubAuthManager.m
//  thingshub
//
//  Created by Chris Dzombak on 1/13/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

#import <OctoKit/OctoKit.h>
#import <SSKeychain/SSKeychain.h>
#import "NSFileHandle+CDZCLIStringReading.h"

#import "CDZGithubAuthManager.h"
#import "CDZThingsHubErrorDomain.h"

static NSString * const CDZThingsHubGithubClientID = @"4522e1cb93f836bc988e";
static NSString * const CDZThingsHubGithubClientSecret = @"3424d858c8e070093eede0b6c71c17632685d9d0";

static NSString * const CDZThingsHubKeychainServiceName = @"ThingsHub-Github";

static const OCTClientAuthorizationScopes CDZThingsHubGithubScopes = (OCTClientAuthorizationScopesUser|OCTClientAuthorizationScopesRepository);

@interface NSError (CDZGithubError)
- (BOOL)cdz_isGithubTwoFactorAuthRequiredError;
@end

@implementation CDZGithubAuthManager

+ (RACSignal *)authenticatedClientForUsername:(NSString *)githubLogin {
    NSParameterAssert(githubLogin);

    [OCTClient setClientID:CDZThingsHubGithubClientID clientSecret:CDZThingsHubGithubClientSecret];
    OCTUser *user = [OCTUser userWithLogin:githubLogin server:OCTServer.dotComServer];
    NSString *storedToken = [SSKeychain passwordForService:CDZThingsHubKeychainServiceName account:githubLogin];

    return [[[RACSignal
        defer:^RACSignal *{
            if (storedToken) {
                return [RACSignal return:[OCTClient authenticatedClientWithUser:user token:storedToken]];
            }
            return [self authenticatedClientForUser:user];
        }]
        doNext:^(OCTClient *client) {
            NSError *keychainError;
            BOOL success = [SSKeychain setPassword:client.token
                                        forService:CDZThingsHubKeychainServiceName
                                           account:client.user.login
                                             error:&keychainError];
            if (!success) {
                CDZCLILog(@"Failed saving token into keychain: %@", keychainError);
            }
        }]
        setNameWithFormat:@"+authenticatedClientForUsername: %@", githubLogin];
}

+ (RACSignal *)authenticatedClientForUser:(OCTUser *)user {
    NSParameterAssert(user);

    NSFileHandle *stdinput = [NSFileHandle fileHandleWithStandardInput];
    CDZCLIPrint(@"Github password for user %@:", user.login);
    NSString *password = [stdinput cdz_availableString];

    return [[OCTClient signInAsUser:user password:password oneTimePassword:nil scopes:CDZThingsHubGithubScopes]
        catch:^RACSignal *(NSError *error) {
            if ([error cdz_isGithubTwoFactorAuthRequiredError]) {
                return [self authenticatedClientForUserWithTwoFactorAuth:user password:password];
            }
            else {
                return [RACSignal error:error];
            }
        }];
}

+ (RACSignal *)authenticatedClientForUserWithTwoFactorAuth:(OCTUser *)user password:(NSString *)password {
    NSParameterAssert(user);
    NSParameterAssert(password);

    NSFileHandle *stdinput = [NSFileHandle fileHandleWithStandardInput];
    CDZCLIPrint(@"Two-factor auth code:");
    NSString *twoFactorCode = [stdinput cdz_availableString];

    return [OCTClient signInAsUser:user password:password oneTimePassword:twoFactorCode scopes:CDZThingsHubGithubScopes];
}

+ (NSError *)deleteStoredAuthTokenForUser:(NSString *)user {
    NSError *error;
    BOOL didDelete = [SSKeychain deletePasswordForService:CDZThingsHubKeychainServiceName account:user error:&error];

    if (didDelete) {
        error = nil;
    } else {
        error = error ?: [NSError errorWithDomain:kThingsHubErrorDomain code:CDZErrorCodeKeychainError userInfo:@{ NSLocalizedDescriptionKey: @"A keychain erorr occurred. There is no additional information available." }];
    }

    return error;
}

@end


@implementation NSError (CDZGithubError)

- (BOOL)cdz_isGithubTwoFactorAuthRequiredError {
    return [self.domain isEqual:OCTClientErrorDomain] && self.code == OCTClientErrorTwoFactorAuthenticationOneTimePasswordRequired;
}

@end
