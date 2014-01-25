//
//  CDZIssueSyncEngine.h
//  thingshub
//
//  Created by Chris Dzombak on 1/13/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

@class OCTClient;
@class RACSignal;
@class CDZThingsHubConfiguration;
@protocol CDZIssueSyncDelegate;

/// Contains the syncing logic needed to sync issues and milestones from a Github API client to an issue sync delegate.
@interface CDZIssueSyncEngine : NSObject

/**
 Designated initializer.
 
 @param delegate The sync delegate to use for communication with local task management software.
 @param config The configuration to use for this sync.
 @param client An authenticated client for the ithub pser specified in the config.
 */
- (instancetype)initWithDelegate:(id<CDZIssueSyncDelegate>)delegate
                   configuration:(CDZThingsHubConfiguration *)config
             authenticatedClient:(OCTClient *)client;

/// Returns a signal which will asynchronously return strings as status updates and complete or error after the sync operation.
- (RACSignal *)sync;

@end
