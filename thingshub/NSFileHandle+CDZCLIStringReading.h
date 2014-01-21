//
//  NSFileHandle+CDZCLIStringReading.h
//  CDZCLIApplication
//
//  Created by Chris Dzombak on 1/13/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

@import Foundation;

/// Convenience category which makes using standard input for CLI input easier.
@interface NSFileHandle (CDZCLIStringReading)

/// Read this handle's `-availableData` as a string, stripping a single trailing newline.
/// Useful with `+[NSFileHandle fileHandleWithStandardInput]`.
- (NSString *)cdz_availableString;

@end
