//
//  CDZIssueSyncDelegate.h
//  thingshub
//
//  Created by Chris Dzombak on 1/14/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

/**
 An issue sync delegate handles fetching and modifying data from the task management application (Things, Omnifocus, …).
 
 Through this interface, it is expected to obtain data and update it as necessary, and have domain-specific knowledge on
 mapping issue and milestone data structures into and out of the task management application.
 
 Delegates may not make assumptions about the thread on which their methods will be called.
 */
@protocol CDZIssueSyncDelegate <NSObject>

// TODO: …

@end
