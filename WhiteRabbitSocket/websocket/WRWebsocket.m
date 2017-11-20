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
#import "WRServerTrustPolicy.h"
#import "WRFrameWriter.h"
#import "WRFrameReader.h"
#import "WRReadableData.h"

NSString * const kWRWebsocketErrorDomain = @"kWRWebsocketErrorDomain";

static uint8_t const kWRWebsocketProtocolVersion = 13;
static NSInteger const kWRWebsocketChunkLength = 4096;

@interface WRWebsocket ()<NSURLSessionDelegate>
@end

@implementation WRWebsocket {
    NSURLRequest *_initialRequest;
    NSURLSession *_session;
    NSURLSessionStreamTask *_streamTask;
    WRServerTrustPolicy *_securePolicy;
    WRFrameReader *_frameReader;
}

- (instancetype)initWithURLRequest:(NSURLRequest *)request
{
    return [self initWithURLRequest:request securePolicy:[WRServerTrustPolicy defaultEvaluationPolicy]];
}

- (instancetype)initWithURLRequest:(NSURLRequest *)request securePolicy:(WRServerTrustPolicy *)serverTrustPolicy
{
    self = [super init];
    if (self != nil) {
        _initialRequest = request.copy;
        _securePolicy = serverTrustPolicy;

        //TODO: setup configuration settings
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        configuration.timeoutIntervalForRequest = request.timeoutInterval;
        configuration.requestCachePolicy = request.cachePolicy;
        configuration.TLSMinimumSupportedProtocol = _securePolicy.minTLSSupportedProtocol;
        configuration.TLSMaximumSupportedProtocol = _securePolicy.maxTLSSupportedProtocol;
        //TODO: put delegate & queue to an other class
        _session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        _streamTask = [_session streamTaskWithHostName:request.URL.host port:request.URL.websocketPort];
    }
    return self;
}

#pragma mark - Public Methods

- (void)open
{
    //TODO: connection via proxy
    
//    [_streamTask startSecureConnection];
    [_streamTask resume];

    NSMutableData *data = [NSMutableData dataWithLength:16];
    int result = SecRandomCopyBytes(kSecRandomDefault, data.length, data.mutableBytes);
    if (result != 0) {
        [NSException raise:NSInternalInconsistencyException format:@"Failed to generate random bytes with OSStatus: %d", result];
    }
    NSString *securityKeyString = [data base64EncodedStringWithOptions:0];
    
    NSData *handshakeData = [WRHandshakeHandler buildHandshakeDataWithRequest:_initialRequest securityKey:securityKeyString cookies:nil websocketProtocols:nil protocolVersion:kWRWebsocketProtocolVersion error:nil];

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
            CFHTTPMessageRef handshakeResponse = CFHTTPMessageCreateEmpty(NULL, NO);
            CFHTTPMessageAppendBytes(handshakeResponse, (const UInt8 *)data.bytes, data.length);
            BOOL isConnectionEstablished = [WRHandshakeHandler parseHandshakeResponse:handshakeResponse securityKey:securityKeyString websocketProtocols:nil error:nil];
            if (isConnectionEstablished) {
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

- (BOOL)sendMessage:(NSString *)message error:(NSError **)outError
{
    __weak typeof(self) wself = self;
    NSData *strData = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [WRFrameWriter buildFrameFromData:strData opCode:WROpCodeTextFrame error:outError];

    if (data == nil) {
        return NO;
    }

    [_streamTask writeData:data timeout:_initialRequest.timeoutInterval completionHandler:^(NSError * _Nullable error) {
        if (error != nil) {
            //TODO: move to callback queue
            [wself.delegate websocket:wself didFailWithError:error];
        } else {
            NSLog(@"OK");
        }
    }];

    _frameReader = [WRFrameReader new];
    _frameReader.onTextFrameFinish = ^(NSString *text) {
        NSLog(@"Resilt: %@", text);
    };

    [self readSocketData];

    return YES;
}

- (BOOL)sendPing:(NSData *)data error:(NSError **)error
{
    return NO;
}

#pragma mark - Private Methods

- (void)readSocketData
{
    __weak typeof(self) wself = self;
    [_streamTask readDataOfMinLength:2 maxLength:kWRWebsocketChunkLength timeout:0 completionHandler:^(NSData * _Nullable data, BOOL atEOF, NSError * _Nullable error) {
        if (error != nil) {
            [wself.delegate websocket:wself didFailWithError:error];
        }
        else {
            NSLog(@"Start reading");
            NSError *readerError;
            BOOL result = [_frameReader readData:data error:&readerError];
            if (!result) {
                [wself.delegate websocket:wself didFailWithError:readerError];
            }

            NSLog(@"Finish reading");

            [wself readSocketData];
        }
    }];
}

@end
