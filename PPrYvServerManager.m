//
//  PPrYvServerManager.m
//  AT PrYv
//
//  Created by Nicolas Manzini on 10.12.12.
//  Copyright (c) 2012 PrYv. All rights reserved.
//

#import "PPrYvServerManager.h"
#import <CoreLocation/CoreLocation.h>
#import "PPrYvOpenUDID.h"
#import "Position.h"

// Development only kVars
#define kPrYvAuthToken @"VVEQmJD5T5"
#define kPrYvUser @"jonmaim"
#define kdevelopmentChannel @"VeA4Yv9RiM"

/**
 REQUIRED IMPORTS
 #import <CoreLocation/CoreLocation.h>
 #import "PPrYvOpenUDID.h"
 #import "AFNetworking.h"
 */

@implementation PPrYvServerManager

#pragma mark - methods for connecting to PrYv API

+ (void)checkOrCreateServerMainFolder:(NSString *)folderName delegate:(id<PPrYvServerManagerDelegate>)delegate {
    
    NSDictionary * folderInfos = @{@"name":folderName, @"id" : [PPrYvOpenUDID value]};
    
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@.rec.la/%@/folders",kPrYvUser,kdevelopmentChannel]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setAllHTTPHeaderFields:@{@"Authorization" : kPrYvAuthToken, @"Content-Type" : @"application/json"}];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:folderInfos options:0 error:nil];
        
    AFJSONRequestOperation * operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        // custom way to store the information about the folder that the folder is available for future uploads
        [[NSUserDefaults standardUserDefaults] setObject:folderName forKey:kUserDefaultsCurrentUserFolder];
        [[NSUserDefaults standardUserDefaults] setObject:[PPrYvOpenUDID value] forKey:kUserDefaultsCurrentUserFolderId];
        NSLog(@"folder created sucessfully");
        
        if([delegate respondsToSelector:@selector(PPrYvServerManagerDidCreateMainFolderSucessfully:)]) {
            
            [delegate PPrYvServerManagerDidCreateMainFolderSucessfully:YES];
        }
                
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                
        if ([[JSON objectForKey:@"id"] isEqualToString:@"ITEM_NAME_ALREADY_EXISTS"]) {
            
            // custom way to store the information about the folder that the folder is available for future uploads
            [[NSUserDefaults standardUserDefaults] setObject:folderName forKey:kUserDefaultsCurrentUserFolder];
            [[NSUserDefaults standardUserDefaults] setObject:[PPrYvOpenUDID value] forKey:kUserDefaultsCurrentUserFolderId];
            
            NSLog(@"item id already exist... renaming it");
            [PPrYvServerManager renameFolder:[PPrYvOpenUDID value] withName:folderName];
            
            if([delegate respondsToSelector:@selector(PPrYvServerManagerDidCreateMainFolderSucessfully:)]) {
                
                [delegate PPrYvServerManagerDidCreateMainFolderSucessfully:YES];
            }
        }
        else if ([[JSON objectForKey:@"id"] isEqualToString:@"ITEM_ID_ALREADY_EXISTS"]) {
            
            [[NSUserDefaults standardUserDefaults] setObject:folderName forKey:kUserDefaultsCurrentUserFolder];
            [[NSUserDefaults standardUserDefaults] setObject:[PPrYvOpenUDID value] forKey:kUserDefaultsCurrentUserFolderId];
            
            NSLog(@"item id already exist... renaming it");
            [PPrYvServerManager renameFolder:[PPrYvOpenUDID value] withName:folderName];
        }
        else{
            
            if([delegate respondsToSelector:@selector(PPrYvServerManagerDidCreateMainFolderSucessfully:)]) {
                
                [delegate PPrYvServerManagerDidCreateMainFolderSucessfully:NO];
            }
        }
    }];
    [operation start];
}

+ (void)renameFolder:(NSString *)folderId withName:(NSString *)newName {
    
    NSDictionary * folderInfos = @{@"name": newName};

    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@.rec.la/%@/folders/%@",kPrYvUser,kdevelopmentChannel,folderId]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setAllHTTPHeaderFields:@{@"Authorization" : kPrYvAuthToken, @"Content-Type" : @"application/json"}];
    request.HTTPMethod = @"PUT";
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:folderInfos options:0 error:nil];
    
    AFJSONRequestOperation * operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];

        // custom way to store the information about the folder that the folder is available for future uploads
        [[NSUserDefaults standardUserDefaults] setObject:newName forKey:kUserDefaultsCurrentUserFolder];
        NSLog(@"did rename folder");
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                
        if ([[JSON objectForKey:@"id"] isEqualToString:@"ITEM_NAME_ALREADY_EXISTS"]) {
            
            [PPrYvServerManager renameFolder:folderId withName:[newName stringByAppendingString:@"1"]];
            NSLog(@"did fail rename folder");

        }
    }];
    [operation start];
}

+ (void)uploadNewEventOfTypeLocation:(CLLocation *)newLocation onFailSaveInContext:(NSManagedObjectContext *)context isBackgroundTask:(UIBackgroundTaskIdentifier)backgroundTask {
    
    NSDictionary * serverJSONFormatedLocation =
    @{@"type": @{
    @"class" : @"position", @"format": @"wgs84"
    },
    @"value": @{
    @"location" : @{
    @"lat": [NSNumber numberWithDouble:newLocation.coordinate.latitude],
    @"long": [NSNumber numberWithDouble:newLocation.coordinate.longitude]
    }
    },
    @"folderId" : [PPrYvOpenUDID value]
    };
    
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@.rec.la/%@/events",kPrYvUser,kdevelopmentChannel]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setAllHTTPHeaderFields:@{@"Authorization" : kPrYvAuthToken, @"Content-Type" : @"application/json"}];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:serverJSONFormatedLocation options:0 error:nil];
    
    AFJSONRequestOperation * operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        NSDictionary * headers = [response allHeaderFields];
        NSString * serverTime = [headers objectForKey:@"Server-Time"];
        NSLog(@"Server Time: %@",serverTime);
        NSLog(@"Local Time: %@", [NSDate date]);
        NSLog(@"%@",[PPrYvOpenUDID value]);
        
        if (backgroundTask != 0) {
            
            [[UIApplication sharedApplication] endBackgroundTask:backgroundTask];
        }
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON){
                
        // Make your own implementatiton to store the data that failed to upload
        [Position storeLastLocation:newLocation forFutureUploadWithContext:context];
        
        if (backgroundTask != 0) {
            
            [[UIApplication sharedApplication] endBackgroundTask:backgroundTask];
        }
    }];
    [operation start];
}

+ (void)uploadBatchEventsOfTypeLocations:(NSArray *)allEvents successDelegate:(id<PPrYvServerManagerDelegate>)delegate {
    
    NSMutableArray * allEventForServer = [NSMutableArray arrayWithCapacity:[allEvents count]];
    
    for (NSDictionary * event in allEvents) {
        
        NSDictionary * newEvent =
        @{@"type": @{
        @"class" : @"position", @"format": @"wgs84"
        },
        @"value": @{
        @"location" : @{
        @"lat": [event objectForKey:@"lat"],
        @"long": [event objectForKey:@"long"],
        }
        },
        @"folderId" : [PPrYvOpenUDID value],
        @"time" : [NSNumber numberWithDouble:[(NSDate *)[event objectForKey:@"date"] timeIntervalSince1970]]
        };
        
        [allEventForServer addObject:newEvent];
    }
    
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:allEventForServer options:NSJSONReadingMutableContainers error:nil];
    
    if (jsonData == nil) {
        
        NSLog(@"JSON INVALID");
        return;
    }
    
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@.rec.la/%@/events",kPrYvUser,kdevelopmentChannel]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setAllHTTPHeaderFields:@{@"Authorization" : kPrYvAuthToken, @"Content-Type" : @"application/json"}];
    request.HTTPMethod = @"POST";
    request.HTTPBody = jsonData;
    
    AFJSONRequestOperation * operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        if ([delegate respondsToSelector:@selector(PPrYvServerManagerDidFinishUploadBatchSuccessfully:)]) {
            
            [delegate PPrYvServerManagerDidFinishUploadBatchSuccessfully:YES];
        }
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON){

        if ([delegate respondsToSelector:@selector(PPrYvServerManagerDidFinishUploadBatchSuccessfully:)]) {
            
            [delegate PPrYvServerManagerDidFinishUploadBatchSuccessfully:NO];
        }
    }];
    [operation start];
}

+ (void)uploadNewEventOfTypeLocation:(CLLocation *)newLocation messageAttached:(NSString *)message onFailSaveInContext:(NSManagedObjectContext *)context {
    
    NSDictionary * formatedLocation =
    @{@"type": @{
        @"class" : @"position", @"format": @"wgs84"
        },
        @"value": @{
        @"location" : @{
            @"lat": [NSNumber numberWithDouble:newLocation.coordinate.latitude],
            @"long": [NSNumber numberWithDouble:newLocation.coordinate.longitude]
            },
        @"message" : message
        },
    @"folderId" : [PPrYvOpenUDID value]
    };
    
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@.rec.la/%@/events",kPrYvUser,kdevelopmentChannel]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setAllHTTPHeaderFields:@{@"Authorization" : kPrYvAuthToken, @"Content-Type" : @"application/json"}];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:formatedLocation options:0 error:nil];
    
    AFJSONRequestOperation * operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON){
        
        // Replace this by your custom implementation to store events for later upload
        [Position storeLastLocation:newLocation forFutureUploadWithContext:context];
    }];
    [operation start];
}

+ (void)uploadNewEventOfTypeLocation:(CLLocation *)newLocation imageAttached:(NSData *)imageData optionalMessageAttached:(NSString *)message onFailSaveInContext:(NSManagedObjectContext *)context {
    
    NSString * imageName = @"nouvelleImage.jpg";
    
    NSDictionary * formatedLocation =
    @{@"type": @{
    @"class" : @"position", @"format": @"wgs84"
    },
    @"value": @{
    @"location" : @{
    @"lat": [NSNumber numberWithDouble:newLocation.coordinate.latitude],
    @"long": [NSNumber numberWithDouble:newLocation.coordinate.longitude]
    },
    @"message" : message
    },
    @"folderId" : [PPrYvOpenUDID value],
    };
    
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:formatedLocation options:0 error:nil];

    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@.rec.la/%@/events",kPrYvUser,kdevelopmentChannel]];
    
    AFHTTPClient * client =[[AFHTTPClient alloc] initWithBaseURL:url];
    [client setDefaultHeader:@"Authorization" value:kPrYvAuthToken];
    
    NSURLRequest *request = [client multipartFormRequestWithMethod:@"POST" path:nil parameters:nil constructingBodyWithBlock: ^(id <AFMultipartFormData> formData) {
        
        [formData appendPartWithFormData:jsonData name:@"event"];
        [formData appendPartWithFileData:imageData name:@"firstImage" fileName:imageName mimeType:@"image/jpg"];
    }];
        
    AFJSONRequestOperation * operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        NSLog(@"success");
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        // make your own implementation here to store the position with image for future upload
        NSLog(@"%@",error);
    }];
    [operation start];
}

+ (void)downloadEventOfTypeLocationBeginningDate:(NSDate *)beginningDate toEndDate:(NSDate *)endDate dataReceiverDelegate:(id<PPrYvServerManagerDelegate>)aDelegate {
    
    NSURL * url = nil;
    NSString * folderId = [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsCurrentUserFolderId];
    
    if (beginningDate != nil && endDate != nil) {
        
        NSString * timeStampBeginning = [[NSNumber numberWithDouble:[beginningDate timeIntervalSince1970]] stringValue];
        NSString * timeStampEnd = [[NSNumber numberWithDouble:[endDate timeIntervalSince1970]] stringValue];

        url = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@.rec.la/%@/events?fromTime=%@&toTime=%@&onlyFolders[]=%@&limit=1200", kPrYvUser, kdevelopmentChannel, timeStampBeginning, timeStampEnd, folderId]];
    }
    else {
        
        url = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@.rec.la/%@/events?onlyFolders[]=%@", kPrYvUser, kdevelopmentChannel, folderId]];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setAllHTTPHeaderFields:@{@"Authorization" : kPrYvAuthToken}];
    request.HTTPMethod = @"GET";
    
    AFJSONRequestOperation * operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        if ([aDelegate respondsToSelector:@selector(PPrYvServerManagerDidReceiveAllLocations:)]) {
            
            [aDelegate PPrYvServerManagerDidReceiveAllLocations:JSON];
        }
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON){
                
        if ([aDelegate respondsToSelector:@selector(PPrYvServerManagerDidReceiveAllLocations:)]) {
            
            [aDelegate PPrYvServerManagerDidReceiveAllLocations:nil];
        }
    }];
    [operation start];
}

@end
