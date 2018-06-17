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
    BOOL _allowSelfSignedCertificates;
}

- (instancetype)initWithCertificates:(NSArray *)pinnedCertificates allowSelfSignedCertificates:(BOOL)allowSelfSignedCertificates {
    self = [super init];
    if (self != nil) {
        if (pinnedCertificates.count == 0) {
            @throw [NSException exceptionWithName:@"Creating security policy failed."
                                           reason:@"Must specify at least one certificate when creating a pinning policy."
                                         userInfo:nil];
        }
        _pinnedCertificates = [pinnedCertificates copy];
        _allowSelfSignedCertificates = allowSelfSignedCertificates;
    }

    return self;
}

- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust domain:(NSString *)domain {
    if (!_allowSelfSignedCertificates && ![super evaluateServerTrust:serverTrust domain:domain]) {
        return NO;
    }

    SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, 0);
    NSData *remoteCertificateData = CFBridgingRelease(SecCertificateCopyData(certificate));

    for (id pinnedCertificate in _pinnedCertificates) {
        SecCertificateRef trustedCert = (__bridge SecCertificateRef)pinnedCertificate;
        NSData *trustedCertData = CFBridgingRelease(SecCertificateCopyData(trustedCert));
        if ([trustedCertData isEqualToData:remoteCertificateData]) {
            return YES;
        }
    }

    return false;
}

@end
