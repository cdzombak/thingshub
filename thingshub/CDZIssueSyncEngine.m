//
//  CDZIssueSyncEngine.m
//  thingshub
//
//  Created by Chris Dzombak on 1/13/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

#import <OctoKit/OctoKit.h>
#import "NSDictionary+GithubAPIAdditions.h"

#import "CDZIssueSyncEngine.h"
#import "CDZIssueSyncDelegate.h"

#import "CDZThingsHubConfiguration.h"
#import "CDZThingsHubErrorDomain.h"
#import "CDZThingsHubSyncDateTracker.h"
#import "CDZThingsHubErrorDomain.h"

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
- (RACSignal *)syncIssuesSince:(NSDate *)date;

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
    NSDate *lastSyncDate = [CDZThingsHubSyncDateTracker lastSyncDateForConfiguration:self.config];
    NSDate *syncStartDate = [NSDate date];
    
    BOOL isDelegateReady = [self.delegate engineWillBeginSync:self];
    if (!isDelegateReady) {
        return [RACSignal error:[NSError errorWithDomain:kThingsHubErrorDomain code:CDZThingsHubApplicationReturnCodeSyncFailed userInfo:@{ NSLocalizedDescriptionKey: @"The sync delegate aborted the sync during initialization." }]];
    }
    
    RACSignal *syncStatusSignal = [[RACSignal return:@"Milestones"] concat:[self syncMilestones]];
    syncStatusSignal = [syncStatusSignal concat:[RACSignal defer:^RACSignal *{
        return [[[RACSignal return:@"Issues"] concat:[self syncIssuesSince:lastSyncDate]] doCompleted:^{
            [CDZThingsHubSyncDateTracker setLastSyncDate:syncStartDate forConfiguration:self.config];
        }];
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

- (RACSignal *)syncIssuesSince:(NSDate *)lastSyncDate {
    [self.delegate collectExtantIssues];
    
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        // we sync *all* open issues, and *only* recently modified closed ones.
        return [[RACSignal merge:@[[self issuesAssignedToMeInState:CDZGithubStateValueOpen since:nil], [self issuesAssignedToMeInState:CDZGithubStateValueClosed since:lastSyncDate]]]
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
                    [self.delegate cancelOpenIssuesInLocalCollection];
                    [subscriber sendCompleted];
                }];
    }];
}

- (RACSignal *)issuesAssignedToMeInState:(NSString *)state since:(NSDate *)lastSyncDate {
    NSParameterAssert(state);
    
    NSMutableDictionary *params = [@{ CDZGithubStateKey: state,
                                      @"assignee": self.config.githubLogin
                                      } mutableCopy];
    
    if (lastSyncDate) {
        NSValueTransformer *dateTransformer = [NSValueTransformer valueTransformerForName:OCTDateValueTransformerName];
        NSString *sinceDateString = [dateTransformer reverseTransformedValue:lastSyncDate];
        CDZCLIPrint(@"\tLast sync: %@", sinceDateString);
        params[@"since"] = sinceDateString;
    }
    
    NSString *path = [NSString stringWithFormat:@"repos/%@/%@/issues", self.config.repoOwner, self.config.repoName];
    NSURLRequest *issuesRequest = [self.client requestWithMethod:CDZHTTPMethodGET
                                                                path:path
                                                          parameters:params
                                       ];
    
    return [[self.client enqueueRequest:issuesRequest resultClass:Nil] map:^id(id value) {
        return [value parsedResult];
    }];
}

@end
