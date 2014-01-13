//
//  CDZCLIApplication.m
//  thingshub
//
//  Created by Chris Dzombak on 1/13/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

#import "CDZCLIApplication.h"

@implementation CDZCLIApplication {
    BOOL _isFinished;
    int _exitCode;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _isFinished = NO;
        _exitCode = 0;
    }
    return self;
}

- (void)start {
    NSLog(@"%s is abstract and must be overridden", __PRETTY_FUNCTION__);
    [self doesNotRecognizeSelector:_cmd];
}

- (void)exitWithCode:(int)exitCode {
    @synchronized(self) {
        _exitCode = exitCode;
        _isFinished = YES;
    }
}

- (BOOL)isFinished {
    @synchronized(self) {
        return _isFinished;
    }
}

- (int)exitCode {
    NSAssert([self isFinished], @"%s must not be called when app is not finished.", __PRETTY_FUNCTION__);
    
    @synchronized(self) {
        return _exitCode;
    }
}

@end
