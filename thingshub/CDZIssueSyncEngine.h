//
//  CDZIssueSyncEngine.h
//  thingshub
//
//  Created by Chris Dzombak on 1/13/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>

@class OCTClient;
@class CDZThingsHubConfiguration;
@protocol CDZIssueSyncDelegate;

@interface CDZIssueSyncEngine : NSObject

/// Designated initializer
- (instancetype)initWithDelegate:(id<CDZIssueSyncDelegate>)delegate
                   configuration:(CDZThingsHubConfiguration *)config
             authenticatedClient:(OCTClient *)client;

/// Returns a signal which will either complete or error after the sync operation.
- (RACSignal *)sync;

@end
