//
//  PPrYvLoginViewController.m
//  AT PrYv
//
//  Created by Nicolas Manzini on 07.12.12.
//  Copyright (c) 2012 PrYv. All rights reserved.
//

#import "PPrYvLoginViewController.h"
#import "User.h"
#import "PPrYvAppDelegate.h"

@interface PPrYvLoginViewController ()

- (void)registerUserWithPassword;

@end

@implementation PPrYvLoginViewController

#pragma mark - Object Life Cycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil inContext:(NSManagedObjectContext *)context {
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.context = context;
    }
    return self;
}

#pragma mark - View Controller Life-cycle

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self.userField becomeFirstResponder];    
}

- (void)viewDidUnload {
    
    [self setUserField:nil];
    [self setUserPassword:nil];
    
    [super viewDidUnload];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    
    return UIInterfaceOrientationPortrait;
}

- (NSUInteger)supportedInterfaceOrientations {
    
    return UIInterfaceOrientationMaskPortrait;
}

- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - TextField Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    if (self.userField == textField) {
        
        [self.userPassword becomeFirstResponder];
    }
    else if (self.userPassword == textField) {
        
        [self registerUserWithPassword];
    }
    return YES;
}

#pragma mark - Register New User

// hardcoded data for example purpose only
#define kPrYvAuthToken @"VVEQmJD5T5"
#define kPrYvUser @"jonmaim"
#define applicationPrYvChannel @"VeA4Yv9RiM"

- (void)registerUserWithPassword {
    
    /** 
     data is hardcoded here for example purpose. You should set the user input as the data
     the method newUserWithId:token:inContext: set some default values for folderId and location preferences
     */
    
    User * newUser = [User newUserWithId:kPrYvUser token:kPrYvAuthToken inContext:self.context];
    
    // reset the mainLocationManager distance preferences
    [[(PPrYvAppDelegate *)[UIApplication sharedApplication].delegate mainLocationManager] setDistanceFilter:30];
    
    // reset the foreground timer with default preferences
    [(PPrYvAppDelegate *)[UIApplication sharedApplication].delegate setForegroundTimer:[NSTimer scheduledTimerWithTimeInterval:30 target:(PPrYvAppDelegate *)[UIApplication sharedApplication].delegate selector:@selector(allowUpdateNow) userInfo:nil repeats:YES]];
    
    [self.context save:nil];

    // start or restart the shared Manager with the new user when you start the manager it will try to synchronize
    // you can use the synchronization delegate to know when the PPrYvDefaultManager is ready to be used
    [[PPrYvDefaultManager sharedManager] startManagerWithUserId:newUser.userId oAuthToken:newUser.userToken channelId:applicationPrYvChannel delegate:self];
}

#pragma mark - PPrYv defautManager delegate

- (void)PPrYvDefaultManagerDidSynchronize {
    
    // upon synchronization we can create a folder for the current user
    User * newUser = [User currentUserInContext:self.context];
    
    [[PPrYvDefaultManager sharedManager] createFolderWithName:newUser.folderName folderId:newUser.folderId delegate:self];
}

- (void)PPrYvDefaultManagerDidCreateFolder:(NSString *)folderName withId:(NSString *)folderId {
    
    // the folder for the current iPhone openUDID did not already exist. we created it.
    User * currentUser = [User currentUserInContext:self.context];
    currentUser.folderName = folderName;
    currentUser.folderId = folderId;
    
    [self.context save:nil];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)PPrYvDefaultManagerDidRenameFolder:(NSString *)renamedFolderId withNewName:(NSString *)folderNewName {
    
    // if the folder did already exist
    User * currentUser = [User currentUserInContext:self.context];
    currentUser.folderName = folderNewName;
    currentUser.folderId = renamedFolderId;
    
    [self.context save:nil];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)PPrYvDefaultManagerDidFail:(PPrYvFailedAction)failedAction withError:(NSError *)error {
    
    if (failedAction == PPrYvFailedCreateFolder || failedAction == PPrYvFailedRenameFolder) {
        
        NSLog(@"couldn't create or rename the folder with Id based on openUDID error %@", error);
        
        // show alert message
        [[[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"alertCantCreateUser", ) delegate:nil cancelButtonTitle:NSLocalizedString(@"cancelButton", ) otherButtonTitles:nil] show];

    }
    else if (failedAction == PPrYvFailedSynchronize) {
        
        NSLog(@"could not synchronize with error %@",error);
        
        // show alert message
        [[[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"alertCantCreateUser", ) delegate:nil cancelButtonTitle:NSLocalizedString(@"cancelButton", ) otherButtonTitles:nil] show];
    }
}

@end
