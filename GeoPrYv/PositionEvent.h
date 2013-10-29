//
//  PositionEvent.h
//  AT PrYv
//
//  Created by Konstantin Dorodov on 1/10/13.
//  Copyright (c) 2013 PrYv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface PositionEvent : NSManagedObject

@property (nonatomic, retain) NSString *attachment;
@property (nonatomic, retain) NSDate   *date;
@property (nonatomic, retain) NSString *streamId;
@property (nonatomic, retain) NSNumber *latitude;
@property (nonatomic, retain) NSNumber *longitude;
@property (nonatomic, retain) NSNumber *elevation;
@property (nonatomic, retain) NSNumber *horizontalAccuracy;
@property (nonatomic, retain) NSNumber *verticalAccuracy;
@property (nonatomic, retain) NSString *message;
@property (nonatomic, retain) NSNumber *uploaded;
@property (nonatomic, retain) NSNumber *duration;
@property (nonatomic, retain) NSNumber *isLastWhenRecording;
@property (nonatomic, retain) NSString *eventId;

// transient array of EventAttachment 
@property (nonatomic, retain) NSArray  *attachmentList;

@end
