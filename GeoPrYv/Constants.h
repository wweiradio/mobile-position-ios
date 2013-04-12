//
//  Created by Konstantin Dorodov on 1/6/13.
//  Copyright (c) 2012 PrYv. All rights reserved.
//

// notifications

#define kPrYvFinishedSendingLocationNotification @"PrYvFinishedSendingLocationNotification"

#define kPrYvLocationDistanceIntervalDidChangeNotification @"PrYvLocationDistanceIntervalDidChangeNotification"
#define kPrYvLocationTimeIntervalDidChangeNotification @"PrYvLocationTimeIntervalDidChangeNotification"
#define kPrYvLocationManagerDidAcceptNewLocationNotification @"kPrYvLocationManagerDidAcceptNewLocationNotification"

// notification keys in userInfo dictionary

#define kPrYvLocationDistanceIntervalDidChangeNotificationUserInfoKey  @"PrYvLocationDistanceIntervalDidChangeNotificationUserInfoKey"
#define kPrYvLocationTimeIntervalDidChangeNotificationUserInfoKey @"PrYvLocationTimeIntervalDidChangeNotificationUserInfoKey"


#define kPrYvApplicationChannelId @"position"
#define kPrYvApplicationChannelName @"Position"

// in meters
#define kPrYvMinimumDistanceBetweenConsecutiveEvents 10

// maximum length of the note in characters
// TODO rename
#define kPrYvMaximumNoteLength 4194304
