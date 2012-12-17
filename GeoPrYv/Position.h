//
//  Position.h
//  AT PrYv
//
//  Created by Nicolas Manzini on 06.12.12.
//  Copyright (c) 2012 PrYv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CLLocation;


@interface Position : NSManagedObject

@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSNumber * uploaded;
@property (nonatomic, retain) NSString * message;


// store a new position to the database in the current context
+ (void)storeLastLocation:(CLLocation *)lastLocation forFutureUploadWithContext:(NSManagedObjectContext *)context;

// store a new postion with a message in the current context
+ (void)storeLastLocation:(CLLocation *)lastLocation withMessage:(NSString *)message forFutureUploadWithContext:(NSManagedObjectContext *)context;

// return all pending upload positionss
+ (NSMutableArray *)allPositionsInFormatReadyToUploadInContext:(NSManagedObjectContext *)context;

// clear all positions in current context
+ (void)clearAllPositionsInContext:(NSManagedObjectContext *)context;


@end
