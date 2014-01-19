//
//  CDZCLIApplication.h
//  CDZCLIApplication
//
//  Created by Chris Dzombak on 1/13/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

@import Foundation;

@interface CDZCLIApplication : NSObject

/**
 Will be called to start your CLI application.

 This method is abstract and must be implemented by your subclass.
 */
- (void)start;

/**
 Call this from within your application code to exit.
 
 @see -isFinished
 @see -exitCode
 
 @param exitCode The exit code with which the application will exit.
 */
- (void)exitWithCode:(int)exitCode;

/**
 Returns YES if the application is finished and should exit.
 
 This method is used by the framework and should not generally be overridden.
 
 @see -exitCode
 @see -exitWithCode:
 
 @return Whether the application should exit.
 */
- (BOOL)isFinished;

/**
 Returns the exit code the application should exit with.
 
 This method is used by the framework and should not generally be overridden.
 This method must be called only after `isFinished` returns YES.
 
 @see -isFinished
 @see -exitWithCode:
 
 @return The exit code the application should exit with.
 */
- (int)exitCode;

@end
