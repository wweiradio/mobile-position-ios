//
//  PPrYvLoginViewController.h
//  AT PrYv
//
//  Created by Nicolas Manzini on 07.12.12.
//  Copyright (c) 2012 PrYv. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PPrYvLoginViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField * userField;
@property (weak, nonatomic) IBOutlet UITextField * userPassword;

@end
