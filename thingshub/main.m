//
//  main.m
//  CDZCLIApplication
//
//  Created by Chris Dzombak on 1/13/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

#import "CDZCLIApplication.h"
#import "CDZThingsHubApplication.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        CDZCLIApplication *main = [CDZThingsHubApplication new];
        [main start];
        dispatch_main();
    };
}
