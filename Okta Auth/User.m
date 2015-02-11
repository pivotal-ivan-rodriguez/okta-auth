//
//  User.m
//  Okta Auth
//
//  Created by Dev Floater 114 on 2015-02-11.
//  Copyright (c) 2015 Pivotal Labs. All rights reserved.
//

#import "User.h"
#import "Constants.h"
#import <ParseOSX/ParseOSX.h>

@implementation User

@dynamic username;
@dynamic secret;

+ (User *)userFromData:(NSDictionary *)data {
    User *user = [User userForUsername:data[kUserNameKey]];
    if (user) return user;
    
    user = [NSEntityDescription insertNewObjectForEntityForName:[User entityName] inManagedObjectContext:[User managedObjectContext]];
    user.username = data[kUserNameKey];
    user.secret = data[kSecretKey];
    [[User managedObjectContext] save:nil];
    
    return user;
}

+ (User *)userFromParseUser:(PFObject *)fpUser {
    User *user = [User userForUsername:fpUser[kUserNameKey]];
    if (user) return user;
    
    user = [NSEntityDescription insertNewObjectForEntityForName:[User entityName] inManagedObjectContext:[User managedObjectContext]];
    user.username = fpUser[kUserNameKey];
    user.secret = fpUser[kSecretKey];
    [[User managedObjectContext] save:nil];
    
    return user;
}

+ (User *)userForUsername:(NSString *)username {
    if (!username) return nil;
    
    return [super objectForID:username];
}

@end
