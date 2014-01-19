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

- (NSInteger)cdz_gh_number {
    NSNumber *number = self[@"number"];
    return [number integerValue];
}

- (BOOL)cdz_gh_isOpen {
    NSString *state = self[@"state"];
    return [state isEqualToString:@"open"];
}

- (NSString *)cdz_gh_title {
    return self[@"title"] ?: @"";
}

- (NSString *)cdz_gh_milestoneDescription {
    return self[@"description"] ?: @"";
}

- (NSDate *)cdz_gh_milestoneDueDate {
    NSString *dateString = self[@"due_on"];
    NSValueTransformer *dateTransformer = [NSValueTransformer valueTransformerForName:OCTDateValueTransformerName];
    return [dateTransformer transformedValue:dateString];
}

@end
