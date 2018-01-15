//
//  WRServerTrustPolicy.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 22/10/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WRServerTrustPolicy : NSObject

@property (nonatomic, assign, readonly) SSLProtocol maxTLSSupportedProtocol;
@property (nonatomic, assign, readonly) SSLProtocol minTLSSupportedProtocol;

+ (instancetype)defaultEvaluationPolicy;
+ (instancetype)pinnningEvaluationPolicyWithCertificates:(NSArray *)pinnedCertificates allowSelfSignedCertificates:(BOOL)allowSelfSignedCertificates;
+ (instancetype)customEvaluationPolicyWithHandler:(BOOL (^)(SecTrustRef serverTrust, NSString *domain))handler;

- (instancetype)init NS_DESIGNATED_INITIALIZER;

- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust domain:(NSString *)domain;

@end
