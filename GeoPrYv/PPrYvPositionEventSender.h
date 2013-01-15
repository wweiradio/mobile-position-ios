//
//  Created by Konstantin Dorodov on 1/7/13.
//  Copyright (c) 2012 PrYv. All rights reserved.
//


#import <Foundation/Foundation.h>

@class PositionEvent;

@interface PPrYvPositionEventSender : NSObject

@property (nonatomic, strong) PositionEvent *positionEvent;

// whether to send PPrYvFinishedSendingLocationNotification upon sending completion
@property (nonatomic) BOOL notify;

/**
 send all events that are still waiting to be sent to the PrYvAPI
 This will simply call the -sendToPrYvApi method for each PositionEvent instance
 that has not been already uploaded
 */
+ (void)sendAllPendingEventsToPrYvApi;


- (id)initWithPositionEvent:(PositionEvent *)positionEvent;

/**
 This is the method you want to look for to know how we
 create the JSON data and send the position event to the PrYv API
 This is an example Events can hold many other paramaters than those used in this method
*/
- (void)sendToPrYvApi;

@end
