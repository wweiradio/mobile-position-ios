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

#define kEventSendingTimout 500

# pragma mark - Folder JSON serialisation

@interface Folder (JSON)

+ (Folder *)folderFromJSON:(id)json;

@end

@implementation Folder (JSON)

+ (Folder *)folderFromJSON:(id)JSON
{
    NSDictionary *jsonDictionary = JSON;
    Folder *folder = [[Folder alloc] init];
    folder.streamId = [jsonDictionary objectForKey:@"id"];
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

    double latitude = [[[positionEventDictionary objectForKey:@"content"] objectForKey:@"latitude"] doubleValue];
    double longitude = [[[positionEventDictionary objectForKey:@"content"] objectForKey:@"longitude"] doubleValue];
    NSString *streamId = [positionEventDictionary objectForKey:@"streamId"];
    double time = [[positionEventDictionary objectForKey:@"time"] doubleValue];
    
    if ([positionEventDictionary[@"content"] objectForKey:@"altitude"]) {
        double elevation = [positionEventDictionary[@"content"][@"altitude"] doubleValue];
        positionEvent.elevation = [NSNumber numberWithDouble:elevation];
    }

    positionEvent.latitude = [NSNumber numberWithDouble:latitude];
    positionEvent.longitude = [NSNumber numberWithDouble:longitude];
    positionEvent.streamId = streamId;
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

    
    if (!self.date) { self.date = [NSDate date]; };
    // turn the date into server format time
    NSNumber * time = [NSNumber numberWithDouble:[self.date timeIntervalSince1970]];

    NSDictionary *positionEventDictionary =
                         @{
                                 @"type" : @"position/wgs84",
                                 @"content" :
                                 @{
                                         @"longitude" : self.longitude,
                                         @"latitude" : self.latitude,
                                         @"verticalAccuracy" : self.horizontalAccuracy,
                                         @"horizontalAccuracy" : self.verticalAccuracy,
                                         @"altitude" : self.elevation
                                 },
                                 @"description" : message,
                                 @"streamId" : self.streamId,
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
    NSNumber * time = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
    
    NSDictionary *noteEventDictionary =
    @{
      @"type" : @"note/txt",
      @"content" : message,
      @"streamId" : self.streamId, // TODO extract
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
    NSNumber * time = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
    
    NSDictionary *noteEventDictionary =
    @{
      @"type" : @"picture/attached",
      @"streamId" : self.streamId, // TODO extract
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
      @"content" :
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
@synthesize streamIdId = _streamIdId;

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
    return [NSString stringWithFormat:@"https://%@.pryv.io", self.userId];
}

- (BOOL)isReady
{
    // The manager must contain a user, token and a application streamId
    if (self.userId == nil || self.userId.length == 0) {
        return NO;
    }
    if (self.oAuthToken == nil || self.oAuthToken.length == 0) {
        return NO;
    }
    if (self.streamIdId == nil || self.streamIdId.length == 0) {
        return NO;
    }

    return YES;
}

- (NSError *)createNotReadyError
{
    NSError *error;
    if (self.userId == nil || self.userId.length == 0) {
            NSLog(@"userId not set");
            error = [NSError errorWithDomain:@"user not set" code:7 userInfo:nil];
        }
        else if (self.oAuthToken == nil || self.oAuthToken.length == 0) {
            NSLog(@"oauthToken not set");
            error = [NSError errorWithDomain:@"auth token not set" code:77 userInfo:nil];
        }
        else if (self.streamIdId == nil || self.streamIdId.length == 0) {
            NSLog(@"streamIdId not set");
            error = [NSError errorWithDomain:@"streamId not set" code:777 userInfo:nil];
        }
        else {
            NSLog(@"unknown error");
            error = [NSError errorWithDomain:@"unknown error" code:999 userInfo:nil];
        }
    return error;
}


#pragma mark - Initiate

- (void)startClientWithUserId:(NSString *)userId
                   oAuthToken:(NSString *)token
                    streamIdId:(NSString *)streamIdId
               successHandler:(void (^)(NSTimeInterval serverTime))successHandler
                 errorHandler:(void(^)(NSError *error))errorHandler;
{
    NSParameterAssert(userId);
    NSParameterAssert(token);
    NSParameterAssert(streamIdId);

    self.userId = userId;
    self.oAuthToken = token;
    self.streamIdId = streamIdId;

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
        
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@", [self apiBaseUrl]]];
    
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

#pragma mark - PrYv API Event update (PUT /{streamId-id}/events/)

// used to update the duration of position event

- (void)updateEvent:(PositionEvent *)event completionHandler:(void(^)(NSString *eventId, NSError *error))completionHandler;
{
    if (![self isReady]) {
        NSLog(@"fail sending event: not initialized");
        
        if (completionHandler)
            completionHandler(nil, [self createNotReadyError]);
        return;
    }
    
    NSString *eventId = event.eventId;
    
    // create the RESTful url corresponding the current action
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/events/%@", [self apiBaseUrl], event.eventId]];

    // send an event without attachments
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:self.oAuthToken forHTTPHeaderField:@"Authorization"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    request.HTTPMethod = @"PUT";
    request.HTTPBody = [event updateDurationJSONObject];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSLog(@"successfully updated event with eventId: %@", eventId);
        
        if (completionHandler)
            completionHandler(eventId, nil);
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
        
        if (completionHandler)
            completionHandler(nil, requestError);
    }];
    [operation setShouldExecuteAsBackgroundTaskWithExpirationHandler:nil];
    [operation start];
    
}


#pragma mark - PrYv API Event create (POST /{streamId-id}/events/)

- (void)sendEvent:(PositionEvent *)event completionHandler:(void(^)(NSString *eventId, NSError *error))completionHandler;
{
    if (![self isReady]) {
        NSLog(@"fail sending event: not initialized");

        if (completionHandler)
            completionHandler(nil, [self createNotReadyError]);
        return;
    }
    
    // create the RESTful url corresponding the current action
    NSString *surl = [NSString stringWithFormat:@"%@/events", [self apiBaseUrl]];
    NSURL *url = [NSURL URLWithString:surl];

    // send an event without attachments
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:self.oAuthToken forHTTPHeaderField:@"Authorization"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    request.HTTPMethod = @"POST";
    NSData* bodyData = [event dataWithJSONObject];
    request.HTTPBody = bodyData;
    [request setTimeoutInterval:kEventSendingTimout];

    NSLog(@"Event: auth:%@ url:%@ %@ \ndata",self.oAuthToken, surl, [[NSString alloc] initWithData:bodyData
          encoding:NSUTF8StringEncoding]);
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id responseDict) {
        NSDictionary* JSON = responseDict[@"event"];
        
        NSLog(@"successfully sent event eventId: %@", JSON[@"id"]);

        if (completionHandler)
            completionHandler(JSON[@"id"], nil);
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

        if (completionHandler)
            completionHandler(nil, requestError);
    }];
    [operation setShouldExecuteAsBackgroundTaskWithExpirationHandler:nil];
    [operation start];
}

#pragma mark - 
#define NOTE_streamId_ID kPrYvApplicationstreamIdId

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
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/events", [self apiBaseUrl]]];
    
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
    [request setTimeoutInterval:kEventSendingTimout];
    
    NSLog(@"sending picture json: %@", [[NSString alloc] initWithData:[event pictureEventWithJSONObject]
                                                             encoding:NSUTF8StringEncoding]);
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
    success:^(NSURLRequest *request, NSHTTPURLResponse *response, id responseDict) {
        
        NSDictionary* JSON = responseDict[@"event"];
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
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/events", [self apiBaseUrl]]];

    // send an event without attachments
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:self.oAuthToken forHTTPHeaderField:@"Authorization"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [event noteEventWithJSONObject];
    [request setTimeoutInterval:kEventSendingTimout];
    
    NSLog(@"sending note json: %@", [[NSString alloc] initWithData:[event noteEventWithJSONObject]
                                                          encoding:NSUTF8StringEncoding]);
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id responseDict) {
        
        NSDictionary* JSON = responseDict[@"event"];
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

#pragma mark - PrYv API Event get/list (GET /{streamId-id}/events/)

- (void)getEventsFromStartDate:(NSDate *)startDate
                     toEndDate:(NSDate *)endDate
                    instreamId:(NSString *)streamId
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
        
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/events?fromTime=%@&toTime=%@&onlyStreams[]=%@&limit=1200", [self apiBaseUrl], timeStampStart, timeStampEnd, streamId]];
    }
    else {
        // the user asked for the last 24h
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/events?onlyStreams[]=%@", [self apiBaseUrl],streamId]];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setAllHTTPHeaderFields:@{@"Authorization" : self.oAuthToken}];
    request.HTTPMethod = @"GET";
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id responseDict) {
        NSArray *JSON = responseDict[@"events"];
        NSLog(@"successfully received events");

        if (successHandler) {
            NSManagedObjectContext *scratchManagedContext = [[PPrYvCoreDataManager sharedInstance] scratchManagedObjectContext];
            NSMutableArray *positionEventList = [NSMutableArray array];
            // TODO think how to destroy the scratchmanagedContext
            for (NSDictionary *positionEventDictionary in JSON) {
                // only process events which are positions
                if ([positionEventDictionary[@"type"] isEqualToString:@"position/wgs84"]) {
                    PositionEvent *positionEvent = [PositionEvent positionEventFromDictionary:positionEventDictionary
                                                                             inScratchContext:scratchManagedContext];
                    // skip 0/0 coordinate
                    if ([positionEvent.longitude doubleValue] == 0.0f && [positionEvent.latitude doubleValue] == 0.0f) {
                        [scratchManagedContext deleteObject:positionEvent];
                        NSLog(@"ignore receiving the 0/0 coordinate");
                        continue;
                    }
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

#pragma mark - PrYv API Folder get all (GET /{streamId-id}/folders/)


- (void)getFoldersWithSuccessHandler:(void (^)(NSArray *folderList))successHandler
                        errorHandler:(void (^)(NSError *error))errorHandler
{
    [self getFoldersInstreamId:self.streamIdId
           withSuccessHandler:successHandler
                 errorHandler:errorHandler];
}

- (void)getFoldersInstreamId:(NSString *)streamIdId
         withSuccessHandler:(void (^)(NSArray *folderList))successHandler
               errorHandler:(void (^)(NSError *error))errorHandler

{
    if (![self isReady]) {
        NSLog(@"fail sending: not initialized");

        if (errorHandler)
            errorHandler([self createNotReadyError]);
        return;
    }

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/streams?parentId=position", [self apiBaseUrl]]];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:self.oAuthToken forHTTPHeaderField:@"Authorization"];

    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id responseDict) {
        NSArray* JSON = responseDict[@"streams"];
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


#pragma mark - PrYv API Folder create (POST /{streamId-id}/folders/)

- (void)createstreamId:(NSString *)streamId
              withName:(NSString *)name
        successHandler:(void (^)(NSString *streamId, NSString *name))successHandler
          errorHandler:(void (^)(NSError *error))errorHandler
{
    if (![self isReady]) {
        NSLog(@"fail creating a folder: not initialized");

        if (errorHandler)
            errorHandler([self createNotReadyError]);
        return;
    }

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/streams", [self apiBaseUrl]]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setAllHTTPHeaderFields:@{@"Authorization" : self.oAuthToken, @"Content-Type" : @"application/json"}];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:@{@"name" : name, @"id" : streamId, @"parentId": kPrYvApplicationstreamIdId}
                                                       options:0
                                                         error:nil];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        NSLog(@"successfully created name: %@ streamId: %@", name, streamId);

        if (successHandler)
            successHandler(streamId, name);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"failed to create name: %@ streamId: %@ reason: %@", name, streamId, JSON);

        NSDictionary *userInfo = @{
                @"connectionError": [self nonNil:error],
                @"NSHTTPURLResponse" : [self nonNil:response],
                @"name": name,
                @"streamId": streamId,
                @"serverError" : [self nonNilDictionary:JSON]
        };
        NSError *requestError = [NSError errorWithDomain:@"Error creating folder" code:210 userInfo:userInfo];

        if (errorHandler)
            errorHandler(requestError);

    }];
    [operation setShouldExecuteAsBackgroundTaskWithExpirationHandler:nil];
    [operation start];
}

#pragma mark - PrYv API Folder modify (PUT /{streamId-id}/folders/{folder-id})

- (void)renamestreamId:(NSString *)streamId
     withNewname:(NSString *)newname
        successHandler:(void(^)(NSString *streamId, NSString *newname))successHandler
          errorHandler:(void(^)(NSError *error))errorHandler;
{
    if (![self isReady]) {
        NSLog(@"fail renaming a folder: not initialized");

        if (errorHandler)
            errorHandler([self createNotReadyError]);
        return;
    }

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/streams", [self apiBaseUrl]]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setAllHTTPHeaderFields:@{@"Authorization" : self.oAuthToken, @"Content-Type" : @"application/json"}];
    request.HTTPMethod = @"PUT";
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:@{@"name" : newname} options:0 error:nil];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSLog(@"successfully renamed streamId: %@ with name: %@", streamId, newname);

        // custom way to store the information about the folder that the folder is available for future uploads
        if (successHandler)
            successHandler(streamId, newname);

    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"failed to rename streamId:%@ with name:%@ reason:%@", streamId, newname, JSON);

        NSDictionary *userInfo = @{
                @"connectionError": [self nonNil:error],
                @"NSHTTPURLResponse" : [self nonNil:response],
                @"name": newname,
                @"streamId": streamId,
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

