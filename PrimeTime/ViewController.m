//
//  ViewController.m
//  PrimeTime
//
//  Created by Eberlein, Peter on 29.11.17.
//  Copyright © 2017 Peter Eberlein. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import <SystemConfiguration/SCNetworkReachability.h>
#import <netinet/in.h>



@interface ViewController ()

@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    Class webviewClass = NSClassFromString(@"UIWebView");
    self.webview = [[webviewClass alloc] initWithFrame:self.view.bounds];
    [self.webview setDelegate:self];
    [self.webview setMediaPlaybackRequiresUserAction:NO]; // autoplay videos but ensure that also the <audio> or <video> element you want to play has the autoplay attribute set
    
    UIScrollView *scrollView = [self.webview scrollView];
    scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever; // otherwise the content is offset to the lower right
    
    [self.view addSubview:self.webview];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSURL *requestURL = appDelegate.homepageURL;
    if (requestURL) {
        NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
        [self.webview loadRequest:request];
    }
}


- (void)webView:(id)webView didFailLoadWithError:(NSError *)error {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([[error.userInfo objectForKey:NSURLErrorFailingURLErrorKey] isEqual:appDelegate.homepageURL]) { // only reload if main page failes, ignore other failures
        NSLog(@"Failed loading main page, retrying in a few seconds...: %@", error);
    
        NSURLRequest *request = [NSURLRequest requestWithURL:appDelegate.homepageURL];
        [webView performSelector:@selector(loadRequest:) withObject:request afterDelay:8]; // 8 dec delay
    }
}


- (BOOL)webView:(id)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(NSInteger)navigationType {
    NSURL *url = request.URL;
    if ([url.scheme isEqualToString:@"primetime"]) { // URL format: primetime://<function>?<key1>=<value1>&<key2>=<value2>&...
        NSString *function = url.host;
        NSArray *parameters = [url.query componentsSeparatedByString:@"&"];
        if ([function isEqualToString:@"screenshot"]) {
            NSString *screen;
            NSString *delay;
            for (NSString *parameter in parameters) {
                NSArray *keyvalue = [parameter componentsSeparatedByString:@"="];
                if (keyvalue.count == 2) {
                    if ([keyvalue[0] isEqualToString:@"screen"]) {
                        screen = keyvalue[1];
                    }
                    if ([keyvalue[0] isEqualToString:@"delay"]) {
                        delay = keyvalue[1];
                    }
                }
            }

            NSTimeInterval delayInterval = [delay doubleValue];
            NSLog(@"Scheduling screenshot for screen %@ in %.0f seconds", screen, delayInterval);
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate performSelector:@selector(sendScreenshot:) withObject:screen afterDelay:delayInterval];
        }
        return NO;
    }
    
    return YES;
}


- (NSData*)screenshot {
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, YES, 0.0);
    [self.view drawViewHierarchyInRect:self.view.bounds afterScreenUpdates:NO];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // UIImageJPEGRepresentation crashes sometimes with BufferIsNotReadable, therefore use PNG instead
    return UIImagePNGRepresentation(image);
}


@end


