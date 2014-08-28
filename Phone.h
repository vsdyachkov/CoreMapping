//
//  Phone.h
//  CoreMapping
//
//  Created by Dyachkov Victor on 28.08.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class City;

@interface Phone : NSManagedObject

@property (nonatomic, retain) NSNumber * phone_id;
@property (nonatomic, retain) NSString * string_number;
@property (nonatomic, retain) City *city;

@end