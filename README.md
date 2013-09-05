# Pryv position iOS

AT PrYv is an iPhone and iPad application that allows you to store or retrieve your location online using the [**PrYv API**](http://dev.pryv.com/), and see past locations according to the desired period of time on a map.

Mainly, This application is a location tracker that will also run in background and regularly send update of your location to the PrYv API or store them locally until the network becomes available again. This application is an exemple of what PrYv allows you to do. AT PrYv sends and retrieves what is known on PrYv as `Events`. PrYv allows you to store events of any type. They basically are JSON dictionaries with id's.

We have built into AT PrYv a `PrYvApiClient` class to simplify the storing and retrieving of events of type location. It's block based and very easy to use. 
`PrYvApiClient` class operate with the [AFNetworking](https://github.com/AFNetworking/AFNetworking) library to manage all the HTTP protocol. We invite you to fork it in order to build upon the `PrYvAPIClient` Class.

**PrYvApiClient**
-------

To use the **PrYvApiClient.h** Singleton Class you simply import the `PrYvApiClient.h` in your `AppDelegate.m` and in the method:

`- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions`

**You initialize the `PrYvApiClient` by calling:**



    PPrYvApiClient *apiClient = [PPrYvApiClient sharedClient];
    
        [apiClient startClientWithUserId:@"{userId}"
                              oAuthToken:@"{userToken}"
                               channelId:@"{applicationChannel}" successHandler:^(NSTimeInterval serverTime)
        {

            // your success code here
        }                   errorHandler:^(NSError *error)
        {
            // your failure code here
        }];

Where `{userId}`,`{userToken}`,`{applicationChannel}` are your credentials.

The `sucessHandler` give you an `NSTimerInterval serverTime` variable. This allows you to synchronize your application with the server. *You should always use `serverTime` to synchronize your app with the server.* It's not required but it's the way for you to be sure that dates within your user application are synchronized with the server. `serverTime` contain the server Unix Timestamp which you can turn into an NSDate using the `timeIntervalSince1970:` method if needed.

Once your PPrYvApiClient has been started, you can use it to send and retrieve events by calling it whenever you need it within your application using `[PPrYvApiClient sharedClient]`.

You can re-synchronize your client using the method

    [[PPrYvApiClient sharedClient] synchronizeTimeWithSuccessHandler:^(NSTimeInterval serverTime) {
        // your code here
    } errorHandler:^(NSError *error) {
        // your code here    
    }];
    

The PrYvApiClient has several methods to send a new event

Send Position Event with

    - (void)sendEvent:(PositionEvent *)event 
    completionHandler:(void(^)(NSString *eventId, NSError *error))completionHandler;

Update Position Event duration with:

    - (void)updateEvent:(PositionEvent *)event 
      completionHandler:(void(^)(NSString *eventId, NSError *error))completionHandler;

Send Note Event with

    - (void)sendNoteEvent:(PositionEvent *)event
        completionHandler:(void(^)(NSString *eventId, NSError *error))completionHandler;

Send Picture event with

    - (void)sendPictureEvent:(PositionEvent *)event
           completionHandler:(void(^)(NSString *eventId, NSError *error))completionHandler;
    
              
and one method to retrieve events from a time period:

    - (void)getEventsFromStartDate:(NSDate *)startDate
                     toEndDate:(NSDate *)endDate
                    inFolderId:(NSString *)folderId
                successHandler:(void (^)(NSArray *positionEventList))successHandler
                  errorHandler:(void(^)(NSError *error))errorHandler;
                  
If you pass nil to both start and end date you will get event from the last 24h. If you pass nil to folderId you will get events from all folders.

**Location Events**
-------

To send a location event, you first need to create a `PositionEvent` object using the PositionEvent class method

    + (PositionEvent *)createPositionEventInLocation:(CLLocation *)location
                                     withMessage:(NSString *)message
                                      attachment:(NSURL *)fileURL
                                          folder:(NSString *)folderId
                                       inContext:(NSManagedObjectContext *)context;
                                       

You then initialize a `PPrYvPositionEventSender` by passing it a position by calling the method:

    - (id)initWithPositionEvent:(PositionEvent *)positionEvent;

You can then send your position event by calling the method `sendToPrYvApiCompletion:` on your `PPrYvPositionEventSender` object. 

`PPrYvPositionEventSender` communicate with the `PPrYvApiClient` and manage the request.

**Example on how to send a position event**

    PositionEvent *locationEvent = [PositionEvent createPositionEventInLocation:location
                                                                    withMessage:nil attachment:nil folder:user.folderId
                                                                      inContext:context
    [[[PPrYvPositionEventSender alloc] initWithPositionEvent:locationEvent] sendToPrYvApiCompletion:^{
      // do something when event was sent or failure occured
    }];

You need to call the method `sendAllPendingEventsToPrYvApi` right after synchronization with the server to send all events that couldn't be uploaded before.
    
// 
    [PPrYvPositionEventSender sendAllPendingEventsToPrYvApi]


_____
The location system works as follow:

A delegate method is called whenever a new location is retrieved by the CCLocationManager. The CLLocationManager has it’s own distanceFilter property that allows us to filter the distance before the delegate gets called. 

Application ignores locations with latitude/longitude 0/0.
 
Two location events are considered the same if they are close enough to each other: a distance between them is 
smaller or equal to (horizontalAccuracy of location) + (min distance Interval between location of consecutive events)
Minimal distance between position events is configurable in the Settings section.

Location Manager's `ditstanceFilter` is also configurable in the Settings section.

The manager also have a property `desiredAccuracy` to decide which kind of accuracy we want. The higher accuracy the more battery consumption. Its default value has been set to kCLLocationAccuracyNearestTenMeters. 
`iOS Service Accuracy` can be adjusted in the Settings section.

The retrieved location is then tested for its accuracy and validity, if the accuracy of location it not good enough the location is rejected (>100m: default, if this number is set lower, most location would be rejected).
This parameter is configurable in the Settings section ("Ignore Locations With Horizontal Accuracy Bigger Than").

Then if the application is operating in foreground, a timer run continuously and allows for new locations to be considered and used every x minutes. (A setting configurable in the Setings section)

When the application is running in background, The timer cannot continue to operate, so the system compare the current date and time to the last one associated with the last accepted location.

If the time interval is long enough the new location is taken into account. Otherwise, it is let go until a new location is returned by the delegate. 

Once a location has passed all the tests it is sent to the server and added locally on the map.

_____
For more informations, you can visit the [**PrYv API**](http://dev.pryv.com/) reference website.

Feel free to fork and improve this API!


## License

[Revised BSD license](https://github.com/pryv/documents/blob/master/license-bsd-revised.md)
