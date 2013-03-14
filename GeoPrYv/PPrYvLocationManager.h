//
//  Created by Konstantin Dorodov on 1/6/13.
//  Copyright (c) 2012 PrYv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface PPrYvLocationManager : NSObject<CLLocationManagerDelegate>

// the location manager responsible for tracking the location we want to store on the PrYv API
@property (nonatomic, strong) CLLocationManager *locationManager;

+ (PPrYvLocationManager *)sharedInstance;

- (void)applicationDidEnterBackground:(UIApplication *)application;
- (void)applicationWillEnterForeground:(UIApplication *)application;

@end
