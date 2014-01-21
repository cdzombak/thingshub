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
    
    if (!dateString || [dateString isEqual:[NSNull null]]) return nil;
    
    NSValueTransformer *dateTransformer = [NSValueTransformer valueTransformerForName:OCTDateValueTransformerName];
    return [dateTransformer transformedValue:dateString];
}

- (NSDictionary *)cdz_gh_issueMilestone {
    NSDictionary *milestone = self[@"milestone"];
    if (!milestone || [milestone isEqual:[NSNull null]]) return nil;
    return milestone;
}

- (NSArray *)cdz_gh_issueLabels {
    NSArray *labels = self[@"labels"];
    return labels ?: @[];
}

- (NSString *)cdz_gh_labelName {
    return self[@"name"] ?: @"";
}

- (NSString *)cdz_gh_htmlUrlString {
    return self[@"html_url"] ?: @"";
}

- (BOOL)cdz_gh_issueIsPullRequest {
    NSDictionary *pr = self[@"pull_request"];
    if (!pr || [pr isEqual:[NSNull null]]) return NO;
    
    NSString *diffUrlString = pr[@"diff_url"];
    return diffUrlString != nil && ![diffUrlString isEqual:[NSNull null]];
}

@end
