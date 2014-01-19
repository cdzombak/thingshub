//
//  NSDictionary+GithubAPIAdditions.h
//  thingshub
//
//  Created by Chris Dzombak on 1/18/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

/// Convenience methods for accessing values in Github API dictionaries.
@interface NSDictionary (GithubAPIAdditions)

/// Return the object's number, or NSNotFound if the "number" key doesn't exist.
- (NSInteger)cdz_gh_number;

/// Return YES if the "state" key == "open".
- (BOOL)cdz_gh_isOpen;

/// Return the object's "title", or `@""` if it isn't set.
- (NSString *)cdz_gh_title;

/// Return the milestone's description, or `@""` if it isn't set.
- (NSString *)cdz_gh_milestoneDescription;

/// Return the milestone's due date, or `nil` if it isn't set.
- (NSDate *)cdz_gh_milestoneDueDate;

@end
