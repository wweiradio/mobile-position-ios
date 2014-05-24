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
                                          folder:(NSString *)streamId
                                       inContext:(NSManagedObjectContext *)context
{
    PositionEvent *positionEvent = [NSEntityDescription insertNewObjectForEntityForName:@"PositionEvent" inManagedObjectContext:context];
    positionEvent.latitude = [NSNumber numberWithDouble:location.coordinate.latitude];
    positionEvent.longitude = [NSNumber numberWithDouble:location.coordinate.longitude];
    positionEvent.elevation = [NSNumber numberWithDouble:location.altitude];
    positionEvent.verticalAccuracy = [NSNumber numberWithDouble:location.verticalAccuracy];
    positionEvent.horizontalAccuracy = [NSNumber numberWithDouble:location.horizontalAccuracy];
    positionEvent.message = message;
    positionEvent.streamId = streamId;
    positionEvent.duration = [NSNumber numberWithDouble:0];
    positionEvent.attachment = [fileURL absoluteString];
    positionEvent.uploaded = @NO;
    NSDate* date = [NSDate date];
    positionEvent.date = date;
    
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"an error occured when saving a position event: %@", error);
    }

    return positionEvent;
}

+ (void)resetLastRecordingEventsInContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"PositionEvent"];
    request.predicate = [NSPredicate predicateWithFormat:@"isLastWhenRecording == YES"];
    
    NSArray *lastEvents = [context executeFetchRequest:request
                                                 error:nil];
    if (![lastEvents count]) {
        NSLog(@"--> no last events were found");
        return;
    }
    for (PositionEvent *positionEvent in lastEvents) {
        positionEvent.isLastWhenRecording = @NO;
    }
    
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"an error occured when finishing recording state: %@", error);
    }
}

+ (PositionEvent *)lastPositionEventIfRecording:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"PositionEvent"];
    request.predicate = [NSPredicate predicateWithFormat:@"isLastWhenRecording == YES"];
    request.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES] ];
    
    NSArray *lastEvents = [context executeFetchRequest:request
                                                 error:nil];
    return [lastEvents lastObject];
}

+ (void)deleteSentPositionEventsInContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"PositionEvent"];
    
    request.predicate = [NSPredicate predicateWithFormat:@"uploaded == YES"];
    [request setIncludesPropertyValues:NO]; //only fetch the managedObjectID

    NSArray *uploadedEvents = [context executeFetchRequest:request
                                                     error:nil];

    if (!uploadedEvents) {
        //error handling goes here
        return;
    }
    for (NSManagedObject *entity in uploadedEvents) {
        [context deleteObject:entity];
    }
    
    NSError *saveError = nil;
    if (![context save:&saveError]) {
        NSLog(@"failed to save the context %@", saveError);
    }
}

- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@", self.streamId=%@", self.streamId];
    [description appendFormat:@", self.message=%@", self.message];
    [description appendFormat:@", self.attachment=%@", self.attachment];
    [description appendFormat:@", self.latitude=%@", self.latitude];
    [description appendFormat:@", self.longitude=%@", self.longitude];
    [description appendFormat:@", self.elevation=%@", self.elevation];
    [description appendFormat:@", self.verticalAccuracy=%@", self.verticalAccuracy];
    [description appendFormat:@", self.horizontalAccuracy=%@", self.horizontalAccuracy];
    [description appendFormat:@", self.uploaded=%@", self.uploaded];
    [description appendFormat:@", self.duration=%@", self.duration];
    [description appendFormat:@", self.isLastWhenRecording=%@", self.isLastWhenRecording];
    [description appendFormat:@", self.eventId=%@", self.eventId];
    [description appendFormat:@", self.date=%@", self.date];
    [description appendString:@">"];
    return description;
}



@end