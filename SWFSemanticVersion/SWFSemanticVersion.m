//
//  SWFSemanticVersion.m
//  SWFSemanticVersion
//
//  Created by Samuel Ford on 2/5/14.
//  Copyright (c) 2014 Samuel Ford. All rights reserved.
//

#import "SWFSemanticVersion.h"

@interface NSString (SWFSM_Contains)

- (BOOL)SWFSM_containsString:(NSString *)string;

@end

@implementation NSString (SWFSM_Contains)

- (BOOL)SWFSM_containsString:(NSString *)string
{
    NSRange r = [self rangeOfString:string ?: @""];
    return r.location != NSNotFound;
}

@end

@interface NSArray (SWFSM_Ordinals)

- (id)SWFSM_secondObject;

- (id)SWFSM_thirdObject;

@end

@implementation NSArray (SWFSM_Ordinals)

- (id)SWFSM_secondObject
{
    if (self.count > 1) {
        return [self objectAtIndex:1];
    }
    
    return nil;
}

- (id)SWFSM_thirdObject
{
    if (self.count > 2) {
        return [self objectAtIndex:2];
    }
    
    return nil;
}

@end

@implementation SWFSemanticVersion

+ (NSRegularExpression *)regex
{
    static NSRegularExpression *_regex = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *error;
        _regex = [NSRegularExpression regularExpressionWithPattern:@"\\A(\\d+\\.\\d+\\.\\d+)(-([0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*))?(\\+([0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*))?\\Z" options:0 error:&error];
    });
    return _regex;
}

+ (instancetype)semanticVersionWithString:(NSString *)string
{
    SWFSemanticVersion *semVer = [SWFSemanticVersion new];
    
    NSRange range = NSMakeRange(0, string.length);
    NSTextCheckingResult *match = [[SWFSemanticVersion regex] firstMatchInString:string options:0 range:range];
    
    if (!match) {
        return nil;
    }
    
    NSArray *stringSplitByDash = [string componentsSeparatedByString:@"-"];
    
    NSString *version = [stringSplitByDash firstObject];
    NSString *parts = [stringSplitByDash SWFSM_secondObject];
    
    if (parts && [parts SWFSM_containsString:@"+"]) {
        NSArray *partsSplitByPlus = [parts componentsSeparatedByString:@"+"];
        semVer.pre = [partsSplitByPlus firstObject];
        semVer.build = [partsSplitByPlus SWFSM_secondObject];
    } else if ([version SWFSM_containsString:@"+"]) {
        NSArray *versionSplitByPlus = [version componentsSeparatedByString:@"+"];
        version = [versionSplitByPlus firstObject];
        semVer.build = [versionSplitByPlus SWFSM_secondObject];
    } else {
        semVer.pre = parts;
    }
    
    NSArray *versionSplitByDot = [version componentsSeparatedByString:@"."];
    
    semVer.major = @([[versionSplitByDot firstObject] integerValue]);
    semVer.minor = @([[versionSplitByDot SWFSM_secondObject] integerValue]);
    semVer.patch = @([[versionSplitByDot SWFSM_thirdObject] integerValue]);
    
    return semVer;
}

- (NSArray *)components
{
    return @[self.major, self.minor, self.patch, self.pre ?: @"", self.build ?: @""];
}

- (NSComparisonResult)compare:(SWFSemanticVersion *)version
{
    if (!version) return NSOrderedDescending;
    
    __block NSComparisonResult result = NSOrderedSame;
    
    NSArray *these = [self components];
    NSArray *those = [version components];
    
    [these enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id this = obj;
        id that = [those objectAtIndex:idx];
        
        result = [this compare:that];
        
        if (result != NSOrderedSame) *stop = YES;
    }];
    
    return result;
}

- (NSString *)description
{
    NSMutableString *string = [NSMutableString stringWithFormat:@"%@.%@.%@", self.major, self.minor, self.patch];
    
    if (self.pre) {
        [string appendFormat:@"-%@", self.pre];
    }
    
    if (self.build) {
        [string appendFormat:@"+%@", self.build];
    }
    
    return string;
}

@end
