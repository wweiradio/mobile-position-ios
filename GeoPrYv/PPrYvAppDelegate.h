//
//  PPrYvAppDelegate.h
//  AT PrYv
//
//  Created by Nicolas Manzini on 06.12.12.
//  Copyright (c) 2012 PrYv. All rights reserved.
//

/**
 AT PrYv is an application example that uses the PrYv API to store and retrieve Events objects with PrYv.
 In This application we use PrYv to store our location. Each location is an Event on the PrYv API. 
 Events have all a type, value and a time parameters.
 The time parameter is either set by us or automatically by PrYv if none was set.
 Events are sent as JSON data to the PrYv API when connection is available and are stored in our data model as Location until then. 
 Events should contain a folderId parameter to be stored properly on the PrYp Server.
 
 In this application we use a Model Object "Location" to store new locations that our locationManager gets.
 We then try to send them to the PrYv API as a new Event.
 
 To retrieve Events from the PrYv API, we sepcifiy a past period and a folderId. more GETs paramters can be used for more accurate requests.
 
 PrYv is a RESTful API that uses the http methods GET POST PUT DELETE to respectively 
 (GET) get data, (POST)create data, (PUT) modify data and (DELETE) delete data.

 RESTful API means that the URL we connect to and the http method we use define the action we want to do.

 SEE "Location" class to understand how we create a PrYv Event from a CLLocation.
 more information here http://dev.pryv.com/event-types.html
 
 SEE "PPrYvDefaultManager" to understand how we connect to the PrYv RESTful API with AFNetworking
 and send or get events from  specific time period.
 
 SEE http://dev.pryv.com/ for the complete documentation on the PrYv API
 */

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "PPrYvDefaultManager.h"

@class PPrYvMapViewController;

@interface PPrYvAppDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate, PPrYvDefaultManagerDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (readonly, strong, nonatomic) NSManagedObjectModel * managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext * managedObjectContext;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator * persistentStoreCoordinator;

// our background date used as a timer when the application is in background mode to filter locations
@property (nonatomic, strong) NSDate * backgroundDate;
// our foreground timer used when the application is in foreground to filter locations
@property (nonatomic, strong) NSTimer * foregroundTimer;
// the location manager responsible for tracking the location we want to store on the PrYv API
@property (nonatomic, strong) CLLocationManager * mainLocationManager;
// the map that will show the points.
@property (nonatomic, strong) PPrYvMapViewController * mapViewController;
// our foreground timer flag
@property (nonatomic, assign, getter = isForegroundLocationUpdatesAllowed) BOOL foregroundLocationUpdatesAllowed;
// a backgroundTaskIdentifier used when connecting to the PrYv API when the application is in background
// background taskIdentifiers allows you to have extra time to perform a task when the application is in background mode.
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

// called by our foregroundTimer
- (void)allowUpdateNow;


@end
