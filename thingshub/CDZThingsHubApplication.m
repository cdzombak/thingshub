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
    RACSignal *configurationSignal = [[CDZThingsHubConfiguration currentConfiguration] doError:^(NSError *error) {
        CDZCLIPrint(@"Configuration error: %@", [error localizedDescription]);
    }];
    
    RACSignal *authClientSignal = [[configurationSignal map:^id(CDZThingsHubConfiguration *config) {
        return [CDZGithubAuthManager authenticatedClientForUsername:config.githubLogin];
    }] doError:^(NSError *error) {
        CDZCLIPrint(@"Authentication failed: %@", [error localizedDescription]);
    }];
    
    RACSignal *syncEngineSignal = [[[[RACSignal zip:@[configurationSignal, authClientSignal]] map:^id(RACTuple *configAndClient) {
        RACTupleUnpack(CDZThingsHubConfiguration *configuration, OCTClient *client) = configAndClient;
        
        NSAssert([configuration isKindOfClass:[CDZThingsHubConfiguration class]], @"configuration must be the correct type");
        NSAssert([client isKindOfClass:[OCTClient class]], @"client must be the correct type");
        
        // TODO: create a sync delegate & pass it in here.
        return [[[CDZIssueSyncEngine alloc] initWithDelegate:nil
                                              configuration:configuration
                                        authenticatedClient:client]
                sync];
    }] doNext:^(NSString *statusUpdate) {
        CDZCLIPrint(@"Syncing: %@", statusUpdate);
    }] doError:^(NSError *error) {
        CDZCLIPrint(@"Sync failed: %@", [error localizedDescription]);
    }];
    
    RACSignal *returnCodeSignal = [RACSignal merge:
   @[
     [[configurationSignal ignoreValues]
      catch:^RACSignal *(NSError *error) {
        return [RACSignal return:@(CDZThingsHubApplicationReturnCodeConfigError)];
    }],
     [[authClientSignal ignoreValues]
      catch:^RACSignal *(NSError *error) {
        return [RACSignal return:@(CDZThingsHubApplicationReturnCodeAuthError)];
    }],
     [[[syncEngineSignal ignoreValues]
      then:^RACSignal *{
        return [RACSignal return:@(CDZThingsHubApplicationReturnCodeNormal)];
    }] catch:^RACSignal *(NSError *error) {
        return [RACSignal return:@(CDZThingsHubApplicationReturnCodeSyncFailed)];
    }],
     ]];

    [self rac_liftSelector:@selector(exitWithCode:) withSignalsFromArray:@[ returnCodeSignal ]];
}

@end
