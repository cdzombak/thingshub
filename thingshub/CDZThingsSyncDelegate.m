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

/// The configuration in use for this sync.
@property (nonatomic, readonly) CDZThingsHubConfiguration *configuration;

/// The selected Things area for milestones & issues during this sync.
@property (nonatomic, strong) ThingsArea *thingsArea;

/// The Next list in Things
@property (nonatomic, strong) ThingsList *nextList;

/// The Today list in Things
@property (nonatomic, strong) ThingsList *todayList;

/// The queue on which all accesses — reads *and* writes — to mutable state in this class must occur.
@property (nonatomic, readonly) dispatch_queue_t mutableStateQueue;

/// A cache of extant projects for this repo's milestones in Things. Used to avoid repeated trips across Scripting Bridge.
@property (nonatomic, strong) NSMutableArray *milestonesCache;

/// A cache of extant todos for this repo's issues in Things. Used to avoid repeated trips across Scripting Bridge.
@property (nonatomic, strong) NSMutableArray *issuesCache;

/// The local collection modified by the sync engine via the delegate API.
@property (nonatomic, strong) NSMutableArray *localCollection;

@end

@implementation CDZThingsSyncDelegate

#pragma mark - Object Lifecycle

// Don't allow usage with the non-designated initializer.
- (instancetype)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

// Designated initializer
- (instancetype)initWithConfiguration:(CDZThingsHubConfiguration *)configuration {
    self = [super init];
    if (self) {
        _configuration = configuration;
        _mutableStateQueue = dispatch_queue_create("com.cdzombak.thingssyncdelegate", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

#pragma mark - Sync Callbacks

- (BOOL)engineWillBeginSync:(CDZIssueSyncEngine *)syncEngine {
    // Select Inbox in the Things.app UI.
    // If one of the objects we're interested in happens to be selected, Things won't update it. This is a workaround.
    NSPredicate *inboxPredicate = [NSPredicate predicateWithFormat:@"%K == %@", NSStringFromSelector(@selector(name)), @"Inbox"];
    [[[[[self thingsApplication] lists] filteredArrayUsingPredicate:inboxPredicate] firstObject] show];
    
    // Get the Things area we'll put milestones & issues into:
    NSPredicate *areaPredicate = [NSPredicate predicateWithFormat:@"%K == %@", NSStringFromSelector(@selector(name)), self.configuration.areaName];
    self.thingsArea = [[[[self thingsApplication] areas] filteredArrayUsingPredicate:areaPredicate] firstObject];
    
    if (!self.thingsArea) {
        CDZCLIPrint(@"Note: no Things area selected. If you expected tasks and projects to be created in an area, ensure it exists and is spelled correctly in the configuration.");
    }
    
    // Cache all extant milestones (projects in Things) related to this repo:
    NSArray *extantMilestones = [[[[self thingsApplication] projects] get] filteredArrayUsingPredicate:[self predicateForAllMilestones]];
    
    dispatch_async(self.mutableStateQueue, ^{
        self.milestonesCache = [extantMilestones mutableCopy];
    });
    
    // Cache extant issues (Todos in Things) related to this repo:
    // For performance across Scripting Bridge, we only get todos from Today, Next, Scheduled, Someday, Projects, Trash (ie. not Inbox or Logbook).
    
    NSSet *listsToCache = [NSSet setWithObjects:@"Today", @"Next", @"Scheduled", @"Someday", @"Projects", @"Trash", nil];
    NSArray *thingsLists = [[[self thingsApplication] lists] get];
    NSArray *extantIssues = @[];
    
    for (ThingsList *list in thingsLists) {
        if ([listsToCache containsObject:list.name]) {
            NSArray *thisListIssues = [[[list toDos] get] filteredArrayUsingPredicate:[self predicateForAllIssues]];
            extantIssues = [extantIssues arrayByAddingObjectsFromArray:thisListIssues];
        }
        
        if ([list.name isEqualToString:@"Today"]) {
            self.todayList = list;
        }
        else if ([list.name isEqualToString:@"Next"]) {
            self.nextList = list;
        }
    }
    
    dispatch_async(self.mutableStateQueue, ^{
        self.issuesCache = [extantIssues mutableCopy];
    });
    
    return YES;
}

- (void)engineDidCompleteSync:(CDZIssueSyncEngine *)syncEngine {
    [self.todayList show];
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
        [self.nextList.toDos addObject:project];
        dispatch_async(self.mutableStateQueue, ^{
            [self.milestonesCache addObject:project];
        });
    }
    
    NSString *namePrefix = self.configuration.projectPrefix ? [NSString stringWithFormat:@"%@: ", self.configuration.projectPrefix] : @"";
    project.name = [NSString stringWithFormat:@"%@%@", namePrefix, [milestone cdz_gh_title]];
    
    NSString *milestoneUrlString = [NSString stringWithFormat:@"https://github.com/%@/%@/issues?milestone=%ld&state=open", self.configuration.repoOwner, self.configuration.repoName, (long)[milestone cdz_gh_number]];
    project.notes = [NSString stringWithFormat:@"%@\n\n%@\n\n%@", milestoneUrlString, [milestone cdz_gh_milestoneDescription], [self identifierForMilestone:milestone]];
    
    project.dueDate = [milestone cdz_gh_milestoneDueDate];
    project.tagNames = [NSString stringWithFormat:@"%@,via:%@", project.tagNames, self.configuration.tagNamespace];

    // Touching the `status` property seems to reorder projects in Things, so we don't do that unnecessarily:
    ThingsStatus newStatus = [milestone cdz_gh_isOpen] ? ThingsStatusOpen : ThingsStatusCompleted;
    if (project.status != newStatus) project.status = newStatus;
    
    // Touching the `area` property seems to reorder projects in Things, so we don't do that unnecessarily:
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
        
        // By now, we've already cached the extant milestones, so we just make a copy of that for the sync engine to use:
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

// These are part of the delegate's responsibility: domain knowledge on marking todos and projects we synced into
// Things.app so we can find them again and update them.

// We do this by placing a specially formatted string in the Notes field, and then we use `-[NSArray filteredArrayUsingPredicate]`
// and friends to find them again.

// Note that we always call `-[SBElementArray get]` before applying a complex LIKE or MATCHES predicate to collections fetched via Scripting
// Bridge. The performance hit is undesirable, but using these predicates on unevaluated `SBElementArray`s causes a crash in the best case,
// and silent failure in the worst case.

/**
 @param milestone A milestone from Github.
 @return The identifier for the given milestone to be placed in the relevant project's Notes field in Things.app.
 */
- (NSString *)identifierForMilestone:(NSDictionary *)milestone {
    return [NSString stringWithFormat:@"//thingshub/%@/%@/milestone/%ld//",
            self.configuration.repoOwner,
            self.configuration.repoName,
            (long)[milestone cdz_gh_number]
            ];
}

/**
 @param milestone A milestone from Github.
 @return A predicate to find the project representing the given milestone in Things.app.
 */
- (NSPredicate *)predicateForMilestone:(NSDictionary *)milestone {
    NSString *format = [NSString stringWithFormat:@"%@ LIKE \"*%@*\"",
                        NSStringFromSelector(@selector(notes)),
                        [self identifierForMilestone:milestone]
                        ];
    return [NSPredicate predicateWithFormat:format];
}

/**
 @return A predicate to find all projects related to `self.configuration`'s Github repo in Things.app.
 */
- (NSPredicate *)predicateForAllMilestones {
    NSString *milestonesQuery = [NSString stringWithFormat:@"%@ LIKE \"*//thingshub/%@/%@/milestone/*//*\"",
                                 NSStringFromSelector(@selector(notes)),
                                 self.configuration.repoOwner,
                                 self.configuration.repoName
                                 ];
    return [NSPredicate predicateWithFormat:milestonesQuery];
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
        todo = [[[[self thingsApplication] classForScriptingClass:@"to do"] alloc] init]; // yes, this object's scripting class has a space in its name.
        [self.nextList.toDos addObject:todo];
        dispatch_async(self.mutableStateQueue, ^{
            [self.issuesCache addObject:todo];
        });
        
        didCreateTask = YES;
    }
    
    // Touching a todo's project or area seems to reorder it in the Things.app UI, so we don't do that unnecessarily:
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
        return [tagName hasPrefix:githubPrefix] || [[self.configuration.githubTagToLocalTagMap allValues] containsObject:tagName];
    }];
    [tags removeObjectsAtIndexes:githubTagIndexes];
    
    for (NSDictionary *label in [issue cdz_gh_issueLabels]) {
        NSString *labelName = [label cdz_gh_labelName];
        
        if (self.configuration.githubTagToLocalTagMap[labelName]) {
            [tags addObject:self.configuration.githubTagToLocalTagMap[labelName]];
        } else {
            [tags addObject:[NSString stringWithFormat:@"%@:%@", self.configuration.tagNamespace, labelName]];
        }
    }
    
    [tags addObject:[NSString stringWithFormat:@"via:%@", self.configuration.tagNamespace]];
    
    todo.tagNames = [tags componentsJoinedByString:@","];

    if (didCreateTask) {
        todo.notes = [NSString stringWithFormat:@"%@\n\n%@", [issue cdz_gh_htmlUrlString], [self identifierForIssue:issue]];
    }

    NSString *projectPrefix = [issue cdz_gh_issueMilestone] || !self.configuration.projectPrefix ? @"" : [NSString stringWithFormat:@"%@ ", self.configuration.projectPrefix];
    NSString *pullReqPrefix = [issue cdz_gh_issueIsPullRequest] ? @"PR " : @"";
    todo.name = [NSString stringWithFormat:@"(%@%@#%ld) %@", projectPrefix, pullReqPrefix, (long)[issue cdz_gh_number], [issue cdz_gh_title]];
    
    // Touching a todo's `status` property seems to reorder it in the Things.app UI, so we don't do that unnecessarily:
    ThingsStatus newStatus = [issue cdz_gh_isOpen] ? ThingsStatusOpen : ThingsStatusCompleted;
    if (todo.status != newStatus) todo.status = newStatus;
    
    return YES;
}

- (void)collectExtantIssues {
    dispatch_async(self.mutableStateQueue, ^{
        NSAssert(self.localCollection == nil || self.localCollection.count == 0, @"%s must be called only once, and after milestone sync is complete.", __PRETTY_FUNCTION__);
        
        // By now, we've already cached the extant issues, so we just make a copy of that for the sync engine to use:
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

- (void)cancelOpenIssuesInLocalCollection {
    dispatch_sync(self.mutableStateQueue, ^{
        NSAssert(self.localCollection, @"-collectExtantIssues must be called before %s", __PRETTY_FUNCTION__);
        
        for (ThingsToDo *todo in self.localCollection) {
            // Per the docs, we never move a todo from Closed -> Cancelled:
            if (todo.status == ThingsStatusOpen) {
                todo.status = ThingsStatusCanceled;
            }
        }
        
        [self.localCollection removeAllObjects];
    });
}

#pragma mark Identifier Helpers

// These are part of the delegate's responsibility: domain knowledge on marking todos and projects we synced into
// Things.app so we can find them again and update them.

// We do this by placing a specially formatted string in the Notes field, and then we use `-[NSArray filteredArrayUsingPredicate]`
// and friends to find them again.

// Note that we always call `-[SBElementArray get]` before applying a complex LIKE or MATCHES predicate to collections fetched via Scripting
// Bridge. The performance hit is undesirable, but using these predicates on unevaluated `SBElementArray`s causes a crash in the best case,
// and silent failure in the worst case.

/**
 @param issue An issue from Github.
 @return The identifier for the given issue to be placed in the relevant todo's Notes field in Things.app.
 */
- (NSString *)identifierForIssue:(NSDictionary *)issue {
    return [NSString stringWithFormat:@"//thingshub/%@/%@/issue/%ld//",
            self.configuration.repoOwner,
            self.configuration.repoName,
            (long)[issue cdz_gh_number]
            ];
}

/**
 @param issue An issue from Github.
 @return A predicate to find the todo representing the given issue in Things.app.
 */
- (NSPredicate *)predicateForIssue:(NSDictionary *)issue {
    NSString *format = [NSString stringWithFormat:@"%@ LIKE \"*%@*\"",
                        NSStringFromSelector(@selector(notes)),
                        [self identifierForIssue:issue]
                        ];
    return [NSPredicate predicateWithFormat:format];
}

/**
 @return A predicate to find all issues related to `self.configuration`'s Github repo in Things.app.
 */
- (NSPredicate *)predicateForAllIssues {
    NSString *issuesQuery = [NSString stringWithFormat:@"%@ LIKE \"*//thingshub/%@/%@/issue/*//*\"",
                             NSStringFromSelector(@selector(notes)),
                             self.configuration.repoOwner,
                             self.configuration.repoName
                             ];
    return [NSPredicate predicateWithFormat:issuesQuery];
}

@end
