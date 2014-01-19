//
//  CDZThingsSyncDelegate.h
//  thingshub
//
//  Created by Chris Dzombak on 1/14/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

#import "CDZIssueSyncDelegate.h"

/// Concrete implemention of CDZIssueSyncDelegate which synchronizes to Things.app via Scripting Bridge
@interface CDZThingsSyncDelegate : NSObject <CDZIssueSyncDelegate>

@end
