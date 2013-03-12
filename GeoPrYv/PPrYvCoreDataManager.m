//
//  Created by Konstantin Dorodov on 1/7/13.
//  Copyright (c) 2012 PrYv. All rights reserved.
//


#import "PPrYvCoreDataManager.h"

@interface PPrYvCoreDataManager ()
- (NSURL *)applicationDocumentsDirectory;
@end

@implementation PPrYvCoreDataManager {
}

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;

NSString * const kDataManagerModelName = @"ATPrYv";
NSString * const kDataManagerSQLiteName = @"ATPrYv.sqlite";

+ (PPrYvCoreDataManager*)sharedInstance
{
	static dispatch_once_t pred;
	static PPrYvCoreDataManager *sharedInstance = nil;
	dispatch_once(&pred, ^{
        sharedInstance = [[self alloc] init];
    });
	return sharedInstance;
}

#pragma mark - Core Data stack

- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

- (NSManagedObjectContext *)scratchManagedObjectContext
{
    NSManagedObjectContext *scratchManagedObjectContext = nil;
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        scratchManagedObjectContext = [[NSManagedObjectContext alloc] init];
        [scratchManagedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return scratchManagedObjectContext;
}


- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }

    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:kDataManagerModelName withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];

    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {

        return _persistentStoreCoordinator;
    }

    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:kDataManagerSQLiteName];

    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];

    // Define the Core Data version migration options
    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES};
    
    NSPersistentStore *persistentStore = [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                                                   configuration:nil
                                                                                             URL:storeURL
                                                                                         options:options
                                                                                           error:&error];
    if (!persistentStore) {
        /*
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         */
        
        NSLog(@"===============================================================================");
        NSLog(@"ATTENTION! The core data model is different from your current persistent store");
        NSLog(@"           Please delete current application on the iDevice       ");
        NSLog(@"           or the iOS Simulator. This would delete the outdated persistent store too. ");
        NSLog(@"===============================================================================");
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }

    return _persistentStoreCoordinator;
}

#pragma mark - Core Data Helpers

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext * managedObjectContext = self.managedObjectContext;

    if (managedObjectContext != nil) {

        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {

            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

#pragma mark - 

- (void)deleteManagedObjectsWithName:(NSString *)entityName
{
    NSFetchRequest *allEntitiesFetchRequest = [[NSFetchRequest alloc] init];
    [allEntitiesFetchRequest setEntity:[NSEntityDescription entityForName:entityName
                                                   inManagedObjectContext:self.managedObjectContext]];
    [allEntitiesFetchRequest setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSError *error = nil;
    NSArray *allEntities = [self.managedObjectContext executeFetchRequest:allEntitiesFetchRequest error:&error];
    if (!allEntities) {
        //error handling goes here
        NSLog(@"failed fetch all entities of type %@ with error: %@ ", entityName, error);
        return;
    }
    for (NSManagedObject *entity in allEntities) {
        [self.managedObjectContext deleteObject:entity];
    }
    NSError *saveError = nil;
    if (![self.managedObjectContext save:&saveError]) {
        //more error handling here
        NSLog(@"failed to save the context %@", saveError);
    }
}

- (void)destroyAllData
{
    [self deleteManagedObjectsWithName:@"PositionEvent"];
    [self deleteManagedObjectsWithName:@"User"];
}



@end