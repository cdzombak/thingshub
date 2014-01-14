//
//  NSFileHandle+CDZCLIStringReading.h
//  thingshub
//
//  Created by Chris Dzombak on 1/13/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

@import Foundation;

@interface NSFileHandle (CDZCLIStringReading)

/// Read user input from stdin, ie. via [[NSFileHandle fileHandleWithStandardInput] cdz_availableString]
- (NSString *)cdz_availableString;

@end
