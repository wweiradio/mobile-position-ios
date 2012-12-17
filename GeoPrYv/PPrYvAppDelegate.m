//
//  PPrYvAppDelegate.m
//  AT PrYv
//
//  Created by Nicolas Manzini on 06.12.12.
//  Copyright (c) 2012 PrYv. All rights reserved.
//

#import "Position.h"
#import "PPrYvAppDelegate.h"
#import "PPrYvMapViewController.h"
#import "PPrYvSettingViewController.h"
#import "PPrYvLoginViewController.h"

@interface PPrYvAppDelegate ()

- (CLLocationManager *)mainLocationManager;
- (void)allowUpdateNow;

@end

@implementation PPrYvAppDelegate

@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

@synthesize locationManager, mapViewController, foregroundTimer, foregroundLocationUpdatesAllowed, backgroundDate;

#pragma mark - Application Life Cycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // set default user settings for first launch
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kLocationTimeInterval] == nil) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithDouble:30] forKey:kLocationTimeInterval];
    }
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kLocationDistanceInterval] == nil) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithDouble:30] forKey:kLocationDistanceInterval];
    }
    // allow network activity indicator in status bar
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    
    self.foregroundLocationUpdatesAllowed = YES;
    self.locationManager = [self mainLocationManager];
    self.foregroundTimer =[NSTimer scheduledTimerWithTimeInterval:[[[NSUserDefaults standardUserDefaults] objectForKey:kLocationTimeInterval] doubleValue] target:self selector:@selector(allowUpdateNow) userInfo:nil repeats:YES];

    BOOL isIPad = NO;
    
    if ([[[UIDevice currentDevice] model] rangeOfString:@"iPad"].location != NSNotFound) {
        
        isIPad = YES;
    }
    
    if (isIPad) {
        
        self.mapViewController = [[PPrYvMapViewController alloc] initWithNibName:@"PPrYvMapViewControlleriPad" bundle:nil andContext:self.managedObjectContext andManager:self.locationManager];
    }
    else {
        
        self.mapViewController = [[PPrYvMapViewController alloc] initWithNibName:@"PPrYvMapViewControlleriPhone" bundle:nil andContext:self.managedObjectContext andManager:self.locationManager];
    }
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = self.mapViewController;
    [self.window makeKeyAndVisible];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsCurrentUser] == nil) {
        
        // show user login
        PPrYvLoginViewController * login = nil;
        
        if (isIPad) {
            
            login = [[PPrYvLoginViewController alloc] initWithNibName:@"PPrYvLoginViewControlleriPad" bundle:nil];
        }
        else {
            
            login = [[PPrYvLoginViewController alloc] initWithNibName:@"PPrYvLoginViewControlleriPhone" bundle:nil];
        }
        
        [self.window.rootViewController presentViewController:login animated:YES completion:nil];
    }
    else if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsCurrentUserFolder] == nil) {
        
        // Try to create a main folder
        [PPrYvServerManager checkOrCreateServerMainFolder:@"PrYvMainFolder" delegate:nil];
    }
    else {
        
        // check for pending uploads if any
        [self checkForPendingEventsToUpload];
    }
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
      
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    
    // invalidate NSTimer and switch to NSDate
    [self.foregroundTimer invalidate];
    self.foregroundTimer = nil;
    self.backgroundDate = [NSDate date];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    
    [self checkForPendingEventsToUpload];
    // switch back from NSDate to NSTimer for location updates
    self.foregroundLocationUpdatesAllowed = YES;
    self.foregroundTimer =[NSTimer scheduledTimerWithTimeInterval:[[[NSUserDefaults standardUserDefaults] objectForKey:kLocationTimeInterval] doubleValue] target:self selector:@selector(allowUpdateNow) userInfo:nil repeats:YES];
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
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"GeoPrYv" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    
    if (_persistentStoreCoordinator != nil) {
        
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"GeoPrYv.sqlite"];
    
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

#pragma mark - Location Manager

- (CLLocationManager *)mainLocationManager {
    // start a main location manager that can be passed to the entire app
    // this location manager is responsible for providing the data to be uploaded
    CLLocationManager * aManager = [[CLLocationManager alloc] init];
    aManager.distanceFilter = [[[NSUserDefaults standardUserDefaults] objectForKey:kLocationDistanceInterval] doubleValue];
    aManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    aManager.delegate = self;

    return aManager;
}

#pragma mark - Location Manager Delegate

- (void)allowUpdateNow {
    
    self.foregroundLocationUpdatesAllowed = YES;
}

// If iOS >= 6.0
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    
    CLLocation * location = [locations lastObject];
    
    if(location.horizontalAccuracy > 100.0f || location.horizontalAccuracy < 0.0f){
        
        return;
    }

    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground){
        
        if([self.backgroundDate timeIntervalSinceNow] > -[[[NSUserDefaults standardUserDefaults] objectForKey:kLocationTimeInterval] doubleValue]) {
            
            return;
        }
        else {
            
            self.backgroundDate = [NSDate date];
        }
    }
    else if (self.foregroundTimer != nil && !self.isForegroundLocationUpdatesAllowed) {
        
        return;
    }
    
    [self.mapViewController didAddNewLocation:location];
    
    UIBackgroundTaskIdentifier __block backgroundTask = 0;
    
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        
        // Ask the phone an extra time to perfom the server connection while in background
        backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            
            backgroundTask = UIBackgroundTaskInvalid;
        }];
    }
    else {
        
        self.foregroundLocationUpdatesAllowed = NO;
    }
    
    [PPrYvServerManager uploadNewEventOfTypeLocation:location onFailSaveInContext:self.managedObjectContext isBackgroundTask:backgroundTask];
}

// iOS <= 5.1
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
        
    if(newLocation.horizontalAccuracy > 100.0f || newLocation.horizontalAccuracy < 0.0f){
        
        return;
    }

    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        
        if([self.backgroundDate timeIntervalSinceNow] > -[[[NSUserDefaults standardUserDefaults] objectForKey:kLocationTimeInterval] doubleValue]) {
            
            return;
        }
        else {
            
            self.backgroundDate = [NSDate date];
        }
    }
    else if (self.foregroundTimer != nil && !self.isForegroundLocationUpdatesAllowed) {
        
        return;
    }
        
    [self.mapViewController didAddNewLocation:newLocation];
    
    UIBackgroundTaskIdentifier __block backgroundTask = 0;
    
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        
        // Ask the phone an extra time to perfom the server connection while in background
        backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            
            backgroundTask = UIBackgroundTaskInvalid;
        }];
    }
    else {
        
        self.foregroundLocationUpdatesAllowed = NO;
    }
    
    [PPrYvServerManager uploadNewEventOfTypeLocation:newLocation onFailSaveInContext:self.managedObjectContext isBackgroundTask:backgroundTask];
}

#pragma mark - Application Will Enter Foreground Tasks

- (void)checkForPendingEventsToUpload {
    
    NSMutableArray * allPositions = [Position allPositionsInFormatReadyToUploadInContext:self.managedObjectContext];
    
    if (allPositions == nil || [allPositions count] == 0) {
        
        return;
    }
    
    [PPrYvServerManager uploadBatchEventsOfTypeLocations:allPositions successDelegate:self];
}

#pragma mark - Server Manager Batch Upload Delegate

- (void)PPrYvServerManagerDidFinishUploadBatchSuccessfully:(BOOL)success {
    
    if (success) {
        
        [Position clearAllPositionsInContext:self.managedObjectContext];
    }
}


@end
