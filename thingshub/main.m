//
//  main.m
//  thingshub
//
//  Created by Chris Dzombak on 1/13/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

#import "CDZCLIApplication.h"
#import "CDZThingsHubApplication.h"

static const NSTimeInterval CDZThingsHubRunLoopInterval = 1.0;

int main(int argc, const char * argv[]) {
    NSRunLoop *runLoop;
    id<CDZCLIApplication> main;
    
    @autoreleasepool {
        runLoop = [NSRunLoop currentRunLoop];
        main = [[CDZThingsHubApplication alloc] init];
        
        [main start];
        
        while(!(main.isFinished) && [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:CDZThingsHubRunLoopInterval]]);
        
    };
    
    return(main.exitCode);
}
