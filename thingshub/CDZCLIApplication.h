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
 
 You _could_ just call exit(), but this method encourages proper thought
 about in-app separation of responsibilities.

 @param exitCode The exit code with which the application will exit.
 */
- (void)exitWithCode:(int)exitCode;

@end
