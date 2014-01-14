//
//  CDZGithubAuthManager.m
//  thingshub
//
//  Created by Chris Dzombak on 1/13/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

#import "CDZGithubAuthManager.h"

static NSString * const CDZThingsHubGithubClientID = @"4522e1cb93f836bc988e";
static NSString * const CDZThingsHubGithubClientSecret = @"3424d858c8e070093eede0b6c71c17632685d9d0";

static const OCTClientAuthorizationScopes CDZThingsHubGithubScopes = (OCTClientAuthorizationScopesUser|OCTClientAuthorizationScopesRepository);

@implementation CDZGithubAuthManager

+ (void)authenticatedClient:(void(^)(OCTClient *authenticatedClient, NSError *error))completionBlock {
    if (!completionBlock) completionBlock = ^(OCTClient *a, NSError *b) {};
    
    NSFileHandle *stdinput = [NSFileHandle fileHandleWithStandardInput];
    
    CDZCLIPrint(@"Please enter your Github username: ");
    NSString *username = [stdinput cdz_availableString];
    
    CDZCLIPrint(@"Github password:");
    NSString *password = [stdinput cdz_availableString];
    
    OCTUser *user = [OCTUser userWithLogin:username server:OCTServer.dotComServer];
    
    [OCTClient setClientID:CDZThingsHubGithubClientID clientSecret:CDZThingsHubGithubClientSecret];
    
    [[[OCTClient signInAsUser:user password:password oneTimePassword:nil scopes:CDZThingsHubGithubScopes]
      deliverOn:RACScheduler.mainThreadScheduler]
     subscribeNext:^(OCTClient *authenticatedClient) {
         completionBlock(authenticatedClient, nil);
     } error:^(NSError *error) {
         if ([error.domain isEqual:OCTClientErrorDomain] && error.code == OCTClientErrorTwoFactorAuthenticationOneTimePasswordRequired) {
             [self attemptTwoFactorAuthWithUser:user password:password completion:completionBlock];
         } else {
             completionBlock(nil, error);
         }
     }];
}

+ (void)attemptTwoFactorAuthWithUser:(OCTUser *)user password:(NSString *)password completion:(void(^)(OCTClient *authenticatedClient, NSError *error))completionBlock {
    NSParameterAssert(completionBlock);
    
    NSFileHandle *stdinput = [NSFileHandle fileHandleWithStandardInput];
    
    CDZCLIPrint(@"Two-factor auth code:");
    NSString *twoFactorCode = [stdinput cdz_availableString];
    
    [[[OCTClient signInAsUser:user password:password oneTimePassword:twoFactorCode scopes:CDZThingsHubGithubScopes]
      deliverOn:RACScheduler.mainThreadScheduler]
     subscribeNext:^(OCTClient *authenticatedClient) {
         completionBlock(authenticatedClient, nil);
     } error:^(NSError *error) {
         completionBlock(nil, error);
     }];
}

@end
