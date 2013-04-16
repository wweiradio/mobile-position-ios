//
//  Created by Konstantin Dorodov on 1/6/13.
//  Copyright (c) 2012 PrYv. All rights reserved.
//


#import <CoreData/CoreData.h>
#import "PPrYvLocationManager.h"
#import "User+Extras.h"
#import "PositionEvent+Extras.h"
#import "PPrYvCoreDataManager.h"
#import "PPrYvPositionEventSender.h"

@interface PPrYvLocationManager()

// the location manager responsible for tracking the location we want to store on the PrYv API
@property (nonatomic, strong) CLLocationManager *locationManager;

// our background date used as a timer when the application is in background mode to filter locations
@property (nonatomic, strong) NSDate *backgroundDate;

// our foreground timer used when the application is in foreground to filter locations
@property (nonatomic, strong) NSTimer *foregroundTimer;

// our foreground timer flag
@property (nonatomic, assign, getter = isForegroundLocationUpdatesAllowed) BOOL foregroundLocationUpdatesAllowed;

@property (nonatomic, strong) PositionEvent *lastPositionEvent;

// a backgroundTaskIdentifier used when connecting to the PrYv API when the application is in background
// background taskIdentifiers allows you to have extra time to perform a task when the application is in background mode.
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

@end


@implementation PPrYvLocationManager

+ (PPrYvLocationManager *)sharedInstance
{
    static PPrYvLocationManager *_sharedSingleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedSingleton = [[self alloc] init];
    });
    return _sharedSingleton;
}

- (id)init
{
    self = [super init];
    if (self) {

        _locationManager = [[CLLocationManager alloc] init];

        CLLocationDistance defaultDistanceInterval = 30;
        NSNumber *defaultUpdateTimeInterval = [NSNumber numberWithDouble:30];

        _foregroundLocationUpdatesAllowed = YES;

        _locationManager.distanceFilter = defaultDistanceInterval;
        _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        _locationManager.delegate = self;

        _foregroundTimer = [NSTimer scheduledTimerWithTimeInterval:[defaultUpdateTimeInterval doubleValue]
                                                            target:self
                                                          selector:@selector(allowUpdateNow)
                                                          userInfo:nil
                                                           repeats:YES];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(locationDistanceIntervalDidChange:)
                                                     name:kPrYvLocationDistanceIntervalDidChangeNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(locationTimeIntervalDidChange:)
                                                     name:kPrYvLocationTimeIntervalDidChangeNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(sendingLocationDidFinish:)
                                                     name:kPrYvFinishedSendingLocationNotification
                                                   object:nil];
    }
    return self;
}

#pragma mark - Application lifecycle


- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // invalidate NSTimer and switch to NSDate
    [self.foregroundTimer invalidate];
    self.foregroundTimer = nil;

    // start background date with now
    self.backgroundDate = [NSDate date];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // switch back from NSDate to NSTimer for location updates
    self.foregroundLocationUpdatesAllowed = YES;

    User * user = [User currentUserInContext:[[PPrYvCoreDataManager sharedInstance] managedObjectContext]];

    NSTimeInterval timeInterval = 30;

    if (user != nil) {
        timeInterval = [user.locationTimeInterval doubleValue];
    }
    
    [self.foregroundTimer invalidate];
    self.foregroundTimer = [NSTimer scheduledTimerWithTimeInterval:timeInterval
                                                            target:self
                                                          selector:@selector(allowUpdateNow)
                                                          userInfo:nil
                                                           repeats:YES];
}

#pragma mark - Actions

- (void)locationDistanceIntervalDidChange:(NSNotification *)aNotification
{
    NSDictionary *userInfo = aNotification.userInfo;
    if ([userInfo objectForKey:kPrYvLocationDistanceIntervalDidChangeNotificationUserInfoKey]){
        CLLocationAccuracy distanceInterval = [[userInfo objectForKey:kPrYvLocationDistanceIntervalDidChangeNotification] doubleValue];
        self.locationManager.distanceFilter = distanceInterval;
    }
}

- (void)locationTimeIntervalDidChange:(NSNotification *)aNotification
{
    NSDictionary *userInfo = aNotification.userInfo;
    if ([userInfo objectForKey:kPrYvLocationTimeIntervalDidChangeNotificationUserInfoKey]) {
        
        assert([UIApplication sharedApplication].applicationState != UIApplicationStateBackground);
        [self.foregroundTimer invalidate];
        NSTimeInterval timeInterval = [[userInfo objectForKey:kPrYvLocationTimeIntervalDidChangeNotificationUserInfoKey] doubleValue];
        self.foregroundTimer = [NSTimer scheduledTimerWithTimeInterval:timeInterval
                                                                target:self
                                                              selector:@selector(allowUpdateNow)
                                                              userInfo:nil
                                                               repeats:YES];
    }
}

- (void)sendingLocationDidFinish:(NSNotification *)aNotification
{
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        [[UIApplication sharedApplication] endBackgroundTask:[self backgroundTaskIdentifier]];
        [self setBackgroundTaskIdentifier: UIBackgroundTaskInvalid];
    }
}

#pragma mark - 

- (void)startUpdatingLocation
{
    self.lastPositionEvent = nil;
    
    [self.locationManager startUpdatingLocation];
}

- (void)stopUpdatingLocation
{
    [self.locationManager stopUpdatingLocation];
}

- (BOOL)tooCloseTooPreviousEvent:(CLLocation *)location
{
    if (!self.lastPositionEvent)
        return NO;
        
    PositionEvent *previousEvent = self.lastPositionEvent;
    
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([previousEvent.latitude doubleValue],
                                                                   [previousEvent.longitude doubleValue]);
    CLLocation *previousLocation = [[CLLocation alloc] initWithCoordinate:coordinate
                                                                 altitude:[previousEvent.elevation doubleValue]
                                                       horizontalAccuracy:[previousEvent.horizontalAccuracy doubleValue]
                                                         verticalAccuracy:[previousEvent.verticalAccuracy doubleValue]
                                                                timestamp:[NSDate date]];
    
    return [location distanceFromLocation:previousLocation] < kPrYvMinimumDistanceBetweenConsecutiveEvents;
}

#pragma mark - Location Manager Delegate

// called by the the foreground timer to allow new location to be accepted
- (void)allowUpdateNow
{
    self.foregroundLocationUpdatesAllowed = YES;
}

// If iOS >= 6.0
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *location = [locations lastObject];
    User *user = [User currentUserInContext:[[PPrYvCoreDataManager sharedInstance] managedObjectContext]];
    if (user == nil) {
        return;
    }
    
    // skip 0/0 coordinate
    if (location.coordinate.latitude == 0.0f && location.coordinate.longitude == 0.0f) {
        NSLog(@"ignore sending the 0/0 coordinate");
        return;
    }
    
    // TODO extract 100.0f to the settings
    if (location.horizontalAccuracy > 100.0f || location.horizontalAccuracy < 0.0f){
        return;
    }

    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground){
        if ([self.backgroundDate timeIntervalSinceNow] > -[user.locationTimeInterval doubleValue]) {
            return;
        }
        else {
            self.backgroundDate = [NSDate date];
        }
    }
    else if (self.foregroundTimer != nil && !self.isForegroundLocationUpdatesAllowed) {
        return;
    }

    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        self.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
            self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }];
    }
    else {
        self.foregroundLocationUpdatesAllowed = NO;
    }
    
    // check with the previous position event
    //      if location is close enough - update the time duration for the event
    
    PositionEvent *locationEvent = nil;
    if ([self tooCloseTooPreviousEvent:location]) {
        
        //send the previous event with calculated duration
        locationEvent = self.lastPositionEvent;
        double secondsSinceLastEvent = [[NSDate date] timeIntervalSince1970] - [locationEvent.date timeIntervalSince1970];
        locationEvent.duration = [NSNumber numberWithDouble:secondsSinceLastEvent];
    } else {
        locationEvent = [PositionEvent createPositionEventInLocation:location
                                                         withMessage:nil
                                                          attachment:nil
                                                              folder:user.folderId
                                                           inContext:[[PPrYvCoreDataManager sharedInstance] managedObjectContext]];
    }
    
    // save last position event
    self.lastPositionEvent = locationEvent;
    
    [[[PPrYvPositionEventSender alloc] initWithPositionEvent:locationEvent] sendToPrYvApiCompletion:nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kPrYvLocationManagerDidAcceptNewLocationNotification
                                                        object:nil
                                                      userInfo:@{kPrYvLocationManagerDidAcceptNewLocationNotification : location}];
}

// iOS <= 5.1
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    [self locationManager:manager didUpdateLocations:@[ newLocation ]];
}

@end
