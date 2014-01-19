//
//  CDZThingsHubErrorDomain.h
//  thingshub
//
//  Created by Chris Dzombak on 1/14/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

#import "CDZThingsHubApplication.h"

extern NSString * const kThingsHubErrorDomain;

typedef NS_ENUM(NSInteger, CDZErrorCode) {
    CDZErrorCodeConfigurationValidationError = CDZThingsHubApplicationReturnCodeConfigError,
    CDZErrorCodeTestError = -1,
};
