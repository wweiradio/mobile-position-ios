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
 Events are sent as JSON data to the PrYv API when connection is available and are stored in our data model as PositionEvent until then.
 Events should contain a folderId parameter to be stored properly on the PrYp Server.
 
 In this application we use a Model Object "PositionEvent" to store new events of type "position" that our locationManager gets.
 We then try to send them to the PrYv API as a new Event.
 
 To retrieve Events from the PrYv API, we specifiy a past period and a folderId. see documentation for additional
 parameters that can be used to obtain more accurate requests.
 
 PrYv is a RESTful API that uses the http methods GET POST PUT DELETE to respectively 
 (GET) get data, (POST)create data, (PUT) modify data and (DELETE) delete data.

 RESTful API means that the URL we connect to and the http method we use define the action we want to do.

 SEE "PositionEvent" class to understand how we create a PrYv Event of type Positon from a CLLocation.
 more information
    see http://pryv.github.com/event-types.html
    see http://pryv.github.com/event-types.html#toc18

 
 SEE "PPrYvApiClient" to understand how we connect to the PrYv RESTful API with AFNetworking
 and send or get events from  specific time period.
 
 SEE http://pryv.github.com/ for the complete documentation on the PrYv API
 */

#import <UIKit/UIKit.h>

@class PPrYvMapViewController;

@interface PPrYvAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;

// the map that will show the points.
@property (nonatomic, strong) PPrYvMapViewController * mapViewController;


@end
