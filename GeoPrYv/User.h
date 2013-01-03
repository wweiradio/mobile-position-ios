//
//  User.h
//  AT PrYv
//
//  Created by Nicolas Manzini on 29.12.12.
//  Copyright (c) 2012 PrYv. All rights reserved.
//

/**
 @discussion 
 This Class contain the user infos and the user's preferences for the application
 */

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface User : NSManagedObject

@property (nonatomic, retain) NSString * userId;
@property (nonatomic, retain) NSString * userToken;
@property (nonatomic, retain) NSNumber * locationDistanceInterval;
@property (nonatomic, retain) NSNumber * locationTimeInterval;
@property (nonatomic, retain) NSString * folderId;
@property (nonatomic, retain) NSString * folderName;


// get the current user for the application
+ (User *)currentUserInContext:(NSManagedObjectContext *)context;

/**
 @name create or change the current user
 
 @discussion will reset the existing user with default values or create a new one if none exist.
 This method will set a default folder Id for the user associated to the OpenUDID value for this phone
 the folder id can be however anything you want but must be a unique Id you can remember.
 
 @param userIdentifier is the userID in the PrYv API
 @param token is the user Authorization token to connect to the PrYv API
 */

+ (User *)newUserWithId:(NSString *)userIdentifier token:(NSString *)token inContext:(NSManagedObjectContext *)context;


@end
