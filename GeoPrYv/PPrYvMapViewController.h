//
//  PPrYvMapViewController.h
//  AT PrYv
//
//  Created by Nicolas Manzini on 06.12.12.
//  Copyright (c) 2012 PrYv. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "PPrYvDefaultManager.h"


@interface PPrYvMapViewController : UIViewController <MKMapViewDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate, PPrYvDefaultManagerDelegate>

// our mainLocationManager intialized in the AppDelegate that is passed to this class via the custom initalizer method for this class. see bottom
@property (strong, nonatomic) CLLocationManager * mainLocationManager;

// our unique context passed by The AppDelegate on initialization
@property (strong, nonatomic) NSManagedObjectContext * context;

// a flag to help us know if we are recording locations with the mainLocationManager
@property (assign, nonatomic, getter = isRecording) BOOL recording;

// our user interface outlets
@property (weak, nonatomic) IBOutlet UILabel * statusBarRecorder;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIButton *bRecorder;
@property (weak, nonatomic) IBOutlet UIButton *bTakePicture;
@property (weak, nonatomic) IBOutlet UIButton *bTakeNote;
@property (weak, nonatomic) IBOutlet UITextView *noteComposer;
@property (weak, nonatomic) IBOutlet UINavigationBar *navBarNote;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *bSendNote;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *bCancelNote;
@property (weak, nonatomic) IBOutlet UIButton *bSettings;
@property (weak, nonatomic) IBOutlet UIDatePicker *datePickerFrom;
@property (weak, nonatomic) IBOutlet UIButton *bAskTimePeriod;
@property (weak, nonatomic) IBOutlet UIButton *bAskLast24h;
@property (weak, nonatomic) IBOutlet UIDatePicker *datePickerTo;
@property (weak, nonatomic) IBOutlet UIButton *bNextDate;
@property (weak, nonatomic) IBOutlet UIButton *bFromDate;
@property (weak, nonatomic) IBOutlet UIButton *bConfirmTimePeriod;
@property (weak, nonatomic) IBOutlet UIButton *bCancelDatePickers;
@property (strong, nonatomic) UIPopoverController * iPadPopover;

// our user interface linked methods
- (IBAction)canceNote:(id)sender;
- (IBAction)askServerForTimePeriodData;
- (IBAction)pushSettingsViewController;
- (IBAction)takeNote:(UIButton *)sender;
- (IBAction)takePicture:(UIButton *)sender;
- (IBAction)askForLast24h:(UIButton *)sender;
- (IBAction)showDatePickerTo:(UIButton *)sender;
- (IBAction)askForTimePeriod:(UIButton *)sender;
- (IBAction)cancelDatePickers:(UIButton *)sender;
- (IBAction)showDatePickerFrom:(UIButton *)sender;
- (IBAction)sendNoteWithCurrentLocation:(id)sender;
- (IBAction)startStopLocationRecording:(UIButton *)sender;

/** 
 This methood will add a new point on the map
 */
- (void)addNewLocation:(CLLocation *)newLocation;

// our custom initializer. We pass the mainLocationManager and the unique application managedObjectContext
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil inContext:(NSManagedObjectContext *)currentContext mainLocationManager:(CLLocationManager *)manager;

@end
