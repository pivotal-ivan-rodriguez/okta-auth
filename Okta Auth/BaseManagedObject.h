//
//  BaseManagedObject.h
//  Okta Auth
//
//  Created by Dev Floater 114 on 2015-02-11.
//  Copyright (c) 2015 Pivotal Labs. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface BaseManagedObject : NSManagedObject

+ (NSString *)entityName;
+ (id)objectForID:(NSString *)objectID;
+ (NSManagedObjectContext *)managedObjectContext;
+ (NSArray *)allObjects;
+ (void)clearAllObjects;

@end
