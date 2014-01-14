//
//  CDZThingsHubConfiguration.h
//  thingshub
//
//  Created by Chris Dzombak on 1/13/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

@interface CDZThingsHubConfiguration : NSObject

/**
 The configuration for the current working directory.
 
 Walks up from the current directory until it finds a ".thingshubconfig" file.
 Merges that with "~/.thingshubconfig"; values in the local config override those in the global.
 
 If there's a validation error, the returned value will be null, and your error
 variable will be populated.
 */
+ (instancetype)currentConfigurationWithError:(NSError **)error;

/// Global (typically); configured by "tagNamespace = ". Default is "github".
@property (nonatomic, copy, readonly) NSString *tagNamespace;

/// Global (typically); configured by "reviewTag = ". Default is "review".
@property (nonatomic, copy, readonly) NSString *reviewTagName;

/// Global (typically); configured by "githubLogin = "
@property (nonatomic, copy, readonly) NSString *githubLogin;

/// Per-project (typically); configured by "githubOrg = "
@property (nonatomic, copy, readonly) NSString *githubOrgName;

/// Per-project; configured by "githubRepo = "
@property (nonatomic, copy, readonly) NSString *githubRepoName;

/// Per-project; configured by "thingsArea = ". May be missing; default is nil.
@property (nonatomic, copy, readonly) NSString *thingsAreaName;

@end
