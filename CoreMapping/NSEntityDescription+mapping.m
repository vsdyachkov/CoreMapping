//
//  NSEntityDescription+EntityExtension.m
//  CoreMapping
//
//  Created by Dyachkov Victor on 26.08.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import "NSEntityDescription+mapping.h"

@implementation NSEntityDescription (mapping)

- (NSString*) mappingName
{
    NSString* name = [NSString stringWithFormat:@"%@",self.name];
    NSDictionary* userInfo = [self userInfo];
    NSString* value = userInfo[CoreDataPrefix];
    NSString* mapKey = (value) ? value : name;
    return mapKey;
}

- (NSString*) idKeyString
{
    NSDictionary* attributes = [self attributesByName];
    __block NSString* key;
    [[attributes allValues] enumerateObjectsUsingBlock:^(NSAttributeDescription* attr, NSUInteger idx, BOOL *stop) {
        if ([attr.userInfo[CoreDataPrefix] isEqualToString:@"id"]) {
            key = [NSString stringWithFormat:@"%@",attr.name];
            *stop = YES;
        }
    }];
    return key;
}


+ (void) findOfCreateObjectWithPredicate: (NSPredicate*) predicate
{
    //
}

@end