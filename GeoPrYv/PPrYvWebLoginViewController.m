//
//  PPrYvWebLoginViewController.m
//  AT PrYv
//
//  Created by Konstantin Dorodov on 3/8/13.
//  Copyright (c) 2013 Pryv. All rights reserved.
//

#import "PPrYvWebLoginViewController.h"
#import "AFNetworking.h"

@interface PPrYvWebLoginViewController () <UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingActivityIndicatorView;

@end


@implementation PPrYvWebLoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.webView.delegate = self;
    
    [self requestLoginView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private

// POST request to /access to obtain a login page URL and load the contents of the URL
//      (which is a login form) to a child webView
//      activate a timer loop 

- (void)requestLoginView
{
    // TODO extract the url to a more meaningful place
    NSURL *url = [NSURL URLWithString:@"https://reg.rec.la"];
    
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    httpClient.parameterEncoding = AFJSONParameterEncoding;
    [httpClient setDefaultHeader:@"Accept" value:@"application/json"];
    [httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
    
    NSDictionary *params = @{
                             // TODO extract the app id some where to constants
                             @"requestingAppId": @"pryv-mobile-position-ios",
                             @"returnURL": @"false",
                             // TODO: permissisions has to be fixed to be more appropriate
                             @"requestedPermissions": @[
                                     @{
                                         @"channelId" : @"diary",
                                         @"level" : @"read",
                                         @"defaultName" : @"Journal",
                                         @"folderPermissions" : @[
                                                 @{
                                                     @"folderId": @"notes",
                                                     @"level": @"manage",
                                                     @"defaultName": @"Notes"
                                                     }]
                                         },
                                     @{
                                         @"channelId" : @"position",
                                         @"level" : @"read",
                                         @"defaultName" : @"Position",
                                         @"folderPermissions" : @[
                                                 @{
                                                     @"folderId": @"iphone",
                                                     @"level": @"manage",
                                                     @"defaultName": @"iPhone"
                                                     }]
                                         }
                                     ]
                             };

    [self.loadingActivityIndicatorView startAnimating];
    
    [httpClient postPath:@"/access" parameters:params success:^(AFHTTPRequestOperation *operation, id JSON) {
        assert(JSON);
        NSLog(@"Request Successful, response '%@'", JSON);
        
        assert([JSON isKindOfClass:[NSDictionary class]]);
        NSDictionary *jsonDictionary = (NSDictionary *)JSON;

        assert([JSON objectForKey:@"url"]);
        NSString *loginPageUrlString = jsonDictionary[@"url"];
        
        NSURL *loginPageURL = [NSURL URLWithString:loginPageUrlString];
        assert(loginPageURL);

        [self.webView loadRequest:[NSURLRequest requestWithURL:loginPageURL]];
        
        // TODO activate a poll loop with repeating timer
    
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        [self.loadingActivityIndicatorView stopAnimating];
        
        // TODO create an alert to notify a user about the problem
        //  like the network not being present
        
        NSLog(@"[HTTPClient Error]: %@", error);
    }];
}


#pragma mark - Target Actions

- (IBAction)close:(id)sender
{
    // TODO
    [self dismissViewControllerAnimated:YES completion:^{
        //
    }];
}

#pragma mark - UIWebViewDelegate 

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSLog(@"shouldStartLoadWithRequest ");
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [self.loadingActivityIndicatorView startAnimating];

    NSLog(@"webViewDidStartLoad ");
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    // TODO
    
    [self.loadingActivityIndicatorView stopAnimating];

    NSLog(@"webViewDidFinishLoad");
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    // TODO create an alert to notify a user of an error
    
    [self.loadingActivityIndicatorView stopAnimating];

    NSLog(@"didFailLoadWithError %@", [error localizedDescription]);
}


@end
