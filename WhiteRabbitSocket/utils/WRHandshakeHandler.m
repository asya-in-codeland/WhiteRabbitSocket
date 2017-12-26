//
//  WRHandshakeHandler.m
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 16/07/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import "WRHandshakeHandler.h"
#import "NSURL+WebSocket.h"
#import "NSError+WRError.h"
#import "NSString+SHA1.h"

static NSString *const WRWebSocketAppendToSecKeyString = @"258EAFA5-E914-47DA-95CA-C5AB0DC85B11";

@implementation WRHandshakeHandler {
    NSString *_securityKey;
    NSArray<NSString *> *_websocketProtocols;
    BOOL _enabledPerMessageDeflate;
}

- (instancetype)initWebsocketProtocols:(NSArray<NSString *> *)websocketProtocols
              enabledPerMessageDeflate:(BOOL)enabledPerMessageDeflate
{
    self = [super init];
    if (self != nil) {
        NSMutableData *data = [NSMutableData dataWithLength:16];
        int result = SecRandomCopyBytes(kSecRandomDefault, data.length, data.mutableBytes);
        if (result != 0) {
            [NSException raise:NSInternalInconsistencyException format:@"Failed to generate random bytes with OSStatus: %d", result];
        }
        _securityKey = [data base64EncodedStringWithOptions:0];
    }
    return self;
}

- (NSData *)buildHandshakeDataWithRequest:(NSURLRequest *)request
                                  cookies:(NSArray<NSHTTPCookie *> *)cookies
                          protocolVersion:(uint8_t)protocolVersion
                                    error:(NSError *__autoreleasing *)error
{
    NSURL *url = request.URL;
    
    CFHTTPMessageRef message = CFHTTPMessageCreateRequest(NULL, CFSTR("GET"), (__bridge CFURLRef)url, kCFHTTPVersion1_1);
    
    CFHTTPMessageSetHeaderFieldValue(message, CFSTR("Host"), (__bridge CFStringRef)url.handshakeHost);
    
    NSMutableData *keyBytes = [[NSMutableData alloc] initWithLength:16];
    int result = SecRandomCopyBytes(kSecRandomDefault, keyBytes.length, keyBytes.mutableBytes);
    if (result != 0) {
        *error = [NSError errorWithCode:result description:@"Generates an array of cryptographically secure random bytes."];
        return nil;
    }
    
    if (cookies.count > 0) {
        NSDictionary<NSString *, NSString *> *messageCookies = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
        [messageCookies enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            if (key.length && obj.length) {
                CFHTTPMessageSetHeaderFieldValue(message, (__bridge CFStringRef)key, (__bridge CFStringRef)obj);
            }
        }];
    }
    
    NSString *baseAuthorization = url.baseAuthorization;
    if (baseAuthorization != nil) {
        CFHTTPMessageSetHeaderFieldValue(message, CFSTR("Authorization"), (__bridge CFStringRef)baseAuthorization);
    }
    
    CFHTTPMessageSetHeaderFieldValue(message, CFSTR("Upgrade"), CFSTR("websocket"));
    CFHTTPMessageSetHeaderFieldValue(message, CFSTR("Connection"), CFSTR("Upgrade"));
    CFHTTPMessageSetHeaderFieldValue(message, CFSTR("Sec-WebSocket-Key"), (__bridge CFStringRef)_securityKey);
    CFHTTPMessageSetHeaderFieldValue(message, CFSTR("Sec-WebSocket-Version"), (__bridge CFStringRef)[NSString stringWithFormat:@"%d", protocolVersion]);
    
    CFHTTPMessageSetHeaderFieldValue(message, CFSTR("Origin"), (__bridge CFStringRef)url.origin);
    
    if (_websocketProtocols.count > 0) {
        CFHTTPMessageSetHeaderFieldValue(message, CFSTR("Sec-WebSocket-Protocol"),
                                         (__bridge CFStringRef)[_websocketProtocols componentsJoinedByString:@", "]);
    }
    
    if (_enabledPerMessageDeflate) {
        CFHTTPMessageSetHeaderFieldValue(message, CFSTR("Sec-WebSocket-Extensions"), (__bridge CFStringRef)@"permessage-deflate");
    }
    
    [request.allHTTPHeaderFields enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        CFHTTPMessageSetHeaderFieldValue(message, (__bridge CFStringRef)key, (__bridge CFStringRef)obj);
    }];
    
    NSData *messageData = CFBridgingRelease(CFHTTPMessageCopySerializedMessage(message));
    CFRelease(message);
    
    return messageData;
}

- (BOOL)parseHandshakeResponse:(NSData *)data error:(NSError *__autoreleasing *)error
{
    //TODO: error may be nil, unexpectedly ><

    if (data == nil) {
        *error = [NSError errorWithCode:1334 description:[NSString stringWithFormat:@"Received bad response code from server: %d.", (int)12334]];
        return NO;
    }

    CFHTTPMessageRef response = CFHTTPMessageCreateEmpty(NULL, NO);
    CFHTTPMessageAppendBytes(response, (const UInt8 *)data.bytes, data.length);

    NSLog(@"Response Headers: %@", ((__bridge NSDictionary*)CFHTTPMessageCopyAllHeaderFields(response)));

    NSInteger responseCode = CFHTTPMessageGetResponseStatusCode(response);
    if (responseCode >= 400) {
        *error = [NSError errorWithCode:responseCode description:[NSString stringWithFormat:@"Received bad response code from server: %d.", (int)responseCode]];
        return NO;
    }

    NSString *upgradeHeader = CFBridgingRelease(CFHTTPMessageCopyHeaderFieldValue(response, CFSTR("Upgrade")));
    if (![upgradeHeader isEqualToString:@"websocket"]) {
        *error = [NSError errorWithCode:responseCode description:@"Invalid Upgrade response"];
        return NO;
    }

    NSString *connectionHeader = CFBridgingRelease(CFHTTPMessageCopyHeaderFieldValue(response, CFSTR("Connection")));
    if (![connectionHeader isEqualToString:@"Upgrade"]) {
        *error = [NSError errorWithCode:responseCode description:@"Invalid Connection response"];
        return NO;
    }

    NSString *acceptHeader = CFBridgingRelease(CFHTTPMessageCopyHeaderFieldValue(response, CFSTR("Sec-WebSocket-Accept")));
    NSString *concattedString = [_securityKey stringByAppendingString:WRWebSocketAppendToSecKeyString];
    NSString *expectedAccept =  [[concattedString SHA1] base64EncodedStringWithOptions:0];;
    if(acceptHeader == nil || ![acceptHeader isEqualToString:expectedAccept]) {
        *error = [NSError errorWithCode:2133 description: @"Invalid Sec-WebSocket-Accept response."];
        return NO;
    }
    
    NSString *negotiatedProtocol = CFBridgingRelease(CFHTTPMessageCopyHeaderFieldValue(response, CFSTR("Sec-WebSocket-Protocol")));
    if (negotiatedProtocol != nil) {
        if ([_websocketProtocols indexOfObject:negotiatedProtocol] == NSNotFound) {
            *error = [NSError errorWithCode:2133 description: @"Server specified Sec-WebSocket-Protocol that wasn't requested."];
            return NO;
        }
    }

    NSString *perMessageDeflateHeader = CFBridgingRelease(CFHTTPMessageCopyHeaderFieldValue(response, CFSTR("Sec-WebSocket-Extensions")));
    //TODO: parse extention parameters
    //Sec-WebSocket-Extensions:
    //permessage-deflate;
    //client_max_window_bits; server_max_window_bits=10
    if (_enabledPerMessageDeflate && ![perMessageDeflateHeader containsString:@"permessage-deflate"]) {
        *error = [NSError errorWithCode:2133 description: @"Server specified Sec-WebSocket-Extensions that wasn't requested."];
        return NO;
    }
    
    return YES;
}

@end
