//
//  CDZThingsSyncDelegate.m
//  thingshub
//
//  Created by Chris Dzombak on 1/14/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

#import "CDZThingsSyncDelegate.h"
#import "Things.h"

@implementation CDZThingsSyncDelegate

- (ThingsApplication *)thingsApplication {
    return [SBApplication applicationWithBundleIdentifier:@"com.culturedcode.things"];
}

@end
