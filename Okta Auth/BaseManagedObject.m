//
//  BaseManagedObject.m
//  Okta Auth
//
//  Created by Dev Floater 114 on 2015-02-11.
//  Copyright (c) 2015 Pivotal Labs. All rights reserved.
//

#import "BaseManagedObject.h"
#import "AppDelegate.h"

@implementation BaseManagedObject

+ (NSString *)entityName {
    return NSStringFromClass([self class]);
}

+ (id)objectForID:(NSString *)objectID {
    if (!objectID) return nil;
    
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:[[self class] entityName] inManagedObjectContext:[BaseManagedObject managedObjectContext]];
    
    NSFetchRequest *request = [NSFetchRequest new];
    [request setEntity:entityDescription];
    
    request.predicate = [NSPredicate predicateWithFormat:@"username == %@",objectID];
    
    NSError *error = nil;
    NSArray *array = [[[self class] managedObjectContext] executeFetchRequest:request error:&error];
    return array.firstObject;
}

+ (NSManagedObjectContext *)managedObjectContext {
    AppDelegate *appDelegate = [NSApp delegate];
    return appDelegate.managedObjectContext;
}

+ (NSArray *)allObjects {
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:[[self class] entityName] inManagedObjectContext:[[self class] managedObjectContext]];
    NSFetchRequest *request = [NSFetchRequest new];
    [request setEntity:entityDescription];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"username" ascending:YES];
    [request setSortDescriptors:@[sortDescriptor]];
    
    NSError *error = nil;
    return [[BaseManagedObject managedObjectContext] executeFetchRequest:request error:&error];
}

+ (void)clearAllObjects {
    NSArray *objects = [[self class] allObjects];
    for (NSManagedObject *object in objects) {
        [[[self class] managedObjectContext] deleteObject:object];
    }
    [[[self class] managedObjectContext] save:nil];
}

@end
