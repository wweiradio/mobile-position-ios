//
//  PPrYvSettingViewController.m
//  AT PrYv
//
//  Created by Nicolas Manzini on 13.12.12.
//  Copyright (c) 2012 PrYv. All rights reserved.
//

#import <MessageUI/MessageUI.h>
#import "PPrYvSettingViewController.h"
#import "PPrYvWebLoginViewController.h"
#import "User+Extras.h"
#import "SSZipArchive.h"
#import "PPrYvCoreDataManager.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreLocation/CoreLocation.h>

@interface PPrYvSettingViewController () <MFMailComposeViewControllerDelegate>
@end

@implementation PPrYvSettingViewController

enum {
    SectionDistanceFilter = 0,
    SectionDesiredAccuracy,
    SectionTimeInterval,
    SectionLoginInfo,
    SectionFolderInfo,
#if DEBUG
    SectionSendLogs,
#endif
    NumSections
};

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
    return NumSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{    
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case SectionDistanceFilter:
            return NSLocalizedString(@"optionSection1Title", );

        case SectionDesiredAccuracy:
            return NSLocalizedString(@"optionSection11Title", );
            
        case SectionTimeInterval:
            return NSLocalizedString(@"optionSection2Title", );
            
        case SectionLoginInfo:
            return NSLocalizedString(@"optionSection3Title", );
            
        case SectionFolderInfo:
            return NSLocalizedString(@"optionSection5Title", );

#if DEBUG
        case SectionSendLogs:
            return @"Report problem";
#endif
            
        default:
            return @"";
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SectionDistanceFilter ||
        indexPath.section == SectionTimeInterval ||
        indexPath.section == SectionDesiredAccuracy) {
        return 60;
    }
    
    return 40;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                    reuseIdentifier:nil];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (indexPath.section == SectionDistanceFilter && indexPath.row == 0) {
        
        UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(20, 30, cell.contentView.frame.size.width-60, 30)];
        slider.maximumValue = powf(100.0f, 0.5f);
        slider.minimumValue = powf(10.0f, 0.5f);
        [slider addTarget:self
                   action:@selector(changeLocationManagerDistanceFilter:)
         forControlEvents:UIControlEventValueChanged];
        [slider setValue:powf([self.currentUser.locationDistanceInterval doubleValue], .5f)
                animated:NO];
        
        self.distanceFilterLabel = [[UILabel alloc] initWithFrame:CGRectMake(cell.contentView.frame.size.width-120, 0, 80, 30)];
        self.distanceFilterLabel.textColor = [UIColor colorWithWhite:.3 alpha:1];
        self.distanceFilterLabel.backgroundColor = [UIColor clearColor];
        self.distanceFilterLabel.textAlignment = UITextAlignmentRight;
        self.distanceFilterLabel.font = [UIFont boldSystemFontOfSize:18.0f];
        
        [cell.contentView addSubview:slider];
        [cell.contentView addSubview:self.distanceFilterLabel];

        [self updateDistanceFilterWithValue:[self.currentUser.locationDistanceInterval doubleValue]];
    }
    else if (indexPath.section == SectionDesiredAccuracy && indexPath.row == 0) {
        
        UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(20, 30,
                                                                      cell.contentView.frame.size.width-60, 30)];
        [slider addTarget:self
                   action:@selector(desiredAccuracyValueChanged:)
         forControlEvents:UIControlEventValueChanged];
        slider.maximumValue = 5.f;
        slider.minimumValue = 0.f;
        
        NSUInteger sliderValue = [self desiredAccuracyIndexFromLocationAccuracy:[self.currentUser.desiredAccuracy doubleValue]];
        [slider setValue:(float)sliderValue animated:NO];
        
        self.desiredAccuracyLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0,
                                                                              260, 30)];
        self.desiredAccuracyLabel.textColor = [UIColor colorWithWhite:.3 alpha:1];
        self.desiredAccuracyLabel.backgroundColor = [UIColor clearColor];
        self.desiredAccuracyLabel.textAlignment = UITextAlignmentRight;
        self.desiredAccuracyLabel.minimumFontSize = 8;
        self.desiredAccuracyLabel.adjustsFontSizeToFitWidth = YES;
        self.desiredAccuracyLabel.font = [UIFont boldSystemFontOfSize:15.0f];
        
        [cell.contentView addSubview:slider];
        [cell.contentView addSubview:self.desiredAccuracyLabel];
        
        // convert from user desiredAccuracy
        [self updateDesiredAccuracyWithSliderValue:sliderValue];
    }
    else if (indexPath.section == SectionTimeInterval && indexPath.row == 0) {
        
        UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(20, 30, cell.contentView.frame.size.width-60, 30)];
        [slider addTarget:self
                   action:@selector(changeLocationManagerTimeInterval:)
         forControlEvents:UIControlEventValueChanged];
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
    else if (indexPath.section == SectionLoginInfo && indexPath.row == 0) {
        
        cell.textLabel.text = self.currentUser.userId;
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.textLabel.textAlignment = UITextAlignmentCenter;
    }
    else if (indexPath.section == SectionFolderInfo) {
        
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.textLabel.text = self.currentUser.folderName;
    }
#if DEBUG
    else if (indexPath.section == SectionSendLogs) {
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.textLabel.text = @"Send Logs";
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
#endif
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

static NSArray *accuracyLabelValues = nil;
static NSArray *accuracyValues = nil;

- (NSUInteger)desiredAccuracyIndexFromLocationAccuracy:(CLLocationAccuracy)locationAccuracy
{
    __block NSUInteger resultIdx = 0;
    double acceptableDelta = 0.01f;
    [accuracyValues enumerateObjectsUsingBlock:^(id acceptableAccuracy, NSUInteger idx, BOOL *stop) {
        if (fabs(locationAccuracy - [acceptableAccuracy doubleValue]) < acceptableDelta) {
            resultIdx = idx;
            *stop = YES;
        }
    }];
    return resultIdx;
}

- (NSString *)desiredAccuracyTextForIndex:(NSUInteger) idx
{
    
    if (accuracyLabelValues == nil) {
        accuracyLabelValues = @[
                           @"kCLLocationAccuracyBestForNavigation",
                           @"kCLLocationAccuracyBest",
                           @"kCLLocationAccuracyNearestTenMeters",
                           @"kCLLocationAccuracyHundredMeters",
                           @"kCLLocationAccuracyKilometer",
                           @"kCLLocationAccuracyThreeKilometers"
                           ];
    }
    
    return accuracyLabelValues[idx];
}

- (NSNumber *)desiredAccuracyValueForIndex:(NSUInteger) idx
{
    if (accuracyValues == nil) {
        accuracyValues = @[
                           @(kCLLocationAccuracyBestForNavigation),
                           @(kCLLocationAccuracyBest),
                           @(kCLLocationAccuracyNearestTenMeters),
                           @(kCLLocationAccuracyHundredMeters),
                           @(kCLLocationAccuracyKilometer),
                           @(kCLLocationAccuracyThreeKilometers)
                           ];
    }
    return accuracyValues[idx];
}

- (void)updateDesiredAccuracyWithSliderValue:(int)sliderValue
{
    self.desiredAccuracyLabel.text = [self desiredAccuracyTextForIndex:sliderValue];
}

#pragma mark - Log sending 

- (NSString *)cachesDirectory
{
    return NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
}

- (NSString *)logsDirectory
{
    return [[self cachesDirectory] stringByAppendingPathComponent:@"Logs"];
}

- (NSData *)zipLogs
{
    NSString *logsDir = [self logsDirectory];
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:logsDir error:nil];
    NSPredicate *textFilePredicate = [NSPredicate predicateWithFormat:@"self ENDSWITH '.txt'"];
    files = [files filteredArrayUsingPredicate:textFilePredicate];
    
    NSString *logZipPath = [logsDir stringByAppendingPathComponent:@"logs.zip"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:logZipPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:logZipPath error:nil];
    }
    
    NSMutableArray *inputFiles = [NSMutableArray array];
    for (NSString *file in files) {
        [inputFiles addObject:[logsDir stringByAppendingPathComponent:file]];
    }
    
    [SSZipArchive createZipFileAtPath:logZipPath withFilesAtPaths:inputFiles];
    NSData *zipData = [NSData dataWithContentsOfFile:logZipPath];
    [[NSFileManager defaultManager] removeItemAtPath:logZipPath error:nil];
    return zipData;
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
#if DEBUG
    if (indexPath.section == SectionSendLogs) {
        if (![MFMailComposeViewController canSendMail]) {
            [[[UIAlertView alloc] initWithTitle:@"Can't send email"
                                        message:@"Please set up your mail account first"
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
            return;
        }
        
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            NSData *zipFileData = [self zipLogs];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                MFMailComposeViewController *mailVC = [[MFMailComposeViewController alloc] init];
                [mailVC setSubject:@"Pryv Logs"];
                [mailVC setToRecipients:@[ @"konstantin@dorodov.com" ]]; // FIXME add a constant
                [mailVC setMessageBody:@"Please specify the date and the time of the crash:\n\nPlease find the attached logs" isHTML:NO];
                [mailVC addAttachmentData:zipFileData
                                 mimeType:@"application/zip"
                                 fileName:@"pryv_logs.zip"];
                
                [mailVC setMailComposeDelegate:self];
                
                [self presentViewController:mailVC animated:YES completion:nil];
            });
        });
    }
#endif
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result) {
        case MFMailComposeResultSaved:
            NSLog(@"Saved as a draft");
            break;
            
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled");
            break;
            
        case MFMailComposeResultSent:
            NSLog(@"Mail sent");
            break;
            
        case MFMailComposeResultFailed:
            NSLog(@"Mail send failed");
            break;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
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

- (void)desiredAccuracyValueChanged:(UISlider *)slider
{
    // get int value from 0 to 5
    int idx = (int)ceilf(slider.value);
    
    // move slider to a discrete value
    [slider setValue:idx animated:NO];
    
    // save settings for later
    self.currentUser.desiredAccuracy = [self desiredAccuracyValueForIndex:idx];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kPrYvDesiredAccuracyDidChangeNotification
                                                        object:nil
                                                      userInfo:@{ kPrYvDesiredAccuracyDidChangeNotificationUserInfoKey : [self desiredAccuracyValueForIndex:idx] }];
    
    [self updateDesiredAccuracyWithSliderValue:idx];
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

// FIXME has to remove the data from the map and other global user state - reset or something

- (IBAction)logOutCurrentUser:(id)sender
{
    self.currentUser = nil;
    
    // destroy all cached user data
    [[PPrYvCoreDataManager sharedInstance] destroyAllData];
    
    if (IS_IPAD) {
        
        [self.iPadHoldingPopOver dismissPopoverAnimated:YES];
                
        int64_t delayInSeconds = 1;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^{
            
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
