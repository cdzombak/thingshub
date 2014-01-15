//
//  CDZGithubAuthManager.h
//  thingshub
//
//  Created by Chris Dzombak on 1/13/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

#import <OctoKit/OctoKit.h>
#import "NSFileHandle+CDZCLIStringReading.h"

@class RACSignal;

@interface CDZGithubAuthManager : NSObject

/**
 Asynchronously returns an authenticated `OCTClient` as the next value in the
 signal, prompting the user for input via the CLI as needed.

 Persists the OAuth token in the Keychain and uses it when possible.
 */
+ (RACSignal *)authenticatedClientForUsername:(NSString *)githubLogin;

@end
