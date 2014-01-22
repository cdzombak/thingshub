//
//  CDZThingsHubConfiguration.m
//  thingshub
//
//  Created by Chris Dzombak on 1/13/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>

#import "CDZThingsHubConfiguration.h"
#import "CDZThingsHubErrorDomain.h"

static NSString * const CDZThingsHubConfigFileName = @".thingshubconfig";

static NSString * const CDZThingsHubConfigDefaultTagNamespace = @"github";
static NSString * const CDZThingsHubConfigTagMapConfigKeyPrefix = @"map.";

@interface CDZThingsHubConfiguration ()

@property (nonatomic, copy, readwrite) NSString *tagNamespace;
@property (nonatomic, copy, readwrite) NSString *githubLogin;
@property (nonatomic, copy, readwrite) NSString *repoOwner;
@property (nonatomic, copy, readwrite) NSString *repoName;
@property (nonatomic, copy, readwrite) NSString *areaName;
@property (nonatomic, copy, readwrite) NSString *projectPrefix;
@property (nonatomic, copy, readwrite) NSString *delegateApp;

@end

@implementation CDZThingsHubConfiguration

@synthesize githubTagToLocalTagMap = _githubTagToLocalTagMap;

+ (RACSignal *)currentConfiguration {
    RACSignal *configSignal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        CDZThingsHubConfiguration *currentConfig = [[CDZThingsHubConfiguration alloc] init];
        
        currentConfig.tagNamespace = CDZThingsHubConfigDefaultTagNamespace;
        currentConfig.delegateApp = @"Things";
        
        NSString *homePath = NSHomeDirectory();
        NSArray *homePathComponents = [homePath pathComponents];
        NSArray *workingPathComponents = [[[NSFileManager defaultManager] currentDirectoryPath] pathComponents];
        
        BOOL workingFromWithinHome = workingPathComponents.count >= homePathComponents.count
            && [[workingPathComponents subarrayWithRange:NSMakeRange(0, homePathComponents.count)] isEqualToArray:homePathComponents];

        if (!workingFromWithinHome) {
            NSString *configFilePath = [homePath stringByAppendingPathComponent:CDZThingsHubConfigFileName];
            [currentConfig mergePriorityConfigurationFromPathIfPossible:configFilePath];
        }
        
        NSUInteger beginningComponent = workingFromWithinHome ? homePathComponents.count : 1;
        for (NSUInteger i = beginningComponent; i <= workingPathComponents.count; ++i) {
            NSArray *pathComponents = [workingPathComponents subarrayWithRange:NSMakeRange(0, i)];
            NSString *path = [NSString pathWithComponents:pathComponents];
            
            NSString *configFilePath = [path stringByAppendingPathComponent:CDZThingsHubConfigFileName];
            [currentConfig mergePriorityConfigurationFromPathIfPossible:configFilePath];
        }
        
        // Finally, allow command-line args to override current config:
        [currentConfig mergeInPriorityConfiguration:[self configurationFromDefaults]];
        
        NSError *validationError = [currentConfig validationError];
        if (validationError) {
            [subscriber sendError:validationError];
        } else {
            [subscriber sendNext:currentConfig];
            [subscriber sendCompleted];
        }
        
        return nil; // no cleanup necessary here.
    }];

    return [RACSignal defer:^RACSignal *{
        return configSignal;
    }];
}

/**
 Parses the given file contents into a configuration object. The resulting object is not guaranteed to be valid.
 
 File format is "key = value" pairs. Whitespace before and after each key/value is ignored. Lines beginning (at index 0) with '#' are ignored as comments. Empty lines are ignored.
 */
+ (instancetype)configurationFromFileContents:(NSString *)fileContents {
    CDZThingsHubConfiguration *config = [[CDZThingsHubConfiguration alloc] init];
    
    for (NSString *line in [fileContents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]) {
        NSString *trimmedLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([trimmedLine isEqualToString:@""]) continue;
        if ([trimmedLine characterAtIndex:0] == '#') continue;
        
        NSArray *lineComponents = [trimmedLine componentsSeparatedByString:@"="];
        if (lineComponents.count != 2) {
            CDZCLIPrint(@" - Warning: invalid configuration line (too many components): \"%@\"", line);
            continue;
        }
        
        NSString *key = [lineComponents[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSString *value = [lineComponents[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        [config setConfigValue:value forConfigKey:key];
    }
    
    return config;
}

/// Builds a configuration object from `+[NSUserDefaults standardUserDefaults]`
+ (instancetype)configurationFromDefaults {
    CDZThingsHubConfiguration *config = [[CDZThingsHubConfiguration alloc] init];
    
    NSDictionary *defaultsDict = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
    [defaultsDict enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
        if ([self propertyKeysByConfigKey][key] != nil || [key hasPrefix:CDZThingsHubConfigTagMapConfigKeyPrefix]) {
            [config setConfigValue:value forConfigKey:key];
        }
    }];
    
    return config;
}

#pragma mark - Merging

- (void)mergePriorityConfigurationFromPathIfPossible:(NSString *)path {
    NSString *contents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
    
    if (contents) {
        CDZCLIPrint(@"Merging config file %@", path);
        CDZThingsHubConfiguration *config = [[self class] configurationFromFileContents:contents];
        [self mergeInPriorityConfiguration:config];
    }
}

/// Merges in the given configuration.
/// @param priorityConfiguration Configuration to merge into `self`. Values in the this new config take priority over those already set on `self`.
- (void)mergeInPriorityConfiguration:(CDZThingsHubConfiguration *)priorityConfiguration {
    for (NSString *propertyKey in [[[self class] propertyKeysByConfigKey] allValues]) {
        id value = [priorityConfiguration valueForKey:propertyKey];
        if (value) {
            [self setValue:value forKey:propertyKey];
        }
    }
    
    [priorityConfiguration.githubTagToLocalTagMap enumerateKeysAndObjectsUsingBlock:^(id key, id val, BOOL *stop) {
        ((NSMutableDictionary *)self.githubTagToLocalTagMap)[key] = val;
    }];
}

- (void)setConfigValue:(NSString *)value forConfigKey:(NSString *)configKey {
    NSString *propertyKey;
    
    if ([configKey hasPrefix:CDZThingsHubConfigTagMapConfigKeyPrefix]) {
        propertyKey = [NSString stringWithFormat:@"%@.%@", NSStringFromSelector(@selector(githubTagToLocalTagMap)), [configKey substringFromIndex:CDZThingsHubConfigTagMapConfigKeyPrefix.length]];
    } else {
        propertyKey = [[self class] propertyKeysByConfigKey][configKey];
    }
    
    if (!propertyKey) {
        CDZCLIPrint(@" - Warning: invalid configuration key: \"%@\"", configKey);
        return;
    }
    
    [self setValue:value forKeyPath:propertyKey];
}

#pragma mark - Validation

/// Return an error if this object is in an invalid state; nil otherwise.
- (NSError *)validationError {
    if (!self.githubLogin) {
        return [NSError errorWithDomain:kThingsHubErrorDomain
                                   code:CDZErrorCodeConfigurationValidationError
                               userInfo:@{ NSLocalizedDescriptionKey: @"Github username must be set." }];
    }
    else if (!self.repoOwner) {
        return [NSError errorWithDomain:kThingsHubErrorDomain
                                   code:CDZErrorCodeConfigurationValidationError
                               userInfo:@{ NSLocalizedDescriptionKey: @"Github repo owner must be set." }];
    }
    else if (!self.repoName) {
        return [NSError errorWithDomain:kThingsHubErrorDomain
                                   code:CDZErrorCodeConfigurationValidationError
                               userInfo:@{ NSLocalizedDescriptionKey: @"Github repo name must be set." }];
    }
    else if (!self.delegateApp) {
        return [NSError errorWithDomain:kThingsHubErrorDomain
                                   code:CDZErrorCodeConfigurationValidationError
                               userInfo:@{ NSLocalizedDescriptionKey: @"Delegate must be set." }];
    }
    
    return nil;
}

#pragma mark - NSObject Protocol

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p>: {\n\ttagNamespace: %@\n\tgithubLogin: %@\n\trepoOwner: %@\n\trepoName: %@\n\tareaName: %@\n\tprojectPrefix: %@\n\tdelegateApp: %@\n\ttag map:\n%@\n}",
            NSStringFromClass([self class]),
            self,
            self.tagNamespace,
            self.githubLogin,
            self.repoOwner,
            self.repoName,
            self.areaName,
            self.projectPrefix,
            self.delegateApp,
            [self.githubTagToLocalTagMap descriptionWithLocale:[NSLocale currentLocale] indent:2]
            ];
}

#pragma mark - Input Handling Help

/// Maps user-facing configuration keys to KVC property keys for CDZThingsHubCOnfiguration objects.
+ (NSDictionary *)propertyKeysByConfigKey {
    static NSDictionary *propertyKeysByConfigKey;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        propertyKeysByConfigKey = @{
                                    @"tagNamespace": NSStringFromSelector(@selector(tagNamespace)),
                                    @"githubLogin": NSStringFromSelector(@selector(githubLogin)),
                                    @"repoOwner": NSStringFromSelector(@selector(repoOwner)),
                                    @"repoName": NSStringFromSelector(@selector(repoName)),
                                    @"areaName": NSStringFromSelector(@selector(areaName)),
                                    @"projectPrefix": NSStringFromSelector(@selector(projectPrefix)),
                                    @"delegate": NSStringFromSelector(@selector(delegateApp)),
                                    };
    });
    return propertyKeysByConfigKey;
}

#pragma mark - Property Overrides

- (NSDictionary *)githubTagToLocalTagMap {
    if (!_githubTagToLocalTagMap) {
        _githubTagToLocalTagMap = [NSMutableDictionary dictionary];
    }
    return _githubTagToLocalTagMap;
}

@end
