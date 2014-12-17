//
//  CDZCLIApplication.m
//  CDZCLIApplication
//
//  Created by Chris Dzombak on 1/13/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

#import "CDZCLIApplication.h"

@implementation CDZCLIApplication

- (void)start {
    CDZCLILog(@"%s is abstract and must be overridden", __PRETTY_FUNCTION__);
    [self doesNotRecognizeSelector:_cmd];
}

- (void)exitWithCode:(int)exitCode {
    exit(exitCode);
}

@end
