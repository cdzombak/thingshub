//
//  CDZThingsSyncDelegate.m
//  thingshub
//
//  Created by Chris Dzombak on 1/14/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

#import "CDZThingsSyncDelegate.h"
#import "CDZThingsHubConfiguration.h"
#import "Things.h"

@interface CDZThingsSyncDelegate ()

@property (nonatomic, readonly) CDZThingsHubConfiguration *configuration;

@property (nonatomic, readonly) dispatch_queue_t mutableStateQueue;
@property (nonatomic, strong) NSMutableArray *milestonesCollection;

@end

@implementation CDZThingsSyncDelegate

#pragma mark Object Lifecycle

- (instancetype)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)initWithConfiguration:(CDZThingsHubConfiguration *)configuration {
    self = [super init];
    if (self) {
        _configuration = [configuration copy];
        _mutableStateQueue = dispatch_queue_create("com.cdzombak.thingssyncdelegate", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

#pragma mark Scripting Bridge Support

- (ThingsApplication *)thingsApplication {
    return [SBApplication applicationWithBundleIdentifier:@"com.culturedcode.things"];
}

#pragma mark Milestone Sync

- (BOOL)syncMilestone:(NSDictionary *)milestone createIfNeeded:(BOOL)createIfNeeded updateExtant:(BOOL)updateExtant {
    // TODO
    return NO;
}

- (void)collectExtantMilestones {
    // TODO
}

- (void)removeMilestoneFromLocalCollection:(NSDictionary *)milestone {
    // TODO
}

- (void)cancelMilestonesInLocalCollection {
    // TODO
}

@end
