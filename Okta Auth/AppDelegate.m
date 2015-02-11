//
//  AppDelegate.m
//  Okta Auth
//
//  Created by Dev Floater 114 on 2015-02-10.
//  Copyright (c) 2015 Pivotal Labs. All rights reserved.
//

#import "AppDelegate.h"
#import "AddUserWindowController.h"
#import "User.h"
#import "Constants.h"

#import "TOTPGenerator.h"
#import "MF_Base32Additions.h"

#import <ParseOSX/ParseOSX.h>

static NSInteger const kPINDigits = 6;
static NSInteger const kPINExpireTime = 30;
static NSString * const kSelectUserButtonText = @"*Select User*";

@interface AppDelegate () <AddUserWindowControllerDelegate>

@property (weak) IBOutlet NSPopUpButton *userListButton;
@property (weak) IBOutlet NSTextField *codeLabel;
@property (weak) IBOutlet NSTextField *timeLabel;
@property (weak) IBOutlet NSButton *clipboardButton;
@property (weak) IBOutlet NSWindow *window;

@property (nonatomic, strong) AddUserWindowController *addUserWindowController;
@property (nonatomic, strong) NSMutableArray *users;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) User *selectedUser;
@property (nonatomic, strong) NSString *currentPing;
@property (nonatomic, assign) NSUInteger expireTime;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self.window center];
    [self initializeParse];
    [self initialSetup];
    [self loadSavedUsers];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

#pragma mark - Getters

- (AddUserWindowController *)addUserWindowController {
    if (!_addUserWindowController) {
        NSString *addUserWindowControllerNib = NSStringFromClass([AddUserWindowController class]);
        _addUserWindowController = [[AddUserWindowController alloc] initWithWindowNibName:addUserWindowControllerNib];
        _addUserWindowController.delegate = self;
    }
    return _addUserWindowController;
}

- (NSMutableArray *)users {
    if (!_users) {
        _users = [NSMutableArray new];
    }
    return _users;
}

#pragma mark - IBActions

- (IBAction)addUserButtonClicked:(NSButton *)sender {
    [self.addUserWindowController showWindow:self];
}

- (IBAction)selectUserButton:(NSPopUpButton *)sender {
    if (sender.title.length == 0 || [sender.title isEqualToString:kSelectUserButtonText]) return;
    
    self.selectedUser = [User userForUsername:sender.title];
    [self startTimer];
}

- (IBAction)copyToClipboard:(NSButton *)sender {
    if (!self.currentPing) return;
    
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    [pasteboard writeObjects:@[self.currentPing]];
}

#pragma mark - Core Data stack

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "io.pivotal.Okta_Auth" in the user's Application Support directory.
    NSURL *appSupportURL = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"io.pivotal.Okta_Auth"];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Okta_Auth" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationDocumentsDirectory = [self applicationDocumentsDirectory];
    BOOL shouldFail = NO;
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    
    // Make sure the application files directory is there
    NSDictionary *properties = [applicationDocumentsDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    if (properties) {
        if (![properties[NSURLIsDirectoryKey] boolValue]) {
            failureReason = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationDocumentsDirectory path]];
            shouldFail = YES;
        }
    } else if ([error code] == NSFileReadNoSuchFileError) {
        error = nil;
        [fileManager createDirectoryAtPath:[applicationDocumentsDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    if (!shouldFail && !error) {
        NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        NSURL *url = [applicationDocumentsDirectory URLByAppendingPathComponent:@"OSXCoreDataObjC.storedata"];
        if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]) {
            coordinator = nil;
        }
        _persistentStoreCoordinator = coordinator;
    }
    
    if (shouldFail || error) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        if (error) {
            dict[NSUnderlyingErrorKey] = error;
        }
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
    }
    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];

    return _managedObjectContext;
}

#pragma mark - Core Data Saving and Undo support

- (IBAction)saveAction:(id)sender {
    // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    NSError *error = nil;
    if ([[self managedObjectContext] hasChanges] && ![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
    return [[self managedObjectContext] undoManager];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    // Save changes in the application's managed object context before the application terminates.
    
    if (!_managedObjectContext) {
        return NSTerminateNow;
    }
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (![[self managedObjectContext] hasChanges]) {
        return NSTerminateNow;
    }
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {

        // Customize this code block to include application-specific recovery steps.              
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }

        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertFirstButtonReturn) {
            return NSTerminateCancel;
        }
    }

    return NSTerminateNow;
}

#pragma mark - AddUserWindowControllerDelegate

- (void)userDidSaveNewUser:(User *)user {
    [self.users addObject:user];
    [self.userListButton addItemWithTitle:user.username];
    [self.addUserWindowController close];
}

#pragma mark - Private

- (void)initializeParse {
    [Parse enableLocalDatastore];
    [Parse setApplicationId:@"CfwEfgQlyADIXMpC0P3TW6rCTtqvbAvZvpO0NYSe" clientKey:@"MerS9PaizY7CggbPyCMt2R1uzG9xf2Zt9vVGCITy"];
    [PFAnalytics trackAppOpenedWithLaunchOptions:nil];
}

- (void)initialSetup {
    self.codeLabel.stringValue = @"";
    self.timeLabel.stringValue = @"";
    [self.clipboardButton setHidden:YES];
    [self.timeLabel setHidden:YES];
}

- (void)loadSavedUsers {
    PFQuery *query = [PFQuery queryWithClassName:@"OktaUser"];
    
    __weak typeof(self) weakSelf = self;
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        [objects enumerateObjectsUsingBlock:^(PFObject *pfUser, NSUInteger idx, BOOL *stop) {
            User *user = [User userFromParseUser:pfUser];
            [weakSelf.users addObject:user];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.userListButton addItemWithTitle:user.username];
            });
        }];
    }];
}

- (void)startTimer {
    if (self.timer) {
        [self.timer invalidate];
    }

    [self.clipboardButton setHidden:NO];
    [self.timeLabel setHidden:NO];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateUI) userInfo:nil repeats:YES];
    
    [self calculateExpireTime];
}

- (void)updateUI {
    NSString *pin = [self generatePINForUser:self.selectedUser];
    self.currentPing = pin;
    if (pin.length == kPINDigits) {
        NSInteger half = (kPINDigits/2);
        self.codeLabel.stringValue = [NSString stringWithFormat:@"%@ %@",[pin substringToIndex:half],[pin substringFromIndex:half]];
        [self decreaseTime];
    }
}

- (void)decreaseTime {
    if (self.expireTime > 0) self.expireTime--;
    else [self calculateExpireTime];
    
    self.timeLabel.stringValue = [NSString stringWithFormat:@"%lus",(unsigned long)self.expireTime];
}

- (void)calculateExpireTime {
    NSInteger expireTime = kPINExpireTime;
    long timestamp = (long)[[NSDate date] timeIntervalSince1970];
    if(timestamp % kPINExpireTime != 0){
        expireTime -= timestamp % kPINExpireTime;
    }
    self.expireTime = expireTime;
}

- (NSString *)generatePINForUser:(User *)user {
    NSData *secretData =  [NSData dataWithBase32String:user.secret];
    TOTPGenerator *generator = [[TOTPGenerator alloc] initWithSecret:secretData algorithm:kOTPGeneratorSHA1Algorithm digits:kPINDigits period:kPINExpireTime];
    
    long timestamp = (long)[[NSDate date] timeIntervalSince1970];
    if(timestamp % kPINExpireTime != 0){
        timestamp -= timestamp % kPINExpireTime;
    }
    return [generator generateOTPForDate:[NSDate dateWithTimeIntervalSince1970:timestamp]];
}

@end
