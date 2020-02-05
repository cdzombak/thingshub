//
//  NSDictionary+GithubAPIAdditions.h
//  thingshub
//
//  Created by Chris Dzombak on 1/18/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

static NSString * const CDZGHMilestoneHasOpenIssuesAssignedToMeKey = @"CDZGHMilestoneHasOpenIssuesAssignedToMeKey";

/// Convenience methods for accessing values in Github API dictionaries.
@interface NSDictionary (GithubAPIAdditions)

/// Return the object's number, or NSNotFound if the "number" key doesn't exist.
- (NSInteger)cdz_gh_number;

/// Return YES if the "state" key == "open".
- (BOOL)cdz_gh_isOpen;

/// Return YES if the milestone has open issues assigned to me.
- (BOOL)cdz_gh_milestoneHasOpenIssuesAssignedToMe;

/// Return the object's "title", or `@""` if it isn't set.
- (NSString *)cdz_gh_title;

/// Return the milestone's description, or `@""` if it isn't set.
- (NSString *)cdz_gh_milestoneDescription;

/// Return the milestone's due date, or `nil` if it isn't set.
- (NSDate *)cdz_gh_milestoneDueDate;

/// Return the issue's milestone, or `nil` if it isn't set.
- (NSDictionary *)cdz_gh_issueMilestone;

/// Return the issue's label dictionaries, or an empty array if none exist.
- (NSArray *)cdz_gh_issueLabels;

/// Return the label's "name" or `@""` if it isn't set.
- (NSString *)cdz_gh_labelName;

/// Return the object's "html_url" string, or `@""` if it isn't set.
- (NSString *)cdz_gh_htmlUrlString;

/// Return YES if this object contains a "pull_request".
- (BOOL)cdz_gh_issueIsPullRequest;

@end
