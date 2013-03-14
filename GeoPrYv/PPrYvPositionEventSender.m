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
- (void)notifyFinishing;
@end

@implementation PPrYvPositionEventSender {
}

@synthesize notify = _notify;
@synthesize positionEvent = _positionEvent;

+ (void)sendAllPendingEventsToPrYvApi
{
    // get all events not uploaded yet and send them to the PrYv API
    NSFetchRequest * request = [NSFetchRequest fetchRequestWithEntityName:@"PositionEvent"];

    request.predicate = [NSPredicate predicateWithFormat:@"uploaded == NO"];
    NSArray * pendingEvents = [[[PPrYvCoreDataManager sharedInstance] managedObjectContext] executeFetchRequest:request
                                                                                                          error:nil];

    if (![pendingEvents count]) {
        return;
    }

    for (PositionEvent *positionEvent in pendingEvents) {
        PPrYvPositionEventSender *eventSender = [[PPrYvPositionEventSender alloc] initWithPositionEvent:positionEvent];
        eventSender.notify = NO;
        [eventSender sendToPrYvApi];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:kPrYvFinishedSendingLocationNotification
                                                        object:nil];
}

- (id)initWithPositionEvent:(PositionEvent *)positionEvent
{
    self = [super init];
    if (self) {
        _positionEvent = positionEvent;
        _notify = YES;
    }
    return self;
}

- (void)sendToPrYvApi
{
    assert([UIApplication sharedApplication].applicationState != UIApplicationStateBackground);

    __block NSArray *attachmentList = nil;
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

            attachmentList = @[[[EventAttachment alloc] initWithFileData:imageData
                                                                    name:name
                                                                fileName:fileName
                                                                mimeType:@"image/jpg"]];

            self.positionEvent.attachmentList = attachmentList;
            [self sendEvent];
        } failureBlock:^(NSError *error) {
            NSLog(@"failed to get image from photo library by url: %@, thus not sending this image", attachmentUrl);
            [[[UIAlertView alloc] initWithTitle:nil
                                        message:[NSString stringWithFormat:NSLocalizedString(@"alertDidNotFindImage", ), attachmentUrl]
                                       delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"cancelButton", )
                              otherButtonTitles:nil] show];
        }];
    } else {
        [self sendEvent];
    }
}

#pragma mark - PPrYvApiManagerDelegate

- (void)sendEvent
{
    [[PPrYvApiClient sharedClient] sendEvent:self.positionEvent withSuccessHandler:^{
        [self didSentEvent];
    } errorHandler:^(NSError *error){
        if (self.notify)
            [self notifyFinishing];
    }];
}

- (void)didSentEvent
{
    self.positionEvent.uploaded = [NSNumber numberWithBool:YES];
    [self.positionEvent.managedObjectContext save:nil];

    if (self.notify)
        [self notifyFinishing];
}

- (void)notifyFinishing
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kPrYvFinishedSendingLocationNotification
                                                        object:nil];
}

@end