//
//  PPrYvAppDelegate.m
//  AT PrYv
//
//  Created by Nicolas Manzini on 06.12.12.
//  Copyright (c) 2012 PrYv. All rights reserved.
//

#import "PPrYvAppDelegate.h"
#import "PPrYvMapViewController.h"
#import "PPrYvLoginViewController.h"
#import "User.h"
#import "Location.h"

#define applicationPrYvChannel @"VeA4Yv9RiM"

@implementation PPrYvAppDelegate

@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

@synthesize mainLocationManager, mapViewController, foregroundTimer, foregroundLocationUpdatesAllowed, backgroundDate;

#pragma mark - Application Life Cycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // get the current user if any available
    User * user = [User currentUserInContext:self.managedObjectContext];
    
    // set some defaults values
    NSTimeInterval timeInterval = 30;
    CLLocationDistance distanceInterval = 30;
    
    if (user != nil) {
        
        timeInterval = [user.locationTimeInterval doubleValue];
        distanceInterval = [user.locationDistanceInterval doubleValue];
    }
    
    // prepare the flag
    self.foregroundLocationUpdatesAllowed = YES;
    
    // create our main location manager set the AppDelegate as the location manager delegate
    self.mainLocationManager = [[CLLocationManager alloc] init];
    self.mainLocationManager.distanceFilter = distanceInterval;
    self.mainLocationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    self.mainLocationManager.delegate = self;
    
    // start the foregroundTimer
    self.foregroundTimer = [NSTimer scheduledTimerWithTimeInterval:[user.locationTimeInterval doubleValue] target:self selector:@selector(allowUpdateNow) userInfo:nil repeats:YES];
    
    BOOL isIPad = NO;
    
    if ([[[UIDevice currentDevice] model] rangeOfString:@"iPad"].location != NSNotFound) {
        
        isIPad = YES;
    }
    
    if (isIPad) {
        
        self.mapViewController = [[PPrYvMapViewController alloc] initWithNibName:@"PPrYvMapViewControlleriPad" bundle:nil inContext:self.managedObjectContext mainLocationManager:self.mainLocationManager];
    }
    else {
        
        self.mapViewController = [[PPrYvMapViewController alloc] initWithNibName:@"PPrYvMapViewControlleriPhone" bundle:nil inContext:self.managedObjectContext mainLocationManager:self.mainLocationManager];
    }
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = self.mapViewController;
    [self.window makeKeyAndVisible];
    
    if (user == nil) {
        
        // no user available show the login form
        PPrYvLoginViewController * login = nil;
        
        if (isIPad) {
            
            login = [[PPrYvLoginViewController alloc] initWithNibName:@"PPrYvLoginViewControlleriPad" bundle:nil inContext:self.managedObjectContext];
        }
        else {
            
            login = [[PPrYvLoginViewController alloc] initWithNibName:@"PPrYvLoginViewControlleriPhone" bundle:nil inContext:self.managedObjectContext];
        }
        
        [self.window.rootViewController presentViewController:login animated:YES completion:nil];
    }
    else {
        
        // a user exist. Thus maybe some events are waiting to be uploaded
        [[PPrYvDefaultManager sharedManager] startManagerWithUserId:user.userId oAuthToken:user.userToken channelId:applicationPrYvChannel delegate:self];
    }
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
      
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    
    // invalidate NSTimer and switch to NSDate
    [self.foregroundTimer invalidate];
    self.foregroundTimer = nil;
    
    // start background date with now
    self.backgroundDate = [NSDate date];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    
    [[PPrYvDefaultManager sharedManager] synchronizeTimeWithServerDelegate:self];
    
    // switch back from NSDate to NSTimer for location updates
    self.foregroundLocationUpdatesAllowed = YES;
    
    User * user = [User currentUserInContext:self.managedObjectContext];
    
    NSTimeInterval timeInterval = 30;
    
    if (user != nil) {
        
        timeInterval = [user.locationTimeInterval doubleValue];
    }
    
    self.foregroundTimer = [NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(allowUpdateNow) userInfo:nil repeats:YES];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    
}

- (void)applicationWillTerminate:(UIApplication *)application {
    
    [self saveContext];
}

- (void)saveContext {
    
    NSError *error = nil;
    NSManagedObjectContext * managedObjectContext = self.managedObjectContext;
    
    if (managedObjectContext != nil) {
        
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {

            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

#pragma mark - Core Data stack

- (NSManagedObjectContext *)managedObjectContext {
    
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
    
    if (_managedObjectModel != nil) {
        
        return _managedObjectModel;
    }
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"ATPrYv" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    
    if (_persistentStoreCoordinator != nil) {
        
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"ATPrYv.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:@{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES} error:&error]) {
        /*
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory {
    
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

#pragma mark - Location Manager Delegate

// called by the the foreground timer to allow new location to be accepted
- (void)allowUpdateNow {
    
    self.foregroundLocationUpdatesAllowed = YES;
}

// If iOS >= 6.0
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    
    CLLocation * location = [locations lastObject];
    
    User * user = [User currentUserInContext:self.managedObjectContext];
    
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
    // add the location on the map
    [self.mapViewController addNewLocation:location];
    
    
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        
        self.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            
            self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }];
    }
    else {
        
        self.foregroundLocationUpdatesAllowed = NO;
    }
    
    Location * aLocation = [Location newLocation:location withMessage:nil attachment:nil folder:user.folderId inContext:self.managedObjectContext];
    
    [aLocation sendToPrYvAPI];
}

// iOS <= 5.1
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
        
    CLLocation * location = newLocation;
    
    User * user = [User currentUserInContext:self.managedObjectContext];
    
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
    // add the location on the map
    [self.mapViewController addNewLocation:location];
    
    
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        
        self.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            
            self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }];
    }
    else {
        
        self.foregroundLocationUpdatesAllowed = NO;
    }
    
    Location * aLocation = [Location newLocation:location withMessage:nil attachment:nil folder:user.folderId inContext:self.managedObjectContext];
    
    [aLocation sendToPrYvAPI];
}

#pragma mark - PPrYvDefaultManager delegate

- (void)PPrYvDefaultManagerDidSynchronize {
    
    [Location sendAllPendingEventsToPrYvAPIInContext:self.managedObjectContext];
}

- (void)PPrYvDefaultManagerDidFail:(PPrYvFailedAction)failedAction withError:(NSError *)error {
    
    if (failedAction == PPrYvFailedSynchronize) {
        
        // handle the error here
    }
}



@end
