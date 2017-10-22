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

+ (instancetype)defaultEvaluationPolicy
{
    return [self new];
}

+ (instancetype)pinnningEvaluationPolicyWithCertificates:(NSArray *)pinnedCertificates
{
    return [[WRSSLPinningPolicy alloc] initWithCertificates:pinnedCertificates];
}

+ (instancetype)customEvaluationPolicyWithHandler:(BOOL (^)(SecTrustRef, NSString *))handler
{
    return [[WRCustomPolicy alloc] initWithHandler:handler];
}

- (instancetype)initWithCertificateChainValidationEnabled:(BOOL)enabled
{
    self = [super init];
    if (self != nil) {
        //TODO: not sure we need it, dont know how to set SSL chain validation enabled to session
        // May be config?
        _certificateChainValidationEnabled = enabled;
    }
    
    return self;
}

- (instancetype)init
{
    return [self initWithCertificateChainValidationEnabled:YES];
}

#pragma mark - Public

- (SSLProtocol)minTLSSupportedProtocol
{
    return kTLSProtocol11;
}

- (SSLProtocol)maxTLSSupportedProtocol
{
    return kTLSProtocol12;
}

- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust domain:(NSString *)domain
{
    return YES;
}

@end
