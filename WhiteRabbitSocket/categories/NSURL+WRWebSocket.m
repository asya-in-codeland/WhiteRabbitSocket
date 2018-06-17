//
//  NSURL+WRWebSocket.m
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 16/07/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import "NSURL+WRWebSocket.h"

@implementation NSURL (WRWebSocket)

- (NSInteger)wr_websocketPort {
    NSInteger port = self.port.integerValue;
    if (port == 0) {
        if(self.wr_isSecureConnection){
            port = 443;
        } else {
            port = 80;
        }
    }
    return port;
}

- (NSString *)wr_handshakeHost {
    NSString *host = self.host;
    if (self.port != nil) {
        host = [host stringByAppendingFormat:@":%@", self.port];
    }
    return host;
}

- (NSString *)wr_baseAuthorization {
    NSData *data = [[NSString stringWithFormat:@"%@:%@", self.user, self.password] dataUsingEncoding:NSUTF8StringEncoding];
    return [NSString stringWithFormat:@"Basic %@", [data base64EncodedStringWithOptions:0]];
}

- (NSString *)wr_origin {
    NSMutableString *origin = [NSMutableString string];
    
    NSString *scheme = self.scheme.lowercaseString;
    if ([scheme isEqualToString:@"wss"]) {
        scheme = @"https";
    } else if ([scheme isEqualToString:@"ws"]) {
        scheme = @"http";
    }
    
    [origin appendFormat:@"%@://%@", scheme, self.host];
    
    NSNumber *port = self.port;
    BOOL useDefaultPort = (port == nil ||
                          ([scheme isEqualToString:@"http"] && port.integerValue == 80) ||
                          ([scheme isEqualToString:@"https"] && port.integerValue == 443));
    if (!useDefaultPort) {
        [origin appendFormat:@":%@", port.stringValue];
    }
    
    return origin;
}

- (BOOL)wr_isSecureConnection {
    NSString *scheme = self.scheme.lowercaseString;
    return ([scheme isEqualToString:@"wss"] || [scheme isEqualToString:@"https"]);
}
@end
