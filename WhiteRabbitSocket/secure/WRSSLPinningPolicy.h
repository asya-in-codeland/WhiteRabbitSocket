//
//  WRSSLPinningPolicy.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 22/10/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import "WRServerTrustPolicy.h"

NS_ASSUME_NONNULL_BEGIN

@interface WRSSLPinningPolicy : WRServerTrustPolicy

- (instancetype)initWithCertificates:(NSArray *)pinnedCertificates allowSelfSignedCertificates:(BOOL)allowSelfSignedCertificates;

@end

NS_ASSUME_NONNULL_END
