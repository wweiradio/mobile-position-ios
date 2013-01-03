//
//  Location.m
//  AT PrYv
//
//  Created by Nicolas Manzini on 27.12.12.
//  Copyright (c) 2012 PrYv. All rights reserved.
//

#import "Location.h"
#import <CoreLocation/CoreLocation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "PPrYvAppDelegate.h"

@implementation Location

@dynamic date;
@dynamic latitude;
@dynamic longitude;
@dynamic message;
@dynamic uploaded;
@dynamic attachment;
@dynamic folderId;


+ (Location *)newLocation:(CLLocation *)location
              withMessage:(NSString *)message
               attachment:(NSURL *)fileURL
                   folder:(NSString *)folderId
                inContext:(NSManagedObjectContext *)context
{
    Location * newLocation = [NSEntityDescription insertNewObjectForEntityForName:@"Location" inManagedObjectContext:context];
    newLocation.latitude = [NSNumber numberWithDouble:location.coordinate.latitude];
    newLocation.longitude = [NSNumber numberWithDouble:location.coordinate.longitude];
    newLocation.message = message;
    newLocation.folderId = folderId;
    newLocation.attachment = [fileURL absoluteString];
    newLocation.uploaded = [NSNumber numberWithBool:NO];
    newLocation.date = [NSDate dateWithTimeIntervalSince1970:([[NSDate date] timeIntervalSince1970] - [PPrYvDefaultManager sharedManager].serverTimeInterval)];
    
    [context save:nil];
    
    return newLocation;
}

+ (void)sendAllPendingEventsToPrYvAPIInContext:(NSManagedObjectContext *)context {
    
    // get all events not uploaded yet and send them to the PrYv API
    NSFetchRequest * request = [NSFetchRequest fetchRequestWithEntityName:@"Location"];
    request.predicate = [NSPredicate predicateWithFormat:@"uploaded == NO"];
    NSArray * pendingEvents = [context executeFetchRequest:request error:nil];
    
    if (![pendingEvents count]) {
        
        return;
    }
        
    for (Location * location in pendingEvents) {
        
        [location sendToPrYvAPI];
    }
}

- (void)sendToPrYvAPI {
    
    if ([self.uploaded boolValue]) {
        
        // if already uploaded return
        return;
    }
    
    // set empty message if no message
    NSString * message = self.message == nil ? @"" : self.message;
    
    // turn the date into server format time
    NSNumber * time = [NSNumber numberWithDouble:[self.date timeIntervalSince1970]];
    
    /** 
     Create the data for the server
     This is an exmaple on how to create the JSON you need to send to the PrYv API to create a new event
     Some parameters are required such as the parameter type, class, format, value. message is optional here, folderId also
     and time will be set by the server if you dont put it yourself.
     SEE http://pryv.github.com/reference.html#data-structure-event for exact documentation.
     
     */
    id foundationObject =
    @{
    @"type":
        @{
        @"class" : @"position", @"format": @"wgs84"
        },
    @"value":
        @{
        @"location" :
            @{
            @"lat": self.latitude,
            @"long": self.longitude
            },
        @"message" : message
        },
    @"folderId" : self.folderId,
    @"time" : time
    };
    
    // turn the foundation object into a JSON ready to be uploaded to PrYv
    NSData * eventData = [NSJSONSerialization dataWithJSONObject:foundationObject options:0 error:nil];
    
    if (self.attachment != nil) {
        
        /** 
         in this application. attachments are only pictures but can be anything you want.
         retrieve the attachment from the picture library
         */
        NSURL * url = [NSURL URLWithString:self.attachment];
        
        ALAssetsLibrary * assetLibrary = [[ALAssetsLibrary alloc] init];

        [assetLibrary assetForURL:url resultBlock:^(ALAsset *asset) {
            
            UIImage * image = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullScreenImage]];
            NSData * imageData = UIImageJPEGRepresentation(image, .5);
            
            NSArray * attachments =
            @[
            @{
            @"file" : imageData,
            @"fileName" : [[asset defaultRepresentation] filename],
            @"mimeType" : @"image/jpg"
            }
            ];
            // this is the call that will send the location with the attachment
            [[PPrYvDefaultManager sharedManager] sendEvent:eventData withAttachments:attachments delegate:self];
            
        } failureBlock:^(NSError *error) {
            
            // handle the error here
            NSLog(@"failed to get image");
        }];
    }
    else {
        // this is the call that will send the event without attachment
        [[PPrYvDefaultManager sharedManager] sendEvent:eventData delegate:self];
    }
}

#pragma mark - PPrYvDefaultManager Delegate

- (void)PPrYvDefaultManagerDidSendEvent:(NSData *)event {
    
    self.uploaded = [NSNumber numberWithBool:YES];
    
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
    
        UIBackgroundTaskIdentifier token = [(PPrYvAppDelegate *)[UIApplication sharedApplication].delegate backgroundTaskIdentifier];
        
        [[UIApplication sharedApplication] endBackgroundTask:token];
        [(PPrYvAppDelegate *)[UIApplication sharedApplication].delegate setBackgroundTaskIdentifier:UIBackgroundTaskInvalid];
    }
}

- (void)PPrYvDefaultManagerDidFail:(PPrYvFailedAction)failedAction withError:(NSError *)error {
    
    if (failedAction == PPrYvFailedSendEvent) {
        
    }
    
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        
        UIBackgroundTaskIdentifier token = [(PPrYvAppDelegate *)[UIApplication sharedApplication].delegate backgroundTaskIdentifier];
        
        [[UIApplication sharedApplication] endBackgroundTask:token];
        [(PPrYvAppDelegate *)[UIApplication sharedApplication].delegate setBackgroundTaskIdentifier:UIBackgroundTaskInvalid];
    }

}

@end
