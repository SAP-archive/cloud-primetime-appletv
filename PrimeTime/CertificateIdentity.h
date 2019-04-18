//
//  CertificateIdentity.h
//  PrimeTime
//
//  Created by Eberlein, Peter on 11.01.13.
//  Copyright (c) 2013 SAP AG. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CertificateIdentity : NSObject{
    SecIdentityRef _identity;
}

@property (nonatomic, strong) NSString *subject;
@property (nonatomic, readonly) SecIdentityRef identity;
@property (nonatomic, strong) NSArray *certificates;
@property (nonatomic, assign, getter = isValid) BOOL valid;

- (id)initWithP12Data:(NSData*)p12Data password:(NSString*)password;

@end
