//
//  NSDictionary+GithubAPIAdditions.m
//  thingshub
//
//  Created by Chris Dzombak on 1/18/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

#import <OctoKit/OctoKit.h>
#import "NSDictionary+GithubAPIAdditions.h"

@implementation NSDictionary (GithubAPIAdditions)

- (NSInteger)cdz_issueNumber {
    NSNumber *number = self[@"number"];
    return [number integerValue];
}

- (BOOL)cdz_issueIsOpen {
    NSString *state = self[@"state"];
    return [state isEqualToString:@"open"];
}

- (NSString *)cdz_issueTitle {
    return self[@"title"] ?: @"";
}

- (NSString *)cdz_issueDescription {
    return self[@"description"] ?: @"";
}

- (NSDate *)cdz_issueDueDate {
    NSString *dateString = self[@"due_on"];
    NSValueTransformer *dateTransformer = [NSValueTransformer valueTransformerForName:OCTDateValueTransformerName];
    return [dateTransformer transformedValue:dateString];
}

@end
