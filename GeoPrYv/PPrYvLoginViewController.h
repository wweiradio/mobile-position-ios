//
//  PPrYvLoginViewController.h
//  AT PrYv
//
//  Created by Nicolas Manzini on 07.12.12.
//  Copyright (c) 2012 PrYv. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PPrYvDefaultManager.h"


@interface PPrYvLoginViewController : UIViewController <UITextFieldDelegate, PPrYvDefaultManagerDelegate>

// user login
@property (weak, nonatomic) IBOutlet UITextField * userField;

// password or token for the prYv API
@property (weak, nonatomic) IBOutlet UITextField * userPassword;

// application unique context started in the app delegate
@property (strong, nonatomic) NSManagedObjectContext * context;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil inContext:(NSManagedObjectContext *)context;

@end
