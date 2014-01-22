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

/// User's Github username.
/// Configured by `githubLogin = `. Required.
@property (nonatomic, copy, readonly) NSString *githubLogin;

/// Namespace to use as a prefix for tags imported from Github.
/// Configured by `tagNamespace = `. Optional; default is `github`.
@property (nonatomic, copy, readonly) NSString *tagNamespace;

/// The sync delegate used to communicate with the local task maager app. Currently only Things is supported.
/// Configured by `delegate = `. Optional; default is `Things`.
@property (nonatomic, copy, readonly) NSString *delegateApp;

/// Map a Github label to a local tag name.
/// Configured by `map.tag name = local tag name` (`-"map.label name"` on the CLI, if you need spaces). Optional.
@property (nonatomic, copy, readonly) NSDictionary *githubTagToLocalTagMap;

/// The owner of the Github repo to sync.
/// Configured by `repoOwner = `. Required.
@property (nonatomic, copy, readonly) NSString *repoOwner;

/// The Github repo to sync.
/// Configured by `repoName = `. Required.
@property (nonatomic, copy, readonly) NSString *repoName;

/// The area in Things to use for this project.
/// Configured by `areaName = `. Optional; default is nil.
@property (nonatomic, copy, readonly) NSString *areaName;

/// Prefix which will be applied to project names.
/// Configured by `projectPrefix = `. Optional; default is nil.
@property (nonatomic, copy, readonly) NSString *projectPrefix;

@end
