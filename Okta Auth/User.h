//
//  User.h
//  Okta Auth
//
//  Created by Dev Floater 114 on 2015-02-11.
//  Copyright (c) 2015 Pivotal Labs. All rights reserved.
//

#import "BaseManagedObject.h"

@class PFObject;

@interface User : BaseManagedObject

@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSString * secret;

+ (User *)userFromData:(NSDictionary *)data;
+ (User *)userFromParseUser:(PFObject *)user;
+ (User *)userForUsername:(NSString *)username;

@end
