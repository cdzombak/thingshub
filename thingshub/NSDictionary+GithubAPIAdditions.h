//
//  NSDictionary+GithubAPIAdditions.h
//  thingshub
//
//  Created by Chris Dzombak on 1/18/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

/// Convenience methods for accessing values in Github API dictionaries.
@interface NSDictionary (GithubAPIAdditions)

/// Return the milestone's number, or NSNotFound if the "number" key doesn't exist.
- (NSInteger)cdz_milestoneNumber;

/// Return whether the milestone is open.
- (BOOL)cdz_milestoneIsOpen;

/// Return the milestone's title, or `@""` if it isn't set.
- (NSString *)cdz_milestoneTitle;

/// Return the milestone's description, or `@""` if it isn't set.
- (NSString *)cdz_milestoneDescription;

/// Return the milestone's due date, or `nil` if it isn't set.
- (NSDate *)cdz_milestoneDueDate;

@end
