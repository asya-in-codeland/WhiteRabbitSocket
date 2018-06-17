//
//  WRCustomPolicy.m
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 22/10/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import "WRCustomPolicy.h"

@implementation WRCustomPolicy {
    BOOL (^_evaluationHandler)(SecTrustRef serverTrust, NSString *domain);
}

- (instancetype)initWithHandler:(BOOL (^)(SecTrustRef serverTrust, NSString *domain))handler {
    self = [self init];
    if (self != nil) {
        if (handler == nil) {
            @throw [NSException exceptionWithName:@"Creating security policy failed."
                                           reason:@"Must specify evaluation handler for custom policy."
                                         userInfo:nil];
        }
        _evaluationHandler = [handler copy];
    }
    return self;
}

- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust domain:(NSString *)domain {
    return _evaluationHandler(serverTrust, domain);
}

@end
