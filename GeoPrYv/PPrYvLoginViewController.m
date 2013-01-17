//
//  PPrYvLoginViewController.m
//  AT PrYv
//
//  Created by Nicolas Manzini on 07.12.12.
//  Copyright (c) 2012 PrYv. All rights reserved.
//

#import "PPrYvLoginViewController.h"
#import "User+Extras.h"
#import "PPrYvCoreDataManager.h"
#import "PPrYvApiClient.h"
#import "Folder.h"

@interface PPrYvLoginViewController ()

@property (assign, nonatomic) NSUInteger iteration;
- (void)registerUserWithPassword;

@end

@implementation PPrYvLoginViewController

#pragma mark - Object Life Cycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        _iteration = 0;
    }
    return self;
}

#pragma mark - View Controller Life-cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.userField becomeFirstResponder];
}

- (void)viewWillAppear:(BOOL)animated
{
    /**
     WARNING

     credentials data are hardcoded in Constants.h just for example and convenience
     
    */
    
    self.userField.text = kPrYvUser;
    self.userPassword.text = kPrYvAuthToken;
}

- (void)viewDidUnload
{
    [self setUserField:nil];
    [self setUserPassword:nil];
    
    [super viewDidUnload];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - TextField Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (self.userField == textField) {
        
        [self.userPassword becomeFirstResponder];
    }
    else if (self.userPassword == textField) {
        
        [self registerUserWithPassword];
    }
    return YES;
}

#pragma mark - Register New User

- (void)registerUserWithPassword
{
    User * newUser = [User createUserWithId:self.userField.text
                                      token:self.userPassword.text
                                  inContext:[[PPrYvCoreDataManager sharedInstance] managedObjectContext]];

    [[NSNotificationCenter defaultCenter] postNotificationName:kPrYvLocationDistanceIntervalDidChangeNotification
                                                        object:nil
                                                      userInfo:@{kPrYvLocationDistanceIntervalDidChangeNotificationUserInfoKey : newUser.locationDistanceInterval}];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kPrYvLocationTimeIntervalDidChangeNotification
                                                        object:nil
                                                      userInfo:@{kPrYvLocationTimeIntervalDidChangeNotificationUserInfoKey : newUser.locationTimeInterval}];
        
    // start or restart the api Client with the new user upon successful start it would try to synchronize
    PPrYvApiClient *apiClient = [PPrYvApiClient sharedClient];
    [apiClient startClientWithUserId:newUser.userId
                          oAuthToken:newUser.userToken
                           channelId:kPrYvApplicationChannel successHandler:^(NSTimeInterval serverTime)
    {
        [self findExistingOrCreateNewFolderForUser];
    }
                        errorHandler:^(NSError *error)
    {
         [[[UIAlertView alloc] initWithTitle:nil
                                    message:NSLocalizedString(@"alertCantSynchronize", )
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"cancelButton", )
                          otherButtonTitles:nil] show];
    }];

}

#pragma mark - test and prepare user's folder structure

- (void)findExistingOrCreateNewFolderForUser
{
    User * newUser = [User currentUserInContext:[[PPrYvCoreDataManager sharedInstance] managedObjectContext]];

    // get list of all folders from API and if there is one with the same folderId use it
    NSLog(@"called find create user");
    
    [[PPrYvApiClient sharedClient] getFoldersWithSuccessHandler:^(NSArray *folderList){
        BOOL foundFolder = NO;
        for (Folder *folder in folderList) {
            if ([folder.folderId isEqualToString:newUser.folderId]) {
                NSLog(@"Found user's folder: %@", folder.name);
                newUser.folderName = folder.name;
                [[[PPrYvCoreDataManager sharedInstance] managedObjectContext] save:nil];
                foundFolder = YES;
                break;
            }
        }
        
        if (!foundFolder) {
           NSLog(@"folder was not found, creating one: %@", newUser.folderName);
          [self createFolder];
        } else {
            
          [self dismissViewControllerAnimated:YES completion:nil];
        }
    } errorHandler:^(NSError *error) {
        
        NSLog(@"couldn't receive folders %@", error);
        /*
        [[[UIAlertView alloc] initWithTitle:nil
                                    message:NSLocalizedString(@"alertCantGetFolderList", )
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"cancelButton", )
                          otherButtonTitles:nil] show];
         */
         
    }];
}

- (void)createFolder
{
    
    if (self.iteration > 10) {
        
        NSLog(@"error cannot create folder despite new name");
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    //  create a folder for the current user
    User * newUser = [User currentUserInContext:[[PPrYvCoreDataManager sharedInstance] managedObjectContext]];
    
    if (self.iteration > 0) {
        newUser.folderName = [newUser.folderName stringByAppendingString:[NSString stringWithFormat:@"%u",self.iteration]];
    }
    self.iteration ++;
    
    [[PPrYvApiClient sharedClient] createFolderId:newUser.folderId
                                         withName:newUser.folderName
                                   successHandler:^(NSString *folderId, NSString *folderName) {

        // the folder for the current iPhone openUDID did not already exist. we created it.
        User *currentUser = [User currentUserInContext:[[PPrYvCoreDataManager sharedInstance] managedObjectContext]];
        currentUser.folderName = folderName;

        [[[PPrYvCoreDataManager sharedInstance] managedObjectContext] save:nil];

        [self dismissViewControllerAnimated:YES completion:nil];
                                       
    } errorHandler:^(NSError *error) {
        
        NSLog(@"couldn't create the folder based on openUDID error %@", error);
        
        [self createFolder];
    }];
}

@end