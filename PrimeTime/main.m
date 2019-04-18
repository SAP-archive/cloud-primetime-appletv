//
//  main.m
//  PrimeTime
//
//  Created by Eberlein, Peter on 29.11.17.
//  Copyright © 2017 Peter Eberlein. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"


void ExceptionHandler(NSException *exception) {
    NSArray *callStack = [exception callStackSymbols];
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey];
    
    NSDictionary *dump = @{@"exception"  : exception.name ? exception.name : @"<unknown>",
                           @"reason"     : exception.reason ? exception.reason : @"<unknown>",
                           @"timestamp"  : [NSISO8601DateFormatter stringFromDate:[NSDate date] timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0] formatOptions:NSISO8601DateFormatWithInternetDateTime],
                           @"version"    : appVersion ? appVersion : @"<unknown>",
                           @"stacktrace" : callStack ? [callStack componentsJoinedByString:@"\n"] : @"<unavailable>"};
    NSData *dumpData = [NSJSONSerialization dataWithJSONObject:dump options:NSJSONWritingPrettyPrinted error:nil];

    [dumpData writeToFile:[NSHomeDirectory() stringByAppendingPathComponent:APPLICATION_DUMP] atomically:NO];
}


int main(int argc, char * argv[]) {
    NSSetUncaughtExceptionHandler(&ExceptionHandler);
    
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
