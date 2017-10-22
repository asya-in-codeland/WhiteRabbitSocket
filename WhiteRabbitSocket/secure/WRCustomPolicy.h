//
//  WRCustomPolicy.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 22/10/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import "WRServerTrustPolicy.h"

@interface WRCustomPolicy : WRServerTrustPolicy

- (instancetype)initWithHandler:(BOOL (^)(SecTrustRef serverTrust, NSString *domain))handler;

@end
