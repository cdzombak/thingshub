//
//  CDZGithubAuthManager.h
//  thingshub
//
//  Created by Chris Dzombak on 1/13/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

#import <OctoKit/OctoKit.h>
#import "NSFileHandle+CDZCLIStringReading.h"

@interface CDZGithubAuthManager : NSObject

/**
 Asynchronously gets an authenticated client, prompting the user for input via the CLI as needed.
 
 Persists the OAuth token in the Keychain and uses it when possible.
 */
+ (void)authenticatedClient:(void(^)(OCTClient *authenticatedClient, NSError *error))completionBlock forUsername:(NSString *)githubLogin;

@end
