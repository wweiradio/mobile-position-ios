//
//  PPrYvLoginViewController.h
//  AT PrYv
//
//  Created by Nicolas Manzini on 07.12.12.
//  Copyright (c) 2012 PrYv. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PPrYvLoginViewController : UIViewController <UITextFieldDelegate>

// user login
@property (weak, nonatomic) IBOutlet UITextField * userField;

// password or token for the prYv API
@property (weak, nonatomic) IBOutlet UITextField * userPassword;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;

@end
