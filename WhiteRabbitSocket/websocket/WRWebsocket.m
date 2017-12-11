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

@interface WRWebsocket ()<NSURLSessionDelegate, WRFrameReaderDelegate>
@property (nonatomic, assign) WRWebsocketState state;
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

        _state = WRWebsocketStateClosed;

        //TODO: setup configuration settings
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        configuration.timeoutIntervalForRequest = request.timeoutInterval;
        configuration.requestCachePolicy = request.cachePolicy;
        configuration.TLSMinimumSupportedProtocol = _securePolicy.minTLSSupportedProtocol;
        configuration.TLSMaximumSupportedProtocol = _securePolicy.maxTLSSupportedProtocol;

        //TODO: put delegate & queue to an other class
        _session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        _streamTask = [_session streamTaskWithHostName:request.URL.host port:request.URL.websocketPort];

        _frameReader = [WRFrameReader new];
        _frameReader.delegate = self;
    }
    return self;
}

#pragma mark - Public Methods

- (void)open
{
    if (_state != WRWebsocketStateClosed) return;

    self.state = WRWebsocketStateConnecting;

    //TODO: [_streamTask startSecureConnection];
    [_streamTask resume];

    __weak typeof(self) wself = self;
    [self openingHandshakeWithCompletion:^(BOOL success, NSError *error) {
        __strong typeof(wself) sself = wself;
        if (sself == nil) return;

        if (success) {
            sself.state = WRWebsocketStateConnected;
            [sself.delegate websocketDidEstablishConnection:sself];

            [sself readData];
        } else {
            [sself onFailWithError:error];
        }
    }];
}

- (void)close
{
    if (_state != WRWebsocketStateConnected) { return; }

    self.state = WRWebsocketStateClosing;

    NSError *error;
    BOOL result = [self writeData:nil opcode:WROpCodeClose error:&error];
    if (!result) {
        [self onFailWithError:error];
    }
}

- (BOOL)sendData:(NSData *)data error:(NSError **)outError
{
    return [self writeData:data opcode:WROpCodeBinary error:outError];
}

- (BOOL)sendMessage:(NSString *)message error:(NSError **)outError
{
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    return [self writeData:data opcode:WROpCodeText error:outError];
}

- (BOOL)sendPing:(NSData *)data error:(NSError **)outError
{
    return [self writeData:data opcode:WROpCodePing error:outError];
}

#pragma mark - Private Methods

- (void)openingHandshakeWithCompletion:(void(^)(BOOL success, NSError *error))completion
{
    NSError *outError;
    WRHandshakeHandler *handshakeHandler = [WRHandshakeHandler new];
    NSData *handshakeData = [handshakeHandler buildHandshakeDataWithRequest:_initialRequest cookies:nil websocketProtocols:nil protocolVersion:kWRWebsocketProtocolVersion error:&outError];

    if (handshakeData == nil) {
        completion(NO, outError);
        return;
    }

    [_streamTask writeData:handshakeData timeout:_initialRequest.timeoutInterval completionHandler:^(NSError * _Nullable error) {
        if (error != nil) {
            completion(NO, error);
        } else {
            NSLog(@"Writing is done!");
        }
    }];

    __weak typeof(self) wself = self;
    [_streamTask readDataOfMinLength:1 maxLength:kWRWebsocketChunkLength timeout:_initialRequest.timeoutInterval completionHandler:^(NSData * _Nullable data, BOOL atEOF, NSError * _Nullable error) {
        __strong typeof(wself) sself = wself;
        if (sself == nil) return;

        if (error != nil) {
            completion(NO, error);
        }
        else {
            NSError *parseError;
            BOOL isConnectionEstablished = [handshakeHandler parseHandshakeResponse:data websocketProtocols:nil error:&parseError];
            completion(isConnectionEstablished, parseError);
        }
    }];
}

- (BOOL)writeData:(NSData *)data opcode:(WROpCode)opcode error:(NSError **)outError
{
    if (_state != WRWebsocketStateConnected) {
        *outError = [NSError errorWithCode:1234 description:@"Unable to write data, connection is closed."];
        return NO;
    }

    NSData *frameData = [WRFrameWriter buildFrameFromData:data opCode:opcode error:outError];

    if (frameData == nil) {
        return NO;
    }

    __weak typeof(self) wself = self;
    [_streamTask writeData:frameData timeout:_initialRequest.timeoutInterval completionHandler:^(NSError * _Nullable error) {
        if (error != nil) {
            [wself onFailWithError:error];
        } else {
            NSLog(@"Writing is done!");
        }
    }];

    return YES;
}

- (void)readData
{
    __weak typeof(self) wself = self;
    [_streamTask readDataOfMinLength:2 maxLength:kWRWebsocketChunkLength timeout:0 completionHandler:^(NSData * _Nullable data, BOOL atEOF, NSError * _Nullable error) {
        __strong typeof(wself) sself = wself;
        if (sself == nil) return;

        if (error != nil) {
            [sself onFailWithError:error];
        }
        else {
            if (atEOF) {
                [sself closeConnection];
            }
            else {
                NSError *readerError;
                BOOL result = [sself->_frameReader readData:data error:&readerError];
                if (!result) {
                    [sself.delegate websocket:sself didFailWithError:readerError];
                }

                [sself readData];
            }
        }
    }];
}

- (void)onFailWithError:(NSError *)error
{
    [self closeConnection];
    [self.delegate websocket:self didFailWithError:error];
}

- (void)closeConnection
{
    [_streamTask closeRead];
    [_streamTask closeWrite];
    self.state = WRWebsocketStateClosed;
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error
{
    //TODO: add implementation
}

#pragma mark - WRFrameReaderDelegate

- (void)frameReader:(WRFrameReader *)reader didProcessText:(NSString *)text
{
    NSLog(@"Resilt: %@", text);
}

- (void)frameReader:(WRFrameReader *)reader didProcessData:(NSData *)data
{
    NSLog(@"Resilt der lenghitten: %lu", (unsigned long)data.length);
}

- (void)frameReader:(WRFrameReader *)reader didProcessClose:(NSData *)data
{
    if (_state == WRWebsocketStateClosing) {
        [self closeConnection];
        [_delegate webSocket:self didCloseWithData:data];
    }

    //TODO: what about WRWebsocketStateConnecting state ><
    if (_state == WRWebsocketStateConnected) {
        [self close];
    }
}

- (void)frameReader:(WRFrameReader *)reader didProcessPing:(NSData *)data
{
    NSLog(@"Die ping");
    [_delegate websocket:self didReceivePing:data];
    [self writeData:nil opcode:WROpCodePong error:nil];
}

- (void)frameReader:(WRFrameReader *)reader didProcessPong:(NSData *)data
{
    NSLog(@"Der pong");
    [_delegate webSocket:self didReceivePong:data];
}

@end
