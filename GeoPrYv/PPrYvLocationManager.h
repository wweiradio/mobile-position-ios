//
//  Created by Konstantin Dorodov on 1/6/13.
//  Copyright (c) 2012 PrYv. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>


@interface PPrYvLocationManager : NSObject<CLLocationManagerDelegate>

// our background date used as a timer when the application is in background mode to filter locations
@property (nonatomic, strong) NSDate * backgroundDate;

// our foreground timer used when the application is in foreground to filter locations
@property (nonatomic, strong) NSTimer * foregroundTimer;

// the location manager responsible for tracking the location we want to store on the PrYv API
@property (nonatomic, strong) CLLocationManager * locationManager;

// our foreground timer flag
@property (nonatomic, assign, getter = isForegroundLocationUpdatesAllowed) BOOL foregroundLocationUpdatesAllowed;

// a backgroundTaskIdentifier used when connecting to the PrYv API when the application is in background
// background taskIdentifiers allows you to have extra time to perform a task when the application is in background mode.
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

+ (PPrYvLocationManager *)sharedInstance;

-(void)applicationDidEnterBackground:(UIApplication *)application;

-(void)applicationWillEnterForeground:(UIApplication *)application;

// called by our foregroundTimer
- (void)allowUpdateNow;

@end