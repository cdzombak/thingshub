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
#import "CDZIssueSyncEngine.h"

@interface CDZThingsHubApplication ()

@property (nonatomic, strong) CDZIssueSyncEngine *syncEngine;

@end

@implementation CDZThingsHubApplication

- (void)start {
    [CDZGithubAuthManager authenticatedClient:^(OCTClient *authenticatedClient, NSError *error) {
        if (authenticatedClient) {
            self.syncEngine = [[CDZIssueSyncEngine alloc] initWithAuthenticatedClient:authenticatedClient];
            // TODO: trigger sync; completion block should exit app
        } else {
            CDZCLILog(@"Authentication error: %@", error);
            [self exitWithCode:CDZThingsHubApplicationReturnCodeAuthError];
        }
    }];
}

@end
