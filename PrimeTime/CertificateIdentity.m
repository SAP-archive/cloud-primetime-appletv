//
//  CertificateIdentity.m
//  PrimeTime
//
//  Created by Eberlein, Peter on 11.01.13.
//  Copyright (c) 2013 SAP AG. All rights reserved.
//

#import "CertificateIdentity.h"


@implementation CertificateIdentity

- (id)initWithP12Data:(NSData*)p12Data password:(NSString*)password
{
    self = [super init];
    if (self) {
        CFArrayRef items = NULL;
        NSDictionary *options = @{ (__bridge id)kSecImportExportPassphrase : password };
        OSStatus status = SecPKCS12Import((__bridge CFDataRef)p12Data, (__bridge CFDictionaryRef)options, &items);
        if (status == errSecSuccess) {
            CFIndex itemCount = CFArrayGetCount(items);
            if (itemCount == 1) {
                CFDictionaryRef identityDictionary = CFArrayGetValueAtIndex(items, 0);
                CFTypeRef identity = CFDictionaryGetValue(identityDictionary, kSecImportItemIdentity);
                if (identity) {
                    _identity = (SecIdentityRef)CFRetain(identity);
                    /* not needed
                    SecCertificateRef certificate = NULL;
                    if (SecIdentityCopyCertificate(_identity, &certificate) == errSecSuccess) {
                        self.subject = CFBridgingRelease(SecCertificateCopySubjectSummary(certificate));
                        CFRelease(certificate);
                    } else {
                        self.subject = NSLocalizedString(@"Unknown", @"XFLD: Unknown identity subject in digital certificate");
                    }
                    */
                    // cannot use kSecImportItemCertChain because it might contain certificates outside of the certifiate chain and SSL does not like this
                    SecTrustRef trust = (SecTrustRef)CFDictionaryGetValue(identityDictionary, kSecImportItemTrust);
                    SecTrustResultType result;
                    self.valid = ((SecTrustEvaluate(trust, &result) == errSecSuccess) && (result == kSecTrustResultProceed || result == kSecTrustResultUnspecified || result == kSecTrustResultRecoverableTrustFailure));
                    
                    CFIndex certCount = SecTrustGetCertificateCount(trust);
                    if (certCount > 1) {
                        NSMutableArray *certificates = [NSMutableArray arrayWithCapacity:certCount - 1];
                        for (CFIndex certIndex = 1; certIndex < certCount; certIndex++) {
                            SecCertificateRef certificate = SecTrustGetCertificateAtIndex(trust, certIndex);
                            [certificates addObject:(__bridge id)certificate];
                        }
                        self.certificates = certificates;
                    }
                } else {
                    NSLog(@"Could not find identity in certificate archive");
                }
            } else {
                NSLog(@"Could not import certificate archive with %ld items (must contain 1 item)", itemCount);
            }
            
            CFRelease(items);
            
        } else {
            NSLog(@"Could not import certificate archive, error code: %d", (int)status);
        }
        
        if (_identity == nil) {
            self = nil;
        }
    }
    
    return self;
}

- (SecIdentityRef)identity
{
    return _identity;
}


- (void)dealloc
{
    if (_identity) {
        CFRelease(_identity);
    }
}

@end
