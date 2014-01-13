//
//  CDZThingsHubApplication.m
//  thingshub
//
//  Created by Chris Dzombak on 1/13/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

#import "CDZThingsHubApplication.h"

@implementation CDZThingsHubApplication

#pragma mark - CDZCLIApplication Protocol

- (void)start {
    CDZCLIPrint(@"Running forever from %s", __PRETTY_FUNCTION__);
}

- (BOOL)isFinished {
    return NO;
}

- (int)exitCode {
    NSAssert([self isFinished], @"%s must not be called when app is not finished.", __PRETTY_FUNCTION__);
    
    return 0;
}

@end
