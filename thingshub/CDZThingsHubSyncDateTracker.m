//
//  CDZThingsHubSyncDateTracker.m
//  thingshub
//
//  Created by Chris Dzombak on 1/22/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

#import "CDZThingsHubSyncDateTracker.h"

@interface CDZThingsHubConfiguration (DateTracker)
- (NSString *)syncDateDefaultsKey;
@end

@implementation CDZThingsHubSyncDateTracker

+ (NSDate *)lastSyncDateForConfiguration:(CDZThingsHubConfiguration *)config {
    return [[NSUserDefaults standardUserDefaults] objectForKey:[config syncDateDefaultsKey]];
}

+ (void)setLastSyncDate:(NSDate *)date forConfiguration:(CDZThingsHubConfiguration *)config {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:date forKey:[config syncDateDefaultsKey]];
    [defaults synchronize];
}

@end

@implementation CDZThingsHubConfiguration (DateTracker)

- (NSString *)syncDateDefaultsKey {
    return [NSString stringWithFormat:@"com.cdzombak.thingshub.lastsyncdate.%@.%@.%@",
            self.githubLogin,
            self.repoOwner,
            self.repoName
            ];
}

@end
