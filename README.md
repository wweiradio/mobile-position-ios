AT PrYv
=======

AT PrYv is an iPhone and iPad application that allows you to store or retrieve your location online using the [**PrYv API**](http://dev.pryv.com/), and see past locations according to the desired period of time on a map.

Mainly, This application is a location tracker that will also run in background and regularly send update of your location to the PrYv API or store them locally until the network becomes available again. This application is an exemple of what PrYv allows you to do. AT PrYv sends and retrieves what is known on PrYv as `Events`. PrYv allows you to store events of any type. They basically are JSON dictionaries with id's.

We have built into AT PrYv a `PrYvApiClient` class to simplify the storing and retrieving of events of type location. It's block based and very easy to use. 
`PrYvApiClient` class operate with the [AFNetworking](https://github.com/AFNetworking/AFNetworking) library to manage all the HTTP protocol. We invite you to fork it in order to build upon the `PrYvAPIClient` Class.

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

Once your PPrYvApiClient has been started, you can use it to send and retrieve events by calling it whenever you need it within your application using `[PPrYvApiClient sharedClient]`

**Location Events**

To send a location event, you first need to create a `PositionEvent` object using the PositionEvent class method

    + (PositionEvent *)createPositionEventInLocation:(CLLocation *)location
                                     withMessage:(NSString *)message
                                      attachment:(NSURL *)fileURL
                                          folder:(NSString *)folderId
                                       inContext:(NSManagedObjectContext *)context;
                                       

You then initialize a `PPrYvPositionEventSender` by passing it a position by calling the method:

    - (id)initWithPositionEvent:(PositionEvent *)positionEvent;

You can then send your position event by calling the method `sendToPrYvApi` on your `PPrYvPositionEventSender` object. 

**Example on how to send a position event**

    PositionEvent *locationEvent = [PositionEvent createPositionEventInLocation:location
                                                                    withMessage:nil attachment:nil folder:user.folderId
                                                                      inContext:context
    [[[PPrYvPositionEventSender alloc] initWithPositionEvent:locationEvent] sendToPrYvApi];


    

**PrYvApiClient**

The PrYvApiClient which is used by the `PPrYvPositionEventSender` has one method to send a new event

    - (void)sendEvent:(PositionEvent *)event
        withSuccessHandler:(void(^)(void))successHandler
              errorHandler:(void(^)(NSError *error))errorHandler;
              
and one method to retrieve events from a time period

    - (void)getEventsFromStartDate:(NSDate *)startDate
                     toEndDate:(NSDate *)endDate
                    inFolderId:(NSString *)folderId
                successHandler:(void (^)(NSArray *positionEventList))successHandler
                  errorHandler:(void(^)(NSError *error))errorHandler;
                  
If you pass nil to both start and end date you will get event from the last 24h. If you pass nil to folderId you will get events from all folders.

For more informations, you can visit the [**PrYv API**](http://dev.pryv.com/) reference website.

Feel free to fork and improve this API!
