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
#import "CDZThingsHubConfiguration.h"

@interface CDZThingsHubApplication ()

@property (nonatomic, strong) CDZIssueSyncEngine *syncEngine;
@property (nonatomic, strong) CDZThingsHubConfiguration *currentConfiguration;

@end

@implementation CDZThingsHubApplication

- (void)start {
    NSError *validationError;
    self.currentConfiguration = [CDZThingsHubConfiguration currentConfigurationWithError:&validationError];
    if (!self.currentConfiguration || validationError) {
        CDZCLIPrint(@"Configuration error: %@", [validationError localizedDescription]);
        [self exitWithCode:CDZThingsHubApplicationReturnCodeConfigError];
    }
    
    [CDZGithubAuthManager authenticatedClient:^(OCTClient *authenticatedClient, NSError *error) {
        if (authenticatedClient) {
            CDZCLIPrint(@"Authenticated with username %@", authenticatedClient.user.login);
            self.syncEngine = [[CDZIssueSyncEngine alloc] initWithAuthenticatedClient:authenticatedClient];
            
            // TODO: trigger sync; completion block should exit app
            [self exitWithCode:CDZThingsHubApplicationReturnCodeNormal];
        } else {
            CDZCLIPrint(@"Authentication error: %@", error);
            [self exitWithCode:CDZThingsHubApplicationReturnCodeAuthError];
        }
    }];
}

@end
