//
//  WRSSLPinningPolicy.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 22/10/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import "WRServerTrustPolicy.h"

@interface WRSSLPinningPolicy : WRServerTrustPolicy

- (instancetype)initWithCertificates:(NSArray *)pinnedCertificates;

@end
