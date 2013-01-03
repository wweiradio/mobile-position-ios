//
//  User.m
//  AT PrYv
//
//  Created by Nicolas Manzini on 29.12.12.
//  Copyright (c) 2012 PrYv. All rights reserved.
//

#import "User.h"
#import "PPrYvOpenUDID.h"

@implementation User

@dynamic userId;
@dynamic userToken;
@dynamic locationDistanceInterval;
@dynamic locationTimeInterval;
@dynamic folderId;
@dynamic folderName;

+ (User *)newUserWithId:(NSString *)userIdentifier token:(NSString *)token inContext:(NSManagedObjectContext *)context {
    
    User * newUser = nil;
    
    NSFetchRequest * request = [NSFetchRequest fetchRequestWithEntityName:@"User"];
    
    newUser = [[context executeFetchRequest:request error:nil] lastObject];
    
    if (newUser == nil) {
        
        newUser = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:context];
    }
    
    newUser.userId = userIdentifier;
    newUser.userToken = token;
    newUser.locationDistanceInterval = [NSNumber numberWithDouble:30];
    newUser.locationTimeInterval = [NSNumber numberWithDouble:30];
    newUser.folderId = [PPrYvOpenUDID value];
    newUser.folderName = @"userMainFolder";
    
    return newUser;
}

+ (User *)currentUserInContext:(NSManagedObjectContext *)context {
    
    NSFetchRequest * request = [NSFetchRequest fetchRequestWithEntityName:@"User"];
    
    return [[context executeFetchRequest:request error:nil] lastObject];
}
@end
