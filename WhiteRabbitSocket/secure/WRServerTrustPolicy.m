//
//  WRServerTrustPolicy.m
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 22/10/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import "WRServerTrustPolicy.h"
#import "WRSSLPinningPolicy.h"
#import "WRCustomPolicy.h"

@implementation WRServerTrustPolicy {
    BOOL _certificateChainValidationEnabled;
}

+ (instancetype)defaultEvaluationPolicy {
    return [self new];
}

+ (instancetype)pinnningEvaluationPolicyWithCertificates:(NSArray *)pinnedCertificates allowSelfSignedCertificates:(BOOL)allowSelfSignedCertificates {
    return [[WRSSLPinningPolicy alloc] initWithCertificates:pinnedCertificates allowSelfSignedCertificates:allowSelfSignedCertificates];
}

+ (instancetype)customEvaluationPolicyWithHandler:(BOOL (^)(SecTrustRef, NSString *))handler {
    return [[WRCustomPolicy alloc] initWithHandler:handler];
}

#pragma mark - Public

- (SSLProtocol)minTLSSupportedProtocol {
    return kTLSProtocol11;
}

- (SSLProtocol)maxTLSSupportedProtocol {
    return kTLSProtocol12;
}

- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust domain:(NSString *)domain {
    NSMutableArray *policies = [NSMutableArray array];
    [policies addObject:(__bridge_transfer id)SecPolicyCreateSSL(true, (__bridge CFStringRef)domain)];
    SecTrustSetPolicies(serverTrust, (__bridge CFArrayRef)policies);

    SecTrustResultType result;
    SecTrustEvaluate(serverTrust, &result);
    return (result == kSecTrustResultUnspecified || result == kSecTrustResultProceed);
}

@end
