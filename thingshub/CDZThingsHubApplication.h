//
//  CDZThingsHubApplication.h
//  thingshub
//
//  Created by Chris Dzombak on 1/13/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

#import "CDZCLIApplication.h"

/// Possible return codes for the application.
NS_ENUM(int, CDZThingsHubApplicationReturnCode) {
    
    /// `0` indicates a normal exit status.
    CDZThingsHubApplicationReturnCodeNormal = 0,

    /// Indicates an auth error occurred.
    CDZThingsHubApplicationReturnCodeAuthError,
    
    /// Indicates a configuration error (typically an invalid config) occurred.
    CDZThingsHubApplicationReturnCodeConfigError,
    
    /// Indicates a sync failure occurred.
    CDZThingsHubApplicationReturnCodeSyncFailed,

    /// Indicates a generic keychain error occurred.
    CDZThingsHubApplicationReturnCodeKeychainError,
};

/// The core ThingsHub application.
@interface CDZThingsHubApplication : CDZCLIApplication

@end
