//
//  WRHandshakeHandler.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 16/07/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WRHandshakeHandler : NSObject

- (NSData *)buildHandshakeDataWithRequest:(NSURLRequest *)request
                                  cookies:(NSArray<NSHTTPCookie *> *)cookies
                       websocketProtocols:(NSArray<NSString *> *)websocketProtocols
                          protocolVersion:(uint8_t)protocolVersion
                                    error:(NSError **)error;

- (BOOL)parseHandshakeResponse:(NSData *)response
            websocketProtocols:(NSArray<NSString *> *)websocketProtocols
                         error:(NSError **)error;

@end
