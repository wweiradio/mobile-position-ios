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
#import "PositionEvent+Extras.h"
#import "PPrYvCoreDataManager.h"
#import "PPrYvLocationManager.h"
#import "PPrYvPositionEventSender.h"
#import "PPrYvApiClient.h"
#import "PPrYvPointAnnotation.h"
#import "UIView+Helpers.h"
#import "PPrYvWebLoginViewController.h"
#import "MBProgressHUD.h"
#import "CrumbPath.h"
#import "CrumbPathView.h"

@interface PPrYvMapViewController ()

@property (nonatomic, strong) CrumbPath *crumbs;
@property (nonatomic, strong) CrumbPathView *crumbView;

@end

@implementation PPrYvMapViewController

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

#pragma mark - default date in query parameters

- (NSDate *)defaultToDate
{
    NSDate *toDate = [NSDate date];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults doubleForKey:@"defaultDateRangeToDate"] > 1) {
        toDate = [NSDate dateWithTimeIntervalSince1970:[userDefaults doubleForKey:@"defaultDateRangeToDate"]];
    }
    return toDate;
}

- (NSDate *)defaultFromDate
{
    // yesterday
    NSDate *today = [NSDate date];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setDay:-1];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDate *fromDate = [gregorian dateByAddingComponents:components toDate:today options:0];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults doubleForKey:@"defaultDateRangeFromDate"] > 1) {
        fromDate = [NSDate dateWithTimeIntervalSince1970:[userDefaults doubleForKey:@"defaultDateRangeFromDate"]];
    }
    return fromDate;
}


#pragma mark - View LifeCycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // rename all the buttons according to the current local en,fr,de...
    [self.bAskLast24h setTitle:NSLocalizedString(@"bAsk24h", ) forState:UIControlStateNormal];
    [self.bTakeNote setTitle:NSLocalizedString(@"bTakeNote", ) forState:UIControlStateNormal];
    [self.bAskTimePeriod setTitle:NSLocalizedString(@"bAskTimePeriod", ) forState:UIControlStateNormal];

    [self.bFromDate setBackgroundImage:[UIImage imageNamed:@"bDateSelected.png"] forState:UIControlStateSelected];
    [self.bNextDate setBackgroundImage:[UIImage imageNamed:@"bDateSelected.png"] forState:UIControlStateSelected];
    
    [self.bRecorder setTitle:NSLocalizedString(@"bRecordStart", ) forState:UIControlStateNormal];
    [self.bRecorder setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

    [self formatDateButton:self.bNextDate withPrefix:NSLocalizedString(@"bToDate", ) date:[self defaultToDate]];
    [self formatDateButton:self.bFromDate withPrefix:NSLocalizedString(@"bFromDate", ) date:[self defaultFromDate]];
    
    self.bSendNote.title = NSLocalizedString(@"bNavBarSendNote", );
    self.bCancelNote.title = NSLocalizedString(@"bNavBarCancelNote", );
    self.statusBarRecorder.text = NSLocalizedString(@"statusBarRecording", );
    
    // Set default datepickers period from a week ago to now
    self.datePickerTo.date = [NSDate date];
    self.datePickerFrom.date = [NSDate dateWithTimeIntervalSinceNow:-60 * 60 * 24 * 7];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateLocation:)
                                                 name:kPrYvLocationManagerDidAcceptNewLocationNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      
                                                      NSManagedObjectContext *context = [[PPrYvCoreDataManager sharedInstance] managedObjectContext];
                                                      
                                                      if ([PositionEvent lastPositionEventIfRecording:context]) {
                                                          [self startRecording];
                                                      }
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    NSLog(@"viewDidAppear");
    [super viewDidAppear:animated];
    
    User *user = [User currentUserInContext:[[PPrYvCoreDataManager sharedInstance] managedObjectContext]];
    
    if (!user) {
        NSLog(@"no user!");
        // no user available - show the login form
        PPrYvWebLoginViewController *loginViewController = nil;
        loginViewController = [[PPrYvWebLoginViewController alloc] initWithNibName:@"PPrYvWebLoginViewController"
                                                                            bundle:nil];
        [self.view endEditing:YES];
        
        // TODO test on iPad
        [self presentViewController:loginViewController animated:YES completion:nil];
    } else {
        NSLog(@"user: %@", user.userId);
    }
    
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

#pragma mark - Application lifecycle

- (void)applicationDidBecomeActive
{
    // get the current user if any available
    User *user = [User currentUserInContext:[[PPrYvCoreDataManager sharedInstance] managedObjectContext]];
    if (!user) {
        return;
    }
   
    // if a user exists Thus might be some events are waiting to be uploaded
    // start or restart the api Client with the new user upon successful start it would try to synchronize
    PPrYvApiClient *apiClient = [PPrYvApiClient sharedClient];
    [apiClient startClientWithUserId:user.userId
                          oAuthToken:user.userToken
                           streamIdId:kPrYvApplicationstreamIdId
                      successHandler:^(NSTimeInterval serverTime) {
                          
                          [PPrYvPositionEventSender sendAllPendingEventsToPrYvApi];
                          
                          if (![self isRecording]) {
                              
                              [MBProgressHUD hideHUDForView:self.view animated:YES];
                              [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                              
                              // ask the PrYv API for events in the last 24h with the current user streamId
                              NSTimeInterval interval = -60 * 60 * 24;
                              NSDate *dateTo = [NSDate date];
                              NSDate *dateFrom = [dateTo dateByAddingTimeInterval:interval];
                              [apiClient getEventsFromStartDate:dateFrom
                                                      toEndDate:dateTo
                                                     instreamId:user.streamId
                                                 successHandler:^(NSArray *positionEventList) {
                                                     
                                                     [self didReceiveEvents:positionEventList];
                                                     self.currentPeriodLabel.text = NSLocalizedString(@"last24hSession", );
                                                     
                                                     [MBProgressHUD hideHUDForView:self.view animated:YES];
                                                     
                                                 } errorHandler:^(NSError *error) {
                                                     [MBProgressHUD hideHUDForView:self.view animated:YES];
                                                     
                                                     [self reportError:error];
                                                 }];
                          }

                          
                      } errorHandler:^(NSError *error) {
                          //
                          [MBProgressHUD hideHUDForView:self.view animated:YES];
                          MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                          
                          // Configure for text only and offset down
                          hud.mode = MBProgressHUDModeText;
                          hud.labelText = NSLocalizedString(@"alertCantSynchronize", );
                          // hud.margin = 10.f;
                          // hud.yOffset = 150.f;
                          hud.removeFromSuperViewOnHide = YES;
                          
                          [hud hide:YES afterDelay:3];
                      }];
    
}

#pragma mark - Actions

- (void)startRecording
{
    self.crumbs = nil;
    self.crumbView = nil;
    [self.mapView removeOverlays:self.mapView.overlays];
    
    // start tracking the user using the mainLocationManager
    [[PPrYvLocationManager sharedInstance] startUpdatingLocation];
    
    // set flag
    self.recording = YES;
    
    // change the button title accroding to the situation
    [self.bRecorder setTitle:NSLocalizedString(@"bRecordStop", ) forState:UIControlStateNormal];
    [self.bRecorder setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    //Change recorder button color
    [self.bRecorder setBackgroundImage:[UIImage imageNamed:@"bPryvitOn.png"] forState:UIControlStateNormal];
    
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

- (IBAction)startStopLocationRecording:(UIButton *)sender
{
    // if we are not tracking the user location when the button is pressed
    if (!self.isRecording) {
        [self startRecording];
    }
    // if we were tracking the user location, we stop now.
    else {
        
        // change the button title according to the situation
        [self.bRecorder setTitle:NSLocalizedString(@"bRecordStart", ) forState:UIControlStateNormal];
        [self.bRecorder setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

        //Change recorder button color
        [self.bRecorder setBackgroundImage:[UIImage imageNamed:@"bPryvitOff.png"] forState:UIControlStateNormal];

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
        [[PPrYvLocationManager sharedInstance] stopUpdatingLocation];
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

// TODO: rename: note doesn't have a location
- (IBAction)sendNoteWithCurrentLocation:(id)sender
{
    // get the message
    NSString * message = self.noteComposer.text;
    
    // do not send the empty note
    if ([message length] > 0) {
        
        // trim the message to MAX length
        if ([message length] > kPrYvMaximumNoteLength) {
            message = [message substringWithRange:NSMakeRange(0, kPrYvMaximumNoteLength)];
        }
        
        // get the current location from the map
        CLLocation * messageLocation = self.mapView.userLocation.location;
        
        User * user = [User currentUserInContext:[[PPrYvCoreDataManager sharedInstance] managedObjectContext]];

        // create a new event and send to PrYv API
        PositionEvent *locationEvent = [PositionEvent createPositionEventInLocation:messageLocation
                                                                        withMessage:message
                                                                         attachment:nil
                                                                             folder:user.streamId
                                                                          inContext:[[PPrYvCoreDataManager sharedInstance] managedObjectContext]];
        
        [[[PPrYvPositionEventSender alloc] initWithPositionEvent:locationEvent] sendToPrYvApiCompletion:nil];
    }
    
    // dimiss the note composer
    [self cancelNote:nil];
}

#pragma mark - private

- (void)openSettingsWithLogout:(BOOL)autoLogout
{
    // show the settings menu
    PPrYvSettingViewController * settingsViewController =
    [[PPrYvSettingViewController alloc] initWithNibName:@"PPrYvSettingViewController"
                                                 bundle:nil];
    
    if (IS_IPAD) {
        
        // we are on ipad need to use a popover
        self.iPadPopover = [[UIPopoverController alloc] initWithContentViewController:settingsViewController];
        
        // keep reference for future dismiss
        settingsViewController.iPadHoldingPopOver = self.iPadPopover;
        settingsViewController.iPadHoldingPopOverViewController = self;
        self.iPadPopover.popoverContentSize = CGSizeMake(320, 540);
        [self.iPadPopover presentPopoverFromRect:self.bSettings.frame
                                          inView:self.view
                        permittedArrowDirections:UIPopoverArrowDirectionAny
                                        animated:YES];
    }
    else {
        
        [self presentViewController:settingsViewController animated:YES completion:^{
            if (autoLogout)
                [settingsViewController logOutCurrentUser:nil];
        }];
    }
}

- (void)reportError:(NSError *)error
{
    NSError *originError = error;
    if ([[error userInfo] objectForKey:@"connectionError"]) {
        originError = [[error userInfo] objectForKey:@"connectionError"];
    }

    NSUInteger httpStatusCode = [[originError userInfo][@"AFNetworkingOperationFailingURLResponseErrorKey"] statusCode];
    if (httpStatusCode == 401 || httpStatusCode == 403 || httpStatusCode == 404) {
        // access / permission error / folder|streamId does not exist
        [self openSettingsWithLogout:YES];
        return;
    }
    
    NSString *message = [originError localizedDescription];
    
    NSDictionary *userInfo = [error userInfo];
    if (userInfo[@"serverError"] && userInfo[@"serverError"][@"message"]) {
        NSString *serverMessage = [error userInfo][@"serverError"][@"message"];
        message = [NSString stringWithFormat: @"%@ (%@)", serverMessage, [originError localizedDescription]];
    }

    [MBProgressHUD hideHUDForView:self.view animated:YES];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
	hud.mode = MBProgressHUDModeText;
	hud.labelText = @"Error";
    hud.detailsLabelText = message;
	hud.removeFromSuperViewOnHide = YES;
	
	[hud hide:YES afterDelay:5];
}

#pragma mark - 

- (void)updateLocation:(NSNotification *)aNotification
{
    CLLocation *newLocation = aNotification.userInfo[kPrYvLocationManagerDidAcceptNewLocationNotification];
    if (!self.crumbs)
    {
        // This is the first time we're getting a location update, so create
        // the CrumbPath and add it to the map.
        //
        _crumbs = [[CrumbPath alloc] initWithCenterCoordinate:newLocation.coordinate];
        [self.mapView addOverlay:self.crumbs];
        
        // On the first location update only, zoom map to user location
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(newLocation.coordinate, 2000, 2000);
        [self.mapView setRegion:region animated:YES];
    }
    else
    {
        // This is a subsequent location update.
        // If the crumbs MKOverlay model object determines that the current location has moved
        // far enough from the previous location, use the returned updateRect to redraw just
        // the changed area.
        //
        // note: iPhone 3G will locate you using the triangulation of the cell towers.
        // so you may experience spikes in location data (in small time intervals)
        // due to 3G tower triangulation.
        //
        MKMapRect updateRect = [self.crumbs addCoordinate:newLocation.coordinate];
        
        if (!MKMapRectIsNull(updateRect))
        {
            // There is a non null update rect.
            // Compute the currently visible map zoom scale
            MKZoomScale currentZoomScale = (CGFloat)(self.mapView.bounds.size.width /
                                                     self.mapView.visibleMapRect.size.width);
            // Find out the line width at this zoom scale and outset the updateRect by that amount
            CGFloat lineWidth = MKRoadWidthAtZoomScale(currentZoomScale);
            updateRect = MKMapRectInset(updateRect, -lineWidth, -lineWidth);
            
            // Ask the overlay view to update just the changed area.
            [self.crumbView setNeedsDisplayInMapRect:updateRect];
        }
    }

}

#pragma mark - MapView Delegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    return nil;
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)annotationViews
{
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
}

#pragma mark - overlay

- (MKPolyline *)createPolyLinePathWithPositionEvents:(NSArray *)positionEventList
{
    NSLog(@"Create a polyline from position events with count %d", [positionEventList count]);
    
    CLLocationCoordinate2D *coords = malloc(sizeof(CLLocationCoordinate2D) *[positionEventList count]);
    
    for (int i = 0; i < [positionEventList count]; i++)
    {
        PositionEvent *positionEvent = [positionEventList objectAtIndex:i];
        coords[i] = CLLocationCoordinate2DMake([positionEvent.latitude doubleValue],
                                               [positionEvent.longitude doubleValue]);
    }
    
    MKPolyline *polyLine = [MKPolyline polylineWithCoordinates:coords
                                                         count:[positionEventList count]];
    free(coords);
    
    return polyLine;
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay
{
    if ([overlay isKindOfClass:[CrumbPath class]])
    {
        if (!self.crumbView) {
            _crumbView = [[CrumbPathView alloc] initWithOverlay:overlay];
        }
        return self.crumbView;
    }
    else
    {
        MKPolylineView * polylineView =[[MKPolylineView alloc] initWithPolyline:(MKPolyline *)overlay];
        polylineView.strokeColor = [UIColor colorWithWhite:.7 alpha:.9];
        polylineView.lineWidth = 9.f;
        polylineView.lineJoin = kCGLineJoinRound;
        
        return polylineView;
    }
}

#pragma mark -  Events Received on Overlay

- (void)didReceiveEvents:(NSArray *)positionEventList
{
    // we have received a list of positionEvents
    
    if (![positionEventList count]) {
        NSLog(@"no events found");
        return;
    }
    
    NSLog(@"fetched events of count %d", [positionEventList count]);
    
    // remove previous overlays made by searches
    NSMutableArray *overlaysToRemove = [NSMutableArray array];
    for (id<MKOverlay> overlay in self.mapView.overlays) {
        if (![overlay isKindOfClass:[CrumbPath class]]) {
            [overlaysToRemove addObject:overlay];
        }
    }
    
    [self.mapView removeOverlays:overlaysToRemove];
    
    // Calculate the region to show on map according to all the received points
    NSUInteger locationsCount = [positionEventList count];
    double latitudeSum = 0;
    double longitudeSum = 0;
    double latitudeMax = 0;
    double latitudeMin = 0;
    double longitudeMax = 0;
    double longitudeMin = 0;
    
    PositionEvent *previousEvent = nil;
    for (PositionEvent *positionEvent in positionEventList)
    {
        if (previousEvent)
        {
            NSAssert([previousEvent.date compare:positionEvent.date] == NSOrderedDescending ||
                     [previousEvent.date compare:positionEvent.date] == NSOrderedSame, @"unordered events!");
        }
        previousEvent = positionEvent;
        
        
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
    }
    
    double latitudeAvg = latitudeSum/ locationsCount;
    double longitudeAvg = longitudeSum / locationsCount;
    double latitudeDelta = MAX(fabs(latitudeMax-latitudeMin), 0.03);
    double longitudeDelta = MAX(fabs(longitudeMax-longitudeMin), 0.03);
    
    MKCoordinateRegion region = MKCoordinateRegionMake(CLLocationCoordinate2DMake(latitudeAvg, longitudeAvg),
                                                       MKCoordinateSpanMake(latitudeDelta, longitudeDelta));
    
    [self.mapView setRegion:region animated:YES];
    
    [self.mapView addOverlay:[self createPolyLinePathWithPositionEvents:positionEventList]];
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
    NSString * streamId = [[User currentUserInContext:[[PPrYvCoreDataManager sharedInstance] managedObjectContext]] streamId];

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
                                                                                                    folder:streamId
                                                                                                 inContext:[[PPrYvCoreDataManager sharedInstance] managedObjectContext]];
                               
                               [[[PPrYvPositionEventSender alloc] initWithPositionEvent:locationEvent] sendToPrYvApiCompletion:nil];
                           }];
                       }
                       // else the image was picked from the library
                       else {
                           
                           // get the image asset URL
                           NSURL * assetURL = [info objectForKey:UIImagePickerControllerReferenceURL];

                           PositionEvent *locationEvent = [PositionEvent createPositionEventInLocation:self.mapView.userLocation.location
                                                                                           withMessage:nil
                                                                                            attachment:assetURL
                                                                                                folder:streamId
                                                                                             inContext:[[PPrYvCoreDataManager sharedInstance] managedObjectContext]];
                           
                           [[[PPrYvPositionEventSender alloc] initWithPositionEvent:locationEvent] sendToPrYvApiCompletion:nil];
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
    [UIView animateWithDuration:.2 animations:^{

        self.deckHolder.top = self.view.height-self.deckHolder.height;
        self.shadowView.alpha = .6f;
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
    [UIView animateWithDuration:.2 animations:^{
        self.deckHolder.top = self.view.height;
        self.shadowView.alpha = 0.f;
    }];
    self.shadowView.hidden = YES;
    
    //self.deckHolder.top = 460;
}

- (NSDateFormatter *)buttonDateFormatter
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterShortStyle;
    dateFormatter.locale = [NSLocale currentLocale];
    return dateFormatter;
}

// TODO: consider putting in a UIButton category
- (void)formatDateButton:(UIButton *)button withPrefix:(NSString *)prefix date:(NSDate *)buttonDate
{
    NSString *dateFormatted = [[self buttonDateFormatter] stringFromDate:buttonDate];
    [button setTitle:[NSString stringWithFormat:@"%@ %@", prefix, dateFormatted]
            forState:UIControlStateNormal];
}

- (IBAction)datePickerFromChanged:(UIDatePicker *)datePicker
{
    [self formatDateButton:self.bFromDate withPrefix:NSLocalizedString(@"bFromDate", ) date:datePicker.date];
}

- (IBAction)datePickerNextChanged:(UIDatePicker *)datePicker
{
    [self formatDateButton:self.bNextDate withPrefix:NSLocalizedString(@"bToDate", ) date:datePicker.date];
}

// TODO consider blocking creating new queries unless this one is finished

- (IBAction)askServerForTimePeriodData
{
    // remember the date range
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setDouble:[self.datePickerFrom.date timeIntervalSince1970]
                     forKey:@"defaultDateRangeFromDate"];
    [userDefaults setDouble:[self.datePickerTo.date timeIntervalSince1970]
                     forKey:@"defaultDateRangeToDate"];
    
    // dismiss the date pickers
    [self cancelDatePickers:nil];
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];

    // get user
    User *user = [User currentUserInContext:[[PPrYvCoreDataManager sharedInstance] managedObjectContext]];
    
    NSTimeInterval interval = 60 * 60 * 24;
    NSDate *dateTo = [self.datePickerTo.date dateByAddingTimeInterval:interval];
    
    // ask for events in the chosen time period with the current user streamId
    [[PPrYvApiClient sharedClient] getEventsFromStartDate:self.datePickerFrom.date
                                                toEndDate:dateTo
                                               instreamId:user.streamId
                                           successHandler:^(NSArray *positionEventList) {
                                               
                                               [self didReceiveEvents:positionEventList];
                                               
                                               // update info label
                                               NSDateFormatter *currentPeriodLabelDateFormatter = [[NSDateFormatter alloc] init];
                                               currentPeriodLabelDateFormatter.dateFormat = @"EEE, MMM d, yyyy";
                                               currentPeriodLabelDateFormatter.locale = [NSLocale currentLocale];
                                               self.currentPeriodLabel.text = [NSString stringWithFormat:
                                                                               NSLocalizedString(@"sessionCustom", ),
                                                                               [currentPeriodLabelDateFormatter stringFromDate:self.datePickerFrom.date],
                                                                               [currentPeriodLabelDateFormatter stringFromDate:self.datePickerTo.date]];
                                               
                                               [MBProgressHUD hideHUDForView:self.view animated:YES];
                                           
                                           } errorHandler:^(NSError *error) {
                                               [MBProgressHUD hideHUDForView:self.view animated:YES];
                                               
                                               [self reportError:error];
                                           }];
}

- (IBAction)askForLast24h:(UIButton *)sender
{
    // dimiss the date pickers
    [self cancelDatePickers:nil];
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    // get user
    User *user = [User currentUserInContext:[[PPrYvCoreDataManager sharedInstance] managedObjectContext]];
    
    // clean the map from all annotations
    NSLog(@"%@", user.streamId);
    
    // ask the PrYv API for events in the last 24h with the current user streamId
    NSTimeInterval interval = -60 * 60 * 24;
    NSDate *dateTo = [NSDate date];
    NSDate *dateFrom = [dateTo dateByAddingTimeInterval:interval];

    [[PPrYvApiClient sharedClient] getEventsFromStartDate:dateFrom
                                                toEndDate:dateTo
                                               instreamId:user.streamId
                                           successHandler:^(NSArray *positionEventList) {
                                               
                                               [self didReceiveEvents:positionEventList];
                                               
                                               // update info label
                                               self.currentPeriodLabel.text = NSLocalizedString(@"last24hSession", );
                                               
                                               [MBProgressHUD hideHUDForView:self.view animated:YES];
                                               
                                           } errorHandler:^(NSError *error) {
                                               [MBProgressHUD hideHUDForView:self.view animated:YES];
                                               
                                               // TODO show error if any
                                               [self reportError:error];
                                           }];
}

#pragma mark - Locate Me Action

- (IBAction)locateMe:(UIButton *)sender
{
    [self.mapView setShowsUserLocation:YES];
    [self.mapView setCenterCoordinate:self.mapView.userLocation.location.coordinate
                             animated:YES];
}

#pragma mark - Settings Actions

- (IBAction)pushSettingsViewController
{
    [self openSettingsWithLogout:NO];
}

#pragma mark - dealloc

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
