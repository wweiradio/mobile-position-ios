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
#import "PPrYvServerManager.h"


@interface PPrYvMapViewController : UIViewController <MKMapViewDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate, PPrYvServerManagerDelegate>

@property (strong, nonatomic) CLLocationManager * locationManager;
@property (strong, nonatomic) NSManagedObjectContext * context;
@property (assign, nonatomic, getter = isRecording) BOOL recording;
@property (assign, nonatomic, getter = isLaunchedByImagePickerOrNoteTaker) BOOL launchedByImagePickerOrNoteTaker;
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
- (void)didAddNewLocation:(CLLocation *)newLocation;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil andContext:(NSManagedObjectContext *)currentContext andManager:(CLLocationManager *)manager;

@end
