//
//  CDZThingsHubErrorDomain.h
//  thingshub
//
//  Created by Chris Dzombak on 1/14/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

#import "CDZThingsHubApplication.h"

extern NSString * const kThingsHubErrorDomain;

/// Error codes that may be used in the application's error domain.
typedef NS_ENUM(NSInteger, CDZErrorCode) {
    /// An error code of `0` is used in testing.
    CDZErrorCodeTestError = CDZThingsHubApplicationReturnCodeNormal,
    
    /// Indicates an authentication error.
    CDZErrorCodeAuthError = CDZThingsHubApplicationReturnCodeAuthError,
    
    /// Indicates an invalid configuration error.
    CDZErrorCodeConfigurationValidationError = CDZThingsHubApplicationReturnCodeConfigError,
    
    /// Indicates that the sync failed.
    CDZErrorCodeSyncFailure = CDZThingsHubApplicationReturnCodeSyncFailed,

    /// Indicates a generic keychain error.
    CDZErrorCodeKeychainError = CDZThingsHubApplicationReturnCodeKeychainError,
};
