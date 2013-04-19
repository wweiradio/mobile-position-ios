//
//  Created by Konstantin Dorodov on 1/4/13.
//  Copyright (c) 2013 PrYv. All rights reserved.
//


#import "User+Extras.h"
#import "PPrYvOpenUDID.h"
#import <CoreLocation/CoreLocation.h>

@implementation User (Extras)

+ (User *)createUserWithId:(NSString *)userIdentifier token:(NSString *)token inContext:(NSManagedObjectContext *)context {

    User *newUser = [User currentUserInContext:context];

    if (newUser == nil) {
        newUser = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:context];
    }

    newUser.userId = userIdentifier;
    newUser.userToken = token;
    newUser.locationDistanceInterval = [NSNumber numberWithDouble:30];
    newUser.desiredAccuracy = [NSNumber numberWithDouble:kCLLocationAccuracyNearestTenMeters];
    newUser.locationTimeInterval = [NSNumber numberWithDouble:30];
    newUser.horizontalAccuracyThreshold = [NSNumber numberWithDouble:100];
    newUser.folderId = [PPrYvOpenUDID value];
    newUser.folderName = [[UIDevice currentDevice] name];
    
    [context save:nil];
    
    return newUser;
}

+ (User *)currentUserInContext:(NSManagedObjectContext *)context {

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"User"];

    return [[context executeFetchRequest:request error:nil] lastObject];
}


@end