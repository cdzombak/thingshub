//
//  CDZIssueSyncEngine.m
//  thingshub
//
//  Created by Chris Dzombak on 1/13/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

#import <OctoKit/OctoKit.h>

#import "CDZIssueSyncEngine.h"

static NSString * const CDZThingsHubHTTPMethodGET = @"GET";

@interface CDZIssueSyncEngine ()

@property (nonatomic, strong) OCTClient *client;

@end

@implementation CDZIssueSyncEngine

- (instancetype)initWithDelegate:(id<CDZIssueSyncDelegate>)delegate configuration:(CDZThingsHubConfiguration *)config authenticatedClient:(OCTClient *)client {
    self = [super init];
    if (self) {
        _client = client;
        _delegate = delegate;
        _config = config;
    }
    return self;
}

- (RACSignal *)sync {
}

}

@end
