//
//  NSEntityDescription+EntityExtension.h
//  CoreMapping
//
//  Created by Dyachkov Victor on 26.08.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import "CoreMapping.h"

@interface NSEntityDescription (mapping)

- (NSString*) mappingEntityName;
- (NSString*) mappingIdKey;
- (NSString*) mappingIdValue;

- (BOOL) isNoParse;

//+ (void) findOfCreateObjectWithPredicate: (NSPredicate*) predicate;

@end