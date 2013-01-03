//
//  PPrYvDefaultManager.h
//  AT PrYv
//
//  Created by Nicolas Manzini on 21.12.12.
//  Copyright (c) 2012 PrYv. All rights reserved.
//

/**
 @discussion
 This class provide an easy way to upload events to the RESTful PrYv API using the well known AFNetworking library.
 You can find AFNetworking on github at this address https://github.com/AFNetworking/AFNetworking
 
 On PrYv, Events are sent as JSON Data parameters. Single event can have files attached to them.
 Events can be of differents types. See http://dev.pryv.com/event-types.html
 And http://dev.pryv.com/standard-structure.html
 Each Application uses one Channel and can have multiple folders within this channel
 You have only one channelId per application.
 Visit http://dev.pryv.com/ for the complete documentation on the PrYv API
 */

#import <Foundation/Foundation.h>

// this is the list of al possibly failed action with the PrYv API
typedef enum{
    
    PPrYvFailedSendEvent,
    PPrYvFailedGetEvents,
    PPrYvFailedCreateFolder,
    PPrYvFailedRenameFolder,
    PPrYvFailedSynchronize
    
}PPrYvFailedAction;

@protocol PPrYvDefaultManagerDelegate;

@interface PPrYvDefaultManager : NSObject {
    
    NSTimeInterval serverTimeInterval;
}

@property (strong, nonatomic) NSString * userId;
@property (strong, nonatomic) NSString * oAuthToken;
@property (strong, nonatomic) NSString * channelId;
@property (readonly ,nonatomic) NSTimeInterval serverTimeInterval;

/**
 @discussion
 Allows you to access the DefaultManager
 You must first set the userId, oAuthToken and channelId before
 Communicating with the API using the 
 
 # method
 startManagerWithUserId:oAuthToken:channelId:delegate:
 */
+ (PPrYvDefaultManager *)sharedManager;


/**
 @discussion
 You need to call this method at least once prior to any action with the api. but you can call it as many time as you want.
 You can modify the sharedManager properties during the application lifetime by setting its properties directly.
 
 # delegate
 PPrYvDefaultManagerDidSynchronize;
 */
- (void)startManagerWithUserId:(NSString *)userId
                    oAuthToken:(NSString *)token
                     channelId:(NSString *)channelId
                      delegate:(id<PPrYvDefaultManagerDelegate>)delegate;


/**
 @discussion
 this method simply connect to the PrYv API to retrive the server time in the returned header
 This method will be called when you start the manager
 
 # delegate
 PPrYvDefaultManagerDidSynchronize;
 */
- (void)synchronizeTimeWithServerDelegate:(id<PPrYvDefaultManagerDelegate>)delegate;


/** 
 @discussion
 This convenient method will call
 # method sendEvent:withAttachments:delegate:
 and pass nil to @param attachments. @param event can be an array of events in one JSON data if all events do not have an attachment
 */
- (void)sendEvent:(NSData *)event
         delegate:(id<PPrYvDefaultManagerDelegate>)delegate;


/** 
 Send an event in JSON format with one or more attachments.
 
 @param event must be JSON data
 @param attachments is an array of dictionnaries containing each 3 keys:
 @param key @"file" as the NSData attachment file.
 @param key @"fileName" as the NSString attachment filename.
 @param key @"mimeType" as the NSString attachment file MIME type.
 
 @discussion Pass nil to @param attachments if no attachments
 
 # delegate
 PPrYvDefaultManagerDidSendEvent:
 */
- (void)sendEvent:(NSData *)event
  withAttachments:(NSArray *)attachments
         delegate:(id<PPrYvDefaultManagerDelegate>)delegate;


/**
 @discussion
 get events between two dates, pass nil to both @param startDate and @param endDate to get the last 24h 
 pass nil to @param folderId to get events from all folders in the current channel Id
 */

- (void)getEventsFromStartDate:(NSDate *)startDate
                     toEndDate:(NSDate *)endDate
                    inFolderId:(NSString *)folderId
                      delegate:(id<PPrYvDefaultManagerDelegate>)delegate;

/**
 @discussion
 Create a new folder in the current channel Id
 folders have one unique Id AND one unique name. Both must be unique
 you need to implement both delegate methods as if folder creation failed because of the name it will try to rename the folder
 
 # delegate
 PPrYvDefaultManagerDidCreateFolder:withId:
 PPrYvDefaultManagerDidRenameFolder:withNewName:
 */
- (void)createFolderWithName:(NSString *)folderName
                    folderId:(NSString *)folderId
                    delegate:(id<PPrYvDefaultManagerDelegate>)delegate;


/** 
 @discussion
 Rename an existing folder Id in the current channel Id with a new name
 will append "1" to the folder name if the desired name already exist
 */
- (void)renameFolderId:(NSString *)folderId
           withNewName:(NSString *)newName
              delegate:(id<PPrYvDefaultManagerDelegate>)delegate;

@end

@protocol PPrYvDefaultManagerDelegate <NSObject>

@optional

// sucessfull synchronize callback
- (void)PPrYvDefaultManagerDidSynchronize;

// contain the event that has just been sent
- (void)PPrYvDefaultManagerDidSendEvent:(NSData *)event;

// contain a Foundation Object from the JSON returned by the Server
- (void)PPrYvDefaultManagerDidReceiveEvents:(id)JSON;

// contain the created folder name along with the Id the server gave to this new folder
- (void)PPrYvDefaultManagerDidCreateFolder:(NSString *)folderName withId:(NSString *)folderId;

// contain the newFolderName associated with the folderId
- (void)PPrYvDefaultManagerDidRenameFolder:(NSString *)renamedFolderId withNewName:(NSString *)folderNewName;

/** 
 contain the error and the action type that failed.
 @param failedAction possible PPrYvFailedAction types are listed at the top of this header file in the typedef enum {}PPrYvFailedAction
 */
- (void)PPrYvDefaultManagerDidFail:(PPrYvFailedAction)failedAction withError:(NSError *)error;

@end