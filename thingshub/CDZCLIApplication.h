//
//  CDZCLIApplication.h
//  thingshub
//
//  Created by Chris Dzombak on 1/13/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

@import Foundation;

@interface CDZCLIApplication : NSObject

/// Will be called to start your CLI application. This method is abstract and must be implemented by your subclass.
- (void)start;

/// Call this from somethere in your app to exit.
- (void)exitWithCode:(int)exitCode;

- (BOOL)isFinished;
- (int)exitCode;

@end
