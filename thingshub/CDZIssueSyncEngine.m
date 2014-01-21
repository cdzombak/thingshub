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

static NSString * const CDZGithubStateKey = @"state";
static NSString * const CDZGithubStateValueOpen = @"open";
static NSString * const CDZGithubStateValueClosed = @"closed";

@interface CDZIssueSyncEngine ()
@property (nonatomic, readonly) OCTClient *client;
@property (nonatomic, readonly) id<CDZIssueSyncDelegate> delegate;
@property (nonatomic, readonly) CDZThingsHubConfiguration *config;
@end

@interface CDZIssueSyncEngine (Milestones)

/// Returns a signal the completes or errors once milestone sync has finished or failed.
- (RACSignal *)syncMilestones;

@end

@interface CDZIssueSyncEngine (Issues)

/// Returns a signal the completes or errors once issue sync has finished or failed.
- (RACSignal *)syncIssues;

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
    
    RACSignal *syncStatusSignal = [[RACSignal return:@"Milestones"] concat:[self syncMilestones]];
    syncStatusSignal = [syncStatusSignal concat:[RACSignal defer:^RACSignal *{
        return [[RACSignal return:@"Issues"] concat:[self syncIssues]];
    }]];
    
    return [[RACSignal defer:^RACSignal *{
        return syncStatusSignal;
    }] replay];
}

@end

@implementation CDZIssueSyncEngine (Milestones)

- (RACSignal *)syncMilestones {
    [self.delegate collectExtantMilestones];
    
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        return [[RACSignal merge:@[[self milestonesInState:CDZGithubStateValueOpen], [self milestonesInState:CDZGithubStateValueClosed]]]
        subscribeNext:^(NSDictionary *milestone) {
            if (![self.delegate syncMilestone:milestone createIfNeeded:[milestone cdz_gh_isOpen] updateExtant:YES]) {
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
    
    NSString *path = [NSString stringWithFormat:@"repos/%@/%@/milestones", self.config.repoOwner, self.config.repoName];
    NSURLRequest *milestonesRequest = [self.client requestWithMethod:CDZHTTPMethodGET
                                                                path:path
                                                          parameters:@{ CDZGithubStateKey: state } ];
    
    return [[self.client enqueueRequest:milestonesRequest resultClass:Nil] map:^id(id value) {
        return [value parsedResult];
    }];
}

@end

@implementation CDZIssueSyncEngine (Issues)

- (RACSignal *)syncIssues {
    [self.delegate collectExtantIssues];
    
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        return [[RACSignal merge:@[[self issuesAssignedToMeInState:CDZGithubStateValueOpen], [self issuesAssignedToMeInState:CDZGithubStateValueClosed]]]
                subscribeNext:^(NSDictionary *issue) {
                    if (![self.delegate syncIssue:issue createIfNeeded:[issue cdz_gh_isOpen] updateExtant:YES]) {
                        [subscriber sendError:[NSError errorWithDomain:kThingsHubErrorDomain code:CDZErrorCodeSyncFailure userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Sync delegate couldn't update issue %@", issue]}]];
                        // TODO: how can I abort the sync here? --CDZ Jan 19, 2014
                        return;
                    }
                    [self.delegate removeIssueFromLocalCollection:issue];
                } error:^(NSError *error) {
                    [subscriber sendError:error];
                } completed:^{
                    [self.delegate cancelIssuesInLocalCollection];
                    [subscriber sendCompleted];
                }];
    }];
}

- (RACSignal *)issuesAssignedToMeInState:(NSString *)state {
    NSParameterAssert(state);
    
    NSString *path = [NSString stringWithFormat:@"repos/%@/%@/issues", self.config.repoOwner, self.config.repoName];
    NSURLRequest *issuesRequest = [self.client requestWithMethod:CDZHTTPMethodGET
                                                                path:path
                                                          parameters:@{ CDZGithubStateKey: state,
                                                                        @"assignee": self.config.githubLogin
                                                                        }
                                       ];
    
    return [[self.client enqueueRequest:issuesRequest resultClass:Nil] map:^id(id value) {
        return [value parsedResult];
    }];
}

@end
