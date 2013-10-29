//
//  Created by Konstantin Dorodov on 1/4/13.
//  Copyright (c) 2012 PrYv. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "PositionEvent.h"

@class CLLocation;

@interface PositionEvent (Extras)

/**
 This is how we create a location object in the application. We then try to send it to PrYv as an Event.
 Pass nil for message if no message pass nil to attachment if no attachment.
*/
+ (PositionEvent *)createPositionEventInLocation:(CLLocation *)location
                                     withMessage:(NSString *)message
                                      attachment:(NSURL *)fileURL
                                          folder:(NSString *)streamId
                                       inContext:(NSManagedObjectContext *)context;


+ (void)resetLastRecordingEventsInContext:(NSManagedObjectContext *)context;

+ (PositionEvent *)lastPositionEventIfRecording:(NSManagedObjectContext *)context;

+ (void)deleteSentPositionEventsInContext:(NSManagedObjectContext *)context;

@end