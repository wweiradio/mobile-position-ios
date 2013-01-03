//
//  Location.h
//  AT PrYv
//
//  Created by Nicolas Manzini on 27.12.12.
//  Copyright (c) 2012 PrYv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "PPrYvDefaultManager.h"

@class CLLocation;

@interface Location : NSManagedObject <PPrYvDefaultManagerDelegate>

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSNumber * uploaded;
@property (nonatomic, retain) NSString * attachment;
@property (nonatomic, retain) NSString * folderId;

/** 
 This is how we create a location object in the application. We then try to send it to PrYv as an Event.
 Pass nil for message if no message pass nil to attachment if no attachment.
*/
+ (Location *)newLocation:(CLLocation *)location
              withMessage:(NSString *)message
               attachment:(NSURL *)fileURL
                   folder:(NSString *)folderId
                inContext:(NSManagedObjectContext *)context;

/**
 send all events that are still waiting to be sent to the PrYvAPI
 This will simply call the -sendToPrYvAPI method on each Location instance
 that has not been already uploaded
 */
+ (void)sendAllPendingEventsToPrYvAPIInContext:(NSManagedObjectContext *)context;


/** 
 This is the method you want to look for to know how we
 create the JSON data and send the location to the PrYv API
 This is an example Events can hold many other paramaters than those used in this method
*/
- (void)sendToPrYvAPI;

@end
