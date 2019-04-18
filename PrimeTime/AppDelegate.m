//
//  AppDelegate.m
//  PrimeTime
//
//  Created by Eberlein, Peter on 29.11.17.
//  Copyright © 2017 Peter Eberlein. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "CustomHTTPProtocol.h"

@interface AppDelegate () <CustomHTTPProtocolDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // AppleTV UserAgent: Mozilla/5.0 (iPhone; CPU iPhone OS 11_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15L211
    // Mac OS  UserAgent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_4) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/11.1 Safari/605.1.15
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults registerDefaults:@{@"UserAgent" : @"Mozilla/5.0 (AppleTV like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Safari/15L211"}]; // override mobile client to show desktop view

    NSString *clientIDkey = @"client_id";
    NSString *clientID = [userDefaults stringForKey:clientIDkey];
    if (clientID == nil) {
        clientID = [[NSUUID UUID] UUIDString];
        [userDefaults setObject:clientID forKey:clientIDkey];
    }
    
    NSDictionary *startConfiguration = [self startConfiguration];
    
    NSString *certificatePassphrase = [startConfiguration objectForKey:@"passphrase"];
    NSData *certificateData = [[NSData alloc] initWithBase64EncodedString:[startConfiguration objectForKey:@"certificate"] options:0];
    self.user = [[CertificateIdentity alloc] initWithP12Data:certificateData password:certificatePassphrase];
    
    // install certifcate handler
    [CustomHTTPProtocol setDelegate:self];
    [CustomHTTPProtocol start];
    
    NSString *reportingPath = [startConfiguration objectForKey:@"reportingURL"];
    if (reportingPath) {
        self.reportingURL = [NSURL URLWithString:[NSString stringWithFormat:reportingPath, clientID]];
        NSLog(@"Reporting URL is %@", self.reportingURL);
        self.reportingUploadSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
        
        [self reportApplicationStart];
    } else {
        NSLog(@"Reporting URL not configured, cannot report application start");
    }
    
    NSString *homepagePath = [startConfiguration objectForKey:@"homepageURL"];
    if (homepagePath) {
        self.homepageURL = [NSURL URLWithString:[NSString stringWithFormat:homepagePath, clientID]];
        NSLog(@"Homepage URL is %@", self.homepageURL);
    } else {
        NSLog(@"Homepage URL not configured, cannot display screen");
    }
    
    NSString *screenshotPath = [startConfiguration objectForKey:@"screenshotURL"];
    if (screenshotPath) {
        self.screenshotURL = [NSURL URLWithString:[NSString stringWithFormat:screenshotPath, clientID]];
        NSLog(@"Screenshot URL is %@", self.screenshotURL);
        self.screenshotUploadSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
    } else {
        NSLog(@"Screenshot URL not configured, cannot send screenshots");
    }
    
    NSString *infoPath = [startConfiguration objectForKey:@"configURL"];
    if (infoPath) {
        self.configURL = [NSURL URLWithString:[NSString stringWithFormat:infoPath, clientID]]; 
        NSLog(@"Info URL is %@", self.configURL);
        self.configDownloadSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
        
        [self setConfigTimerToInterval:60]; // short initial refresh interval to read the config quickly (including the actual refresh interval) if the first call fails
        [self downloadConfig];              // perform the initial config load immediately; if it fails, the refresh timer will retry
            
    } else {
        NSLog(@"Info URL not configured, cannot read server configuration");
    }

    return YES;
}


-(NSDictionary *)startConfiguration
{
#ifdef USE_CONFIG // read config.plist from main bundle for local testing without MDM
    NSURL *startConfigurationURL = [[NSBundle mainBundle] resourceURL];
    return [NSDictionary dictionaryWithContentsOfURL:[startConfigurationURL URLByAppendingPathComponent:@"config.plist"]];
#else        // read config.plist from user defaults injected by MDM
    return [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"com.apple.configuration.managed"];
#endif
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    return YES;
}


#pragma mark Timer

- (void)setConfigTimerToInterval:(NSTimeInterval)configInterval
{
    if (self.configTimer) {
        if (configInterval != self.configTimer.timeInterval) {
            NSLog(@"Config time interval has changed from %.0f seconds to %.0f seconds, resetting timer", self.configTimer.timeInterval, configInterval);
            [self.configTimer invalidate];
        } else {
            return; // nothing has changed, nothing to do
        }
    } else {
        NSLog(@"Setting config time interval to %.0f seconds", configInterval);
    }

    if (configInterval > 0) {
        self.configTimer = [NSTimer scheduledTimerWithTimeInterval:configInterval
                                                            target:self
                                                          selector:@selector(downloadConfig)
                                                          userInfo:nil
                                                           repeats:YES];
    }
}


- (void)setReloadTimerToInterval:(NSTimeInterval)reloadInterval
{
    if (self.reloadTimer) {
        if (reloadInterval != self.reloadTimer.timeInterval) {
            NSLog(@"Reload time interval has changed from %.0f seconds to %.0f seconds, resetting timer", self.reloadTimer.timeInterval, reloadInterval);
            [self.reloadTimer invalidate];
        } else {
            return; // nothing has changed, nothing to do
        }
    } else {
        NSLog(@"Setting reload time interval to %.0f seconds", reloadInterval);
    }
    
    if (reloadInterval > 0) {
        self.reloadTimer = [NSTimer scheduledTimerWithTimeInterval:reloadInterval
                                                            target:self
                                                          selector:@selector(reloadHomepage)
                                                          userInfo:nil
                                                           repeats:YES];
    }
}


- (void)setScreenshotTimerToInterval:(NSTimeInterval)screenshotInterval
{
    if (self.screenshotTimer) {
        if (screenshotInterval != self.screenshotTimer.timeInterval) {
            NSLog(@"Screenshot time interval has changed from %.0f seconds to %.0f seconds, resetting timer", self.screenshotTimer.timeInterval, screenshotInterval);
            [self.screenshotTimer invalidate];
        } else {
            return; // nothing has changed, nothing to do
        }
    } else {
        NSLog(@"Setting screenshot time interval to %.0f seconds", screenshotInterval);
    }
    
    if (screenshotInterval > 0) {
        [self sendScreenshot:nil]; // send a first screenshot right now because the timer fires for the first time only at the end of the interval, not at the beginning
        self.screenshotTimer = [NSTimer scheduledTimerWithTimeInterval:screenshotInterval
                                                                target:self
                                                              selector:@selector(sendScreenshot:)
                                                              userInfo:nil
                                                               repeats:YES];
    }
}

#pragma mark Server config

- (void)downloadConfig
{
    [self.configDownloadTask cancel]; // if there is still an old pending download task then kill it

    self.configDownloadTask = [self.configDownloadSession downloadTaskWithURL:self.configURL completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Config download task failed with HTTP code %ld, error: %@", [(NSHTTPURLResponse *)response statusCode], error);
        } else if (location) {
            [self performSelectorOnMainThread:@selector(loadConfigFromLocation:) withObject:location waitUntilDone:YES]; // scheduling timers must happen on main task
        } else {
            NSLog(@"Config download task did not load config data");
        }
    }];
    [self.configDownloadTask resume];
}
                               

- (void)loadConfigFromLocation:(NSURL*)location
{
    NSData *downloadedData = [NSData dataWithContentsOfURL:location];
    if (downloadedData) {
        NSError *error = nil;
        NSDictionary *remoteConfig = [NSJSONSerialization JSONObjectWithData:downloadedData options:0 error:&error];
        if (remoteConfig) {
            NSLog(@"Loading new configuration: %@", remoteConfig);
            
            NSString *configInterval = [remoteConfig objectForKey:@"configRefreshInterval"];
            if (configInterval) {
                [self setConfigTimerToInterval:[configInterval doubleValue]];
            }

            NSString *screenshotInterval = [remoteConfig objectForKey:@"screenshotInterval"];
            if (screenshotInterval) {
                [self setScreenshotTimerToInterval:[screenshotInterval doubleValue]];
            }

            NSString *reloadInterval = [remoteConfig objectForKey:@"reloadInterval"];
            if (reloadInterval) {
                [self setReloadTimerToInterval:[reloadInterval doubleValue]];
            }
            
        } else {
            NSLog(@"Could not read configuration JSON: %@\n%@", [[NSString alloc] initWithData:downloadedData encoding:NSUTF8StringEncoding], error);
        }
    } else {
        NSLog(@"Could not load config data from location %@", location);
    }
}


#pragma mark Reload homepage feature

- (ViewController*)viewController
{
    return (ViewController*)self.window.rootViewController;
}


- (void)reloadHomepage
{
    NSLog(@"Reloading homepage from %@", self.homepageURL);
    NSURLRequest *request = [NSURLRequest requestWithURL:self.homepageURL];
    [self.viewController.webview loadRequest:request];
}

#pragma mark Error reporting feature

/*
    This method is supposed to be called once at application launch.
 
    It reports the start of the app to the server to draw attention to repeated app starts that might go unnoticed due to automatic restarts in single app mode.
 
    If the app crashed and left a dump then this dump is included as body when the application start is reported
 */
- (void)reportApplicationStart
{
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey];
    NSMutableDictionary *report = [NSMutableDictionary dictionaryWithDictionary:
                                   @{@"timestamp"  : [NSISO8601DateFormatter stringFromDate:[NSDate date] timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0] formatOptions:NSISO8601DateFormatWithInternetDateTime],
                                     @"version"    : appVersion ? appVersion : @"<unknown>"}];
    
    NSJSONSerialization *dump;
    NSString *dumpFile = [NSHomeDirectory() stringByAppendingPathComponent:APPLICATION_DUMP];
    NSData *dumpData = [NSData dataWithContentsOfFile:dumpFile];
    if (dumpData) {
        dump = [NSJSONSerialization JSONObjectWithData:dumpData options:0 error:nil];
        if (dump) {
            NSLog(@"Reporting dump: %@", dump);
            [report setValue:dump forKey:@"dump"];
        }
    }
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:self.reportingURL];
    urlRequest.HTTPMethod = @"POST";
        
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
     
    self.reportingUploadTask = [self.reportingUploadSession uploadTaskWithRequest:urlRequest
                                                                         fromData:[NSJSONSerialization dataWithJSONObject:report options:NSJSONWritingPrettyPrinted error:nil]
                                                                completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Reporting upload task failed with HTTP code %ld, error: %@", [(NSHTTPURLResponse *)response statusCode], error);
        } else {
            long statusCode = [(NSHTTPURLResponse *)response statusCode];
            NSLog(@"Reporting upload task succeeded with HTTP code %ld", statusCode);
            
            if (statusCode == 200 && dumpData) { // remove the last dump if the upload was successful
                NSError *fileError = nil;
                if (![[NSFileManager defaultManager] removeItemAtPath:dumpFile error:&fileError]) {
                    NSLog(@"Could not remove last dump at %@: %@", dumpFile, error);
                }
            }
        }
    }];
    
    [self.reportingUploadTask resume];
}

     
#pragma mark Screenshot feature

- (void)sendScreenshot:(NSString*)screen // screen is the name of the screen for which the screenshot is taken (if known) or nil (if unknown)
{
    NSData *screenshot = [self.viewController screenshot];
    
    if (screenshot) {
        [self.screenshotUploadTask cancel]; // if there is still an old pending upload task then kill it
        
        NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:self.screenshotURL];
        urlRequest.HTTPMethod = @"POST";

        // wrap image in multipart form because server cannot handle plain image/jpeg content
        NSString *boundary = @"fafFghzKlPs2fdj5Hksgh5dfjkPlQhkg";
        NSString *name = screen ? [NSString stringWithFormat:@" name=\"%@\";", screen] : @"";
        NSMutableData *body = [NSMutableData dataWithCapacity:screenshot.length + 250];
        [body appendData:[[NSString stringWithFormat:@"--%@\r\nContent-Disposition: form-data;%@ filename=\"image.png\"\r\nContent-Type: image/png\r\n\r\n", boundary, name] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:screenshot];
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        
        // would be so much nicer to use plain image/jpeg
        // [urlRequest setValue:@"image/png" forHTTPHeaderField:@"Content-Type"];
        [urlRequest setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary]
          forHTTPHeaderField:@"Content-Type"];
        
        // use multipart wrapped body instead of plain image data
        self.screenshotUploadTask = [self.screenshotUploadSession uploadTaskWithRequest:urlRequest fromData:body/*screenshot*/ completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (error) {
                NSLog(@"Screenshot upload task failed with HTTP code %ld, error: %@", [(NSHTTPURLResponse *)response statusCode], error);
            } else {
                NSLog(@"Screenshot upload task succeeded with HTTP code %ld", [(NSHTTPURLResponse *)response statusCode]);
            }
        }];
        [self.screenshotUploadTask resume];
    } else {
        NSLog(@"Could not take screenshot");
    }
}

// credentials for both CustomHTTPProtocol (UIWebView) and URLSession challenges
- (NSURLCredential*)authCredentialForChallenge:(NSURLAuthenticationChallenge *)challenge {
    NSURLCredential *credential;
    if ([[[challenge protectionSpace] authenticationMethod] isEqual:NSURLAuthenticationMethodServerTrust]) {
        credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]; // trust any server certificate
        
    } else if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodClientCertificate]) {
        credential = [[NSURLCredential alloc] initWithIdentity:self.user.identity
                                                  certificates:self.user.certificates
                                                   persistence:NSURLCredentialPersistenceForSession];
    }
    return credential;
}


#pragma mark NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler
{
    NSURLCredential *credential = [self authCredentialForChallenge:challenge];
    if (credential) {
        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
    } else {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}


#pragma mark CustomHTTPProtocol Delegate

- (void)customHTTPProtocol:(CustomHTTPProtocol *)protocol logWithFormat:(NSString *)format arguments:(va_list)arguments
{
//    NSLogv(format, arguments);
}

- (BOOL)customHTTPProtocol:(CustomHTTPProtocol *)protocol canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    NSString *authenticationMethod = [protectionSpace authenticationMethod];

    return [authenticationMethod isEqual:NSURLAuthenticationMethodServerTrust] ||
           [authenticationMethod isEqual:NSURLAuthenticationMethodClientCertificate];
}

- (void)customHTTPProtocol:(CustomHTTPProtocol *)protocol didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    NSURLCredential *credential = [self authCredentialForChallenge:challenge];
    [protocol resolveAuthenticationChallenge:challenge withCredential:credential];
}

@end
