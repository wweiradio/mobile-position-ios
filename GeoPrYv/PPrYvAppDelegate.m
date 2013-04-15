//
//  PPrYvAppDelegate.m
//  AT PrYv
//
//  Created by Nicolas Manzini on 06.12.12.
//  Copyright (c) 2012 PrYv. All rights reserved.
//

#import "PPrYvAppDelegate.h"
#import "PPrYvMapViewController.h"
#import "User+Extras.h"
#import "PPrYvCoreDataManager.h"
#import "PPrYvLocationManager.h"
#import "PPrYvPositionEventSender.h"
#import "PPrYvApiClient.h"
#import "PPrYvOpenUDID.h"
#import "Folder.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "DDFileLogger.h"

@interface PPrYvAppDelegate()

// the map that will show the points.
@property (nonatomic, strong) PPrYvMapViewController * mapViewController;

@property (nonatomic, assign, getter = isSendingPendingEvents) BOOL sendingPendingEvents;

@end

@implementation PPrYvAppDelegate

#pragma mark - Application Life Cycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self setupLogging];
    
    // start core location manager
    [PPrYvLocationManager sharedInstance];

    self.mapViewController = [[PPrYvMapViewController alloc] initWithNibName:@"PPrYvMapViewController"
                                                                      bundle:nil];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = self.mapViewController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    NSLog(@"applicationWillResignActive");
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    NSLog(@"applicationDidEnterBackground");

    [[PPrYvLocationManager sharedInstance] applicationDidEnterBackground:application];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    NSLog(@"applicationWillEnterForeground");

    self.mapViewController.mapView.showsUserLocation = YES;
    [[PPrYvLocationManager sharedInstance] applicationWillEnterForeground:application];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSLog(@"applicationDidBecomeActive");
    
    [self.mapViewController applicationDidBecomeActive];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    NSLog(@"applicationWillTerminate");
    
    [[PPrYvCoreDataManager sharedInstance] saveContext];
}

#pragma mark - private

- (void)setupLogging
{
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
    [fileLogger setRollingFrequency:60 * 60 * 24];   // roll every day
    [fileLogger setMaximumFileSize:1024 * 1024 * 2]; // max 2mb file size
    [fileLogger.logFileManager setMaximumNumberOfLogFiles:7];
    
    [DDLog addLogger:fileLogger];
    
    NSLog(@"Logging is setup (\"%@\")", [fileLogger.logFileManager logsDirectory]);
}
//
//- (void)reportSyncError:(NSError *)error
//{
//    [[[UIAlertView alloc] initWithTitle:nil
//                                message:NSLocalizedString(@"alertCantSynchronize", )
//                               delegate:nil
//                      cancelButtonTitle:NSLocalizedString(@"cancelButton", )
//                      otherButtonTitles:nil] show];
//}

@end
