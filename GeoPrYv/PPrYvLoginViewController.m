//
//  PPrYvLoginViewController.m
//  AT PrYv
//
//  Created by Nicolas Manzini on 07.12.12.
//  Copyright (c) 2012 PrYv. All rights reserved.
//

#import "PPrYvLoginViewController.h"
#import "PPrYvServerManager.h"
#import <CommonCrypto/CommonCrypto.h>

@interface PPrYvLoginViewController ()

- (void)registerUserWithPassword;

@end

@implementation PPrYvLoginViewController

#pragma mark - Object Life Cycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

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

- (void)registerUserWithPassword {
    
    // User your own way of storing user credentials
    [[NSUserDefaults standardUserDefaults] setObject:self.userField.text
                                              forKey:kUserDefaultsCurrentUser];
    [[NSUserDefaults standardUserDefaults] setObject:self.userPassword.text
                                              forKey:kUserDefaultsCurrentUserPassword];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // contact server to create main folder for futur uploads
    [PPrYvServerManager checkOrCreateServerMainFolder:@"PrYvMainFolder" delegate:nil];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
