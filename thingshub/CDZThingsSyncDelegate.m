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

/// A cache of extant milestones for this repo. Used to avoid repeated trips across Scripting Bridge.
@property (nonatomic, strong) NSMutableArray *milestonesCache;

/// The local milestones collection modified by the sync engine via the delegate API.
@property (nonatomic, strong) NSMutableArray *localMilestonesCollection;

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
    
    project.status = [milestone cdz_milestoneIsOpen] ? ThingsStatusOpen : ThingsStatusCompleted;
    project.name = [milestone cdz_milestoneTitle];
    project.notes = [NSString stringWithFormat:@"%@\n\n%@", [milestone cdz_milestoneDescription], [self identifierForMilestone:milestone]];
    project.dueDate = [milestone cdz_milestoneDueDate];
    project.tagNames = [NSString stringWithFormat:@"%@,via:%@,%@", project.tagNames, self.configuration.tagNamespace, self.configuration.reviewTagName];
    project.area = self.thingsArea;
    
    return YES;
}

- (void)collectExtantMilestones {
    NSAssert(self.localMilestonesCollection == nil, @"%s must be called only once", __PRETTY_FUNCTION__);
    
    dispatch_async(self.mutableStateQueue, ^{
        self.localMilestonesCollection = [self.milestonesCache mutableCopy];
    });
}

- (void)removeMilestoneFromLocalCollection:(NSDictionary *)milestone {
    NSAssert(self.localMilestonesCollection, @"-collectExtantMilestones must be called before %s", __PRETTY_FUNCTION__);
    
    dispatch_async(self.mutableStateQueue, ^{
        NSArray *milestonesInCollection = [self.localMilestonesCollection filteredArrayUsingPredicate:[self predicateForMilestone:milestone]];
        [self.localMilestonesCollection removeObjectsInArray:milestonesInCollection];
    });
}

- (void)cancelMilestonesInLocalCollection {
    NSAssert(self.localMilestonesCollection, @"-collectExtantMilestones must be called before %s", __PRETTY_FUNCTION__);
    
    dispatch_sync(self.mutableStateQueue, ^{
        for (ThingsProject *project in self.localMilestonesCollection) {
            project.status = ThingsStatusCanceled;
        }
        
        [self.localMilestonesCollection removeAllObjects];
    });
}

#pragma mark Identifier Helpers

- (NSString *)identifierForMilestone:(NSDictionary *)milestone {
    return [NSString stringWithFormat:@"//thingshub/%@/%@/milestone/%ld//",
            self.configuration.githubOrgName,
            self.configuration.githubRepoName,
            (long)[milestone cdz_milestoneNumber]
            ];
}

- (NSPredicate *)predicateForMilestone:(NSDictionary *)milestone {
    NSString *format = [NSString stringWithFormat:@"%@ LIKE \"*%@*\"",
                        NSStringFromSelector(@selector(notes)),
                        [self identifierForMilestone:milestone]
                        ];
    return [NSPredicate predicateWithFormat:format];
}

@end
