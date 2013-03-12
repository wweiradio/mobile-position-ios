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
#import "PPrYvPointAnnotation.h"
#import "UIView+Helpers.h"

@interface PPrYvMapViewController ()

- (void)createMKPolyLine;
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
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      
        User * user = [User currentUserInContext:[[PPrYvCoreDataManager sharedInstance] managedObjectContext]];
        
        // clean the map from all annotations
        // ask the PrYv API for events in the last 24h with the current user channel
        [[PPrYvApiClient sharedClient] getEventsFromStartDate:nil
                                                    toEndDate:nil
                                                   inFolderId:user.folderId
                                               successHandler:^(NSArray *positionEventList) {
                                                   
                                                   [self didReceiveEvents:positionEventList];
                                                   self.currentPeriodLabel.text = NSLocalizedString(@"last24hSession", );
                                                   
                                               } errorHandler:^(NSError *error) {
                                                   
                                               }];

    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
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
    [self setDeckHolder:nil];
    [self setShadowView:nil];
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
        
        for (MKPointAnnotation * annot in self.mapView.annotations) {
            if (annot != (MKPointAnnotation *)self.mapView.userLocation) {
                [self.mapView removeAnnotation:annot];
            }
        }
        
        [self.mapView removeOverlays:self.mapView.overlays];
        
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

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if (annotation == mapView.userLocation) {
        return nil;
    }
    static NSString *annotationIdentifier = @"annotationIdentifier";
    MKAnnotationView *annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation
                                                                    reuseIdentifier:annotationIdentifier];
    annotationView.image = [UIImage imageNamed:@"pinPryv.png"];
    annotationView.enabled = YES;
    annotationView.canShowCallout = YES;
    
    return annotationView;
}

// TODO rethink animating all the views because the amount of points/view can be pretty big
- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)annotationViews
{
    for (int i = 0; i< [annotationViews count]; i++) {
        
        MKAnnotationView *annotationView = [annotationViews objectAtIndex:i];
        CGRect endFrame = annotationView.frame;
        annotationView.frame = CGRectOffset(endFrame, 0, -500);
        NSTimeInterval interval = 0.03 * i;
        
        if (![[annotationView annotation] isKindOfClass:[MKUserLocation class]]) {
            // send annotaion view to back if it is not current user location
            [[annotationView superview] sendSubviewToBack:annotationView];
        }
        
        [UIView animateWithDuration:0.5 delay:interval options:UIViewAnimationCurveEaseOut animations:^{
            annotationView.frame = endFrame;
        } completion:^(BOOL finished) {
            
            // attempt to bring the current userLocation in front
            if (i == [annotationViews count] - 1) {
                UIView *view = [mapView viewForAnnotation:mapView.userLocation];
                [[view superview] bringSubviewToFront:view];
            } 
        }];
    }
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    for (NSObject *annotation in [mapView annotations])
    {
        if ([annotation isKindOfClass:[MKUserLocation class]])
        {
            MKAnnotationView *view = [mapView viewForAnnotation:(MKUserLocation *)annotation];
            [[view superview] bringSubviewToFront:view];
        }
    }
}

- (void)createMKPolyLine
{
    
    NSMutableArray * mapPoints = [NSMutableArray arrayWithArray:self.mapView.annotations];
    
    [mapPoints removeObject:self.mapView.userLocation];

    
    CLLocationCoordinate2D *coords = malloc(sizeof(CLLocationCoordinate2D) * [mapPoints count]);
    
    NSMutableArray * sortedPoint = [NSMutableArray arrayWithArray:[mapPoints sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        
        PPrYvPointAnnotation * point1 = obj1;
        PPrYvPointAnnotation * point2 = obj2;
        
        if ([[point1.date earlierDate:point2.date] isEqualToDate:point1.date]) {
            NSLog(@"ascending budy!");
            return (NSComparisonResult)NSOrderedDescending;
        }
        else if([[point1.date earlierDate:point2.date] isEqualToDate:point2.date]){
            NSLog(@"descending budy! event1 = %@ event2 = %@", point1.date,point2.date);
            return (NSComparisonResult)NSOrderedAscending;
        }
        
        return (NSComparisonResult)NSOrderedSame;

    }]];
        
    for (int i = 0; i < [sortedPoint count]; i++) {
        
        coords[i] = [(MKPointAnnotation *)[sortedPoint objectAtIndex:i] coordinate];
        NSLog(@"did add coordinate");
    }
    
    MKPolyline * polyLine = [MKPolyline polylineWithCoordinates:coords count:[sortedPoint count]];
    
    [self.mapView addOverlay:polyLine];
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay
{
    MKPolylineView * polylineView =[[MKPolylineView alloc] initWithPolyline:(MKPolyline *)overlay];
    polylineView.strokeColor = [UIColor colorWithWhite:.7 alpha:.9];
    polylineView.lineWidth = 5.f;
    polylineView.lineJoin = kCGLineJoinRound;
    
    return polylineView;
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
    self.shadowView.hidden = NO;
    NSLog(@"everything I called");
    [UIView animateWithDuration:.5 animations:^{

        self.deckHolder.top = self.view.height-self.deckHolder.height;
        self.shadowView.alpha = .3f;
    }];
    
    if (!IS_IPAD) {
        
        self.bFromDate.selected = YES;
        self.bNextDate.selected = NO;
        self.datePickerFrom.hidden = NO;
        self.datePickerTo.hidden = YES;
    }
}

- (IBAction)showDatePickerFrom:(UIButton *)sender
{
    sender.selected = YES;
    self.datePickerFrom.hidden = NO;
    self.datePickerTo.hidden = YES;
    self.bNextDate.selected = NO;
}

- (IBAction)showDatePickerTo:(UIButton *)sender
{
    sender.selected = YES;
    self.datePickerFrom.hidden = YES;
    self.datePickerTo.hidden = NO;
    self.bFromDate.selected = NO;

}

- (IBAction)cancelDatePickers:(UIButton *)sender
{
    [UIView animateWithDuration:.3 animations:^{
        self.deckHolder.top = self.view.height;
        self.shadowView.alpha = 0.f;
    }];
    self.shadowView.hidden = YES;
    
    //self.deckHolder.top = 460;
}

- (IBAction)askServerForTimePeriodData
{
    // dismiss the date pickers
    
    // get user
    User * user = [User currentUserInContext:[[PPrYvCoreDataManager sharedInstance] managedObjectContext]];
    
    // clean the map from all annotations
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
                                               [self cancelDatePickers:nil];
                                               
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
    NSLog(@"%@",user.folderId);
    // ask the PrYv API for events in the last 24h with the current user channel
    [[PPrYvApiClient sharedClient] getEventsFromStartDate:nil
                                                toEndDate:nil
                                               inFolderId:user.folderId
                                           successHandler:^(NSArray *positionEventList) {
                                               
                                               [self didReceiveEvents:positionEventList];
                                               self.currentPeriodLabel.text = NSLocalizedString(@"last24hSession", );
                                           
                                           } errorHandler:^(NSError *error) {
                                           
                                               // do some code here
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
    
    for (MKPointAnnotation * annot in self.mapView.annotations) {
        if (annot != (MKPointAnnotation *)self.mapView.userLocation) {
            [self.mapView removeAnnotation:annot];
        }
    }
    
    [self.mapView removeOverlays:self.mapView.overlays];

    NSMutableArray * annotations = [NSMutableArray array];
    
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

        PPrYvPointAnnotation * aPosition = [[PPrYvPointAnnotation alloc] init];
        aPosition.title = NSLocalizedString(@"mapPointText", );
        aPosition.coordinate = CLLocationCoordinate2DMake(latitude, longitude);
        aPosition.date = positionEvent.date;
        [annotations addObject:aPosition];
    }

    double latitudeAvg = latitudeSum/ locationsCount;
    double longitudeAvg = longitudeSum / locationsCount;
    double latitudeDelta = MAX(fabs(latitudeMax-latitudeMin), 0.03);
    double longitudeDelta = MAX(fabs(longitudeMax-longitudeMin), 0.03);

    
    MKCoordinateRegion region = MKCoordinateRegionMake(CLLocationCoordinate2DMake(latitudeAvg, longitudeAvg), MKCoordinateSpanMake(latitudeDelta, longitudeDelta));
    
    [self.mapView setRegion:region animated:YES];
    
    [self.mapView addAnnotations:annotations];
    
    [self createMKPolyLine];
}
#pragma mark - dealloc

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
