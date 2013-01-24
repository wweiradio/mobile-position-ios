//
//  PPrYvMapViewController.m
//  AT PrYv
//
//  Created by Nicolas Manzini on 06.12.12.
//  Copyright (c) 2012 PrYv. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import "PPrYvMapViewController.h"
#import "PPrYvSettingViewController.h"
#import "PositionEvent+Extras.h"
#import "User+Extras.h"
#import "PPrYvCoreDataManager.h"
#import "PPrYvLocationManager.h"
#import "PPrYvPositionEventSender.h"
#import "PPrYvApiClient.h"

@interface PPrYvMapViewController ()
@end

@implementation PPrYvMapViewController

@synthesize recording = _recording;

#pragma mark - Object Life Cycle

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        _recording = NO;
    }
    return self;
}

#pragma mark - View LifeCycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // rename all the buttons according to the current local en,fr,de...
    [self.bNextDate setTitle:NSLocalizedString(@"bToDate", ) forState:UIControlStateNormal];
    [self.bAskLast24h setTitle:NSLocalizedString(@"bAsk24h", ) forState:UIControlStateNormal];
    [self.bFromDate setTitle:NSLocalizedString(@"bFromDate", ) forState:UIControlStateNormal];
    [self.bTakeNote setTitle:NSLocalizedString(@"bTakeNote", ) forState:UIControlStateNormal];
    [self.bRecorder setTitle:NSLocalizedString(@"bRecordStart", ) forState:UIControlStateNormal];
    [self.bTakePicture setTitle:NSLocalizedString(@"bTakePicture", ) forState:UIControlStateNormal];
    [self.bAskTimePeriod setTitle:NSLocalizedString(@"bAskTimePeriod", ) forState:UIControlStateNormal];
    [self.bConfirmTimePeriod setTitle:NSLocalizedString(@"bConfirmTimePeriod", ) forState:UIControlStateNormal];
    [self.bCancelDatePickers setTitle:NSLocalizedString(@"bCancelDatePickers", ) forState:UIControlStateNormal];
    
    self.bSendNote.title = NSLocalizedString(@"bNavBarSendNote", );
    self.bCancelNote.title = NSLocalizedString(@"bNavBarCancelNote", );
    self.statusBarRecorder.text = NSLocalizedString(@"statusBarRecording", );
    
    // Set default datepickers period from a week ago to now
    self.datePickerTo.date = [NSDate date];
    self.datePickerFrom.date = [NSDate dateWithTimeIntervalSinceNow:-60*60*24*7];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kPrYvLocationManagerDidAcceptNewLocation object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        
        CLLocation * newLocation = [note.userInfo objectForKey:kPrYvLocationManagerDidAcceptNewLocation];
        
        // add a new point on the map
        MKPointAnnotation * aPosition = [[MKPointAnnotation alloc] init];
        aPosition.title = NSLocalizedString(@"You were here", );
        aPosition.coordinate = newLocation.coordinate;
        
        [self.mapView addAnnotation:aPosition];
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    /*
    // if we are not tracking our position at the moment the view appeared
    if (!self.isRecording) {
        
        // Show rapidly the user location and leave until the user start tracking himself or until the view appears again.
        self.mapView.showsUserLocation = YES;
        [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
        
        // after 3 seconds we stop tracking the user's location within the map to save the phone battery
        int64_t delayInSeconds = 3;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            
            self.mapView.showsUserLocation = NO;
            [self.mapView setUserTrackingMode:MKUserTrackingModeNone animated:YES];
        });
    }
     */
    self.mapView.showsUserLocation = YES;
    [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];

}

- (void)viewDidUnload
{
    [self setMapView:nil];
    [self setBRecorder:nil];
    [self setBTakePicture:nil];
    [self setBTakeNote:nil];
    [self setNoteComposer:nil];
    [self setBCancelNote:nil];
    [self setBSendNote:nil];
    [self setNavBarNote:nil];
    [self setMapView:nil];
    [self setDatePickerFrom:nil];
    [self setBAskTimePeriod:nil];
    [self setBAskLast24h:nil];
    [self setDatePickerTo:nil];
    [self setBNextDate:nil];
    [self setBFromDate:nil];
    [self setBConfirmTimePeriod:nil];
    [self setBSettings:nil];
    [self setBCancelDatePickers:nil];
    
    [self setCurrentPeriodLabel:nil];
    [self setCurrentPeriodLabel:nil];
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

#pragma mark - Actions

- (IBAction)startStopLocationRecording:(UIButton *)sender
{
    // if we are not tracking the user location when the button is pressed
    if (self.isRecording == NO) {
        
        // start tracking the user using the mainLocationManager
        [[[PPrYvLocationManager sharedInstance] locationManager] startUpdatingLocation];
        
        // set flag
        self.recording = YES;
        /*
        // also activate the user location on the map
        self.mapView.showsUserLocation = YES;
        [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
         */
        [self.mapView removeAnnotations:self.mapView.annotations];
        
        // change the button title accroding to the situation
        [self.bRecorder setTitle:NSLocalizedString(@"bRecordStop", ) forState:UIControlStateNormal];
        
        // prompt the information
        self.currentPeriodLabel.text = NSLocalizedString(@"currentPeriod", );
        
        // animate the interface for the user experience and
        // show a status bar to inform the location recording is enabled
        [UIView animateWithDuration:.3 animations:^{
            
            self.bRecorder.transform = CGAffineTransformMakeTranslation(0, 20);
            self.bTakeNote.transform = CGAffineTransformMakeTranslation(0, 20);
            self.bTakePicture.transform = CGAffineTransformMakeTranslation(0, 20);
            self.statusBarRecorder.transform = CGAffineTransformMakeTranslation(0, 20);
        }];
    }
    // if we were tracking the user location, we stop now.
    else {
        
        // change the button title according to the situation
        [self.bRecorder setTitle:NSLocalizedString(@"bRecordStart", ) forState:UIControlStateNormal];

        // animate the transition from the recording state back to the idle state
        [UIView animateWithDuration:.3 animations:^{
            
            self.bRecorder.transform = CGAffineTransformIdentity;
            self.bTakeNote.transform = CGAffineTransformIdentity;
            self.bTakePicture.transform = CGAffineTransformIdentity;
            self.statusBarRecorder.transform = CGAffineTransformIdentity;
        }];
        
        // set flag
        self.recording = NO;
        /*
        // stop showing the user's location on the map
        self.mapView.showsUserLocation = NO;
        [self.mapView setUserTrackingMode:MKUserTrackingModeNone animated:YES];
        */
        // stop tracking the user
        [[[PPrYvLocationManager sharedInstance] locationManager] stopUpdatingLocation];
    }
}

- (IBAction)takePicture:(id)sender
{
    // show an action sheet to allow the user to chose picture from library or from camera
    UIActionSheet * actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"actionSheetPhotoTitle", ) delegate:self cancelButtonTitle:NSLocalizedString(@"actionSheetPhotoCancel", ) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"actionSheetPhotoCamera", ),NSLocalizedString(@"actionSheetPhotoLibrary", ), nil];
    
    [actionSheet showInView:self.view];
}

- (IBAction)takeNote:(UIButton *)sender
{
    // reinitialize the note composer text
    self.noteComposer.text = @"";
    
    // prepare some layout infos to start the animation correctly
    self.noteComposer.alpha = 0;
    self.noteComposer.hidden = NO;
    self.navBarNote.hidden = NO;
    self.noteComposer.transform = CGAffineTransformMakeTranslation(0, self.noteComposer.frame.size.height+50);
    
    // animate the note composer apparition
    [UIView animateWithDuration:.5
                     animations:^{
                         
                        self.navBarNote.alpha = 1;
                        self.noteComposer.alpha = 1;
                        self.noteComposer.transform = CGAffineTransformIdentity;
                    }];
    
    // this will show the keyboard and associated its input to our note composer
    [self.noteComposer becomeFirstResponder];
    /*
    // if the app is not currently tracking the user's location
    if (!self.isRecording) {
        
        // start the gps with the map
        self.mapView.showsUserLocation = YES;
    }
     */
}

- (IBAction)cancelNote:(id)sender
{
    // dimiss the keyboard
    [self.noteComposer resignFirstResponder];

    // animate the transition of the note taker
    [UIView animateWithDuration:.5
                     animations:^{
                         
                         self.navBarNote.alpha = 0;
                         self.noteComposer.alpha = 0;
                         self.noteComposer.transform = CGAffineTransformMakeTranslation(0, self.noteComposer.frame.size.height+50);
                         
                     }completion:^(BOOL finished) {
                         
                         self.navBarNote.hidden = YES;
                         self.noteComposer.hidden = YES;
                     }];
    /*
    // if the app was not tracking the user location
    if(!self.isRecording) {
        
        // stop the gps by stopping the map showing the user location
        self.mapView.showsUserLocation = NO;
    }
     */
}

- (IBAction)sendNoteWithCurrentLocation:(id)sender
{
    // get the message
    NSString * message = self.noteComposer.text;
    
    // get the current location from the map
    CLLocation * messageLocation = self.mapView.userLocation.location;
    
    User * user = [User currentUserInContext:[[PPrYvCoreDataManager sharedInstance] managedObjectContext]];

    // create a new event and send to PrYv API
    PositionEvent *locationEvent = [PositionEvent createPositionEventInLocation:messageLocation
                                                                    withMessage:message
                                                                     attachment:nil folder:user.folderId
                                                                      inContext:[[PPrYvCoreDataManager sharedInstance] managedObjectContext]];
    [[[PPrYvPositionEventSender alloc] initWithPositionEvent:locationEvent] sendToPrYvApi];

    
    // dimiss the note composer
    [self cancelNote:nil];
}

#pragma mark MapView Delegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    
    if (annotation == mapView.userLocation) {
        return nil;
    }
    static NSString * annotationIdentifier = @"annotationIdentifier";
    MKPinAnnotationView * annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation
                                                                           reuseIdentifier:annotationIdentifier];
    annotationView.animatesDrop = YES;
    annotationView.pinColor = MKPinAnnotationColorGreen;
    annotationView.enabled = YES;
    annotationView.canShowCallout = YES;
    
    return annotationView;
}

#pragma mark - Action Sheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
            // Camera
            if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                
                if (!self.isRecording) {
                    
                    self.mapView.showsUserLocation = YES;
                }

                UIImagePickerController * picker = [[UIImagePickerController alloc] init];
                picker.sourceType = UIImagePickerControllerSourceTypeCamera;
                picker.allowsEditing = NO;
                picker.delegate = self;
                
                if (IS_IPAD) {
                    
                    // we are on ipad need to use a popover
                    self.iPadPopover = [[UIPopoverController alloc] initWithContentViewController:picker];
                    [self.iPadPopover presentPopoverFromRect:self.bTakePicture.frame
                                                      inView:self.view
                                    permittedArrowDirections:UIPopoverArrowDirectionAny
                                                    animated:YES];
                }
                else {
                    // we are on iPhone show picker as modal view
                    [self presentViewController:picker animated:YES completion:nil];
                }
            }
            break;
        case 1:
            // Photo Library
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
                /*
                if (!self.isRecording) {
                    
                    self.mapView.showsUserLocation = YES;
                }
                 */

                UIImagePickerController * picker = [[UIImagePickerController alloc] init];
                picker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:
                                        UIImagePickerControllerSourceTypePhotoLibrary];
                picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                picker.delegate = self;
                
                if (IS_IPAD) {
                    // we are on ipad need to use a popover
                    
                    self.iPadPopover = [[UIPopoverController alloc] initWithContentViewController:picker];
                    [self.iPadPopover presentPopoverFromRect:self.bTakePicture.frame
                                             inView:self.view
                           permittedArrowDirections:UIPopoverArrowDirectionAny
                                           animated:YES];
                }
                else {
                    // we are on iPhone show photo library as modal view
                    [self presentViewController:picker animated:YES completion:nil];
                }
            }
            
            break;
        default:
            break;
    }
}

#pragma mark - Image Picker Delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // current folder
    NSString * folderId = [[User currentUserInContext:[[PPrYvCoreDataManager sharedInstance] managedObjectContext]] folderId];

    // detach a thread to perform some action on the picture data
    dispatch_queue_t queue1 = dispatch_queue_create("com.PrYv.loadImage",NULL);
    
    dispatch_async(queue1,
                   ^{
                       // if there is metaData with the image, it means the image comes from the camera
                       if ([info objectForKey: UIImagePickerControllerMediaMetadata] != nil) {
                           
                           // get the image
                           UIImage * image = [info objectForKey:UIImagePickerControllerOriginalImage];
                           
                           // store the new image in the phone library
                           ALAssetsLibrary * asset = [[ALAssetsLibrary alloc] init];
                           [asset writeImageToSavedPhotosAlbum:image.CGImage metadata:[info objectForKey: UIImagePickerControllerMediaMetadata] completionBlock:^(NSURL *assetURL, NSError *error) {
                                                              
                               // store the location with attachment url here and send it
                               PositionEvent *locationEvent = [PositionEvent createPositionEventInLocation:self.mapView.userLocation.location
                                                                                               withMessage:nil
                                                                                                attachment:assetURL
                                                                                                    folder:folderId
                                                                                                 inContext:[[PPrYvCoreDataManager sharedInstance] managedObjectContext]];
                               [[[PPrYvPositionEventSender alloc] initWithPositionEvent:locationEvent] sendToPrYvApi];
                           }];
                       }
                       // else the image was picked from the library
                       else {
                           
                           // get the image asset URL
                           NSURL * assetURL = [info objectForKey:UIImagePickerControllerReferenceURL];

                           PositionEvent *locationEvent = [PositionEvent createPositionEventInLocation:self.mapView.userLocation.location
                                                                                           withMessage:nil
                                                                                            attachment:assetURL
                                                                                                folder:folderId
                                                                                             inContext:[[PPrYvCoreDataManager sharedInstance] managedObjectContext]];
                           [[[PPrYvPositionEventSender alloc] initWithPositionEvent:locationEvent] sendToPrYvApi];
                       }
                       /*

                       dispatch_async(dispatch_get_main_queue(), ^{
                           if (!self.isRecording) {
                               self.mapView.showsUserLocation = NO;
                           }
                       });
                        */
                   });
    
    // if we are on iPad we remove the picker popover
    if (IS_IPAD) {
        
        [self.iPadPopover dismissPopoverAnimated:YES];
    }
    // if on iPhone we remove the picker modal view
    else {
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    /*
    if(!self.isRecording) {
        
        self.mapView.showsUserLocation = NO;
    }
     */
    // if on iPad remove the popover
    if (IS_IPAD) {
        
        [self.iPadPopover dismissPopoverAnimated:YES];
    }
    // if on iPhone remove the modal view
    else {
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - User Interface Periods Actions

- (IBAction)askForTimePeriod:(UIButton *)sender
{
    // if we are already selecting a time period, do nothing
    if (!self.bCancelDatePickers.hidden) {
        
        return;
    }
    
    if (IS_IPAD) {
        // we are on ipad animate user interface

        self.datePickerTo.transform = CGAffineTransformMakeTranslation(0,self.datePickerTo.frame.size.height+200);
        self.datePickerFrom.transform = CGAffineTransformMakeTranslation(0,self.datePickerFrom.frame.size.height+200);
        
        self.datePickerFrom.alpha = 0;
        self.datePickerTo.alpha = 0;
        self.datePickerFrom.hidden = NO;
        self.datePickerTo.hidden = NO;
        self.bCancelDatePickers.alpha = 1;
        self.bCancelDatePickers.hidden = NO;
        self.bConfirmTimePeriod.alpha = 0;
        self.bConfirmTimePeriod.hidden = NO;
        
        [UIView animateWithDuration:.5 animations:^{
            
            self.datePickerTo.transform = CGAffineTransformIdentity;
            self.datePickerFrom.transform = CGAffineTransformIdentity;
            self.datePickerTo.alpha = 1;
            self.datePickerFrom.alpha = 1;
            self.bCancelDatePickers.alpha = 1;
            self.bCancelDatePickers.alpha = 1;
            self.bConfirmTimePeriod.alpha = 1;
            
        }];
        
        return;
    }
    
    // if we are on iPhone animate for the iPhone
    self.bNextDate.alpha = 0;
    self.bNextDate.hidden = NO;
    self.datePickerFrom.hidden = NO;
    self.bCancelDatePickers.alpha = 0;
    self.bCancelDatePickers.hidden = NO;
    self.datePickerTo.transform = CGAffineTransformMakeTranslation(0,self.datePickerTo.frame.size.height+52);
    self.datePickerFrom.transform = CGAffineTransformMakeTranslation(0,self.datePickerFrom.frame.size.height+52);
    
    [UIView animateWithDuration:.5 animations:^{
        
        self.datePickerFrom.transform = CGAffineTransformIdentity;
        self.bNextDate.alpha = 1;
        self.bCancelDatePickers.alpha = 1;
        
    }];
}

- (IBAction)showDatePickerFrom:(UIButton *)sender
{
    // this button is for iPhone only
    self.bNextDate.alpha = 0;
    self.bNextDate.hidden = NO;
    
    [UIView animateWithDuration:.5 animations:^{
        
        self.bFromDate.alpha = 0;
        self.bConfirmTimePeriod.alpha = 0;
        self.datePickerTo.transform = CGAffineTransformMakeTranslation(0,self.datePickerTo.frame.size.height+52);

    } completion:^(BOOL finished) {
        
        self.bFromDate.hidden = YES;
        self.bConfirmTimePeriod.hidden = YES;

        [UIView animateWithDuration:.5 animations:^{
            
            self.bNextDate.alpha = 1;
            self.datePickerFrom.transform = CGAffineTransformIdentity;
        }];
    }];
}

- (IBAction)showDatePickerTo:(UIButton *)sender
{
    // button only on iPhone
    self.bFromDate.alpha = 0;
    self.bFromDate.hidden = NO;
    self.datePickerTo.hidden = NO;
    self.bConfirmTimePeriod.alpha = 0;
    self.bConfirmTimePeriod.hidden = NO;
    
    [UIView animateWithDuration:.5 animations:^{
        
        self.bNextDate.alpha = 0;
        self.datePickerFrom.transform = CGAffineTransformMakeTranslation(0,self.datePickerFrom.frame.size.height+52);
        
    } completion:^(BOOL finished) {
        
        self.bNextDate.hidden = YES;
        
        [UIView animateWithDuration:.5 animations:^{
            
            self.datePickerTo.transform = CGAffineTransformIdentity;
            self.bConfirmTimePeriod.alpha = 1;
            self.bFromDate.alpha = 1;
        }];
    }];
}

- (IBAction)cancelDatePickers:(UIButton *)sender
{
    // only for iPhone
    [UIView animateWithDuration:.5 animations:^{
        
        self.bFromDate.alpha = 0;
        self.bNextDate.alpha = 0;
        self.bConfirmTimePeriod.alpha = 0;
        self.bCancelDatePickers.alpha = 0;
        self.datePickerFrom.transform = CGAffineTransformMakeTranslation(0,self.datePickerFrom.frame.size.height);
        self.datePickerTo.transform = CGAffineTransformMakeTranslation(0,self.datePickerTo.frame.size.height);
        
    } completion:^(BOOL finished) {
        
        self.datePickerTo.hidden = YES;
        self.datePickerTo.transform = CGAffineTransformIdentity;
        self.datePickerFrom.hidden = YES;
        self.datePickerFrom.transform = CGAffineTransformIdentity;
        self.bConfirmTimePeriod.hidden = YES;
        self.bCancelDatePickers.hidden = YES;
        self.bFromDate.hidden = YES;
        self.bNextDate.hidden = YES;
    }];
}

- (IBAction)askServerForTimePeriodData
{
    // dismiss the date pickers
    [self cancelDatePickers:nil];
    
    // get user
    User * user = [User currentUserInContext:[[PPrYvCoreDataManager sharedInstance] managedObjectContext]];
    
    // clean the map from all annotations
    [self.mapView removeAnnotations:self.mapView.annotations];
    NSTimeInterval interval = 60.*60.*24.;
    NSDate * dateTo = [self.datePickerTo.date dateByAddingTimeInterval:interval];
    // ask for events in the chosen time period with the current user channel
    [[PPrYvApiClient sharedClient] getEventsFromStartDate:self.datePickerFrom.date
                                                toEndDate:dateTo
                                               inFolderId:user.folderId
                                           successHandler:^(NSArray *positionEventList) {
                                                
                                                [self didReceiveEvents:positionEventList];
                                                
                                                NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
                                                formatter.dateFormat = @"EEE, MMM d, yyyy";
                                                formatter.locale = [NSLocale currentLocale];
                                                
                                                NSString * dateFrom = [formatter stringFromDate:self.datePickerFrom.date];
                                                NSString * dateTo = [formatter stringFromDate:self.datePickerTo.date];
                                                
                                                self.currentPeriodLabel.text =
                                                [NSString stringWithFormat:NSLocalizedString(@"sessionCustom", ), dateFrom, dateTo];
                                            
                                            } errorHandler:^(NSError *error) {
                                                
                                            }];
}

- (IBAction)askForLast24h:(UIButton *)sender
{
    // dimiss the date pickers
    [self cancelDatePickers:nil];
    
    // get user
    User * user = [User currentUserInContext:[[PPrYvCoreDataManager sharedInstance] managedObjectContext]];
    
    // clean the map from all annotations
    [self.mapView removeAnnotations:self.mapView.annotations];
    NSLog(@"%@",user.folderId);
    // ask the PrYv API for events in the last 24h with the current user channel
    [[PPrYvApiClient sharedClient] getEventsFromStartDate:nil
                                                toEndDate:nil
                                               inFolderId:user.folderId
                                           successHandler:^(NSArray *positionEventList) {
                                               
                                               [self didReceiveEvents:positionEventList];
                                               self.currentPeriodLabel.text = NSLocalizedString(@"last24hSession", );
                                           
                                           } errorHandler:^(NSError *error) {
                                                /*
                                                [[[UIAlertView alloc] initWithTitle:nil
                                                                            message:NSLocalizedString(@"alertCantReceiveEvents", )
                                                                           delegate:nil
                                                                  cancelButtonTitle:NSLocalizedString(@"cancelButton", )
                                                                  otherButtonTitles:nil] show];
                                                 */
                                           }];
}

#pragma mark - Settings Actions

- (IBAction)pushSettingsViewController
{
    // show the settings menu
    PPrYvSettingViewController * settings =
       [[PPrYvSettingViewController alloc] initWithNibName:@"PPrYvSettingViewController"
                                                    bundle:nil];

    if (IS_IPAD) {

        // we are on ipad need to use a popover
        self.iPadPopover = [[UIPopoverController alloc] initWithContentViewController:settings];        
        
        // keep refference for future dismiss
        settings.iPadHoldingPopOver = self.iPadPopover;
        settings.iPadHoldingPopOverViewController = self;
        self.iPadPopover.popoverContentSize = CGSizeMake(320, 540);
        [self.iPadPopover presentPopoverFromRect:self.bSettings.frame
                                          inView:self.view
                        permittedArrowDirections:UIPopoverArrowDirectionAny
                                        animated:YES];
    }
    else {
        
        [self presentViewController:settings animated:YES completion:nil];
    }
}

#pragma mark -  Events Received

- (void)didReceiveEvents:(NSArray *)positionEventList
{
    // we have received a list of positionEvents

    if (![positionEventList count]) {
        NSLog(@"no events found");

        return;
    }
    NSLog(@"fetched events: %d", [positionEventList count]);

    // Calculate the region to show on map according to all the received points
    u_int locationsCount = [positionEventList count];
    double latitudeSum = 0;
    double longitudeSum = 0;
    double latitudeMax = 0;
    double latitudeMin = 0;
    double longitudeMax = 0;
    double longitudeMin = 0;
    
    for (PositionEvent *positionEvent in positionEventList) {

        double latitude = [positionEvent.latitude doubleValue];
        double longitude = [positionEvent.longitude doubleValue];

        latitudeSum += latitude;
        longitudeSum += longitude;
        
        if (latitudeMax != 0) {
            latitudeMax = MAX(latitude, latitudeMax);
        }else {
            latitudeMax = longitude;
        }
        if (latitudeMin != 0) {
            latitudeMin = MIN(latitude, latitudeMin);
        }
        else {
            latitudeMin = latitude;
        }
        if (longitudeMax != 0) {
            longitudeMax = MAX(longitude, longitudeMax);
        }
        else {
            longitudeMax = longitude;
        }
        if (longitudeMin != 0) {
            longitudeMin = MIN(longitude, longitudeMin);
        }
        else {
            longitudeMin = longitude;
        }

        MKPointAnnotation * aPosition = [[MKPointAnnotation alloc] init];
        aPosition.title = NSLocalizedString(@"mapPointText", );
        aPosition.coordinate = CLLocationCoordinate2DMake(latitude, longitude);
        
        [self.mapView addAnnotation:aPosition];
    }

    double latitudeMean = latitudeSum/ locationsCount;
    double longitudeMean = longitudeSum / locationsCount;
    double latitudeDelta = MAX(fabs(latitudeMax-latitudeMin), 0.03);
    double longitudeDelta = MAX(fabs(longitudeMax-longitudeMin), 0.03);

    MKCoordinateRegion region = MKCoordinateRegionMake(CLLocationCoordinate2DMake(latitudeMean, longitudeMean), MKCoordinateSpanMake(latitudeDelta, longitudeDelta));
    
    [self.mapView setRegion:region animated:YES];
}
#pragma mark - dealloc

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
