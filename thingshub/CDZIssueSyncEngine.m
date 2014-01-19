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
#import "CDZThingsHubErrorDomain.h"
#import "CDZIssueSyncDelegate.h"
#import "CDZThingsHubErrorDomain.h"
#import "NSDictionary+GithubAPIAdditions.h"

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
    [self.delegate engineWillBeginSync:self];
    
    RACSignal *syncStatusSignal = [[RACSignal return:@"milestones"] concat:[self syncMilestones]];
    
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
    [self.delegate collectExtantMilestones];
    
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        return [[RACSignal merge:@[[self milestonesInState:CDZGithubMilestoneStateOpen], [self milestonesInState:CDZGithubMilestoneStateClosed]]]
        subscribeNext:^(NSDictionary *milestone) {
            if (![self.delegate syncMilestone:milestone createIfNeeded:[milestone cdz_issueIsOpen] updateExtant:YES]) {
                [subscriber sendError:[NSError errorWithDomain:kThingsHubErrorDomain code:CDZErrorCodeSyncFailure userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Sync delegate couldn't update milestone %@", milestone]}]];
                // TODO: how can I abort the sync here? --CDZ Jan 18, 2014
                return;
            }
            [self.delegate removeMilestoneFromLocalCollection:milestone];
        } error:^(NSError *error) {
            [subscriber sendError:error];
        } completed:^{
            [self.delegate cancelMilestonesInLocalCollection];
            [subscriber sendCompleted];
        }];
    }];
}

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
