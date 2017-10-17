//
//  WRHandshakeRequestBuilder.m
//  WhiteRabbitSocket
//
//  Created by Anastasia Kononova on 17/10/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import "WRHandshakeRequestBuilder.h"
#import "NSError+WRError.h"
#import "NSURL+WebSocket.h"

@implementation WRHandshakeRequestBuilder

+ (NSURLRequest *)handshakeRequestWithRequest:(NSURLRequest *)request
                                  securityKey:(NSString *)securityKey
                                      cookies:(NSArray<NSHTTPCookie *> *)cookies
                           websocketProtocols:(NSArray<NSString *> *)websocketProtocols
                              protocolVersion:(uint8_t)protocolVersion
                                        error:(NSError **)error
{
    NSURL *url = request.URL;

    NSMutableURLRequest *handshakeRequest = [[NSMutableURLRequest alloc] initWithURL:url];
    [handshakeRequest setHTTPMethod:@"GET"];

    [handshakeRequest setValue:url.handshakeHost forHTTPHeaderField:@"Host"];
    NSString *baseAuthorization = url.baseAuthorization;
    if (baseAuthorization != nil) {
        [handshakeRequest setValue:baseAuthorization forHTTPHeaderField:@"Authorization"];
    }

    [handshakeRequest setValue:@"websocket" forHTTPHeaderField:@"Upgrade"];
    [handshakeRequest setValue:@"Upgrade" forHTTPHeaderField:@"Connection"];
    [handshakeRequest setValue:securityKey forHTTPHeaderField:@"Sec-WebSocket-Key"];
    [handshakeRequest setValue:[NSString stringWithFormat:@"%d", protocolVersion] forHTTPHeaderField:@"Sec-WebSocket-Version"];
    [handshakeRequest setValue:url.origin forHTTPHeaderField:@"Origin"];

    if (websocketProtocols.count > 0) {
        [handshakeRequest setValue:[websocketProtocols componentsJoinedByString:@", "] forHTTPHeaderField:@"Sec-WebSocket-Protocol"];
    }

    [request.allHTTPHeaderFields enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [handshakeRequest setValue:obj forHTTPHeaderField:key];
    }];

    return handshakeRequest;
}
@end
