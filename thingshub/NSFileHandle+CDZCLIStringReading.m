//
//  NSFileHandle+CDZCLIStringReading.m
//  CDZCLIApplication
//
//  Created by Chris Dzombak on 1/13/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

#import "NSFileHandle+CDZCLIStringReading.h"

@implementation NSFileHandle (CDZCLIStringReading)

- (NSString *)cdz_availableString {
    NSData *availableData = [self availableData];
    NSString *string = [[NSString alloc] initWithData:availableData encoding:NSUTF8StringEncoding];
    return string.length && [string characterAtIndex:string.length-1] == '\n' ? [string substringToIndex:(string.length - 1)] : string;
}

@end
