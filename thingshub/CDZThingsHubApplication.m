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
#import "CDZIssueSyncDelegate.h"
#import "CDZIssueSyncEngine.h"
#import "CDZThingsHubConfiguration.h"

@interface CDZThingsHubApplication ()
@end

@implementation CDZThingsHubApplication

- (void)start {
    [self displayVersionAndQuitIfRequested];
    
    RACSignal *configurationSignal = [[[[CDZThingsHubConfiguration currentConfiguration] doError:^(NSError *error) {
        CDZCLIPrint(@"Configuration error: %@", [error localizedDescription]);
    }] doNext:^(CDZThingsHubConfiguration *config) {
        CDZCLIPrint(@"Using configuration: %@", [config description]);
    }] replayLazily];
    
    RACSignal *authClientSignal = [[[configurationSignal flattenMap:^id(CDZThingsHubConfiguration *config) {
        return [CDZGithubAuthManager authenticatedClientForUsername:config.githubLogin];
    }] doError:^(NSError *error) {
        CDZCLIPrint(@"Authentication failed: %@", [error localizedDescription]);
    }] replayLazily];
    
    RACSignal *syncEngineSignal = [[[[[RACSignal zip:@[configurationSignal, authClientSignal]] flattenMap:^id(RACTuple *configAndClient) {
        RACTupleUnpack(CDZThingsHubConfiguration *configuration, OCTClient *client) = configAndClient;
        
        Class delegateClass = NSClassFromString([NSString stringWithFormat:@"CDZ%@SyncDelegate", configuration.delegateApp]);
        NSCParameterAssert(delegateClass);
        id<CDZIssueSyncDelegate> delegate = [[delegateClass alloc] initWithConfiguration:configuration];
        
        return [[[[CDZIssueSyncEngine alloc] initWithDelegate:delegate
                                                configuration:configuration
                                          authenticatedClient:client]
                sync] replay];
    }] doNext:^(NSString *statusUpdate) {
        CDZCLIPrint(@"Syncing: %@", statusUpdate);
    }] doError:^(NSError *error) {
        CDZCLIPrint(@"Sync failed: %@", [error localizedDescription]);
    }] doCompleted:^{
        CDZCLIPrint(@"Sync complete!");
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

- (void)displayVersionAndQuitIfRequested {
    NSArray *arguments = [[NSProcessInfo processInfo] arguments];
    if ([arguments containsObject:@"-version"]) {
        CDZCLIPrint(@"thingshub v1.0.2");
        [self exitWithCode:CDZThingsHubApplicationReturnCodeNormal];
    }
}

@end
