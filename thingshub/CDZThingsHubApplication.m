//
//  CDZThingsHubApplication.m
//  thingshub
//
//  Created by Chris Dzombak on 1/13/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <OctoKit/OctoKit.h>

#import "CDZThingsHubApplication.h"

#import "CDZGithubAuthManager.h"
#import "CDZIssueSyncEngine.h"
#import "CDZThingsHubConfiguration.h"

@interface CDZThingsHubApplication ()
@end

@implementation CDZThingsHubApplication

- (void)start {
    /* Core App Flow */
    
    RACSignal *configurationSignal = [CDZThingsHubConfiguration currentConfiguration];
    
    RACSignal *authClientSignal = [configurationSignal map:^id(CDZThingsHubConfiguration *config) {
        return [CDZGithubAuthManager authenticatedClientForUsername:config.githubLogin];
    }];
    
    RACSignal *syncEngineSignal = [[RACSignal zip:@[configurationSignal, authClientSignal]] map:^id(RACTuple *configAndClient) {
        RACTupleUnpack(CDZThingsHubConfiguration *configuration, OCTClient *client) = configAndClient;
        // TODO: create a sync delegate & pass it in here.
        return [[[CDZIssueSyncEngine alloc] initWithDelegate:nil
                                              configuration:configuration
                                        authenticatedClient:client]
                sync];
    }];

    /* Print errors */
    
    // TODO: can I use some RAC trickery to combine these error format messages, and the signals they represent, into an error signal, therefore reducing code duplication below? --CDZ Jan 17, 2014
    
    [configurationSignal doError:^(NSError *error) {
        CDZCLIPrint(@"Configuration error: %@", error);
    }];
    
    [authClientSignal doError:^(NSError *error) {
        CDZCLIPrint(@"Authentication error: %@", error);
    }];
    
    [syncEngineSignal doError:^(NSError *error) {
        CDZCLIPrint(@"Sync failed: %@", error);
    }];
    
    /* Exit with appropriate error code */
    
    RACSignal *returnCodeSignal = [RACSignal merge:
   @[
     [configurationSignal catch:^RACSignal *(NSError *error) {
        return [RACSignal return:@(CDZThingsHubApplicationReturnCodeConfigError)];
    }],
     [authClientSignal catch:^RACSignal *(NSError *error) {
        return [RACSignal return:@(CDZThingsHubApplicationReturnCodeAuthError)];
    }],
     [[syncEngineSignal then:^RACSignal *{
        return [RACSignal return:@(CDZThingsHubApplicationReturnCodeNormal)];
    }] catch:^RACSignal *(NSError *error) {
        return [RACSignal return:@(CDZThingsHubApplicationReturnCodeSyncFailed)];
    }],
     ]];

    [self rac_liftSelector:@selector(exitWithCode:) withSignalsFromArray:@[ returnCodeSignal ]];
}

@end
