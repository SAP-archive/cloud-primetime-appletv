//
//  AppDelegate.h
//  PrimeTime
//
//  Created by Eberlein, Peter on 29.11.17.
//  Copyright © 2017 Peter Eberlein. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CertificateIdentity.h"

#define APPLICATION_DUMP @"applicationDump.txt"

@interface AppDelegate : UIResponder <UIApplicationDelegate, NSURLSessionDelegate>

- (void)sendScreenshot:(NSString*)screen;

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) CertificateIdentity *user;
@property (strong, nonatomic) NSURL *homepageURL;

@property (strong, nonatomic) NSURL *reportingURL;
@property (strong, nonatomic) NSURLSession *reportingUploadSession;
@property (strong, nonatomic) NSURLSessionUploadTask *reportingUploadTask;

@property (strong, nonatomic) NSURL *configURL;
@property (strong, nonatomic) NSTimer *configTimer;
@property (strong, nonatomic) NSURLSession *configDownloadSession;
@property (strong, nonatomic) NSURLSessionDownloadTask *configDownloadTask;

@property (strong, nonatomic) NSURL *screenshotURL;
@property (strong, nonatomic) NSTimer *screenshotTimer;
@property (strong, nonatomic) NSURLSession *screenshotUploadSession;
@property (strong, nonatomic) NSURLSessionUploadTask *screenshotUploadTask;

@property (strong, nonatomic) NSTimer *reloadTimer;
@property (strong, nonatomic) NSURLSession *reloadDownloadSession;
@property (strong, nonatomic) NSURLSessionDownloadTask *reloadDownloadTask;

@end

