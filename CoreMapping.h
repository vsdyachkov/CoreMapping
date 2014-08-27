//
//  CoreMapping.h
//  CoreMapping
//
//  Created by Dyachkov Victor on 26.08.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSEntityDescription+EntityExtension.h"
#import "NSAttributeDescription+AttributeExtension.h"
#import "NSManagedObject+manager.h"

static NSString* SQLFileName = @"CoreMapping";

static NSPersistentStoreCoordinator* persistentStoreCoordinator;
static NSManagedObjectContext* managedObjectContext;
static NSManagedObjectContext* childManagedObjectContext;
static NSManagedObjectModel* managedObjectModel;

@interface CoreMapping : NSObject

+ (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
+ (NSManagedObjectContext *)managedObjectContext;
+ (NSManagedObjectModel *)managedObjectModel;

+ (void)saveContext;
+ (void)clearDatabase;

+ (void) mapAllEntityWithJson: (NSDictionary*) json;

+ (void) saveInBackgroundWithBlock: (void(^)(NSManagedObjectContext *context))block completion:(void(^)(BOOL success, NSError *error)) completion;


@end