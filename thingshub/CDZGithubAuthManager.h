//
//  CDZGithubAuthManager.h
//  thingshub
//
//  Created by Chris Dzombak on 1/13/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

#import <OctoKit/OctoKit.h>
#import "NSFileHandle+CDZCLIStringReading.h"

@interface CDZGithubAuthManager : NSObject

+ (void)authenticatedClient:(void(^)(OCTClient *authenticatedClient, NSError *error))completionBlock;

@end
