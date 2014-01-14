//
//  CDZCLIPrint.h
//  thingshub
//
//  Created by Chris Dzombak on 1/13/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

@import Foundation;

#define CDZCLILog(fmt, ...) CDZCLIPrint((@"%s [line %d]: " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)

extern void CDZCLIPrint(NSString *format, ...);
