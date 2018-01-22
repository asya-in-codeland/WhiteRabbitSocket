//
//  WRHandshakeHandler.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 16/07/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WRHandshakeHandler : NSObject

@property (nonatomic, assign, readonly) NSUInteger maxWindowBits;
@property (nonatomic, assign, readonly) BOOL noContextTakeover;

- (instancetype)initWithWebsocketProtocols:(NSArray<NSString *> *)websocketProtocols
                  enabledPerMessageDeflate:(BOOL)enabledPerMessageDeflate;

- (NSData *)buildHandshakeDataWithRequest:(NSURLRequest *)request
                                  cookies:(NSArray<NSHTTPCookie *> *)cookies
                          protocolVersion:(uint8_t)protocolVersion
                                    error:(NSError **)error;

- (BOOL)parseHandshakeResponse:(NSData *)response error:(NSError **)error;

@end
