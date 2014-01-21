//
//  NSDictionary+GithubAPIAdditions.h
//  thingshub
//
//  Created by Chris Dzombak on 1/18/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

/// Convenience methods for accessing values in Github API dictionaries.
@interface NSDictionary (GithubAPIAdditions)

/// Return the "number" key for an issue or milestone, or NSNotFound if the "number" key doesn't exist.
- (NSInteger)cdz_issueNumber;

/// Return whether the issue or milestone is open.
- (BOOL)cdz_issueIsOpen;

- (NSString *)cdz_issueTitle;

- (NSString *)cdz_issueDescription;

- (NSDate *)cdz_issueDueDate;

@end
