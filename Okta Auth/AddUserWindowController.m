//
//  AddUserWindowController.m
//  Okta Auth
//
//  Created by Dev Floater 114 on 2015-02-11.
//  Copyright (c) 2015 Pivotal Labs. All rights reserved.
//

#import "AddUserWindowController.h"
#import "Constants.h"
#import "User.h"

#import <ParseOSX/ParseOSX.h>

@interface AddUserWindowController ()

@property (weak) IBOutlet NSTextField *usernameTextField;
@property (weak) IBOutlet NSTextField *keyTextField;

@end

@implementation AddUserWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    [self.window center];
}

#pragma mark - IBActions

- (IBAction)doneButtonClicked:(NSButton *)sender {
    if ([self validTextFields]) {
        NSDictionary *userData = @{kUserNameKey:self.usernameTextField.stringValue,kSecretKey:self.keyTextField.stringValue};
        User *user = [User userFromData:userData];
        
        if ([self.delegate conformsToProtocol:@protocol(AddUserWindowControllerDelegate)]) {
            [self.delegate userDidSaveNewUser:user];
        }
        
        [self saveParseUser:user];
        [self clearFields];
        [self displaySuccessMessage];
    }
}

#pragma mark - Private

- (void)saveParseUser:(User *)user {
    PFObject *oktaUser = [PFObject objectWithClassName:@"OktaUser"];
    oktaUser[kUserNameKey] = user.username;
    oktaUser[kSecretKey] = user.secret;
    [oktaUser saveInBackground];
}

- (BOOL)validTextFields {
   return self.usernameTextField.stringValue.length > 0 && self.keyTextField.stringValue.length > 0;
}

- (void)clearFields {
    self.usernameTextField.stringValue = @"";
    self.keyTextField.stringValue = @"";
}

- (void)displaySuccessMessage {
    NSAlert *alert = [NSAlert new];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert setMessageText:@"You are done!"];
    [alert setInformativeText:@"New user created successfully"];
    [alert runModal];
}

@end
