//
//  AddUserWindowController.h
//  Okta Auth
//
//  Created by Dev Floater 114 on 2015-02-11.
//  Copyright (c) 2015 Pivotal Labs. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class User;

@protocol AddUserWindowControllerDelegate <NSObject>

- (void)userDidSaveNewUser:(User *)user;

@end

@interface AddUserWindowController : NSWindowController

@property (nonatomic, weak) id<AddUserWindowControllerDelegate>delegate;

@end
