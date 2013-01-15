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

@implementation PPrYvLocationManager {
}

@synthesize backgroundDate = _backgroundDate;
@synthesize foregroundTimer = _foregroundTimer;
@synthesize locationManager = _locationManager;
@synthesize foregroundLocationUpdatesAllowed = _foregroundLocationUpdatesAllowed;
@synthesize backgroundTaskIdentifier = _backgroundTaskIdentifier;


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
                                                 selector:@selector(sendingLocaionDidFihish:)
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
    if ([userInfo objectForKey:kPrYvLocationDistanceIntervalDidChangeNotification]){
        CLLocationAccuracy distanceInterval = [[userInfo objectForKey:kPrYvLocationDistanceIntervalDidChangeNotification] doubleValue];
        self.locationManager.distanceFilter = distanceInterval;
    }
}

- (void)locationTimeIntervalDidChange:(NSNotification *)aNotificition
{
    NSDictionary *userInfo = aNotificition.userInfo;
    if ([userInfo objectForKey:kPrYvLocationTimeIntervalDidChangeNotificationUserInfoKey]) {
        [self.foregroundTimer invalidate];
        NSTimeInterval timeInterval = [[userInfo objectForKey:kPrYvLocationTimeIntervalDidChangeNotificationUserInfoKey] doubleValue];
        self.foregroundTimer = [NSTimer scheduledTimerWithTimeInterval:timeInterval
                                                                target:self
                                                              selector:@selector(allowUpdateNow)
                                                              userInfo:nil
                                                               repeats:YES];
    }
}

- (void)sendingLocaionDidFihish:(NSNotification *)aNotificition
{
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        [[UIApplication sharedApplication] endBackgroundTask:[self backgroundTaskIdentifier]];
        [self setBackgroundTaskIdentifier: UIBackgroundTaskInvalid];
    }
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
    CLLocation * location = [locations lastObject];
    User * user = [User currentUserInContext:[[PPrYvCoreDataManager sharedInstance] managedObjectContext]];

    if (user == nil) {
        return;
    }

    if(location.horizontalAccuracy > 100.0f || location.horizontalAccuracy < 0.0f){
        return;
    }

    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground){
        if([self.backgroundDate timeIntervalSinceNow] > -[user.locationTimeInterval doubleValue]) {
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
            self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }];
    }
    else {
        self.foregroundLocationUpdatesAllowed = NO;
    }

    PositionEvent *locationEvent = [PositionEvent createPositionEventInLocation:location
                                                                    withMessage:nil attachment:nil folder:user.folderId
                                                                      inContext:[[PPrYvCoreDataManager sharedInstance] managedObjectContext]];
    [[[PPrYvPositionEventSender alloc] initWithPositionEvent:locationEvent] sendToPrYvApi];
}

// iOS <= 5.1
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    CLLocation * location = newLocation;
    User * user = [User currentUserInContext:[[PPrYvCoreDataManager sharedInstance] managedObjectContext]];
    if (user == nil) {
        return;
    }

    if(location.horizontalAccuracy > 100.0f || location.horizontalAccuracy < 0.0f){
        return;
    }

    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground){
        if([self.backgroundDate timeIntervalSinceNow] > -[user.locationTimeInterval doubleValue]) {
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
            self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }];
    }
    else {
        self.foregroundLocationUpdatesAllowed = NO;
    }

    PositionEvent *locationEvent = [PositionEvent createPositionEventInLocation:location
                                                                    withMessage:nil attachment:nil folder:user.folderId
                                                                      inContext:[[PPrYvCoreDataManager sharedInstance] managedObjectContext]];
    [[[PPrYvPositionEventSender alloc] initWithPositionEvent:locationEvent] sendToPrYvApi];

}

@end