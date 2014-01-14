//
//  CDZGithubAuthManager.m
//  thingshub
//
//  Created by Chris Dzombak on 1/13/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

#import <SSKeychain/SSKeychain.h>
#import "CDZGithubAuthManager.h"

static NSString * const CDZThingsHubGithubClientID = @"4522e1cb93f836bc988e";
static NSString * const CDZThingsHubGithubClientSecret = @"3424d858c8e070093eede0b6c71c17632685d9d0";

static NSString * const CDZThingsHubKeychainServiceName = @"ThingsHub-Github";

static const OCTClientAuthorizationScopes CDZThingsHubGithubScopes = (OCTClientAuthorizationScopesUser|OCTClientAuthorizationScopesRepository);

@interface NSError (CDZGithubError)
- (BOOL)cdz_isGithubTwoFactorAuthRequiredError;
@end

@implementation CDZGithubAuthManager

+ (void)authenticatedClient:(void(^)(OCTClient *authenticatedClient, NSError *error))completionBlock forUsername:(NSString *)githubLogin {
    NSParameterAssert(githubLogin);
    
    completionBlock = ^(OCTClient *client, NSError *error) {
        if (client && !error) {
            NSError *keychainError;
            BOOL success = [SSKeychain setPassword:client.token forService:CDZThingsHubKeychainServiceName account:client.user.login error:&keychainError];
            if (!success) {
                CDZCLILog(@"Failed saving token into keychain: %@", keychainError);
            }
        }
        
        if (completionBlock) completionBlock(client, error);
    };
    
    [OCTClient setClientID:CDZThingsHubGithubClientID clientSecret:CDZThingsHubGithubClientSecret];
    OCTUser *user = [OCTUser userWithLogin:githubLogin server:OCTServer.dotComServer];
    
    NSString *storedToken = [SSKeychain passwordForService:CDZThingsHubKeychainServiceName account:githubLogin];
    
    if (storedToken) {
        OCTClient *client = [OCTClient authenticatedClientWithUser:user token:storedToken];
        completionBlock(client, nil);
    } else {
        [self attemptAuthFlowWithUser:user completion:completionBlock];
    }
}

+ (void)attemptAuthFlowWithUser:(OCTUser *)user completion:(void(^)(OCTClient *authenticatedClient, NSError *error))completionBlock {
    NSParameterAssert(user);
    NSParameterAssert(completionBlock);
    
    NSFileHandle *stdinput = [NSFileHandle fileHandleWithStandardInput];
    CDZCLIPrint(@"Github password for user %@:", user.login);
    NSString *password = [stdinput cdz_availableString];
    
    [[[OCTClient signInAsUser:user password:password oneTimePassword:nil scopes:CDZThingsHubGithubScopes] deliverOn:RACScheduler.mainThreadScheduler]
     subscribeNext:^(OCTClient *authenticatedClient) {
         completionBlock(authenticatedClient, nil);
     } error:^(NSError *error) {
         if ([error cdz_isGithubTwoFactorAuthRequiredError]) {
             [self attemptTwoFactorAuthWithUser:user password:password completion:completionBlock];
         } else {
             completionBlock(nil, error);
         }
     }];
}

+ (void)attemptTwoFactorAuthWithUser:(OCTUser *)user password:(NSString *)password completion:(void(^)(OCTClient *authenticatedClient, NSError *error))completionBlock {
    NSParameterAssert(user);
    NSParameterAssert(password);
    NSParameterAssert(completionBlock);
    
    NSFileHandle *stdinput = [NSFileHandle fileHandleWithStandardInput];
    CDZCLIPrint(@"Two-factor auth code:");
    NSString *twoFactorCode = [stdinput cdz_availableString];
    
    [[[OCTClient signInAsUser:user password:password oneTimePassword:twoFactorCode scopes:CDZThingsHubGithubScopes] deliverOn:RACScheduler.mainThreadScheduler]
     subscribeNext:^(OCTClient *authenticatedClient) {
         completionBlock(authenticatedClient, nil);
     } error:^(NSError *error) {
         completionBlock(nil, error);
     }];
}

@end


@implementation NSError (CDZGithubError)

- (BOOL)cdz_isGithubTwoFactorAuthRequiredError {
    return [self.domain isEqual:OCTClientErrorDomain] && self.code == OCTClientErrorTwoFactorAuthenticationOneTimePasswordRequired;
}

@end
