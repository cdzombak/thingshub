//
//  CDZThingsHubConfiguration.h
//  thingshub
//
//  Created by Chris Dzombak on 1/13/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

@class RACSignal;

@interface CDZThingsHubConfiguration : NSObject

/**
 Asynchronously returns the app's current `CZDThingsHubConfiguration` as the next value in the signal, then completes.
 
 Walks from ~ down to the current directory, merging in .thingshubconfig files as they are found.
 Command-line parameters override any parameters set in the merged config file.
 
 If there's a validation error, the signal will complete with an error.
 */
+ (RACSignal *)currentConfiguration;

/// Global (typically); configured by "tagNamespace = ". Default is "github".
@property (nonatomic, copy, readonly) NSString *tagNamespace;

/// Global (typically); configured by "githubLogin = "
@property (nonatomic, copy, readonly) NSString *githubLogin;

/// Per-project (typically); configured by "githubOrg = "
@property (nonatomic, copy, readonly) NSString *githubOrgName;

/// Per-project; configured by "githubRepo = "
@property (nonatomic, copy, readonly) NSString *githubRepoName;

/// Per-project; configured by "areaName = ". May be missing; default is nil.
@property (nonatomic, copy, readonly) NSString *areaName;

/// Per-project; configured by "projectPrefix = ". May be missing; default is nil.
@property (nonatomic, copy, readonly) NSString *projectPrefix;

@end
