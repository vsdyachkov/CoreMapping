//
//  NSAttributeDescription+AttributeExtension.m
//  CoreMapping
//
//  Created by Dyachkov Victor on 26.08.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import "NSAttributeDescription+AttributeExtension.h"

@implementation NSAttributeDescription (AttributeExtension)

- (NSString*) mappingName
{
    NSString* name = [NSString stringWithFormat:@"%@",self.name];
    NSDictionary* userInfo = [self userInfo];
    NSString* value = userInfo[@"CM"];
    NSString* mapKey = (value) ? value : name;
    return mapKey;
}

@end