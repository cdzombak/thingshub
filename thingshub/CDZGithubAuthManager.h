//
//  CDZGithubAuthManager.h
//  thingshub
//
//  Created by Chris Dzombak on 1/13/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

@class RACSignal;

/// Handles the Github login flow in the CLI, with support for two-factor auth and persisting the resulting
/// auth token in the Keychain for future reuse.
@interface CDZGithubAuthManager : NSObject

/**
 Asynchronously returns an authenticated `OCTClient` as the next value in the
 signal, prompting the user for input via the CLI as needed.

 Persists the OAuth token in the Keychain and uses it when possible.
 
 @param githubLogin The user's Github username.
 */
+ (RACSignal *)authenticatedClientForUsername:(NSString *)githubLogin;

/**
 Deletes the auth token stored in the user's keychain, if any.
 @return An error describing an error that occurred, or `nil` if there was no error.
 */
+ (NSError *)deleteStoredAuthTokenForUser:(NSString *)user;

@end
