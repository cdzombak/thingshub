//
//  CDZIssueSyncEngine.m
//  thingshub
//
//  Created by Chris Dzombak on 1/13/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

#import <OctoKit/OctoKit.h>

#import "CDZIssueSyncEngine.h"

#import "CDZThingsHubConfiguration.h"
#import "CDZIssueSyncDelegate.h"
#import "CDZThingsHubErrorDomain.h"

static NSString * const CDZHTTPMethodGET = @"GET";

@interface CDZIssueSyncEngine ()
@property (nonatomic, readonly) OCTClient *client;
@property (nonatomic, readonly) id<CDZIssueSyncDelegate> delegate;
@property (nonatomic, readonly) CDZThingsHubConfiguration *config;
@end

@interface CDZIssueSyncEngine (Milestones)

/// Returns a signal the completes or errors once milestone sync has finished or failed.
- (RACSignal *)syncMilestones;

@end

@implementation CDZIssueSyncEngine

- (instancetype)initWithDelegate:(id<CDZIssueSyncDelegate>)delegate configuration:(CDZThingsHubConfiguration *)config authenticatedClient:(OCTClient *)client {
    self = [super init];
    if (self) {
        _client = client;
        _delegate = delegate;
        _config = config;
    }
    return self;
}

- (RACSignal *)sync {
    RACSignal *syncStatusSignal = [RACSignal return:@"Printing milestones (temporary)"];
    
    return [[RACSignal defer:^RACSignal *{
        return syncStatusSignal;
    }] replay];
}

@end

static NSString * const CDZGithubMilestoneState = @"state";
static NSString * const CDZGithubMilestoneStateOpen = @"open";
static NSString * const CDZGithubMilestoneStateClosed = @"closed";

@implementation CDZIssueSyncEngine (Milestones)

- (RACSignal *)syncMilestones {
    return [RACSignal error:[NSError errorWithDomain:kThingsHubErrorDomain code:CDZErrorCodeTestError userInfo:@{ NSLocalizedDescriptionKey: @"Test error" }]];
- (RACSignal *)milestonesInState:(NSString *)state {
    NSParameterAssert(state);
    
    NSString *path = [NSString stringWithFormat:@"repos/%@/%@/milestones", self.config.githubOrgName, self.config.githubRepoName];
    NSURLRequest *milestonesRequest = [self.client requestWithMethod:CDZHTTPMethodGET
                                                                path:path
                                                          parameters:@{ CDZGithubMilestoneState: state } ];
    
    return [[self.client enqueueRequest:milestonesRequest resultClass:Nil] map:^id(id value) {
        return [value parsedResult];
    }];
}

@end
