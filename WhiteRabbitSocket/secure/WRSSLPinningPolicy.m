//
//  WRSSLPinningPolicy.m
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 22/10/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import "WRSSLPinningPolicy.h"

@implementation WRSSLPinningPolicy {
    NSArray *_pinnedCertificates;
}

- (instancetype)initWithCertificates:(NSArray *)pinnedCertificates
{
    self = [super initWithCertificateChainValidationEnabled:NO];
    if (self != nil) {
        if (pinnedCertificates.count == 0) {
            @throw [NSException exceptionWithName:@"Creating security policy failed."
                                           reason:@"Must specify at least one certificate when creating a pinning policy."
                                         userInfo:nil];
        }
        _pinnedCertificates = [pinnedCertificates copy];
    }

    return self;
}

- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust domain:(NSString *)domain
{
    NSUInteger requiredCertCount = _pinnedCertificates.count;
    
    NSUInteger validatedCertCount = 0;
    CFIndex serverCertCount = SecTrustGetCertificateCount(serverTrust);
    for (CFIndex i = 0; i < serverCertCount; i++) {
        SecCertificateRef cert = SecTrustGetCertificateAtIndex(serverTrust, i);
        NSData *data = CFBridgingRelease(SecCertificateCopyData(cert));
        for (id ref in _pinnedCertificates) {
            SecCertificateRef trustedCert = (__bridge SecCertificateRef)ref;
            NSData *trustedCertData = CFBridgingRelease(SecCertificateCopyData(trustedCert));
            if ([trustedCertData isEqualToData:data]) {
                validatedCertCount++;
                break;
            }
        }
    }
    
    return requiredCertCount == validatedCertCount;
}

@end
