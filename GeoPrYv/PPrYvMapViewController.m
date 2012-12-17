//
//  PPrYvMapViewController.m
//  AT PrYv
//
//  Created by Nicolas Manzini on 06.12.12.
//  Copyright (c) 2012 PrYv. All rights reserved.
//

#import "PPrYvMapViewController.h"
#import "PPrYvSettingViewController.h"
#import "PPrYvLoginViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "Position.h"

@interface PPrYvMapViewController ()

@end

@implementation PPrYvMapViewController

@synthesize recording, launchedByImagePickerOrNoteTaker;

#pragma mark - Object Life Cycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil andContext:(NSManagedObjectContext *)currentContext andManager:(CLLocationManager *)manager {
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        
        self.context = currentContext;
        self.locationManager = manager;
        self.recording = NO;
        self.launchedByImagePickerOrNoteTaker = NO;
    }
    return self;
}

#pragma mark - View LifeCycle

- (void)viewDidLoad {
    
    [super viewDidLoad];
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
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    if (!self.isRecording) {
        
        // Show rapidly the user location and leave until the user start tracking himself
        self.mapView.showsUserLocation = YES;
        [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
        
        double delayInSeconds = 5;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            
            self.mapView.showsUserLocation = NO;
            [self.mapView setUserTrackingMode:MKUserTrackingModeNone animated:YES];
        });
    }
}

- (void)viewDidUnload {
    
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
    
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {

    return YES;
}

#pragma mark - Interface

- (IBAction)startStopLocationRecording:(UIButton *)sender {
    
    if (self.isRecording == NO) {
        
        self.recording = YES;
        self.mapView.showsUserLocation = YES;
        [self.locationManager startUpdatingLocation];
        [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
        [self.bRecorder setTitle:NSLocalizedString(@"bRecordStop", ) forState:UIControlStateNormal];

        [UIView animateWithDuration:.3 animations:^{
            
            self.bRecorder.transform = CGAffineTransformMakeTranslation(0, 20);
            self.bTakeNote.transform = CGAffineTransformMakeTranslation(0, 20);
            self.bTakePicture.transform = CGAffineTransformMakeTranslation(0, 20);
            self.statusBarRecorder.transform = CGAffineTransformMakeTranslation(0, 20);
        }];
    }
    else {
        
        [UIView animateWithDuration:.3 animations:^{
            
            self.bRecorder.transform = CGAffineTransformIdentity;
            self.bTakeNote.transform = CGAffineTransformIdentity;
            self.bTakePicture.transform = CGAffineTransformIdentity;
            self.statusBarRecorder.transform = CGAffineTransformIdentity;
        }];
        
        self.recording = NO;
        self.mapView.showsUserLocation = NO;
        [self.locationManager stopUpdatingLocation];
        [self.mapView setUserTrackingMode:MKUserTrackingModeNone animated:YES];
        [self.bRecorder setTitle:NSLocalizedString(@"bRecordStart", ) forState:UIControlStateNormal];
    }
}

- (IBAction)takePicture:(id)sender {
    
    UIActionSheet * actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"actionSheetPhotoTitle", ) delegate:self cancelButtonTitle:NSLocalizedString(@"actionSheetPhotoCancel", ) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"actionSheetPhotoCamera", ),NSLocalizedString(@"actionSheetPhotoLibrary", ), nil];
    
    [actionSheet showInView:self.view];
}

- (IBAction)takeNote:(UIButton *)sender {
    
    self.noteComposer.text = @"";
    self.noteComposer.alpha = 0;
    self.noteComposer.hidden = NO;
    self.navBarNote.hidden = NO;
    self.noteComposer.transform = CGAffineTransformMakeTranslation(0, self.noteComposer.frame.size.height+50);
    
    [UIView animateWithDuration:.5
                     animations:^{
                         
                        self.navBarNote.alpha = 1;
                        self.noteComposer.alpha = 1;
                        self.noteComposer.transform = CGAffineTransformIdentity;
                    }];
    
    [self.noteComposer becomeFirstResponder];
    
    if (!self.isRecording) {
        
        self.recording = YES;
        self.launchedByImagePickerOrNoteTaker = YES;
        [self.locationManager startUpdatingLocation];
        [self.bRecorder setTitle:NSLocalizedString(@"bRecordStop", ) forState:UIControlStateNormal];
    }
}

- (IBAction)canceNote:(id)sender {
    
    [UIView animateWithDuration:.5
                     animations:^{
                         
                         self.navBarNote.alpha = 0;
                         self.noteComposer.alpha = 0;
                         self.noteComposer.transform = CGAffineTransformMakeTranslation(0, self.noteComposer.frame.size.height+50);
                         
                     }completion:^(BOOL finished) {
                         
                         self.navBarNote.hidden = YES;
                         self.noteComposer.hidden = YES;
                     }];
    
    if(self.isLaunchedByImagePickerOrNoteTaker) {
        
        self.recording = NO;
        self.launchedByImagePickerOrNoteTaker = NO;
        [self.locationManager stopUpdatingLocation];
        [self.bRecorder setTitle:NSLocalizedString(@"bRecordStart", ) forState:UIControlStateNormal];
    }
    [self.noteComposer resignFirstResponder];
}

- (IBAction)sendNoteWithCurrentLocation:(id)sender {
    
    [UIView animateWithDuration:.5
                     animations:^{
                         
                         self.navBarNote.alpha = 0;
                         self.noteComposer.alpha = 0;
                         self.noteComposer.transform = CGAffineTransformMakeTranslation(0, self.noteComposer.frame.size.height+50);
                         
                     }completion:^(BOOL finished) {
                         
                         self.navBarNote.hidden = YES;
                         self.noteComposer.hidden = YES;
                     }];
    
    NSString * message = self.noteComposer.text;
    CLLocation * messageLocation = self.locationManager.location;
        
    [PPrYvServerManager uploadNewEventOfTypeLocation:messageLocation messageAttached:message onFailSaveInContext:self.context];

    if(self.isLaunchedByImagePickerOrNoteTaker) {
        
        self.recording = NO;
        self.launchedByImagePickerOrNoteTaker = NO;
        [self.locationManager stopUpdatingLocation];
        [self.bRecorder setTitle:NSLocalizedString(@"bRecordStart", ) forState:UIControlStateNormal];
    }
    [self.noteComposer resignFirstResponder];
}

#pragma mark - Location Manager 

- (void)didAddNewLocation:(CLLocation *)newLocation {
        
    MKPointAnnotation * aPosition = [[MKPointAnnotation alloc] init];
    aPosition.title = NSLocalizedString(@"You were here", );
    aPosition.coordinate = newLocation.coordinate;

    [self.mapView addAnnotation:aPosition];
}

#pragma mark - Action Sheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch (buttonIndex) {
        case 0:
            // Camera
            if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                
                if (!self.isRecording) {
                    
                    self.recording = YES;
                    self.launchedByImagePickerOrNoteTaker = YES;
                    [self.locationManager startUpdatingLocation];
                    [self.bRecorder setTitle:NSLocalizedString(@"bRecordStop", ) forState:UIControlStateNormal];
                }

                UIImagePickerController * picker = [[UIImagePickerController alloc] init];
                picker.sourceType = UIImagePickerControllerSourceTypeCamera;
                picker.allowsEditing = NO;
                picker.delegate = self;
                
                if ([[[UIDevice currentDevice] model] rangeOfString:@"iPad"].location != NSNotFound) {
                    // we are on ipad need to use a popover
                    
                    self.iPadPopover = [[UIPopoverController alloc] initWithContentViewController:picker];
                    [self.iPadPopover presentPopoverFromRect:self.bTakePicture.frame
                                                      inView:self.view
                                    permittedArrowDirections:UIPopoverArrowDirectionAny
                                                    animated:YES];
                }
                else {
                    
                    [self presentViewController:picker animated:YES completion:nil];
                }
            }
            break;
        case 1:
            // Photo Library
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
                
                if (!self.isRecording) {
                    
                    [self.bRecorder setTitle:NSLocalizedString(@"bRecordStop", ) forState:UIControlStateNormal];
                    [self.locationManager startUpdatingLocation];
                    self.launchedByImagePickerOrNoteTaker = YES;
                    self.recording = YES;
                }

                UIImagePickerController * picker = [[UIImagePickerController alloc] init];
                picker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:
                                        UIImagePickerControllerSourceTypePhotoLibrary];
                picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                picker.delegate = self;
                
                if ([[[UIDevice currentDevice] model] rangeOfString:@"iPad"].location != NSNotFound) {
                    // we are on ipad need to use a popover
                    
                    self.iPadPopover = [[UIPopoverController alloc] initWithContentViewController:picker];
                    [self.iPadPopover presentPopoverFromRect:self.bTakePicture.frame
                                             inView:self.view
                           permittedArrowDirections:UIPopoverArrowDirectionAny
                                           animated:YES];
                }
                else {
                    
                    [self presentViewController:picker animated:YES completion:nil];
                }
            }
            
            break;
        default:
            break;
    }
}

#pragma mark - Image Picker Delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    if(self.isLaunchedByImagePickerOrNoteTaker) {
        
        self.recording = NO;
        self.launchedByImagePickerOrNoteTaker = NO;
        [self.locationManager stopUpdatingLocation];
        [self.bRecorder setTitle:NSLocalizedString(@"bRecordStart", ) forState:UIControlStateNormal];
    }
    
    dispatch_queue_t queue1 = dispatch_queue_create("com.PrYv.loadImage",NULL);
    dispatch_queue_t main = dispatch_get_main_queue();
    
    dispatch_async(queue1,
                   ^{
                       UIImage * image = [info objectForKey:UIImagePickerControllerOriginalImage];
                       NSData * imageData = UIImageJPEGRepresentation(image, .5);
                       NSLog(@"%u",imageData.length);

                       if ([info objectForKey: UIImagePickerControllerMediaMetadata] != nil) {
                           
                           ALAssetsLibrary * asset = [[ALAssetsLibrary alloc] init];
                           [asset writeImageToSavedPhotosAlbum:image.CGImage metadata:[info objectForKey: UIImagePickerControllerMediaMetadata] completionBlock:nil];
                       }
                       
                       dispatch_async(main, ^{
                           
                           [PPrYvServerManager uploadNewEventOfTypeLocation:self.locationManager.location imageAttached:imageData optionalMessageAttached:@"" onFailSaveInContext:self.context];
                       });
                       
                   });
        
    if ([[[UIDevice currentDevice] model] rangeOfString:@"iPad"].location != NSNotFound) {
        
        [self.iPadPopover dismissPopoverAnimated:YES];
    }
    else {
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    if(self.isLaunchedByImagePickerOrNoteTaker) {
        
        self.recording = NO;
        self.launchedByImagePickerOrNoteTaker = NO;
        [self.locationManager stopUpdatingLocation];
        [self.bRecorder setTitle:NSLocalizedString(@"bRecordStart", ) forState:UIControlStateNormal];
    }
    if ([[[UIDevice currentDevice] model] rangeOfString:@"iPad"].location != NSNotFound) {
        
        [self.iPadPopover dismissPopoverAnimated:YES];
    }
    else {
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - User Interface Periods Actions

- (IBAction)askForTimePeriod:(UIButton *)sender {
    
    if (!self.bCancelDatePickers.hidden) {
        
        return;
    }
    
    if ([[[UIDevice currentDevice] model] rangeOfString:@"iPad"].location != NSNotFound) {
        // we are on ipad

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
            
        } completion:^(BOOL finished) {
            
        }];

        return;
    }
    
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
        
    } completion:^(BOOL finished) {
        
    }];
}

- (IBAction)showDatePickerFrom:(UIButton *)sender {
    
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

- (IBAction)showDatePickerTo:(UIButton *)sender {
    
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

- (IBAction)cancelDatePickers:(UIButton *)sender {
    
    
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

- (IBAction)askServerForTimePeriodData {
    
    [self cancelDatePickers:nil];
    
    [self.mapView removeAnnotations:self.mapView.annotations];
    
    [PPrYvServerManager downloadEventOfTypeLocationBeginningDate:self.datePickerFrom.date toEndDate:self.datePickerTo.date dataReceiverDelegate:self];
}

- (IBAction)askForLast24h:(UIButton *)sender {
    
    [self cancelDatePickers:nil];
    
    [self.mapView removeAnnotations:self.mapView.annotations];
    
    [PPrYvServerManager downloadEventOfTypeLocationBeginningDate:nil toEndDate:nil dataReceiverDelegate:self];
}

- (IBAction)pushSettingsViewController {
    
    
    
    PPrYvSettingViewController * settings = nil;
    
    if ([[[UIDevice currentDevice] model] rangeOfString:@"iPad"].location != NSNotFound) {
        
        settings = [[PPrYvSettingViewController alloc] initWithNibName:@"PPrYvSettingViewControlleriPad" bundle:nil];
        
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
        
        settings = [[PPrYvSettingViewController alloc] initWithNibName:@"PPrYvSettingViewControlleriPhone" bundle:nil];
        [self presentViewController:settings animated:YES completion:nil];
    }
}

#pragma mark - PPrYvServerManagerDelegate

- (void)PPrYvServerManagerDidReceiveAllLocations:(NSDictionary *)locations {
    
    if (![locations count]) {
        
        return;
    }
    
    // Calculate the region to show on map according to all the received points
    u_int locationsCount = [locations count];
    double latitudeSum = 0;
    double longitudeSum = 0;
    double latitudeMax = 0;
    double latitudeMin = 0;
    double longitudeMax = 0;
    double longitudeMin = 0;
    
    
    for (NSDictionary * dico in locations) {
        
        double latitude = [[[[dico objectForKey:@"value"] objectForKey:@"location"] objectForKey:@"lat"] doubleValue];
        double longitude = [[[[dico objectForKey:@"value"] objectForKey:@"location"] objectForKey:@"long"] doubleValue];
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
        
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
        aPosition.coordinate = coordinate;
        
        [self.mapView addAnnotation:aPosition];
    }

    double latitudeMean = latitudeSum/ locationsCount;
    double longitudeMean = longitudeSum / locationsCount;
    double latitudeDelta = MAX(fabs(latitudeMax-latitudeMin), 0.03);
    double longitudeDelta = MAX(fabs(longitudeMax-longitudeMin),0.03);

    MKCoordinateRegion region = MKCoordinateRegionMake(CLLocationCoordinate2DMake(latitudeMean, longitudeMean), MKCoordinateSpanMake(latitudeDelta, longitudeDelta));
    
    [self.mapView setRegion:region animated:YES];
}

@end
