//
//  CDZThingsHubSyncDateTracker.h
//  thingshub
//
//  Created by Chris Dzombak on 1/22/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

#import "CDZThingsHubConfiguration.h"

@interface CDZThingsHubSyncDateTracker : NSObject

+ (NSDate *)lastSyncDateForConfiguration:(CDZThingsHubConfiguration *)config;

+ (void)setLastSyncDate:(NSDate *)date forConfiguration:(CDZThingsHubConfiguration *)config;

@end
