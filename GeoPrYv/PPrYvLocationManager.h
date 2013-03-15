//
//  Created by Konstantin Dorodov on 1/6/13.
//  Copyright (c) 2012 PrYv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface PPrYvLocationManager : NSObject<CLLocationManagerDelegate>

+ (PPrYvLocationManager *)sharedInstance;

- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;

- (void)applicationDidEnterBackground:(UIApplication *)application;
- (void)applicationWillEnterForeground:(UIApplication *)application;

@end
