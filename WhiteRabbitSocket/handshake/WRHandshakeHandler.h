//
//  WRHandshakeHandler.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 16/07/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WRHandshakePreferences;

@interface WRHandshakeHandler : NSObject

- (instancetype)initWithWebsocketProtocols:(NSArray<NSString *> *)websocketProtocols
                  enabledPerMessageDeflate:(BOOL)enabledPerMessageDeflate;

- (NSData *)buildHandshakeDataWithRequest:(NSURLRequest *)request
                                  cookies:(NSArray<NSHTTPCookie *> *)cookies
                          protocolVersion:(uint8_t)protocolVersion
                                    error:(NSError **)error;

- (WRHandshakePreferences *)parseHandshakeResponse:(NSData *)response error:(NSError **)error;

@end
