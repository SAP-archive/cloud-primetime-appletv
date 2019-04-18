//
//  ViewController.h
//  PrimeTime
//
//  Created by Eberlein, Peter on 29.11.17.
//  Copyright © 2017 Peter Eberlein. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (strong, nonatomic) UITextView *textview;
@property (strong, nonatomic) id webview;

- (NSData*)screenshot;

@end

