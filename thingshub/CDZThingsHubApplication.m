//
//  CDZThingsHubApplication.m
//  thingshub
//
//  Created by Chris Dzombak on 1/13/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

#import <OctoKit/OctoKit.h>
#import "CDZThingsHubApplication.h"

#import "CDZGithubAuthManager.h"

@interface CDZThingsHubApplication ()
@end

@implementation CDZThingsHubApplication

- (void)start {
    [CDZGithubAuthManager authenticatedClient:^(OCTClient *authenticatedClient, NSError *error) {
        if (authenticatedClient) {
            NSLog(@"Authenticated! %@", authenticatedClient);
            [self exitWithCode:CDZThingsHubApplicationReturnCodeNormal];
        } else {
            NSLog(@"Authentication error: %@", error);
            [self exitWithCode:CDZThingsHubApplicationReturnCodeAuthError];
        }
    }];
}

@end
