//
//  CDZThingsSyncDelegate.m
//  thingshub
//
//  Created by Chris Dzombak on 1/14/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

#import "CDZThingsSyncDelegate.h"
#import "CDZThingsHubConfiguration.h"

#import "NSDictionary+GithubAPIAdditions.h"
#import "Things.h"

@interface CDZThingsSyncDelegate ()

@property (nonatomic, readonly) CDZThingsHubConfiguration *configuration;

@property (nonatomic, readonly) dispatch_queue_t mutableStateQueue;

/// The selected Things area for milestones & issues during this sync.
@property (nonatomic, strong) ThingsArea *thingsArea;

/// A cache of extant projects for this repo's milestones in Things. Used to avoid repeated trips across Scripting Bridge.
@property (nonatomic, strong) NSMutableArray *milestonesCache;

/// A cache of extant todos for this repo's issues in Things. Used to avoid repeated trips across Scripting Bridge.
@property (nonatomic, strong) NSMutableArray *issuesCache;

/// The local collection modified by the sync engine via the delegate API.
@property (nonatomic, strong) NSMutableArray *localCollection;

@end

@implementation CDZThingsSyncDelegate

#pragma mark - Object Lifecycle

- (instancetype)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)initWithConfiguration:(CDZThingsHubConfiguration *)configuration {
    self = [super init];
    if (self) {
        _configuration = configuration;
        _mutableStateQueue = dispatch_queue_create("com.cdzombak.thingssyncdelegate", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

#pragma mark - Sync Callbacks

- (void)engineWillBeginSync:(CDZIssueSyncEngine *)syncEngine {
    // Select Inbox in the UI.
    // If one of the objects we're interested in happens to be selected, Things won't update it. This is a workaround.
    NSPredicate *inboxPredicate = [NSPredicate predicateWithFormat:@"%K == %@", NSStringFromSelector(@selector(name)), @"Inbox"];
    [[[[[self thingsApplication] lists] filteredArrayUsingPredicate:inboxPredicate] firstObject] show];
    
    // Get the area for milestones:
    NSPredicate *areaPredicate = [NSPredicate predicateWithFormat:@"%K == %@", NSStringFromSelector(@selector(name)), self.configuration.thingsAreaName];
    self.thingsArea = [[[[self thingsApplication] areas] filteredArrayUsingPredicate:areaPredicate] firstObject];
    
    if (!self.thingsArea) {
        CDZCLIPrint(@"Note: no Things area selected. If you expected tasks and projects to be created in an area, ensure it exists and is spelled correctly in the configuration.");
    }
    
    // Cache extant milestones:
    NSString *milestonesCacheQuery = [NSString stringWithFormat:@"%@ LIKE \"*//thingshub/%@/%@/milestone/*//*\"",
                                      NSStringFromSelector(@selector(notes)),
                                      _configuration.githubOrgName,
                                      _configuration.githubRepoName
                                      ];
    NSPredicate *milestonesPredicate = [NSPredicate predicateWithFormat:milestonesCacheQuery];
    NSArray *extantMilestones = [[[[self thingsApplication] projects] get] filteredArrayUsingPredicate:milestonesPredicate];
    
    dispatch_async(self.mutableStateQueue, ^{
        self.milestonesCache = [extantMilestones mutableCopy];
    });
    
    // Cache extant issues:
    NSString *issuesCacheQuery = [NSString stringWithFormat:@"%@ LIKE \"*//thingshub/%@/%@/issue/*//*\"",
                                  NSStringFromSelector(@selector(notes)),
                                  _configuration.githubOrgName,
                                  _configuration.githubRepoName
                                  ];
    NSPredicate *issuesPredicate = [NSPredicate predicateWithFormat:issuesCacheQuery];
    NSArray *extantIssues = [[[[self thingsApplication] toDos] get] filteredArrayUsingPredicate:issuesPredicate];
    
    dispatch_async(self.mutableStateQueue, ^{
        self.issuesCache = [extantIssues mutableCopy];
    });
}

#pragma mark - Scripting Bridge Support

- (ThingsApplication *)thingsApplication {
    return [SBApplication applicationWithBundleIdentifier:@"com.culturedcode.things"];
}

#pragma mark - Milestone Sync

- (BOOL)syncMilestone:(NSDictionary *)milestone createIfNeeded:(BOOL)createIfNeeded updateExtant:(BOOL)updateExtant {
    __block ThingsProject *project;
    
    dispatch_sync(self.mutableStateQueue, ^{
        project = [[self.milestonesCache filteredArrayUsingPredicate:[self predicateForMilestone:milestone]] firstObject];
    });
    
    if (project && !updateExtant) {
        return YES;
    }
    else if (!project && !createIfNeeded) {
        return YES;
    }
    else if (!project && createIfNeeded) {
        project = [[[[self thingsApplication] classForScriptingClass:@"project"] alloc] init];
        [[[self thingsApplication] projects] addObject:project];
        dispatch_async(self.mutableStateQueue, ^{
            [self.milestonesCache addObject:project];
        });
    }
    
    project.name = [milestone cdz_gh_title];
    project.notes = [NSString stringWithFormat:@"%@\n\n%@", [milestone cdz_gh_milestoneDescription], [self identifierForMilestone:milestone]];
    project.dueDate = [milestone cdz_gh_milestoneDueDate];
    project.tagNames = [NSString stringWithFormat:@"%@,via:%@,%@", project.tagNames, self.configuration.tagNamespace, self.configuration.reviewTagName];

    ThingsStatus newStatus = [milestone cdz_gh_isOpen] ? ThingsStatusOpen : ThingsStatusCompleted;
    if (project.status != newStatus) project.status = newStatus;
    
    if (project.area && !self.thingsArea) {
        project.area = nil;
    } else if ((!project.area && self.thingsArea) || ![project.area.id isEqual:self.thingsArea.id]) {
        project.area = self.thingsArea;
    }
    
    return YES;
}

- (void)collectExtantMilestones {
    dispatch_async(self.mutableStateQueue, ^{
        NSAssert(self.localCollection == nil, @"%s must be called only once", __PRETTY_FUNCTION__);
        
        self.localCollection = [self.milestonesCache mutableCopy];
    });
}

- (void)removeMilestoneFromLocalCollection:(NSDictionary *)milestone {
    dispatch_async(self.mutableStateQueue, ^{
        NSAssert(self.localCollection, @"-collectExtantMilestones must be called before %s", __PRETTY_FUNCTION__);
        
        NSArray *milestonesInCollection = [self.localCollection filteredArrayUsingPredicate:[self predicateForMilestone:milestone]];
        [self.localCollection removeObjectsInArray:milestonesInCollection];
    });
}

- (void)cancelMilestonesInLocalCollection {
    dispatch_sync(self.mutableStateQueue, ^{
        NSAssert(self.localCollection, @"-collectExtantMilestones must be called before %s", __PRETTY_FUNCTION__);
        
        for (ThingsProject *project in self.localCollection) {
            project.status = ThingsStatusCanceled;
        }
        
        [self.localCollection removeAllObjects];
    });
}

#pragma mark Identifier Helpers

- (NSString *)identifierForMilestone:(NSDictionary *)milestone {
    return [NSString stringWithFormat:@"//thingshub/%@/%@/milestone/%ld//",
            self.configuration.githubOrgName,
            self.configuration.githubRepoName,
            (long)[milestone cdz_gh_number]
            ];
}

- (NSPredicate *)predicateForMilestone:(NSDictionary *)milestone {
    NSString *format = [NSString stringWithFormat:@"%@ LIKE \"*%@*\"",
                        NSStringFromSelector(@selector(notes)),
                        [self identifierForMilestone:milestone]
                        ];
    return [NSPredicate predicateWithFormat:format];
}

#pragma mark - Issue Sync

- (BOOL)syncIssue:(NSDictionary *)issue createIfNeeded:(BOOL)createIfNeeded updateExtant:(BOOL)updateExtant {
    __block ThingsToDo *todo;
    
    dispatch_sync(self.mutableStateQueue, ^{
        todo = [[self.issuesCache filteredArrayUsingPredicate:[self predicateForIssue:issue]] firstObject];
    });
    
    BOOL didCreateTask = NO;
    
    if (todo && !updateExtant) {
        return YES;
    }
    else if (!todo && !createIfNeeded) {
        return YES;
    }
    else if (!todo && createIfNeeded) {
        todo = [[[[self thingsApplication] classForScriptingClass:@"to do"] alloc] init];
        [[[self thingsApplication] toDos] addObject:todo];
        didCreateTask = YES;
        dispatch_async(self.mutableStateQueue, ^{
            [self.issuesCache addObject:todo];
        });
    }

    NSDictionary *issueMilestone = [issue cdz_gh_issueMilestone];
    if (issueMilestone) {
        ThingsProject *project = [[self.milestonesCache filteredArrayUsingPredicate:[self predicateForMilestone:issueMilestone]] firstObject];
        
        if (![todo.project.id isEqual:project.id]) {
            todo.project = project;
        }
    }
    else {
        if (todo.project) todo.project = nil;
        
        if (todo.area && !self.thingsArea) {
            todo.area = nil;
        } else if ((!todo.area && self.thingsArea) || ![todo.area.id isEqual:self.thingsArea.id]) {
            todo.area = self.thingsArea;
        }
    }

    NSString *currentTagNames = todo.tagNames ?: @"";
    NSMutableArray *tags = [[currentTagNames componentsSeparatedByString:@","] mutableCopy];

    NSString *githubPrefix = [NSString stringWithFormat:@"%@:", self.configuration.tagNamespace];
    NSIndexSet *githubTagIndexes = [tags indexesOfObjectsPassingTest:^BOOL(NSString *tagName, NSUInteger idx, BOOL *stop) {
        return [tagName hasPrefix:githubPrefix];
    }];
    [tags removeObjectsAtIndexes:githubTagIndexes];
    
    for (NSDictionary *label in [issue cdz_gh_issueLabels]) {
        [tags addObject:[NSString stringWithFormat:@"%@:%@", self.configuration.tagNamespace, [label cdz_gh_labelName]]];
    }
    
    [tags addObject:[NSString stringWithFormat:@"via:%@", self.configuration.tagNamespace]];
    [tags addObject:self.configuration.reviewTagName];
    
    todo.tagNames = [tags componentsJoinedByString:@","];

    if (didCreateTask) {
        todo.notes = [NSString stringWithFormat:@"%@\n\n%@", [issue cdz_gh_htmlUrlString], [self identifierForIssue:issue]];
    }

    NSString *pullReqPrefix = [issue cdz_gh_issueIsPullRequest] ? @"PR " : @"";
    todo.name = [NSString stringWithFormat:@"(%@#%ld) %@", pullReqPrefix, (long)[issue cdz_gh_number], [issue cdz_gh_title]];
    
    ThingsStatus newStatus = [issue cdz_gh_isOpen] ? ThingsStatusOpen : ThingsStatusCompleted;
    if (todo.status != newStatus) todo.status = newStatus;
    
    return YES;
}

- (void)collectExtantIssues {
    dispatch_async(self.mutableStateQueue, ^{
        NSAssert(self.localCollection == nil || self.localCollection.count == 0, @"%s must be called only once, and after milestone sync is complete.", __PRETTY_FUNCTION__);
        
        self.localCollection = [self.issuesCache mutableCopy];
    });
}

- (void)removeIssueFromLocalCollection:(NSDictionary *)issue {
    dispatch_async(self.mutableStateQueue, ^{
        NSAssert(self.localCollection, @"-collectExtantIssues must be called before %s", __PRETTY_FUNCTION__);
        
        NSArray *issuesInCollection = [self.localCollection filteredArrayUsingPredicate:[self predicateForIssue:issue]];
        [self.localCollection removeObjectsInArray:issuesInCollection];
    });
}

- (void)cancelIssuesInLocalCollection {
    dispatch_sync(self.mutableStateQueue, ^{
        NSAssert(self.localCollection, @"-collectExtantIssues must be called before %s", __PRETTY_FUNCTION__);
        
        for (ThingsToDo *todo in self.localCollection) {
            todo.status = ThingsStatusCanceled;
        }
        
        [self.localCollection removeAllObjects];
    });
}

#pragma mark Identifier Helpers

- (NSString *)identifierForIssue:(NSDictionary *)issue {
    return [NSString stringWithFormat:@"//thingshub/%@/%@/issue/%ld//",
            self.configuration.githubOrgName,
            self.configuration.githubRepoName,
            (long)[issue cdz_gh_number]
            ];
}

- (NSPredicate *)predicateForIssue:(NSDictionary *)issue {
    NSString *format = [NSString stringWithFormat:@"%@ LIKE \"*%@*\"",
                        NSStringFromSelector(@selector(notes)),
                        [self identifierForIssue:issue]
                        ];
    return [NSPredicate predicateWithFormat:format];
}

@end
