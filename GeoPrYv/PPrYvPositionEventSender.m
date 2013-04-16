//
//  Created by Konstantin Dorodov on 1/7/13.
//  Copyright (c) 2012 PrYv. All rights reserved.
//


#import <CoreData/CoreData.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "PPrYvPositionEventSender.h"
#import "PositionEvent.h"
#import "PPrYvCoreDataManager.h"
#import "EventAttachment.h"
#import "PPrYvApiClient.h"

@interface PPrYvPositionEventSender ()
@end

@implementation PPrYvPositionEventSender

#pragma mark - Class methods

// should batch send all the pending events
+ (void)sendAllPendingEventsToPrYvApi
{
    NSLog(@"--> starting sending out pending events");
    // get all events not uploaded yet and send them to the PrYv API
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"PositionEvent"];

    request.predicate = [NSPredicate predicateWithFormat:@"uploaded == NO"];
    
    NSManagedObjectContext *context = [[PPrYvCoreDataManager sharedInstance] managedObjectContext];
    NSArray *pendingEvents = [context executeFetchRequest:request
                                                    error:nil];
    if (![pendingEvents count]) {
        NSLog(@"--> no pending events found");
        return;
    }

    NSLog(@"--> preparing to send pending events: %d", [pendingEvents count]);
    
    [pendingEvents enumerateObjectsUsingBlock:^(PositionEvent *positionEvent, NSUInteger idx, BOOL *stop) {
        PPrYvPositionEventSender *eventSender = [[PPrYvPositionEventSender alloc] initWithPositionEvent:positionEvent];
        eventSender.notify = NO;
        
        [eventSender sendToPrYvApiCompletion:^{
            if (idx == [pendingEvents count] - 1) {
                NSLog(@"--> just sent the last event");
                
                // FIXME should send a notification only when the last event was sent!
                [[NSNotificationCenter defaultCenter] postNotificationName:kPrYvFinishedSendingLocationNotification
                                                                    object:nil];
                NSLog(@"--> supposedly finished sending out pending events");

            } else {
                NSLog(@"--> sending the event #%d", idx);
            }
        }];
    }];
    
}

#pragma mark - designated initialiser

- (id)initWithPositionEvent:(PositionEvent *)positionEvent
{
    self = [super init];
    if (self) {
        _positionEvent = positionEvent;
        _notify = YES;
    }
    return self;
}

- (void)sendToPrYvApiCompletion:(void(^)(void))completionBlock
{
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
        if (completionBlock)
            completionBlock();
        
        return;
    }
    
    if (self.positionEvent.attachment != nil) {

        /**
         in this application. attachments are only pictures but can be anything you want.
         retrieve the attachment from the picture library
         */
        NSURL *attachmentUrl = [NSURL URLWithString:self.positionEvent.attachment];

        ALAssetsLibrary * assetLibrary = [[ALAssetsLibrary alloc] init];

        [assetLibrary assetForURL:attachmentUrl resultBlock:^(ALAsset *asset) {
            
            UIImage *image     = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullScreenImage]];
            NSData  *imageData = UIImageJPEGRepresentation(image, .5);

            NSString *fileName = [[asset defaultRepresentation] filename];
            if ([[fileName lowercaseString] hasSuffix:@".png"]) {
                fileName = [NSString stringWithFormat:@"%@.jpg", [fileName substringToIndex:[fileName length] - 4]];
            }

            NSString *name = fileName;
            // warning! dots are not allowed in the name of the attachment: delete the last dot with file extension
            NSRange lastOccurenceOfDot = [name rangeOfString:@"." options:NSBackwardsSearch];
            if (lastOccurenceOfDot.location != NSNotFound) {
                name = [name substringToIndex:lastOccurenceOfDot.location];
            }

            // replace all other dots with underscores, just in case
            name = [name stringByReplacingOccurrencesOfString:@"."
                                                   withString:@"_"];

            self.positionEvent.attachmentList = @[ [[EventAttachment alloc] initWithFileData:imageData
                                                                                        name:name
                                                                                    fileName:fileName
                                                                                    mimeType:@"image/jpg"] ];
            [self sendEventCompletion:completionBlock];
        } failureBlock:^(NSError *error) {
            NSLog(@"failed to get image: %@", error);
            NSLog(@"failed to get image from photo library by url: %@, thus not sending this image", attachmentUrl);
            [[[UIAlertView alloc] initWithTitle:nil
                                        message:[NSString stringWithFormat:NSLocalizedString(@"alertDidNotFindImage", ), attachmentUrl]
                                       delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"cancelButton", )
                              otherButtonTitles:nil] show];
            
            if (completionBlock)
                completionBlock();
        }];
    } else {
        [self sendEventCompletion:completionBlock];
    }
}

#pragma mark - PPrYvApiManagerDelegate

- (void)sendEventCompletion:(void(^)(void))completionBlock
{
    void (^eventCompletion)(NSString *eventId, NSError *error) = ^(NSString *eventId, NSError *error) {
        if (eventId) {
            // handle success
            self.positionEvent.uploaded = @YES;
            [self.positionEvent.managedObjectContext save:nil];
        }
        
        if (completionBlock)
            completionBlock();
        
        if (self.notify)
            [[NSNotificationCenter defaultCenter] postNotificationName:kPrYvFinishedSendingLocationNotification
                                                                object:nil];

    };
    
    if (self.positionEvent.message) {
        // send note event
        
        [[PPrYvApiClient sharedClient] sendNoteEvent:self.positionEvent
                                   completionHandler:eventCompletion];
        
    } else if (self.positionEvent.attachmentList) {
        // send picture event
        
        [[PPrYvApiClient sharedClient] sendPictureEvent:self.positionEvent
                                      completionHandler:eventCompletion];

    } else if (self.positionEvent.eventId) {
        // update position event in case eventId is present
        
        [[PPrYvApiClient sharedClient] updateEvent:self.positionEvent completionHandler:eventCompletion];
        
    } else {
        // send position event

        [[PPrYvApiClient sharedClient] sendEvent:self.positionEvent completionHandler:eventCompletion];
    }
}

@end
