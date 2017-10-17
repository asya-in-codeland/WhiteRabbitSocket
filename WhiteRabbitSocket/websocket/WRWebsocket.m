//
//  WRWebsocket.m
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 10/07/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import "WRWebsocket.h"
#import "WRWebsocketDelegate.h"
#import "NSURL+WebSocket.h"
#import "WRHandshakeHandler.h"
#import "NSError+WRError.h"

NSString * const kWRWebsocketErrorDomain = @"kWRWebsocketErrorDomain";

static uint8_t const kWRWebsocketProtocolVersion = 13;
static NSInteger const kWRWebsocketChunkLength = 4096;

@interface WRWebsocket ()<NSURLSessionDelegate>
@end

@implementation WRWebsocket {
    NSURLRequest *_initialRequest;
    NSURLSession *_session;
    NSURLSessionStreamTask *_streamTask;
    NSURLSessionDataTask *_handshakeTask;
}

- (instancetype)initWithURLRequest:(NSURLRequest *)request
{
    self = [super init];
    if (self != nil) {
        _initialRequest = request.copy;
        
        //TODO: setup configuration settings
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        configuration.timeoutIntervalForRequest = request.timeoutInterval;
        configuration.requestCachePolicy = request.cachePolicy;
        //TODO: put delegate & queue to an other class
        _session = [NSURLSession sessionWithConfiguration:configuration];
        //_streamTask = [_session streamTaskWithHostName:request.URL.host port:request.URL.websocketPort];
    }
    return self;
}

#pragma mark - Public Methods

- (void)open
{
    //TODO: connection via proxy
    
    [_streamTask startSecureConnection];
    [_streamTask resume];
    
    CFHTTPMessageRef _handshakeResponse = CFHTTPMessageCreateEmpty(NULL, NO);
    NSData *handshakeData = [WRHandshakeHandler buildHandshakeDataWithRequest:_initialRequest securityKey:@"" cookies:nil websocketProtocols:nil protocolVersion:kWRWebsocketProtocolVersion error:nil];

    //TODO: writeData is proceed synchroniously, should we do smth with it?
    __weak typeof(self) wself = self;
    [_streamTask writeData:handshakeData timeout:_initialRequest.timeoutInterval completionHandler:^(NSError * _Nullable error) {
        if (error != nil) {
            //TODO: move to callback queue
            [wself.delegate websocket:wself didFailWithError:error];
        } else {
            //TODO: state is ready, I guess
        }
    }];
    
    [_streamTask readDataOfMinLength:1 maxLength:kWRWebsocketChunkLength timeout:_initialRequest.timeoutInterval completionHandler:^(NSData * _Nullable data, BOOL atEOF, NSError * _Nullable error) {
        if (error != nil) {
            //TODO: move to callback queue
            [wself.delegate websocket:wself didFailWithError:error];
        } else {
            BOOL isHeaderComplete = CFHTTPMessageIsHeaderComplete(_handshakeResponse);
            if (!(isHeaderComplete ^ atEOF)) {
                //TODO: move to callback queue
                NSError *error = [NSError errorWithCode:2433 description:@""];
                [wself.delegate websocket:wself didFailWithError:error];
            }
            else if (!isHeaderComplete) {
                CFHTTPMessageAppendBytes(_handshakeResponse, (const UInt8 *)data.bytes, data.length);
            }
            else {
                BOOL isConnectionEstablished = [WRHandshakeHandler parseHandshakeResponse:_handshakeResponse securityKey:@"" websocketProtocols:nil error:nil];
                //TODO
                [wself.delegate websocketDidEstablishConnection:wself];
            }
        }
    }];
}

- (void)close
{
    
}

- (BOOL)sendData:(NSData *)data error:(NSError **)error
{
    return NO;
}

- (BOOL)sendMessage:(NSString *)message error:(NSError **)error
{
    return NO;
}

- (BOOL)sendPing:(NSData *)data error:(NSError **)error
{
    return NO;
}

#pragma mark - Private Methods

@end
