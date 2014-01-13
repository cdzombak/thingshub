//
//  CDZCLIApplication.h
//  thingshub
//
//  Created by Chris Dzombak on 1/13/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

@import Foundation;

@protocol CDZCLIApplication <NSObject>

- (void)start;

- (BOOL)isFinished;
- (int)exitCode;

@end
