//
//  PPrYvDefaultManager.m
//  AT PrYv
//
//  Created by Nicolas Manzini on 21.12.12.
//  Copyright (c) 2012 PrYv. All rights reserved.
//


#import "PPrYvDefaultManager.h"
#import "AFNetworking.h"



// DO NOT CALL THOSE METHOD DIRECTLY
@interface PPrYvDefaultManager (private)

// perform check before trying to connect to the PrYv API
- (BOOL)isReady;

// will call the delegate method with the current error
- (void)failedWithError:(NSError *)error
           failedAction:(PPrYvFailedAction)failedAction
               delegate:(id<PPrYvDefaultManagerDelegate>)delegate;

// will call the delegate method with the current event
- (void)didSendEvent:(NSData *)event
            delegate:(id<PPrYvDefaultManagerDelegate>)delegate;

@end

@implementation PPrYvDefaultManager

@synthesize serverTimeInterval;

#pragma mark - Default Manager Main Access
// access the manager
+ (PPrYvDefaultManager *)sharedManager {
    
    static PPrYvDefaultManager *_manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [[self alloc] init];
    });
    
    return _manager;
}

#pragma mark - Default Manager

- (void)startManagerWithUserId:(NSString *)userId
                    oAuthToken:(NSString *)token
                     channelId:(NSString *)channelId
                      delegate:(id<PPrYvDefaultManagerDelegate>)delegate
{
    
    self.userId = userId;
    self.oAuthToken = token;
    self.channelId = channelId;
    
    [self synchronizeTimeWithServerDelegate:delegate];
}

- (BOOL)isReady {
    
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


- (void)synchronizeTimeWithServerDelegate:(id<PPrYvDefaultManagerDelegate>)delegate {
    
    if (![self isReady]) {
        
        [self failedWithError:nil failedAction:PPrYvFailedSynchronize delegate:delegate];
        return;
    }
        
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@.rec.la/", self.userId]];
    
    AFHTTPClient * client = [AFHTTPClient clientWithBaseURL:url];
    [client setDefaultHeader:@"Authorization" value:self.oAuthToken];
    
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:self.oAuthToken forHTTPHeaderField:@"Authorization"];
    
    AFHTTPRequestOperation * operation = [client HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSTimeInterval serverTime = [[[operation.response allHeaderFields] objectForKey:@"Server-Time"] doubleValue];
        
        NSLog(@"%f server time", serverTime);
        serverTimeInterval = [[NSDate date] timeIntervalSince1970] - serverTime;
        
        if ([delegate respondsToSelector:@selector(PPrYvDefaultManagerDidSynchronize)]) {
            [delegate PPrYvDefaultManagerDidSynchronize];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        NSTimeInterval serverTime = [[[operation.response allHeaderFields] objectForKey:@"Server-Time"] doubleValue];
        
        NSLog(@"%f server time", serverTime);
        serverTimeInterval = [[NSDate date] timeIntervalSince1970] - serverTime;
        
        if ([delegate respondsToSelector:@selector(PPrYvDefaultManagerDidSynchronize)]) {
            [delegate PPrYvDefaultManagerDidSynchronize];
        }
    }];
    [operation start];
}

#pragma mark - PrYv API Requests

// Convenient method that will call sendEvent:withAttachments:delegate and pass nil to attachments
- (void)sendEvent:(NSData *)event delegate:(id<PPrYvDefaultManagerDelegate>)delegate {
    
    [self sendEvent:event withAttachments:nil delegate:delegate];
}

- (void)sendEvent:(NSData *)event withAttachments:(NSArray *)attachments delegate:(id<PPrYvDefaultManagerDelegate>)delegate {
    
    if (![self isReady]) {
        
        [self failedWithError:nil failedAction:PPrYvFailedSendEvent delegate:delegate];
        return;
    }
    
    if (event == nil || event.length == 0) {
        
        // event is missing
        NSError * error = [NSError errorWithDomain:@"missing event parameter" code:10 userInfo:nil];
        
        [self failedWithError:error failedAction:PPrYvFailedSendEvent delegate:delegate];
        
        return;
    }
    
    if ([NSJSONSerialization JSONObjectWithData:event options:0 error:nil] == nil) {
        
        // event is not a valid JSON
        NSError * error = [NSError errorWithDomain:@"event data is not valid JSON" code:11 userInfo:nil];
        
        [self failedWithError:error failedAction:PPrYvFailedSendEvent delegate:delegate];
        
        return;
    }
    
    BOOL containAttachment = NO;
    
    if (attachments != nil) {
        
        if ([attachments count] == 0) {
            
            // attachments are empty. Pass nil to specify no attachments
            NSError * error = [NSError errorWithDomain:@"empty attachment parameter" code:20 userInfo:nil];
            
            [self failedWithError:error failedAction:PPrYvFailedSendEvent delegate:delegate];
            
            return;
        }
        
        for (NSDictionary * attachment in attachments) {
            
            // simple data verification before sending
            NSData * fileData = [attachment objectForKey:@"file"];
            NSString * fileName = [attachment objectForKey:@"fileName"];
            NSString * mimeType = [attachment objectForKey:@"mimeType"];
            
            if (fileData == nil || fileData.length == 0) {
                
                NSError * error = [NSError errorWithDomain:@"an attachment file is empty or missing." code:21 userInfo:nil];
                
                [self failedWithError:error failedAction:PPrYvFailedSendEvent delegate:delegate];
                
                return;
            }
            
            if (fileName == nil || fileName.length == 0) {
                
                NSError * error = [NSError errorWithDomain:@"an attachment file name is empty or missing." code:22 userInfo:nil];
                
                [self failedWithError:error failedAction:PPrYvFailedSendEvent delegate:delegate];
                
                return;
            }
            
            if (mimeType == nil || mimeType.length == 0) {
                
                NSError * error = [NSError errorWithDomain:@"an attachment MIME Type specifier is empty or missing." code:23 userInfo:nil];
                
                [self failedWithError:error failedAction:PPrYvFailedSendEvent delegate:delegate];
                
                return;
            }
        }
        // data verified, this event should contain valid attachment(s)
        containAttachment = YES;
    }
    
    // create the RESTful url corresponding the current action    
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@.rec.la/%@/events", self.userId, self.channelId]];

    if (url == nil) {
        
        // failed to create the url because of missing userId, channelId or oAuthToken
        [self failedWithError:nil failedAction:PPrYvFailedSendEvent delegate:delegate];
        
        return;
    }
    
    if (!containAttachment) {
        
        // send an even without attachments
        NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url];
        [request addValue:self.oAuthToken forHTTPHeaderField:@"Authorization"];
        [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        request.HTTPMethod = @"POST";
        request.HTTPBody = event;
        
        AFJSONRequestOperation * operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            
            // call the successfull delegate
            [self didSendEvent:event delegate:delegate];
            
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            
            // create a dictionary with all the information we can get and pass it as userInfo
            NSDictionary * dico = @{@"connectionError": error, @"NSHTTPURLResponse" : response, @"event": event, @"serverError" : JSON};
            NSError * requestError = [NSError errorWithDomain:@"connection failed" code:100 userInfo:dico];
            
            [self failedWithError:requestError failedAction:PPrYvFailedSendEvent delegate:delegate];
        }];
        [operation start];
    }
    else {
        
        // send event with attachments
        AFHTTPClient * client = [AFHTTPClient clientWithBaseURL:url];
        [client setDefaultHeader:@"Authorization" value:self.oAuthToken];
        
        NSMutableURLRequest * request = [client multipartFormRequestWithMethod:@"POST" path:nil parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            
            // append the event part
            [formData appendPartWithFormData:event name:@"event"];
            
            for (NSDictionary * infos in attachments) {
                // append the attachment(s) parts
                [formData appendPartWithFileData:[infos objectForKey:@"file"] name:[infos objectForKey:@"fileName"] fileName:[infos objectForKey:@"fileName"] mimeType:[infos objectForKey:@"mimeType"]];
            }
        }];
        
        AFJSONRequestOperation * operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            
            // call the successfull delegate
            [self didSendEvent:event delegate:delegate];
            
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            
            // create a dictionary with all the data we can get and pass it as userInfo
            NSDictionary * dico = @{@"connectionError": error, @"NSHTTPURLResponse" : response, @"event": event, @"serverError" : JSON};
            NSError * requestError = [NSError errorWithDomain:@"connection failed" code:100 userInfo:dico];
            
            [self failedWithError:requestError failedAction:PPrYvFailedSendEvent delegate:delegate];
        }];
        [operation start];
    }
}

- (void)getEventsFromStartDate:(NSDate *)startDate
                     toEndDate:(NSDate *)endDate
                    inFolderId:(NSString *)folderId
                      delegate:(id<PPrYvDefaultManagerDelegate>)delegate
{
    if (![self isReady]) {
        
        [self failedWithError:nil failedAction:PPrYvFailedGetEvents delegate:delegate];
        
        return;
    }
    
    NSURL * url =  nil;
    
    if (startDate != nil && endDate != nil) {
        
        // the user asked for a specific time period
        NSNumber * timeStampBeginning = [NSNumber numberWithDouble:[startDate timeIntervalSince1970]];
        NSNumber * timeStampEnd = [NSNumber numberWithDouble:[endDate timeIntervalSince1970]];
        
        url = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@.rec.la/%@/events?fromTime=%@&toTime=%@&onlyFolders[]=%@&limit=1200", self.userId, self.channelId, timeStampBeginning, timeStampEnd, folderId]];
    }
    else {
        // the user asked for the last 24h
        url = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@.rec.la/%@/events?onlyFolders[]=%@", self.userId, self.channelId, folderId]];
    }
    
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url];
    [request setAllHTTPHeaderFields:@{@"Authorization" : self.oAuthToken}];
    request.HTTPMethod = @"GET";
    
    AFJSONRequestOperation * operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        // id JSON is  a foundation object containing our data
        if ([delegate respondsToSelector:@selector(PPrYvDefaultManagerDidReceiveEvents:)]) {
            
            [delegate PPrYvDefaultManagerDidReceiveEvents:JSON];
        }
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON){
        
        NSDictionary * dico = @{@"connectionError": error, @"NSHTTPURLResponse" : response, @"serverError" : JSON};
        NSError * requestError = [NSError errorWithDomain:@"connection failed" code:100 userInfo:dico];

        [self failedWithError:requestError failedAction:PPrYvFailedGetEvents delegate:delegate];
    }];
    [operation start];
}

- (void)createFolderWithName:(NSString *)folderName
                    folderId:(NSString *)folderId
                    delegate:(id<PPrYvDefaultManagerDelegate>)delegate
{
    
    if (![self isReady]) {
        
        [self failedWithError:nil failedAction:PPrYvFailedGetEvents delegate:delegate];
        return;
    }
    
    NSDictionary * folderInfos = @{@"name" : folderName, @"id" : folderId};
    
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@.rec.la/%@/folders",self.userId,self.channelId]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setAllHTTPHeaderFields:@{@"Authorization" : self.oAuthToken, @"Content-Type" : @"application/json"}];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:folderInfos options:0 error:nil];
    
    AFJSONRequestOperation * operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        if ([delegate respondsToSelector:@selector(PPrYvDefaultManagerDidCreateFolder:withId:)]) {
            
            [delegate PPrYvDefaultManagerDidCreateFolder:folderName withId:folderId];
        }
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                
        // if the folder name already exist
        if ([[JSON objectForKey:@"id"] isEqualToString:@"ITEM_NAME_ALREADY_EXISTS"]) {
            
            NSLog(@"folder name already exist... try to create with another name");
            
            // try to create  the same folder with a new name but same id
            [self createFolderWithName:[folderName stringByAppendingString:@"1"] folderId:folderId delegate:delegate];
                        
        }
        // if the folder Id already exist
        else if ([[JSON objectForKey:@"id"] isEqualToString:@"ITEM_ID_ALREADY_EXISTS"]) {
            
            NSLog(@"folder id already exist... renaming it");
            // rename the folder
            [self renameFolderId:folderId withNewName:folderName delegate:delegate];
        }
        else{
            
            // unknown error
            [self failedWithError:nil failedAction:PPrYvFailedCreateFolder delegate:delegate];
        }
    }];
    [operation start];
}

- (void)renameFolderId:(NSString *)folderId
           withNewName:(NSString *)newName
              delegate:(id<PPrYvDefaultManagerDelegate>)delegate
{
    
    NSDictionary * folderInfos = @{@"name": newName};
    
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@.rec.la/%@/folders/%@",self.userId,self.channelId,folderId]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setAllHTTPHeaderFields:@{@"Authorization" : self.oAuthToken, @"Content-Type" : @"application/json"}];
    request.HTTPMethod = @"PUT";
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:folderInfos options:0 error:nil];
    
    AFJSONRequestOperation * operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                
        // custom way to store the information about the folder that the folder is available for future uploads
        NSLog(@"did rename folder");

        if ([delegate respondsToSelector:@selector(PPrYvDefaultManagerDidRenameFolder:withNewName:)]) {
            
            [delegate PPrYvDefaultManagerDidRenameFolder:folderId withNewName:newName];
        }
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        
        if ([[JSON objectForKey:@"id"] isEqualToString:@"ITEM_NAME_ALREADY_EXISTS"]) {
            
            // rename the folder
            [self renameFolderId:folderId withNewName:[newName stringByAppendingString:@"1"] delegate:delegate];
        }
    }];
    [operation start];
}

#pragma mark -  Delegate 

// the main error callback for every action
- (void)failedWithError:(NSError *)error failedAction:(PPrYvFailedAction)failedAction delegate:(id<PPrYvDefaultManagerDelegate>)delegate {
    
    // nil is passed as the error when the manager is not ready
    if (error == nil) {
        
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
    }
    
    if ([delegate respondsToSelector:@selector(PPrYvDefaultManagerDidFail:withError:)]) {
        
        [delegate PPrYvDefaultManagerDidFail:failedAction withError:error];
    }
}

- (void)didSendEvent:(NSData *)event delegate:(id<PPrYvDefaultManagerDelegate>)delegate {
    
    if ( [delegate respondsToSelector:@selector(PPrYvDefaultManagerDidSendEvent:)]) {
        
        [delegate PPrYvDefaultManagerDidSendEvent:event];
    }
}

@end
