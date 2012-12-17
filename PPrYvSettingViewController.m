//
//  PPrYvSettingViewController.m
//  AT PrYv
//
//  Created by Nicolas Manzini on 13.12.12.
//  Copyright (c) 2012 PrYv. All rights reserved.
//

#import "PPrYvSettingViewController.h"
#import "PPrYvLoginViewController.h"
#import "PPrYvAppDelegate.h"

@interface PPrYvSettingViewController ()

@end

@implementation PPrYvSettingViewController

@synthesize distanceFilterLabel, timeFilterLabel;

#pragma mark - Object Life Cycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

#pragma mark - View Life Cycle

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.navItems.title = NSLocalizedString(@"settingsTitle", );
    self.bReturn.title = NSLocalizedString(@"bSettingsReturn", );
    self.bLogOut.title = NSLocalizedString(@"bSettingsLogOut", );
}

- (void)viewDidUnload {
    
    [self setNavItems:nil];
    [self setBLogOut:nil];
    [self setBReturn:nil];
    
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    
    return UIInterfaceOrientationPortrait;
}

- (NSUInteger)supportedInterfaceOrientations {
    
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    // Return the number of sections.
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    // Return the number of rows in the section.
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    if (section == 0) {
        
        return NSLocalizedString(@"optionSection1Title", );
    }
    else if (section == 1) {
        
        return NSLocalizedString(@"optionSection2Title", );
    }
    else if (section == 2) {
        
        return NSLocalizedString(@"optionSection3Title", );
    }
    else if (section == 3) {
        
        return NSLocalizedString(@"optionSection4Title", );
    }
    return @"";
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0 || indexPath.section == 1) {
        
        return 60;
    }
    
    return 40;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
        
    UITableViewCell * cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (indexPath.section == 0 && indexPath.row == 0) {
        
        UISlider * slider = [[UISlider alloc] initWithFrame:CGRectMake(20, 30, cell.contentView.frame.size.width-60, 30)];
        slider.maximumValue = powf(100.0f, 0.5f);
        slider.minimumValue = powf(10.0f, 0.5f);
        [slider addTarget:self action:@selector(changeLocationManagerDistanceFilter:) forControlEvents:UIControlEventValueChanged];
        [slider setValue:powf([[[NSUserDefaults standardUserDefaults] objectForKey:kLocationDistanceInterval] doubleValue], .5f) animated:NO];
        
        distanceFilterLabel = [[UILabel alloc] initWithFrame:CGRectMake(cell.contentView.frame.size.width-120, 0, 80, 30)];
        distanceFilterLabel.textColor = [UIColor colorWithWhite:.3 alpha:1];
        distanceFilterLabel.backgroundColor = [UIColor clearColor];
        distanceFilterLabel.textAlignment = UITextAlignmentRight;
        distanceFilterLabel.font = [UIFont boldSystemFontOfSize:18.0f];
        
        [cell.contentView addSubview:slider];
        [cell.contentView addSubview:distanceFilterLabel];
        
        if ([[[NSLocale currentLocale] objectForKey:NSLocaleUsesMetricSystem] boolValue]) {
            
            distanceFilterLabel.text = [NSString stringWithFormat:@"%.0f m", [[[NSUserDefaults standardUserDefaults] objectForKey:kLocationDistanceInterval] doubleValue]];
        }
        else {
            distanceFilterLabel.text = [NSString stringWithFormat:@"%.0f ft", [[[NSUserDefaults standardUserDefaults] objectForKey:kLocationDistanceInterval] doubleValue]*3.2808399f];
        }
    }
    else if (indexPath.section == 1 && indexPath.row == 0) {
        
        UISlider * slider = [[UISlider alloc] initWithFrame:CGRectMake(20, 30, cell.contentView.frame.size.width-60, 30)];
        [slider addTarget:self action:@selector(changeLocationManagerTimeInterval:) forControlEvents:UIControlEventValueChanged];
        slider.maximumValue = powf(300.0f, 0.5f);
        slider.minimumValue = powf(10.0f, 0.5f);
        [slider setValue:powf([[[NSUserDefaults standardUserDefaults] objectForKey:kLocationTimeInterval] doubleValue], .5f) animated:NO];
        
        timeFilterLabel = [[UILabel alloc] initWithFrame:CGRectMake(cell.contentView.frame.size.width-120, 0, 80, 30)];
        timeFilterLabel.textColor = [UIColor colorWithWhite:.3 alpha:1];
        timeFilterLabel.backgroundColor = [UIColor clearColor];
        timeFilterLabel.textAlignment = UITextAlignmentRight;
        timeFilterLabel.font = [UIFont boldSystemFontOfSize:18.0f];
        
        [cell.contentView addSubview:slider];
        [cell.contentView addSubview:timeFilterLabel];
        
        if ([[[NSUserDefaults standardUserDefaults] objectForKey:kLocationTimeInterval] doubleValue] < 60) {
            
            timeFilterLabel.text = [NSString stringWithFormat:@"%.0f sec", [[[NSUserDefaults standardUserDefaults] objectForKey:kLocationTimeInterval] doubleValue]];
        }
        else {
            
            timeFilterLabel.text = [NSString stringWithFormat:@"%.0f min", [[[NSUserDefaults standardUserDefaults] objectForKey:kLocationTimeInterval] doubleValue]/60];
        }
    }
    else if (indexPath.section == 2 && indexPath.row == 0) {
        
        cell.textLabel.text = [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsCurrentUser];
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.textLabel.textAlignment = UITextAlignmentCenter;
    }
    else if (indexPath.section == 3 && indexPath.row == 0) {
        
        cell.textLabel.text =[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsCurrentUserFolder];
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
    }
    
    return cell;
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
      
}

#pragma mark - Settings Methods

- (void)changeLocationManagerDistanceFilter:(UISlider *)distanceIntervalSlider {
    
    PPrYvAppDelegate * responder = (PPrYvAppDelegate *)[UIApplication sharedApplication].delegate;
    
    CLLocationAccuracy distanceFilter = round(pow(distanceIntervalSlider.value, 2.0));
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithDouble:distanceFilter] forKey:kLocationDistanceInterval];
    responder.locationManager.distanceFilter = distanceFilter;

    
    if ([[[NSLocale currentLocale] objectForKey:NSLocaleUsesMetricSystem] boolValue]) {
        
        distanceFilterLabel.text = [NSString stringWithFormat:@"%.0f m", distanceFilter];
    }
    else {
        
        distanceFilterLabel.text = [NSString stringWithFormat:@"%.0f ft", distanceFilter*3.2808399f];
    }
}

- (void)changeLocationManagerTimeInterval:(UISlider *)timeIntervalSlider {
    
    PPrYvAppDelegate * responder = (PPrYvAppDelegate *)[UIApplication sharedApplication].delegate;
    
    NSTimeInterval timeInterval = round(pow(timeIntervalSlider.value, 2.0));
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithDouble:timeInterval] forKey:kLocationTimeInterval];
    [responder.foregroundTimer invalidate];
    responder.foregroundTimer = [NSTimer scheduledTimerWithTimeInterval:timeInterval target:responder selector:@selector(allowUpdateNow) userInfo:nil repeats:YES];
    
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:kLocationTimeInterval] doubleValue] < 60) {
        
        timeFilterLabel.text = [NSString stringWithFormat:@"%.0f sec", [[[NSUserDefaults standardUserDefaults] objectForKey:kLocationTimeInterval] doubleValue]];
    }
    else {
        
        timeFilterLabel.text = [NSString stringWithFormat:@"%.0f min", [[[NSUserDefaults standardUserDefaults] objectForKey:kLocationTimeInterval] doubleValue]/60];
    }
}

#pragma mark - Navigation Bar Button

- (IBAction)dismissOptions:(id)sender {
    
    if ([[[UIDevice currentDevice] model] rangeOfString:@"iPad"].location != NSNotFound) {
        
        [self.iPadHoldingPopOver dismissPopoverAnimated:YES];
    }
    else {
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
}

- (IBAction)logOutCurrentUser:(id)sender {
    
    [[NSUserDefaults standardUserDefaults] setObject:nil
                                              forKey:kUserDefaultsCurrentUser];
    [[NSUserDefaults standardUserDefaults] setObject:nil
                                              forKey:kUserDefaultsCurrentUserPassword];
    [[NSUserDefaults standardUserDefaults] setObject:nil
                                              forKey:kUserDefaultsCurrentUserFolder];
    [[NSUserDefaults standardUserDefaults] setObject:nil
                                              forKey:kUserDefaultsCurrentUserFolderId];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    
    if ([[[UIDevice currentDevice] model] rangeOfString:@"iPad"].location != NSNotFound) {
        
        [self.iPadHoldingPopOver dismissPopoverAnimated:YES];
                
        int64_t delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            
            PPrYvLoginViewController * login = [[PPrYvLoginViewController alloc] initWithNibName:@"PPrYvLoginViewControlleriPad" bundle:nil];
            
            [self.iPadHoldingPopOverViewController presentViewController:login animated:YES completion:nil];
        });
    }
    else {
        
        UIViewController * controller = self.presentingViewController;

        [controller dismissViewControllerAnimated:YES completion:^{
            
            PPrYvLoginViewController * login = [[PPrYvLoginViewController alloc] initWithNibName:@"PPrYvLoginViewControlleriPhone" bundle:nil];
            
            [controller presentViewController:login animated:YES completion:nil];
        }];
    }    
}

@end
