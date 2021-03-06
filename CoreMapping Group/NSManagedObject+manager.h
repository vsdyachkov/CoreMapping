//
//  NSManagedObject+manager.h
//  CoreMapping
//
//  Created by Dyachkov Victor on 26.08.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CoreMapping.h"

@interface NSManagedObject (manager)

# pragma mark - Finding with id

+ (instancetype) findObjectWithId:(NSNumber*)idObj;

# pragma mark - Finding custom

+ (NSArray*) findRowsWithPredicate:(NSPredicate*)predicate andSortDescriptors:(NSArray*)sortDescriptors;
+ (NSArray*) findRowsWithPredicate:(NSPredicate*)predicate sortedBy:(NSString*)sortProperty ascending:(BOOL)ascending;
+ (NSArray*) findRowsWithPredicate:(NSPredicate*)predicate;

# pragma mark - Finding all

+ (NSArray*) findAllRowsWithSortDescriptors:(NSArray*)sortDescriptors;
+ (NSArray*) findAllRowsSortedBy:(NSString*)sortProperty ascending:(BOOL)ascending;
+ (NSArray*) findAllRows;

# pragma mark - Finding first

+ (instancetype) findFirstRowWithPredicate:(NSPredicate*)predicate andSortDescriptors:(NSArray*)sortDescriptors;
+ (instancetype) findFirstRowWithPredicate:(NSPredicate*)predicate sortedBy:(NSString*)sortProperty ascending:(BOOL)ascending;
+ (instancetype) findFirstRowWithPredicate:(NSPredicate*)predicate;

# pragma mark - Inserting

+ (instancetype) insert;

# pragma mark - Deleting

- (void) deleteObjects:(NSSet*)set;
- (void) deleteRow;
+ (void) deleteAllRows;


@end
