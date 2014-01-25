//
//  CDZIssueSyncDelegate.h
//  thingshub
//
//  Created by Chris Dzombak on 1/14/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

@class CDZIssueSyncEngine;
@class CDZThingsHubConfiguration;

/**
 An issue sync delegate handles fetching and modifying data from the task management application (Things, Omnifocus, …).
 
 Through this interface, it is expected to obtain data and update it as necessary, and have domain-specific knowledge on
 mapping issue and milestone data structures into and out of the task management application.
 
 Delegates may not make assumptions about the thread on which their methods will be called.
 */
@protocol CDZIssueSyncDelegate <NSObject>

#pragma mark Object Lifecycle

/// Designated initializer.
- (instancetype)initWithConfiguration:(CDZThingsHubConfiguration *)configuration;

#pragma mark Sync Callbacks

/**
 Called before the sync engine begins the sync.

 @return `YES` if the delegate is ready to begin sync; `NO` to abort.
 */
- (BOOL)engineWillBeginSync:(CDZIssueSyncEngine *)syncEngine;

#pragma mark Milestones

/**
 Sync the milestone into the local task management application.
 
 @param milestone The milestone dictionary from Github.
 @param createIfNeeded Allow creating the milestone locally if it doesn't exist.
 @param updateExtant Allow updating the milestone locally if it already exists.
 
 @return YES if the operation was successful; NO otherwise.
 */
- (BOOL)syncMilestone:(NSDictionary *)milestone createIfNeeded:(BOOL)createIfNeeded updateExtant:(BOOL)updateExtant;

/**
 Collect extant milestones for this Github repo into a local mutable collection.
 
 Milestones will be removed from this collection as we sync them, and after we sync all extant milestones, any remaining 
 in this collection will be cancelled. This allows us to cancel milestones that were deleted from Github.
 
 Assuming your delegate implements this collection with a standard mutable Cocoa collection, ensure that all accesses
 and modifications occur on a private serial dispatch queue.
 
 Your delegate may assume (and may assert) that this method will be called only once.
 
 @see -removeMilestoneFromLocalCollection:
 @see -cancelMilestonesInLocalCollection
 */
- (void)collectExtantMilestones;

/**
 Remove the given milestone from the local mutable collection created when `-collectExtantMilestones` was called.
 
 Assuming your delegate implements this collection with a standard mutable Cocoa collection, ensure that all accesses
 and modifications occur on a private serial dispatch queue.
 
 Your delegate may assume (and may assert) that `-collectExtantMilestones` was called before this method.
 
 @see -collectExtantMilestones
 @see -cancelMilestonesInLocalCollection
 */
- (void)removeMilestoneFromLocalCollection:(NSDictionary *)milestone;

/**
 Cancel the projects left in the local mutable collection created when `-collectExtantMilestones` was called, after
 calls to `-removeMilestoneFromCollection`.
 
 Assuming your delegate implements this collection with a standard mutable Cocoa collection, ensure that all accesses
 and modifications occur on a private serial dispatch queue.
 
 Your delegate may assume (and may assert) that `-collectExtantMilestones` was called before this method.
 
 @see -collectExtantMilestones
 @see -removeMilestoneFromLocalCollection:
 */
- (void)cancelMilestonesInLocalCollection;


#pragma mark Issues

/**
 Sync the issue into the local task management application.
 
 @param issue The issue dictionary from Github.
 @param createIfNeeded Allow creating the issue locally if it doesn't exist.
 @param updateExtant Allow updating the issue locally if it already exists.
 
 @return YES if the operation was successful; NO otherwise.
 */
- (BOOL)syncIssue:(NSDictionary *)issue createIfNeeded:(BOOL)createIfNeeded updateExtant:(BOOL)updateExtant;

/**
 Collect extant issues for this Github repo into a local mutable collection.
 
 Issues will be removed from this collection as we sync them, and after we sync all extant issues, any open issues remaining
 in this collection will be cancelled. This allows us to cancel tasks that were deleted from Github or unassigned
 to you.
 
 Assuming your delegate implements this collection with a standard mutable Cocoa collection, ensure that all accesses
 and modifications occur on a private serial dispatch queue.
 
 Your delegate may assume (and may assert) that this method will be called only once.
 
 @see -removeIssueFromLocalCollection:
 @see -cancelOpenIssuesInLocalCollection
 */
- (void)collectExtantIssues;

/**
 Remove the given issue from the local mutable collection created when `-collectExtantIssues` was called.
 
 Assuming your delegate implements this collection with a standard mutable Cocoa collection, ensure that all accesses
 and modifications occur on a private serial dispatch queue.
 
 Your delegate may assume (and may assert) that `-collectExtantIssues` was called before this method.
 
 @see -collectExtantIssues
 @see -cancelOpenIssuesInLocalCollection
 */
- (void)removeIssueFromLocalCollection:(NSDictionary *)issue;

/**
 Cancel the incomplete tasks left in the local mutable collection created when `-collectExtantIssues` was called, after
 calls to `-removeIssueFromCollection`.
 
 Assuming your delegate implements this collection with a standard mutable Cocoa collection, ensure that all accesses
 and modifications occur on a private serial dispatch queue.
 
 Your delegate may assume (and may assert) that `-collectExtantIssues` was called before this method.
 
 @warning Only cancel **open** issues left in the collection. Ignore any closed ones.
 
 @see -collectExtantIssues
 @see -removeIssueFromLocalCollection:
 */
- (void)cancelOpenIssuesInLocalCollection;


@end
