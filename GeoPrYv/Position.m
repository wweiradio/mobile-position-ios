//
//  Position.m
//  AT PrYv
//
//  Created by Nicolas Manzini on 06.12.12.
//  Copyright (c) 2012 PrYv. All rights reserved.
//

#import "Position.h"
#import <CoreLocation/CoreLocation.h>


@implementation Position

@dynamic latitude;
@dynamic longitude;
@dynamic date;
@dynamic uploaded;
@dynamic message;


+ (void)storeLastLocation:(CLLocation *)lastLocation forFutureUploadWithContext:(NSManagedObjectContext *)context {
    
    [Position storeLastLocation:lastLocation withMessage:nil forFutureUploadWithContext:context];
}

+ (void)storeLastLocation:(CLLocation *)lastLocation withMessage:(NSString *)message forFutureUploadWithContext:(NSManagedObjectContext *)context {
    
    Position * position = [NSEntityDescription insertNewObjectForEntityForName:@"Position" inManagedObjectContext:context];
    
    position.latitude = [NSNumber numberWithDouble:lastLocation.coordinate.latitude];
    position.longitude = [NSNumber numberWithDouble:lastLocation.coordinate.longitude];
    position.date = [NSDate date];
    position.message = message;
    position.uploaded = [NSNumber numberWithBool:NO];
    
    [context save:nil];
}

+ (NSMutableArray *)allPositionsInFormatReadyToUploadInContext:(NSManagedObjectContext *)context {
    
    NSFetchRequest * request = [NSFetchRequest fetchRequestWithEntityName:@"Position"];
    
    NSArray * allPosition = [context executeFetchRequest:request error:nil];
        
    if (allPosition == nil || [allPosition count] == 0) {
        
        return nil;
    }
    
    NSMutableArray * list = [NSMutableArray arrayWithCapacity:[allPosition count]];
    
    for (Position * position in allPosition) {
        NSDictionary * event =
        @{@"lat" : position.latitude, @"long" :position.longitude, @"date" : position.date};
        [list addObject:event];
    }
    
    return list;
}

+ (void)clearAllPositionsInContext:(NSManagedObjectContext *)context {
    
    NSArray * allPosition = [Position allPositionsInFormatReadyToUploadInContext:context];
    
    for (Position * position in allPosition) {
        
        [context deleteObject:position];
    }
    
    [context save:nil];
}


@end
