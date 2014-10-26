//
//  CoreMapping.m
//  CoreMapping
//
//  Created by Dyachkov Victor on 26.08.14.
//  Copyright (c) 2014 Dyachkov Victor. All rights reserved.
//

#import "CoreMapping.h"
#import <AFNetworking.h>

@implementation CoreMapping

#pragma mark - Core Mapping stack

+ (void) mapValue:(id) value withJsonKey: (NSString*) key andType: (NSAttributeType) type andManagedObject: (NSManagedObject*) obj
{
    NSAssert(value || key || type || obj, @"%@ value: %@, key: %@, type: %lu, obj: %@", errNilParam, value, key, (long)type, obj);
    [CMTests checkString:key];
    [CMTests checkManagedObject:obj];
    
    id convertedValue;
    NSString* strValue = [NSString stringWithFormat:@"%@",value];
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    [format setDateFormat: CMDefaultDateFormat];
    switch (type) {
        case NSUndefinedAttributeType: convertedValue =  nil; break;
        case NSInteger16AttributeType: convertedValue =  [NSNumber numberWithInt:[strValue intValue]]; break;
        case NSInteger32AttributeType: convertedValue =  [NSNumber numberWithInt:[strValue intValue]]; break;
        case NSInteger64AttributeType: convertedValue =  [NSNumber numberWithInt:[strValue intValue]]; break;
        case NSDecimalAttributeType: convertedValue =    [NSNumber numberWithInt:[strValue doubleValue]]; break;
        case NSDoubleAttributeType: convertedValue =     [NSNumber numberWithInt:[strValue doubleValue]]; break;
        case NSFloatAttributeType: convertedValue =      [NSNumber numberWithInt:[strValue floatValue]]; break;
        case NSStringAttributeType: convertedValue =     strValue; break;
        case NSBooleanAttributeType: convertedValue =    [NSNumber numberWithInt:[strValue boolValue]]; break;
        case NSDateAttributeType: convertedValue =       [format dateFromString:strValue]; break;
        case NSBinaryDataAttributeType: convertedValue = [strValue dataUsingEncoding:NSUTF8StringEncoding]; break;
            
        default: [NSException raise:@"Invalid attribute type" format:@"This type is not supported in database"]; break;
    }
    
    NSAssert(convertedValue || key, @"%@ convertedValue: %@, key: %@", errNilParam, convertedValue, key);
    [obj setValue:convertedValue forKey:key];
}

+ (NSManagedObject*) findObjectInEntity: (NSEntityDescription*) entity withId: (NSNumber*) idNumber enableCreating: (BOOL) create
{
    NSAssert(entity || idNumber, @"%@ entity: %@, idNumber: %@", errNilParam, entity, idNumber);
    [CMTests checkEntityDescription:entity];
    [CMTests checkNumber:idNumber];
    
    NSFetchRequest* req = [[NSFetchRequest alloc]initWithEntityName:entity.name];
    NSString* idKey = [entity mappingIdKey];
    NSPredicate* myPred = [NSPredicate predicateWithFormat:@"%K == %@", idKey, idNumber];
    [req setPredicate:myPred];
    
    NSArray* arr = [[CMCoreData contextForCurrentThread] executeFetchRequest:req error:nil];
    if (arr.count > 0) {
        return arr[0];
    } else {
        if (create) {
            return [NSEntityDescription insertNewObjectForEntityForName:entity.name inManagedObjectContext:[CMCoreData contextForCurrentThread]];
        } else {
            return nil;
        }
        
    }
}

+ (NSManagedObject*) mapSingleRowInEntity: (NSEntityDescription*) desc andJsonDict: (NSDictionary*) json
{
    NSAssert(desc || json, @"%@ desc: %@, json: %@", errNilParam, desc, json);
    [CMTests checkEntityDescription:desc];
    [CMTests checkDictionary:json];
    
    NSString* mappingIdKey = [desc mappingIdValue];
    
    NSNumber* idFromJson;
    if (mappingIdKey)
    {
        if (json[mappingIdKey]) {
            idFromJson = @([json[mappingIdKey] integerValue]);
        } else {
            idFromJson = @([json[@"id"] integerValue]);
        }
    }
    
    NSManagedObject* obj = [self findObjectInEntity:desc withId:idFromJson enableCreating:YES];
    
    NSDictionary* attributes = [desc attributesByName];
    [[attributes allValues] enumerateObjectsUsingBlock:^(NSAttributeDescription* attr, NSUInteger idx, BOOL *stop) {
        NSString* mappingAttrName = [attr mappingName];
        // if "id" of entity != mappingAttrName in json
        id valueFromJson = (json [mappingAttrName]) ? json [mappingAttrName] : json[@"id"];
        [self mapValue:valueFromJson withJsonKey:attr.name andType:attr.attributeType andManagedObject:obj];
    }];
    
    [self mapRelationshipsWithObject:obj andJsonDict:json];
    
    NSAssert(obj, @"%@ json: %@", errNilParam, obj);
    return obj;
}

+ (NSMutableDictionary*) addRelationshipIfNeed: (NSString*) name andRelationship: (NSRelationshipDescription*) relationship
{
    if (relationshipDictionary != nil) {
        if (![relationshipDictionary.allKeys containsObject:name]) {
            [relationshipDictionary setObject:relationship forKey:name];
            return relationshipDictionary;
        }
        return relationshipDictionary;
    }
    
    relationshipDictionary = [NSMutableDictionary new];
    [relationshipDictionary setObject:relationship forKey:name];
    return relationshipDictionary;
}

+ (void) mapRelationshipsWithObject: (NSManagedObject*) obj andJsonDict: (NSDictionary*) json
{
    NSAssert(obj || json, @"%@ obj: %@, json: %@", errNilParam, obj, json);
    [CMTests checkManagedObject:obj];
    [CMTests checkDictionary:json];
    
    // perform Relationships: ManyToOne & OneToOne & OneToMany
    NSEntityDescription* desc = obj.entity;
    for (NSString* name in desc.relationshipsByName) {
        NSRelationshipDescription* relationFromChild = desc.relationshipsByName[name];
        NSRelationshipDescription* inverseFromParent = relationFromChild.inverseRelationship;
        
        if ((relationFromChild && inverseFromParent) &&  ![[CMHelper relationshipIdFrom:relationFromChild to:inverseFromParent] isEqual: @3]) {
            // This (many) Childs to -> (one) Parent
            NSEntityDescription* destinationEntity = relationFromChild.destinationEntity;
            NSString* relationMappedName = [relationFromChild mappingName];
            NSNumber* idObjectFormJson = json[relationMappedName];
            if (idObjectFormJson) {
                // Relationship found
                NSManagedObject* toObject = [self findObjectInEntity:destinationEntity withId:idObjectFormJson enableCreating:NO];
                NSString* selectorName = [NSString stringWithFormat:@"add%@Object:", inverseFromParent.name.capitalizedString];
                [toObject performSelectorIfResponseFromString:selectorName withObject:obj];
            }
        } else {
            [self addRelationshipIfNeed:[relationFromChild manyToManyTableName] andRelationship:relationFromChild];
        }
        
    }
}

+ (void) mapAllRowsInEntity: (NSEntityDescription*) desc andWithJsonArray: (NSArray*) jsonArray
{
    NSAssert(desc || jsonArray, @"%@ desc: %@, jsonArray: %@", errNilParam, desc, jsonArray);
    [CMTests checkEntityDescription:desc];
    [CMTests checkArray:jsonArray];
    
    [jsonArray enumerateObjectsUsingBlock:^(NSDictionary* singleDict, NSUInteger idx, BOOL *stop) {
        NSManagedObject* obj = [self mapSingleRowInEntity:desc andJsonDict:singleDict];
        [obj performSelectorIfResponseFromString:@"customizeWithJson:" withObject:singleDict];
    }];
}

+ (void) removeRowsInEntity: (NSEntityDescription*) desc withNumberArray: (NSArray*) removeArray
{
    NSAssert(desc || removeArray, @"%@ desc: %@, removeArray: %@", errNilParam, desc, removeArray);
    [CMTests checkEntityDescription:desc];
    [CMTests checkArray:removeArray];
    
    [removeArray enumerateObjectsUsingBlock:^(NSNumber* removeId, NSUInteger idx, BOOL *stop) {
        NSFetchRequest* req = [[NSFetchRequest alloc]initWithEntityName:desc.name];
        NSPredicate* myPred = [NSPredicate predicateWithFormat:@"%K == %@", [desc mappingIdValue], removeId];
        [req setPredicate:myPred];
        NSArray* arr = [[CMCoreData contextForCurrentThread] executeFetchRequest:req error:nil];
        if (arr.count > 0) {
            [[CMCoreData contextForCurrentThread] deleteObject:arr[0]];
        }
    }];
}

#pragma mark - Sync methods

+ (void) syncWithJson: (NSDictionary*) json
{
    NSAssert(json, @"%@ json: %@", errNilParam, json);
    [CMTests checkDictionary:json];
    
    NSMutableString* report = @"\n\nParsing status:\n".mutableCopy;
    
    __block float progress = 0.0f;
    
    NSMutableArray* entities = [[CMCoreData managedObjectModel] entities].mutableCopy;
    
    // Remove not parsing entities
    [entities.copy enumerateObjectsUsingBlock:^(NSEntityDescription* obj, NSUInteger idx, BOOL *stop) {
        if ([obj isNoParse]) {
            [entities removeObject:obj];
        }
    }];
    
    // Add and Remove processing
    [entities enumerateObjectsUsingBlock:^(NSEntityDescription* desc, NSUInteger idx, BOOL *stop) {
        
        if ([CMTests validateDictionary:json[desc.mappingEntityName]])
        {
            NSDictionary* jsonTable = json[desc.mappingEntityName];
            
            if ([jsonTable.allKeys containsObject:CMJsonAddName])
            {
                NSArray* addArray = [CMTests validateArray:json[desc.mappingEntityName][CMJsonAddName]];
                [report appendFormat:@"[+] Added %lu '%@' from Json -> %@ -> %@\n", (unsigned long)addArray.count, desc.mappingEntityName, desc.mappingEntityName,CMJsonAddName];
                if (addArray) [self mapAllRowsInEntity:desc andWithJsonArray:addArray];
            } else {
                [report appendFormat:@"[i] No 'add' section in Json -> %@ -> %@\n", desc.mappingEntityName, CMJsonAddName];
            }
            
            progress = (float)(idx+0.5f)/(entities.count+1);
            [[NSNotificationCenter defaultCenter] postNotificationName:CMProgressNotificationName object:nil userInfo:@{CMProgress:@(progress), CMProgressEntityName:desc.mappingEntityName}];
            
            if ([jsonTable.allKeys containsObject:CMJsonRemoveName])
            {
                NSArray* removeArray = [CMTests validateArray:json[desc.mappingEntityName][CMJsonRemoveName]];
                [report appendFormat:@"[-] Removed %lu '%@' from Json -> %@ -> %@\n", (unsigned long)removeArray.count, desc.mappingEntityName, desc.mappingEntityName, CMJsonRemoveName];
                if (removeArray) [self removeRowsInEntity:desc withNumberArray:(NSArray*)removeArray];
            } else {
                [report appendFormat:@"[i] No 'remove' section in Json -> %@ -> %@\n", desc.mappingEntityName, CMJsonAddName];
            }
            
            progress = (float)(idx+1.0f)/(entities.count+1);
            [[NSNotificationCenter defaultCenter] postNotificationName:CMProgressNotificationName object:nil userInfo:@{CMProgress:@(progress), CMProgressEntityName:desc.mappingEntityName}];
        }
        else
        {
            [report appendFormat:@"[!] Json -> '%@' not found or not array\n", desc.mappingEntityName];
        }
        
    }];
    
    
    // Parsing relationship tables
    for (NSString* tableName in [relationshipDictionary.copy  allKeys])
    {
        if (!json[tableName]) {
            [relationshipDictionary removeObjectForKey:tableName];
        }
    }
    
    int relations = 0;
    
    for (NSString* key in relationshipDictionary.allKeys) {
        
        if (![json.allKeys containsObject:key]) return;
        NSDictionary* relationDict = [json objectForKey:key];
        
        if (![relationDict.allKeys containsObject:CMJsonAddName]) return;
        NSArray* addArray = [relationDict objectForKey:CMJsonAddName];
        
        for (NSDictionary* tmpJson in addArray) {
            
            relations++;
            
            NSRelationshipDescription* relationFromChild = [relationshipDictionary objectForKey:key];
            NSRelationshipDescription* inverseFromParent = relationFromChild.inverseRelationship;
            
            NSEntityDescription* childEntity = relationFromChild.entity;
            NSEntityDescription* destinationEntity = relationFromChild.destinationEntity;
            
            NSString* key1 = [childEntity mappingIdKey];
            NSString* key2 = [destinationEntity mappingIdKey];
            
            NSNumber* value1 = @([tmpJson[key1] integerValue]);
            NSNumber* value2 = @([tmpJson[key2] integerValue]);
            
            if (value1 && value2) {
                // Relationship found
                NSManagedObject* firstObject = [self findObjectInEntity:childEntity withId:value1 enableCreating:NO];
                NSManagedObject* secondObject = [self findObjectInEntity:destinationEntity withId:value2 enableCreating:NO];
                
                if (firstObject && secondObject) {
                    NSString* selectorName = [NSString stringWithFormat:@"add%@Object:", inverseFromParent.name.capitalizedString];
                    [secondObject performSelectorIfResponseFromString:selectorName withObject:firstObject];
                }
                
            }
            
        }
        
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:CMProgressNotificationName object:nil userInfo:@{CMProgress:@(1)}];
    
    if (relationshipDictionary) {
        [report appendFormat:@"[+] Add %d relationship from tables: Json -> %@", relations, relationshipDictionary.allKeys];
    } else {
        [report appendFormat:@"[i] No relationship tables found"];
    }
    
    NSLog(@"%@\n\n",report);
    
    [CMCoreData saveContext];
    
}

+ (void) syncWithJson: (NSDictionary*) json completion:(void(^)(NSDictionary* json)) completion
{
    NSAssert(json, @"%@ json: %@", errNilParam, json);
    [CMTests checkDictionary:json];
    
    [self databaseOperationInBackground:^(NSManagedObjectContext *context) {
        [self syncWithJson:json];
    } completion:^(BOOL success, NSError *error) {
        if (success) completion(json);
    }];
}

+ (void) syncWithJsonByName: (NSString*) name
{
    NSAssert(name, @"%@ name: %@", errNilParam, name);
    [CMTests checkString:name];
    
    NSDictionary* json = [CMHelper jsonWithFileName:name];
    [self syncWithJson:json];
}

+ (void) syncWithJsonByName: (NSString*) name completion:(void(^)(NSDictionary* json)) completion
{
    NSAssert(name, @"%@ name: %@", errNilParam, name);
    [CMTests checkString:name];
    
    NSDictionary* json = [CMHelper jsonWithFileName:name];
    [self databaseOperationInBackground:^(NSManagedObjectContext *context) {
        [self syncWithJson:json];
    } completion:^(BOOL success, NSError *error) {
        if (success) completion(json);
    }];
}

+ (void) syncWithJsonByUrl: (NSURL*) url completion:(void(^)(NSDictionary* json)) completion
{
    NSAssert(url, @"%@ url: %@", errNilParam, url);
    [CMTests checkURL:url];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setTimeoutInterval:10.0];
    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    op.responseSerializer = [AFJSONResponseSerializer serializer];
    NSMutableSet* responseTypes = [NSMutableSet setWithSet:op.responseSerializer.acceptableContentTypes];
    [responseTypes addObject:@"text/html"];
    op.responseSerializer.acceptableContentTypes = responseTypes;
    
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, NSDictionary* responseObject) {
        [Logger logSuccessWithTitle:@"Json downloaded" message:nil debugDict:@{@"url":url} alert:NO];
        [self databaseOperationInBackground:^(NSManagedObjectContext *context) {
            [self syncWithJson:responseObject];
        } completion:^(BOOL success, NSError *error) {
            if (success) completion(responseObject);
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [Logger logErrorWithTitle:@"Json not downloaded" message:error.localizedDescription debugDict:@{@"url":url} alert:NO];
    }];
    
    [[NSOperationQueue mainQueue] cancelAllOperations];
    [[NSOperationQueue mainQueue] addOperation:op];
}

#pragma mark - Async database operation methods

+ (void) databaseOperationInBackground: (void(^)(NSManagedObjectContext *context))block completion:(void(^)(BOOL success, NSError *error)) completion
{
    NSAssert([NSThread isMainThread], errInvalidThread);
    
    NSManagedObjectContext *childManagedObjectContext = [CMCoreData childManagedObjectContext];
    [childManagedObjectContext performBlock:^{
        if (block) {
            block(childManagedObjectContext);
            NSError* error1 = [CMCoreData saveChildContext];
            [[CMCoreData managedObjectContext] performBlock:^{
                NSError* error2 = [CMCoreData saveMainContext];
                BOOL isSuccess = (!error1 && !error2);
                NSString* errorDesc = [NSString stringWithFormat:@"Errors: %@, %@", error1.localizedDescription, error2.localizedDescription];
                NSError* fatalError = [NSError errorWithDomain:errorDesc code:-1 userInfo:nil];
                if (completion) {
                    (isSuccess) ? completion(YES, nil) : completion(NO, fatalError);
                }
            }];
        }
    }];
}

@end