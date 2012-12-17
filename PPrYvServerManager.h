//
//  PPrYvServerManager.h
//  AT PrYv
//
//  Created by Nicolas Manzini on 10.12.12.
//  Copyright (c) 2012 PrYv. All rights reserved.
//
//  This class help upload location on PrYv API with a message and/or an image attached to it
//  On the current user channel

#import <Foundation/Foundation.h>

/**
 
 `PPrYvServerManager` is a helper class based on AFNetworking that simplify upload and download of events of type Location to the PrYv API
 
 */

@class CLLocation;

@protocol PPrYvServerManagerDelegate;

@interface PPrYvServerManager : NSObject

// This method creates or check the existance of a main folder for the current device on the PrYv server side
// After calling this method you can direcly test for
// [[NSUserDefaults standardUserDefaults] objectForKey:@"currentUserFolder"] != nil
// To know if the folder has been sucessfully created and get its name
// this function will create or check for a folder with an Id based on the OpenUDID value
// This method must be called suessfully at least once before you can upload events to the server
// you can optionaly pass a delegate to be inform on success or failure. Pass nil if no delegate

+ (void)checkOrCreateServerMainFolder:(NSString *)folderName delegate:(id<PPrYvServerManagerDelegate>)delegate;


// Rename an existing folder

+ (void)renameFolder:(NSString *)folderId withName:(NSString *)newName;


// This method uploads new locations for the simple tracking mode while in foreground or background
// Pass 0 for backgroundTask if not in background
// Starting a backgroundTask ensure the service will have the time to connect to the server while in background
// You must start a BackgroundTask in your location manager delegate before calling
// This method and pass it the backgroundTaskIdentifier you created.

+ (void)uploadNewEventOfTypeLocation:(CLLocation *)newLocation onFailSaveInContext:(NSManagedObjectContext *)context isBackgroundTask:(UIBackgroundTaskIdentifier)backgroundTask;


// This method allows you to upload an array of events of type location
// Each event must be a dictionary with the 3 required following keys:
// key @"lat" value NSNumber,
// key @"long" value NSNumber,
// key @"date" value NSDate

+ (void)uploadBatchEventsOfTypeLocations:(NSArray *)allEvents successDelegate:(id<PPrYvServerManagerDelegate>)delegate;


// This method uploads new locations and attaches a message to it. Should be called only while application is in foreground

+ (void)uploadNewEventOfTypeLocation:(CLLocation *)newLocation messageAttached:(NSString *)message onFailSaveInContext:(NSManagedObjectContext *)context;


// This method uploads new locations and attaches an image to it. Should be called only while application is in foreground

+ (void)uploadNewEventOfTypeLocation:(CLLocation *)newLocation imageAttached:(NSData *)imageData optionalMessageAttached:(NSString *)message onFailSaveInContext:(NSManagedObjectContext *)context;


// This method downloads a time period locations.
// If you pass nil to both beginningDate and endDate the server will return the last 24h

+ (void)downloadEventOfTypeLocationBeginningDate:(NSDate *)beginningDate toEndDate:(NSDate *)endDate dataReceiverDelegate:(id<PPrYvServerManagerDelegate>)aDelegate;


@end

@protocol PPrYvServerManagerDelegate <NSObject>

@optional

// Returns the locations downloaded from the server or nil if an error occurs

- (void)PPrYvServerManagerDidReceiveAllLocations:(NSDictionary *)locations;


// Inform the delegate that the folder exist and is available for future use

- (void)PPrYvServerManagerDidCreateMainFolderSucessfully:(BOOL)success;


// Inform the delegate if the batch upload has been sucessfull
// You would typically use this delegate to know if you can clean your locally stored data

- (void)PPrYvServerManagerDidFinishUploadBatchSuccessfully:(BOOL)success;


@end