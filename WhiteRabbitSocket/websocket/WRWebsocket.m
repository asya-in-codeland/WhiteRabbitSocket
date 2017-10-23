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
#import "WRHandshakeRequestBuilder.h"
#import "WRServerTrustPolicy.h"

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
    WRServerTrustPolicy *_securePolicy;
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
    
    CFHTTPMessageRef _handshakeResponse = CFHTTPMessageCreateEmpty(NULL, NO);
    NSData *handshakeData = [WRHandshakeHandler buildHandshakeDataWithRequest:_initialRequest securityKey:securityKeyString cookies:nil websocketProtocols:nil protocolVersion:kWRWebsocketProtocolVersion error:nil];
    
//    NSURLRequest *handshakeRequest = [WRHandshakeRequestBuilder handshakeRequestWithRequest:_initialRequest securityKey:securityKeyString cookies:nil websocketProtocols:nil protocolVersion:13 error:nil];
    // TODO: add headers from requestBuilder
//    _handshakeTask = [_session dataTaskWithRequest:handshakeRequest];
//    [_handshakeTask resume];

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

            // TODO: For handshake isHeaderComplete is false, I have no idea why ><
            // Need re-check it for normal response
//            BOOL isHeaderComplete = CFHTTPMessageIsHeaderComplete(_handshakeResponse);
//            if (!(isHeaderComplete ^ atEOF)) {
//                //TODO: move to callback queue
//                NSError *error = [NSError errorWithCode:2433 description:@""];
//                [wself.delegate websocket:wself didFailWithError:error];
//            }
//            else if (!isHeaderComplete) {
//                CFHTTPMessageAppendBytes(_handshakeResponse, (const UInt8 *)data.bytes, data.length);
//            }
//            else {
//                BOOL isConnectionEstablished = [WRHandshakeHandler parseHandshakeResponse:_handshakeResponse securityKey:securityKeyString websocketProtocols:nil error:nil];
//                //TODO
//                [wself.delegate websocketDidEstablishConnection:wself];
//            }
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

#pragma mark - NSURLSessionTaksDelegate

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    NSLog(@"Did receive response %@", httpResponse.allHeaderFields);
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error
{
    NSLog(@"session:didBecomeInvalidWithError: %@", error.localizedDescription);
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    NSLog(@"session:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend");
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error
{
    NSLog(@"session:task:didCompleteWithError: %@", error.localizedDescription);
}

#pragma mark - Private Methods

@end
