//
//  Created by Konstantin Dorodov on 1/4/13.
//  Copyright (c) 2012 PrYv. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "PositionEvent+Extras.h"
#import "PPrYvApiClient.h"

@implementation PositionEvent (Extras)

+ (PositionEvent *)createPositionEventInLocation:(CLLocation *)location
                                     withMessage:(NSString *)message
                                      attachment:(NSURL *)fileURL
                                          folder:(NSString *)folderId
                                       inContext:(NSManagedObjectContext *)context
{
    PositionEvent *positionEvent = [NSEntityDescription insertNewObjectForEntityForName:@"PositionEvent" inManagedObjectContext:context];
    positionEvent.latitude = [NSNumber numberWithDouble:location.coordinate.latitude];
    positionEvent.longitude = [NSNumber numberWithDouble:location.coordinate.longitude];
    positionEvent.elevation = [NSNumber numberWithDouble:location.altitude];
    positionEvent.verticalAccuracy = [NSNumber numberWithDouble:location.verticalAccuracy];
    positionEvent.horizontalAccuracy = [NSNumber numberWithDouble:location.horizontalAccuracy];
    positionEvent.message = message;
    positionEvent.folderId = folderId;
    positionEvent.duration = [NSNumber numberWithDouble:0];
    positionEvent.attachment = [fileURL absoluteString];
    positionEvent.uploaded = [NSNumber numberWithBool:NO];
    positionEvent.date = [NSDate dateWithTimeIntervalSince1970:([[NSDate date] timeIntervalSince1970] - [PPrYvApiClient sharedClient].serverTimeInterval)];
    
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"an error occured when saving a a position event: %@", error);
    }

    return positionEvent;
}

- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@", self.folderId=%@", self.folderId];
    [description appendFormat:@", self.message=%@", self.message];
    [description appendFormat:@", self.attachment=%@", self.attachment];
    [description appendFormat:@", self.latitude=%@", self.latitude];
    [description appendFormat:@", self.longitude=%@", self.longitude];
    [description appendFormat:@", self.elevation=%@", self.elevation];
    [description appendFormat:@", self.verticalAccuracy=%@", self.verticalAccuracy];
    [description appendFormat:@", self.horizontalAccuracy=%@", self.horizontalAccuracy];
    [description appendFormat:@", self.uploaded=%@", self.uploaded];
    [description appendFormat:@", self.duration=%@", self.duration];
    [description appendFormat:@", self.eventId=%@", self.eventId];
    [description appendFormat:@", self.date=%@", self.date];
    [description appendString:@">"];
    return description;
}



@end