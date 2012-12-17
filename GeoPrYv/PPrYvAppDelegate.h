//
//  PPrYvAppDelegate.h
//  AT PrYv
//
//  Created by Nicolas Manzini on 06.12.12.
//  Copyright (c) 2012 PrYv. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PPrYvServerManager.h"
#import <CoreLocation/CoreLocation.h>

@class PPrYvMapViewController, PPrYvSettingViewController;

@interface PPrYvAppDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate, PPrYvServerManagerDelegate> {
    
    NSDate * backgroundDate;
    NSTimer * foregroundTimer;
    BOOL foregroundLocationUpdatesAllowed;
    CLLocationManager * locationManager;
    PPrYvMapViewController * mapViewController;
}

@property (strong, nonatomic) UIWindow *window;
@property (readonly, strong, nonatomic) NSManagedObjectModel * managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext * managedObjectContext;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator * persistentStoreCoordinator;
@property (nonatomic, strong) NSDate * backgroundDate;
@property (nonatomic, strong) NSTimer * foregroundTimer;
@property (nonatomic, strong) CLLocationManager * locationManager;
@property (nonatomic, strong) PPrYvMapViewController * mapViewController;
@property (nonatomic, assign, getter = isForegroundLocationUpdatesAllowed) BOOL foregroundLocationUpdatesAllowed;

- (void)saveContext;
- (void)checkForPendingEventsToUpload;
- (NSURL *)applicationDocumentsDirectory;


@end
