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

    RACSignal *authClientSignal = [CDZGithubAuthManager authenticatedClientForUsername:self.currentConfiguration.githubLogin];

    RAC(self, syncEngine) = [[authClientSignal
        map:^id(id client) {
            return [[CDZIssueSyncEngine alloc] initWithAuthenticatedClient:client];
        }]
        catch:^RACSignal *(NSError *error) {
            return [RACSignal return:NSNull.null];
        }];

    [RACObserve(self, syncEngine) subscribeNext:^(id x) {
        // TODO: trigger sync whenever the syncEngine changes
    }];

    RACSignal *authenticated = [[authClientSignal mapReplace:@YES] catch:^RACSignal *(NSError *error) {
        return [RACSignal return:@NO];
    }];

    [self rac_liftSelector:@selector(exitWithCode:) withSignalsFromArray:@[
        [RACSignal if:authenticated
                   then:[RACSignal return:@(CDZThingsHubApplicationReturnCodeNormal)]
                   else:[RACSignal return:@(CDZThingsHubApplicationReturnCodeAuthError)]]
    ]];
}

@end
