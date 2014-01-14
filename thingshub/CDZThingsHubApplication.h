//
//  CDZThingsHubApplication.h
//  thingshub
//
//  Created by Chris Dzombak on 1/13/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

#import "CDZCLIApplication.h"

NS_ENUM(int, CDZThingsHubApplicationReturnCode) {
    CDZThingsHubApplicationReturnCodeNormal = 0,
    CDZThingsHubApplicationReturnCodeAuthError,
    CDZThingsHubApplicationReturnCodeConfigError
};

@interface CDZThingsHubApplication : CDZCLIApplication

@end
