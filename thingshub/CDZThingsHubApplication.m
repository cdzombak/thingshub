//
//  CDZThingsHubApplication.m
//  thingshub
//
//  Created by Chris Dzombak on 1/13/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

#import "CDZThingsHubApplication.h"

@interface CDZThingsHubApplication ()

@property (nonatomic, strong) NSTimer *timer;

@end

@implementation CDZThingsHubApplication

- (void)start {
    CDZCLIPrint(@"Running for 5 seconds from %s", __PRETTY_FUNCTION__);
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(timerFired:) userInfo:nil repeats:NO];
}

- (void)timerFired:(id)sender {
    CDZCLIPrint(@"Exiting with exit code 1 from %s", __PRETTY_FUNCTION__);
    [self exitWithCode:1];
}

@end
