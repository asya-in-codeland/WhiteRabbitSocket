//
//  WRHandshakeRequestBuilder.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Kononova on 17/10/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WRHandshakeRequestBuilder : NSObject

+ (NSURLRequest *)handshakeRequestWithRequest:(NSURLRequest *)request
                                  securityKey:(NSString *)securityKey
                                      cookies:(NSArray<NSHTTPCookie *> *)cookies
                           websocketProtocols:(NSArray<NSString *> *)websocketProtocols
                              protocolVersion:(uint8_t)protocolVersion
                                        error:(NSError **)error;
@end
