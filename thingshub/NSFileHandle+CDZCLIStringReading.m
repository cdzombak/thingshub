//
//  NSFileHandle+CDZCLIStringReading.m
//  thingshub
//
//  Created by Chris Dzombak on 1/13/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

#import "NSFileHandle+CDZCLIStringReading.h"

@implementation NSFileHandle (CDZCLIStringReading)

- (NSString *)cdz_availableString {
    NSData *availableData = [self availableData];
    NSString *stringWithTrailingNewline = [[NSString alloc] initWithData:availableData encoding:NSUTF8StringEncoding];
    return [stringWithTrailingNewline substringToIndex:(stringWithTrailingNewline.length - 1)];
}

@end
