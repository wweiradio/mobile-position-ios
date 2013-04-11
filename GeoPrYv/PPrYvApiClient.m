//
//  PPrYvApiClient.m
//  AT PrYv
//
//  Created by Nicolas Manzini on 21.12.12.
//  Copyright (c) 2012 PrYv. All rights reserved.
//


#import "PPrYvApiClient.h"
#import "AFNetworking.h"
#import "EventAttachment.h"
#import "Folder.h"
#import "PositionEvent.h"
#import "PPrYvCoreDataManager.h"

# pragma mark - Folder JSON serialisation

@interface Folder (JSON)

+ (Folder *)folderFromJSON:(id)json;

@end

@implementation Folder (JSON)

+ (Folder *)folderFromJSON:(id)JSON
{
    NSDictionary *jsonDictionary = JSON;
    Folder *folder = [[Folder alloc] init];
    folder.folderId = [jsonDictionary objectForKey:@"id"];
    folder.name = [jsonDictionary objectForKey:@"name"];
    folder.parentId = [jsonDictionary objectForKey:@"parentId"];
    folder.hidden = [[jsonDictionary objectForKey:@"hidden"] boolValue];
    folder.trashed = [[jsonDictionary objectForKey:@"trashed"] boolValue];
    return folder;
}

@end

# pragma mark - PositionEvent JSON serialisation

@interface PositionEvent (JSON)

// TODO rename and move somewhere else

+ (PositionEvent *)positionEventFromDictionary:(NSDictionary *)positionEventDictionary inScratchContext:(NSManagedObjectContext *)scratchManagedObjectContext;

- (NSData *)dataWithJSONObject;
- (NSData *)noteEventWithJSONObject;

@end

@implementation PositionEvent (JSON)

+ (PositionEvent *)positionEventFromDictionary:(NSDictionary *)positionEventDictionary inScratchContext:(NSManagedObjectContext *)scratchManagedObjectContext
{
    PositionEvent *positionEvent = [NSEntityDescription insertNewObjectForEntityForName:@"PositionEvent"
                                                                 inManagedObjectContext:scratchManagedObjectContext];

    double latitude = [[[positionEventDictionary objectForKey:@"value"] objectForKey:@"latitude"] doubleValue];
    double longitude = [[[positionEventDictionary objectForKey:@"value"] objectForKey:@"longitude"] doubleValue];
    NSString *folderId = [positionEventDictionary objectForKey:@"folderId"];
    double time = [[positionEventDictionary objectForKey:@"time"] doubleValue];
    
    if ([positionEventDictionary[@"value"] objectForKey:@"altitude"]) {
        double elevation = [positionEventDictionary[@"value"][@"altitude"] doubleValue];
        positionEvent.elevation = [NSNumber numberWithDouble:elevation];
    }

    positionEvent.latitude = [NSNumber numberWithDouble:latitude];
    positionEvent.longitude = [NSNumber numberWithDouble:longitude];
    positionEvent.folderId = folderId;
    positionEvent.eventId = positionEventDictionary[@"id"];
    positionEvent.duration = [NSNumber numberWithDouble:[[positionEventDictionary objectForKey:@"duration"] doubleValue]];
    positionEvent.uploaded = @YES; // do not try to upload it
    positionEvent.message = [positionEventDictionary objectForKey:@"description"];
    positionEvent.date = [NSDate dateWithTimeIntervalSince1970:time];

    return positionEvent;
}

// FIXME remove message from position event
- (NSData *)dataWithJSONObject
{
    // set empty message if no message
    NSString * message = self.message == nil ? @"" : self.message;

    // turn the date into server format time
    NSNumber * time = [NSNumber numberWithDouble:[self.date timeIntervalSince1970]];

    NSDictionary *positionEventDictionary =
                         @{
                                 @"type" :
                                 @{
                                         @"class" : @"position",
                                         @"format" : @"wgs84"
                                 },
                                 @"value" :
                                 @{
                                         @"longitude" : self.longitude,
                                         @"latitude" : self.latitude,
                                         @"verticalAccuracy" : self.horizontalAccuracy,
                                         @"horizontalAccuracy" : self.verticalAccuracy,
                                         @"elevation" : self.elevation
                                 },
                                 @"description" : message,
                                 @"folderId" : self.folderId,
                                 @"time" : time
                         };

    NSData *result = [NSJSONSerialization dataWithJSONObject:positionEventDictionary options:0 error:nil];

    NSAssert(result != nil, @"Unsuccessful json creation from position event");
    NSAssert(result.length > 0, @"Unsuccessful json creation from position event");

    return result;
}

- (NSData *)noteEventWithJSONObject
{
    NSString * message = self.message;
    
    // turn the date into server format time
    NSNumber * time = [NSNumber numberWithDouble:[self.date timeIntervalSince1970]];
    
    NSDictionary *noteEventDictionary =
    @{
      @"type" :
          @{
              @"class" : @"note",
              @"format" : @"txt"
           },
      @"value" : message,
      @"folderId" : @"notes", // TODO extract
      @"time" : time
    };
    
    NSData *result = [NSJSONSerialization dataWithJSONObject:noteEventDictionary options:0 error:nil];
    
    NSAssert(result != nil, @"Unsuccessful json creation from note event");
    NSAssert(result.length > 0, @"Unsuccessful json creation from note event");
    
    return result;
}

- (NSData *)pictureEventWithJSONObject
{
    // turn the date into server format time
    NSNumber * time = [NSNumber numberWithDouble:[self.date timeIntervalSince1970]];
    
    NSDictionary *noteEventDictionary =
    @{
      @"type" :
          @{
              @"class" : @"picture",
              @"format" : @"attached"
           },
      @"folderId" : @"notes", // TODO extract
      @"time" : time
    };
    
    NSData *result = [NSJSONSerialization dataWithJSONObject:noteEventDictionary options:0 error:nil];
    
    NSAssert(result != nil, @"Unsuccessful json creation from note event");
    NSAssert(result.length > 0, @"Unsuccessful json creation from note event");
    
    return result;
}

- (NSData *)updateDurationJSONObject
{
    NSDictionary *positionEventDictionary =
    @{
      @"id" : self.eventId,
      @"value" :
          @{
              @"longitude" : self.longitude,
              @"latitude" : self.latitude,
              @"verticalAccuracy" : self.horizontalAccuracy,
              @"horizontalAccuracy" : self.verticalAccuracy,
              @"elevation" : self.elevation,
              @"duration" : self.duration
           },
      };
    
    NSData *result = [NSJSONSerialization dataWithJSONObject:positionEventDictionary options:0 error:nil];
    
    NSAssert(result != nil, @"Unsuccessful json creation from position event");
    NSAssert(result.length > 0, @"Unsuccessful json creation from position event");
    
    return result;
}

@end


# pragma mark - PPrYvApiClient


@interface PPrYvApiClient ()

// perform check before trying to connect to the PrYv API
- (BOOL)isReady;

// if isReady returns Falsereturn a reason based
- (NSError *)createNotReadyError;

// construct the baseUrl with schema
- (NSString *)apiBaseUrl;

// for creating infoObjects for errors
// @return empty NSString if @param object is nil
- (id)nonNil:(id)object;

@end

@implementation PPrYvApiClient

@synthesize serverTimeInterval = _serverTimeInterval;
@synthesize userId = _userId;
@synthesize oAuthToken = _oAuthToken;
@synthesize channelId = _channelId;

#pragma mark - Class methods

+ (PPrYvApiClient *)sharedClient
{
    static PPrYvApiClient *_manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [[self alloc] init];
    });
    
    return _manager;
}

#pragma mark - private helpers

- (id)nonNil:(id)object
{
  if (!object) {
    return @"";
  }
  else
    return object;
}

- (id)nonNilDictionary:(id)object
{
    if (!object) {
        return [NSDictionary dictionary];
    }
    else
        return object;
}

- (NSString *)apiBaseUrl
{
    // production url
    //return [NSString stringWithFormat:@"https://%@.pryv.io", self.userId];

    // development url
    return [NSString stringWithFormat:@"https://%@.rec.la", self.userId];
}

- (BOOL)isReady
{
    // The manager must contain a user, token and a application channel
    if (self.userId == nil || self.userId.length == 0) {
        return NO;
    }
    if (self.oAuthToken == nil || self.oAuthToken.length == 0) {
        return NO;
    }
    if (self.channelId == nil || self.channelId.length == 0) {
        return NO;
    }

    return YES;
}

- (NSError *)createNotReadyError
{
    NSError *error;
    if (self.userId == nil || self.userId.length == 0) {
            error = [NSError errorWithDomain:@"user not set" code:7 userInfo:nil];
        }
        else if (self.oAuthToken == nil || self.oAuthToken.length == 0) {
            error = [NSError errorWithDomain:@"auth token not set" code:77 userInfo:nil];
        }
        else if (self.channelId == nil || self.channelId.length == 0) {
            error = [NSError errorWithDomain:@"channel not set" code:777 userInfo:nil];
        }
        else {
            error = [NSError errorWithDomain:@"unknown error" code:999 userInfo:nil];
        }
    return error;
}


#pragma mark - Initiate

- (void)startClientWithUserId:(NSString *)userId
                   oAuthToken:(NSString *)token
                    channelId:(NSString *)channelId
               successHandler:(void (^)(NSTimeInterval serverTime))successHandler
                 errorHandler:(void(^)(NSError *error))errorHandler;
{
    NSParameterAssert(userId);
    NSParameterAssert(token);
    NSParameterAssert(channelId);

    self.userId = userId;
    self.oAuthToken = token;
    self.channelId = channelId;

    [self synchronizeTimeWithSuccessHandler:successHandler
                               errorHandler:errorHandler];
}

#pragma mark - PrYv API authorize and get server time (GET /)

- (void)synchronizeTimeWithSuccessHandler:(void(^)(NSTimeInterval serverTime))successHandler
                             errorHandler:(void(^)(NSError *error))errorHandler
{
    if (![self isReady]) {
        NSLog(@"fail synchronize: not initialized");

        // we should just ignore this case
        return;
    }
        
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/", [self apiBaseUrl]]];
    
    AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:url];
    [client.operationQueue setMaxConcurrentOperationCount:1];
    [client setDefaultHeader:@"Authorization" value:self.oAuthToken];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:self.oAuthToken forHTTPHeaderField:@"Authorization"];
    
    AFHTTPRequestOperation *operation = [client HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSTimeInterval serverTime = [[[operation.response allHeaderFields] objectForKey:@"Server-Time"] doubleValue];
        
        NSLog(@"successfully authorized and synchronized with server time: %f ", serverTime);
        _serverTimeInterval = [[NSDate date] timeIntervalSince1970] - serverTime;

        if (successHandler)
            successHandler(serverTime);

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

        NSLog(@"could not synchronize %@", error);
        NSDictionary *userInfo = @{
                @"connectionError": [self nonNil:error],
                @"NSHTTPURLResponse" : [self nonNil:operation.response],
                @"serverError" : @{ @"message": [self nonNil:operation.responseString] }
        };
        NSError *requestError = [NSError errorWithDomain:@"connection failed" code:100 userInfo:userInfo];

        if (errorHandler)
            errorHandler(requestError);

    }];
    [operation setShouldExecuteAsBackgroundTaskWithExpirationHandler:nil];
    [operation start];
}

#pragma mark - PrYv API Event update (PUT /{channel-id}/events/)

// used to update the duration of position event

- (void)updateEvent:(PositionEvent *)event withSuccessHandler:(void(^)(NSString *eventId))successHandler errorHandler:(void(^)(NSError *error))errorHandler;
{
    if (![self isReady]) {
        NSLog(@"fail sending event: not initialized");
        
        if (errorHandler)
            errorHandler([self createNotReadyError]);
        return;
    }
    
    NSString *eventId = event.eventId;
    
    // create the RESTful url corresponding the current action
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/events/%@", [self apiBaseUrl], self.channelId, event.eventId]];

    // send an event without attachments
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:self.oAuthToken forHTTPHeaderField:@"Authorization"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    request.HTTPMethod = @"PUT";
    request.HTTPBody = [event updateDurationJSONObject];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSLog(@"successfully updated event with eventId: %@", eventId);
        
        if (successHandler)
            successHandler(eventId);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"failed to send an event %@", error);
        // create a dictionary with all the information we can get and pass it as userInfo
        NSDictionary *userInfo = @{
                                   @"connectionError": [self nonNil:error],
                                   @"NSHTTPURLResponse" : [self nonNil:response],
                                   @"event": [self nonNil:event],
                                   @"serverError" : [self nonNilDictionary:JSON]
                                   };
        NSError *requestError = [NSError errorWithDomain:@"connection failed" code:100 userInfo:userInfo];
        
        if (errorHandler)
            errorHandler(requestError);
    }];
    [operation setShouldExecuteAsBackgroundTaskWithExpirationHandler:nil];
    [operation start];
    
}


#pragma mark - PrYv API Event create (POST /{channel-id}/events/)

- (void)sendEvent:(PositionEvent *)event withSuccessHandler:(void(^)(NSString *eventId))successHandler errorHandler:(void(^)(NSError *error))errorHandler;
{
    if (![self isReady]) {
        NSLog(@"fail sending event: not initialized");

        if (errorHandler)
            errorHandler([self createNotReadyError]);
        return;
    }
    
    // create the RESTful url corresponding the current action    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/events", [self apiBaseUrl], self.channelId]];

    // send an event without attachments
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:self.oAuthToken forHTTPHeaderField:@"Authorization"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [event dataWithJSONObject];

    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSLog(@"successfully sent event eventId: %@", JSON[@"id"]);

        if (successHandler)
            successHandler(JSON[@"id"]);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"failed to send an event %@", error);
        // create a dictionary with all the information we can get and pass it as userInfo
        NSDictionary *userInfo = @{
                @"connectionError": [self nonNil:error],
                @"NSHTTPURLResponse" : [self nonNil:response],
                @"event": [self nonNil:event],
                @"serverError" : [self nonNilDictionary:JSON]
        };
        NSError *requestError = [NSError errorWithDomain:@"connection failed" code:100 userInfo:userInfo];

        if (errorHandler)
            errorHandler(requestError);
    }];
    [operation setShouldExecuteAsBackgroundTaskWithExpirationHandler:nil];
    [operation start];
}

#pragma mark - 
#define NOTE_CHANNEL_ID @"diary"

- (void)sendPictureEvent:(PositionEvent *)event
       completionHandler:(void(^)(NSString *eventId, NSError *error))completionHandler
{
    if (![self isReady]) {
        NSLog(@"fail sending event: not initialized");
        
        if (completionHandler)
            completionHandler(nil, [self createNotReadyError]);
        return;
    }
    
    NSArray *attachmentList = [event attachmentList];
    
    if (attachmentList != nil && [attachmentList count] > 0) {
        for (EventAttachment *attachment in attachmentList) {
            // simple data verification before sending
            NSData *fileData = attachment.fileData;
            NSString *fileName = attachment.fileName;
            NSString *mimeType = attachment.mimeType;
            
            if (fileData == nil || fileData.length == 0) {
                NSError *error = [NSError errorWithDomain:@"an attachment file is empty or missing." code:21 userInfo:nil];
                
                if (completionHandler)
                    completionHandler(nil, error);
                return;
            }
            
            if (fileName == nil || fileName.length == 0) {
                NSError *error = [NSError errorWithDomain:@"an attachment file name is empty or missing." code:22 userInfo:nil];
                
                if (completionHandler)
                    completionHandler(nil, error);
                return;
            }
            
            if (mimeType == nil || mimeType.length == 0) {
                NSError *error = [NSError errorWithDomain:@"an attachment MIME Type specifier is empty or missing." code:23 userInfo:nil];
                
                if (completionHandler)
                    completionHandler(nil, error);
                return;
            }
        }
        // data verified, this event should contain valid attachment(s)
    }
    
    // create the RESTful url corresponding the current action
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/events", [self apiBaseUrl], NOTE_CHANNEL_ID]];
    
    // send event with attachments
    AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:url];
    [client.operationQueue setMaxConcurrentOperationCount:1];
    [client setDefaultHeader:@"Authorization" value:self.oAuthToken];
    
    NSMutableURLRequest *request = [client multipartFormRequestWithMethod:@"POST"
                                                                     path:@""
                                                               parameters:nil
    constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        
        // append the event part
        [formData appendPartWithFormData:[event pictureEventWithJSONObject] name:@"event"];
        
        for (EventAttachment *attachment in attachmentList) {
            // append the attachment(s) parts
            [formData appendPartWithFileData:attachment.fileData
                                        name:attachment.name
                                    fileName:attachment.fileName
                                    mimeType:attachment.mimeType];
        }
    }];
    
    NSLog(@"sending picture json: %@", [[NSString alloc] initWithData:[event pictureEventWithJSONObject]
                                                             encoding:NSUTF8StringEncoding]);
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
    success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSLog(@"successfully sent event with attachment(s) eventId: %@", JSON[@"id"]);
        
        if (completionHandler)
            completionHandler(JSON[@"id"], nil);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"failed to send an event with attachment(s) %@", error);
        // create a dictionary with all the data we can get and pass it as userInfo
        NSDictionary *userInfo = @{
                                   @"connectionError": [self nonNil:error],
                                   @"NSHTTPURLResponse" : [self nonNil:response],
                                   @"event": [self nonNil:event],
                                   @"serverError" : [self nonNilDictionary:JSON]
                                   };
        NSError *requestError = [NSError errorWithDomain:@"connection failed" code:100 userInfo:userInfo];
        
        if (completionHandler)
            completionHandler(nil, requestError);
    }];
    [operation setShouldExecuteAsBackgroundTaskWithExpirationHandler:nil];
    [operation start];
}

#pragma mark -

- (void)sendNoteEvent:(PositionEvent *)event
       completionHandler:(void(^)(NSString *eventId, NSError *error))completionHandler
{
    if (![self isReady]) {
        NSLog(@"fail sending message event: not initialized");
        
        if (completionHandler)
            completionHandler(nil, [self createNotReadyError]);
        return;
    }
    
    // create the RESTful url corresponding the current action
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/events", [self apiBaseUrl], NOTE_CHANNEL_ID]];

    // send an event without attachments
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:self.oAuthToken forHTTPHeaderField:@"Authorization"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [event noteEventWithJSONObject];
    
    NSLog(@"sending note json: %@", [[NSString alloc] initWithData:[event noteEventWithJSONObject]
                                                          encoding:NSUTF8StringEncoding]);
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSLog(@"successfully sent note event eventId: %@", JSON[@"id"]);
        
        if (completionHandler)
            completionHandler(JSON[@"id"], nil);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"failed to send an note event %@", error);
        // create a dictionary with all the information we can get and pass it as userInfo
        NSDictionary *userInfo = @{
                                   @"connectionError": [self nonNil:error],
                                   @"NSHTTPURLResponse" : [self nonNil:response],
                                   @"event": [self nonNil:event],
                                   @"serverError" : [self nonNilDictionary:JSON]
                                   };
        NSError *requestError = [NSError errorWithDomain:@"connection failed" code:100 userInfo:userInfo];
        
        if (completionHandler)
            completionHandler(nil, requestError);
    }];
    [operation setShouldExecuteAsBackgroundTaskWithExpirationHandler:nil];
    [operation start];
}

#pragma mark - PrYv API Event get/list (GET /{channel-id}/events/)

- (void)getEventsFromStartDate:(NSDate *)startDate
                     toEndDate:(NSDate *)endDate
                    inFolderId:(NSString *)folderId
                successHandler:(void (^)(NSArray *positionEventList))successHandler
                  errorHandler:(void(^)(NSError *error))errorHandler
{
    if (![self isReady]) {
        NSLog(@"fail getting events: not initialized");

        if (errorHandler)
            errorHandler([self createNotReadyError]);
        return;
    }
    
    NSURL *url =  nil;
    
    if (startDate != nil && endDate != nil) {
        
        // the user asked for a specific time period
        NSNumber *timeStampStart = [NSNumber numberWithDouble:[startDate timeIntervalSince1970]];
        NSNumber *timeStampEnd = [NSNumber numberWithDouble:[endDate timeIntervalSince1970]];
        
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/events?fromTime=%@&toTime=%@&onlyFolders[]=%@&limit=1200", [self apiBaseUrl], self.channelId, timeStampStart, timeStampEnd, folderId]];
    }
    else {
        // the user asked for the last 24h
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/events?onlyFolders[]=%@", [self apiBaseUrl], self.channelId, folderId]];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setAllHTTPHeaderFields:@{@"Authorization" : self.oAuthToken}];
    request.HTTPMethod = @"GET";
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSLog(@"successfully received events");

        if (successHandler) {
            NSManagedObjectContext *scratchManagedContext = [[PPrYvCoreDataManager sharedInstance] scratchManagedObjectContext];
            NSMutableArray *positionEventList = [NSMutableArray array];
            // TODO think how to destroy the scratchmanagedContext
            for (NSDictionary *positionEventDictionary in JSON) {
                // only process events which are positions
                if ([positionEventDictionary[@"type"][@"class"] isEqualToString:@"position"]) {
                    PositionEvent *positionEvent = [PositionEvent positionEventFromDictionary:positionEventDictionary
                                                                             inScratchContext:scratchManagedContext];
                    [positionEventList addObject:positionEvent];
                }
            }
            successHandler(positionEventList);
        }
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON){
        NSLog(@"failed to receive events: %@", error);
        
        NSDictionary *userInfo = @{
                @"connectionError": [self nonNil:error],
                @"NSHTTPURLResponse" : [self nonNil:response],
                @"serverError" : [self nonNilDictionary:JSON]
        };
        NSError *requestError = [NSError errorWithDomain:@"connection failed" code:100 userInfo:userInfo];

        if (errorHandler)
            errorHandler(requestError);
    }];
    [operation setShouldExecuteAsBackgroundTaskWithExpirationHandler:nil];
    [operation start];
}

#pragma mark - PrYv API Folder get all (GET /{channel-id}/folders/)


- (void)getFoldersWithSuccessHandler:(void (^)(NSArray *folderList))successHandler
                        errorHandler:(void (^)(NSError *error))errorHandler
{
    [self getFoldersInChannel:self.channelId
           withSuccessHandler:successHandler
                 errorHandler:errorHandler];
}

- (void)getFoldersInChannel:(NSString *)channelId
         withSuccessHandler:(void (^)(NSArray *folderList))successHandler
               errorHandler:(void (^)(NSError *error))errorHandler

{
    if (![self isReady]) {
        NSLog(@"fail sending: not initialized");

        if (errorHandler)
            errorHandler([self createNotReadyError]);
        return;
    }

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/folders/", [self apiBaseUrl], channelId]];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:self.oAuthToken forHTTPHeaderField:@"Authorization"];

    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSLog(@"successfully received folders");

        NSMutableArray *folderList = [[NSMutableArray alloc] init];
        for (NSDictionary *folderDictionary in JSON) {
            Folder *folderObject = [Folder folderFromJSON:folderDictionary];
            [folderList addObject:folderObject];
        }

        if (successHandler) {
            successHandler(folderList);
        }

    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON){
        NSLog(@"could not receive folders");

        NSDictionary *userInfo = @{
                @"connectionError": [self nonNil:error],
                @"NSHTTPURLResponse" : [self nonNil:response],
                @"serverError" : [self nonNilDictionary:JSON]
        };
        NSError *requestError = [NSError errorWithDomain:@"connection failed" code:200 userInfo:userInfo];

        if (errorHandler)
            errorHandler(requestError);

    }];
    [operation setShouldExecuteAsBackgroundTaskWithExpirationHandler:nil];
    [operation start];
}


#pragma mark - PrYv API Folder create (POST /{channel-id}/folders/)

- (void)createFolderId:(NSString *)folderId
              withName:(NSString *)folderName
        successHandler:(void (^)(NSString *folderId, NSString *folderName))successHandler
          errorHandler:(void (^)(NSError *error))errorHandler
{
    if (![self isReady]) {
        NSLog(@"fail creating a folder: not initialized");

        if (errorHandler)
            errorHandler([self createNotReadyError]);
        return;
    }

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/folders", [self apiBaseUrl], self.channelId]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setAllHTTPHeaderFields:@{@"Authorization" : self.oAuthToken, @"Content-Type" : @"application/json"}];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:@{@"name" : folderName, @"id" : folderId}
                                                       options:0
                                                         error:nil];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        NSLog(@"successfully created folderName: %@ folderId: %@", folderName, folderId);

        if (successHandler)
            successHandler(folderId, folderName);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"failed to create folderName: %@ folderId: %@ reason: %@", folderName, folderId, JSON);

        NSDictionary *userInfo = @{
                @"connectionError": [self nonNil:error],
                @"NSHTTPURLResponse" : [self nonNil:response],
                @"folderName": folderName,
                @"folderId": folderId,
                @"serverError" : [self nonNilDictionary:JSON]
        };
        NSError *requestError = [NSError errorWithDomain:@"Error creating folder" code:210 userInfo:userInfo];

        if (errorHandler)
            errorHandler(requestError);

    }];
    [operation setShouldExecuteAsBackgroundTaskWithExpirationHandler:nil];
    [operation start];
}

#pragma mark - PrYv API Folder modify (PUT /{channel-id}/folders/{folder-id})

- (void)renameFolderId:(NSString *)folderId
     withNewFolderName:(NSString *)newFolderName
        successHandler:(void(^)(NSString *folderId, NSString *newFolderName))successHandler
          errorHandler:(void(^)(NSError *error))errorHandler;
{
    if (![self isReady]) {
        NSLog(@"fail renaming a folder: not initialized");

        if (errorHandler)
            errorHandler([self createNotReadyError]);
        return;
    }

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/folders/%@", [self apiBaseUrl], self.channelId, folderId]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setAllHTTPHeaderFields:@{@"Authorization" : self.oAuthToken, @"Content-Type" : @"application/json"}];
    request.HTTPMethod = @"PUT";
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:@{@"name" : newFolderName} options:0 error:nil];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSLog(@"successfully renamed folderId: %@ with folderName: %@", folderId, newFolderName);

        // custom way to store the information about the folder that the folder is available for future uploads
        if (successHandler)
            successHandler(folderId, newFolderName);

    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"failed to rename folderId:%@ with folderName:%@ reason:%@", folderId, newFolderName, JSON);

        NSDictionary *userInfo = @{
                @"connectionError": [self nonNil:error],
                @"NSHTTPURLResponse" : [self nonNil:response],
                @"folderName": newFolderName,
                @"folderId": folderId,
                @"serverError" : [self nonNilDictionary:JSON]
        };
        NSError *requestError = [NSError errorWithDomain:@"Error renaming folder" code:220 userInfo:userInfo];

        if (errorHandler)
            errorHandler(requestError);
    }];
    [operation setShouldExecuteAsBackgroundTaskWithExpirationHandler:nil];
    [operation start];
}

@end

