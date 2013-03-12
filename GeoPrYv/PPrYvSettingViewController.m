//
//  PPrYvSettingViewController.m
//  AT PrYv
//
//  Created by Nicolas Manzini on 13.12.12.
//  Copyright (c) 2012 PrYv. All rights reserved.
//

#import "PPrYvSettingViewController.h"
#import "PPrYvWebLoginViewController.h"
#import "User+Extras.h"
#import "PPrYvCoreDataManager.h"

@interface PPrYvSettingViewController ()
- (void)updateDistanceFilterWithValue:(double)distanceFilterValue;
- (void)updateTimeFilterWithValue:(double)timeFilterValue;
- (void)changeLocationManagerTimeInterval:(UISlider *)timeIntervalSlider;
- (void)changeLocationManagerDistanceFilter:(UISlider *)distanceIntervalSlider;
@end

@implementation PPrYvSettingViewController

@synthesize distanceFilterLabel = _distanceFilterLabel;
@synthesize timeFilterLabel = _timeFilterLabel;
@synthesize currentUser = _currentUser;

#pragma mark - Object Life Cycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {

        _currentUser = [User currentUserInContext:[[PPrYvCoreDataManager sharedInstance] managedObjectContext]];
    }
    return self;
}

#pragma mark - View Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navItems.title = NSLocalizedString(@"settingsTitle", );
    self.bReturn.title = NSLocalizedString(@"bSettingsReturn", );
    self.bLogOut.title = NSLocalizedString(@"bSettingsLogOut", );
}

- (void)viewDidUnload
{
    [self setNavItems:nil];
    [self setBLogOut:nil];
    [self setBReturn:nil];
    
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{    
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        
        return NSLocalizedString(@"optionSection1Title", );
    }
    else if (section == 1) {
        
        return NSLocalizedString(@"optionSection2Title", );
    }
    else if (section == 2) {
        
        return NSLocalizedString(@"optionSection3Title", );
    }
    /*
    else if (section == 3) {
        
        return NSLocalizedString(@"optionSection4Title", );
    }
     */
    else if (section == 3) {
        return NSLocalizedString(@"optionSection5Title", );
    }
    else
        return @"";
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 || indexPath.section == 1) {
        
        return 60;
    }
    
    return 40;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (indexPath.section == 0 && indexPath.row == 0) {
        
        UISlider * slider = [[UISlider alloc] initWithFrame:CGRectMake(20, 30, cell.contentView.frame.size.width-60, 30)];
        slider.maximumValue = powf(100.0f, 0.5f);
        slider.minimumValue = powf(10.0f, 0.5f);
        [slider addTarget:self action:@selector(changeLocationManagerDistanceFilter:) forControlEvents:UIControlEventValueChanged];
        [slider setValue:powf([self.currentUser.locationDistanceInterval doubleValue], .5f) animated:NO];
        
        self.distanceFilterLabel = [[UILabel alloc] initWithFrame:CGRectMake(cell.contentView.frame.size.width-120, 0, 80, 30)];
        self.distanceFilterLabel.textColor = [UIColor colorWithWhite:.3 alpha:1];
        self.distanceFilterLabel.backgroundColor = [UIColor clearColor];
        self.distanceFilterLabel.textAlignment = UITextAlignmentRight;
        self.distanceFilterLabel.font = [UIFont boldSystemFontOfSize:18.0f];
        
        [cell.contentView addSubview:slider];
        [cell.contentView addSubview:self.distanceFilterLabel];

        [self updateDistanceFilterWithValue:[self.currentUser.locationDistanceInterval doubleValue]];
    }
    else if (indexPath.section == 1 && indexPath.row == 0) {
        
        UISlider * slider = [[UISlider alloc] initWithFrame:CGRectMake(20, 30, cell.contentView.frame.size.width-60, 30)];
        [slider addTarget:self action:@selector(changeLocationManagerTimeInterval:) forControlEvents:UIControlEventValueChanged];
        slider.maximumValue = powf(300.0f, 0.5f);
        slider.minimumValue = powf(10.0f, 0.5f);
        [slider setValue:powf([self.currentUser.locationTimeInterval doubleValue], .5f) animated:NO];
        
        self.timeFilterLabel = [[UILabel alloc] initWithFrame:CGRectMake(cell.contentView.frame.size.width-120, 0, 80, 30)];
        self.timeFilterLabel.textColor = [UIColor colorWithWhite:.3 alpha:1];
        self.timeFilterLabel.backgroundColor = [UIColor clearColor];
        self.timeFilterLabel.textAlignment = UITextAlignmentRight;
        self.timeFilterLabel.font = [UIFont boldSystemFontOfSize:18.0f];
        
        [cell.contentView addSubview:slider];
        [cell.contentView addSubview:self.timeFilterLabel];

        [self updateTimeFilterWithValue:[self.currentUser.locationTimeInterval doubleValue]];
    }
    else if (indexPath.section == 2 && indexPath.row == 0) {
        
        cell.textLabel.text = self.currentUser.userId;
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.textLabel.textAlignment = UITextAlignmentCenter;
    }
    /*
    else if (indexPath.section == 3) {
        
        cell.textLabel.text = self.currentUser.folderId;
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
    }
     */
    else if (indexPath.section == 3) {
        
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.textLabel.text = self.currentUser.folderName;
    }
    return cell;
}

#pragma mark - private

- (void)updateDistanceFilterWithValue:(double)distanceFilterValue
{
    if ([[[NSLocale currentLocale] objectForKey:NSLocaleUsesMetricSystem] boolValue]) {
        self.distanceFilterLabel.text = [NSString stringWithFormat:@"%.0f m", distanceFilterValue];
    }
    else {
        self.distanceFilterLabel.text = [NSString stringWithFormat:@"%.0f ft", distanceFilterValue * 3.2808399f];
    }
}

- (void)updateTimeFilterWithValue:(double)timeFilterValue
{
    if (timeFilterValue < 60) {
        self.timeFilterLabel.text = [NSString stringWithFormat:@"%.0f sec", timeFilterValue];
    }
    else {
        self.timeFilterLabel.text = [NSString stringWithFormat:@"%.0f min", timeFilterValue / 60];
    }
}


#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
      // do nothing here
}

#pragma mark - Settings Methods

- (void)changeLocationManagerDistanceFilter:(UISlider *)distanceIntervalSlider
{
    CLLocationAccuracy distanceFilter = round(pow(distanceIntervalSlider.value, 2.0));
    NSNumber *distanceInterval = [NSNumber numberWithDouble:distanceFilter];
    self.currentUser.locationDistanceInterval = distanceInterval;

    [[NSNotificationCenter defaultCenter] postNotificationName:kPrYvLocationDistanceIntervalDidChangeNotification
                                                        object:nil
                                                      userInfo:@{kPrYvLocationDistanceIntervalDidChangeNotificationUserInfoKey : distanceInterval}];

    [self updateDistanceFilterWithValue:distanceFilter];
}

- (void)changeLocationManagerTimeInterval:(UISlider *)timeIntervalSlider
{
    NSTimeInterval timeInterval = round(pow(timeIntervalSlider.value, 2.0));
    self.currentUser.locationTimeInterval = [NSNumber numberWithDouble:timeInterval];

    [[NSNotificationCenter defaultCenter] postNotificationName:kPrYvLocationTimeIntervalDidChangeNotification
                                                        object:nil
                                                      userInfo:@{kPrYvLocationTimeIntervalDidChangeNotificationUserInfoKey : [NSNumber numberWithDouble:timeInterval]}];

    [self updateTimeFilterWithValue:[self.currentUser.locationTimeInterval doubleValue]];
}

#pragma mark - Navigation Bar Button Actions

- (IBAction)dismissOptions:(id)sender
{
    [[[PPrYvCoreDataManager sharedInstance] managedObjectContext] save:nil];
    
    if (IS_IPAD) {
        
        [self.iPadHoldingPopOver dismissPopoverAnimated:YES];
    }
    else {
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

// FIXME logout does actually nothing: it is not enough to open the loginViewController:
// has to remove the data from the map and affect somehow the global user state - reset or something

- (IBAction)logOutCurrentUser:(id)sender
{
    if (IS_IPAD) {
        
        [self.iPadHoldingPopOver dismissPopoverAnimated:YES];
                
        int64_t delayInSeconds = 1;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            
            PPrYvWebLoginViewController * login = [[PPrYvWebLoginViewController alloc] initWithNibName:@"PPrYvWebLoginViewController" bundle:nil];
            
            [self.iPadHoldingPopOverViewController presentViewController:login animated:YES completion:nil];
        });
    }
    else {
        
        UIViewController * controller = self.presentingViewController;

        [controller dismissViewControllerAnimated:YES completion:^{
            
            PPrYvWebLoginViewController * login = [[PPrYvWebLoginViewController alloc] initWithNibName:@"PPrYvWebLoginViewController" bundle:nil];

            [controller presentViewController:login animated:YES completion:nil];
        }];
    }    
}

@end
