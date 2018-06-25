//
//  WRWebsocket.m
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 10/07/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import "WRWebsocket.h"
#import "WRWebsocketDelegate.h"
#import "NSURL+WRWebSocket.h"
#import "WRHandshakeHandler.h"
#import "WRHandshakePreferences.h"
#import "NSError+WRError.h"
#import "WRServerTrustPolicy.h"
#import "WRFrameWriter.h"
#import "WRFrameReader.h"
#import "WRReadableData.h"
#import "WRDataDeflater.h"
#import "WRDataInflater.h"
#import "WRDispatching.h"
#import "WRLoggerWrapper.h"

NSString * const kWRWebsocketErrorDomain = @"kWRWebsocketErrorDomain";

static uint8_t const kWRCompressionMemoryLevel = 8;
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
    WRFrameWriter *_frameWriter;
}

- (instancetype)initWithURLRequest:(NSURLRequest *)request {
    return [self initWithURLRequest:request securePolicy:[WRServerTrustPolicy defaultEvaluationPolicy]];
}

- (instancetype)initWithURLRequest:(NSURLRequest *)request securePolicy:(WRServerTrustPolicy *)serverTrustPolicy {
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
        _streamTask = [_session streamTaskWithHostName:request.URL.host port:request.URL.wr_websocketPort];
        
        WRDebugLog(@"Create WRWebsocket instance");
    }
    return self;
}

#pragma mark - Public Methods

- (void)open {
    if (_state != WRWebsocketStateClosed) return;

    WRDebugLog(@"Start opening...");
    
    self.state = WRWebsocketStateConnecting;

    //TODO: [_streamTask startSecureConnection];
    [_streamTask resume];

    __weak typeof(self) wself = self;
    [self openingHandshakeWithCompletion:^(WRHandshakePreferences *preferences, NSError *error) {
        __strong typeof(wself) sself = wself;
        if (sself == nil) return;

        if (preferences != nil) {
            sself.state = WRWebsocketStateConnected;
            
            WRDebugLog(@"Websocket did establish connection");
            backgroundDispatch(sself.delegate, @selector(websocketDidEstablishConnection:), ^{
                [sself.delegate websocketDidEstablishConnection:sself];
            });
            [sself setupFrameHandlersWithPreferences:preferences];
            [sself readData];
        } else {
            WRErrorLog(@"Websocket did fail with error: %@", error);
            backgroundDispatch(sself.delegate, @selector(websocket:didFailWithError:), ^{
                [sself.delegate websocket:sself didFailWithError:error];
            });
            [sself closeStream];
        }
    }];
}

- (void)close {
    // TODO: WRWebsocketStateConnecting?
    if (_state != WRWebsocketStateConnected) { return; }

    WRDebugLog(@"Start closing...");
    
    self.state = WRWebsocketStateClosed;

    NSError *error;
    BOOL result = [self writeData:nil opcode:WROpCodeClose error:&error];
    if (!result) {
        [self closeStream];
    }
}

- (BOOL)sendData:(NSData *)data error:(NSError **)outError {
    WRDebugLog(@"Send data with length: %lu", data.length);
    return [self writeData:data opcode:WROpCodeBinary error:outError];
}

- (BOOL)sendMessage:(NSString *)message error:(NSError **)outError {
    WRDebugLog(@"Send message: %@", message);
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    return [self writeData:data opcode:WROpCodeText error:outError];
}

- (BOOL)sendPing:(NSData *)data error:(NSError **)outError {
    WRDebugLog(@"Send ping");
    return [self writeData:data opcode:WROpCodePing error:outError];
}

- (void)setLogger:(id<WRLogger>)logger {
    _logger = logger;
    [WRLoggerWrapper setLogger:logger];
}

#pragma mark - Private Methods

- (void)openingHandshakeWithCompletion:(void(^)(WRHandshakePreferences *, NSError *))completion {
    NSError *outError;
    WRHandshakeHandler *handshakeHandler = [[WRHandshakeHandler alloc] initWithWebsocketProtocols:nil enabledPerMessageDeflate:_enabledPerMessageDeflate];
    NSData *handshakeData = [handshakeHandler buildHandshakeDataWithRequest:_initialRequest cookies:nil protocolVersion:kWRWebsocketProtocolVersion error:&outError];

    if (handshakeData == nil) {
        WRErrorLog(@"Unable to build handshake request.");
        completion(nil, outError);
        return;
    }

    WRDebugLog(@"Send handshake request: %@", [[NSString alloc] initWithData:handshakeData encoding:kCFStringEncodingUTF8]);

    [_streamTask writeData:handshakeData timeout:_initialRequest.timeoutInterval completionHandler:^(NSError * _Nullable error) {
        if (error != nil) {
            completion(nil, error);
        } else {
            WRInfoLog(@"Handshake request was sended.");
        }
    }];

    __weak typeof(self) wself = self;
    [_streamTask readDataOfMinLength:1 maxLength:kWRWebsocketChunkLength timeout:_initialRequest.timeoutInterval completionHandler:^(NSData * _Nullable data, BOOL atEOF, NSError * _Nullable error) {
        __strong typeof(wself) sself = wself;
        if (sself == nil) return;

        if (error != nil) {
            completion(nil, error);
        }
        else {
            NSError *parseError;
            WRDebugLog(@"Receive handshake response: %@", [[NSString alloc] initWithData:data encoding:kCFStringEncodingUTF8]);
            WRHandshakePreferences *preferences = [handshakeHandler parseHandshakeResponse:data error:&parseError];
            completion(preferences, parseError);
        }
    }];
}

- (BOOL)writeData:(NSData *)data opcode:(WROpCode)opcode error:(NSError **)outError {
    if (_state != WRWebsocketStateConnected) {
        WRErrorLog(@"Unable to send data. Connection is not opened.");
        *outError = [NSError wr_errorWithCode:1234 description:@"Unable to write data, connection is closed."];
        return NO;
    }

    NSData *frameData = [_frameWriter buildFrameFromData:data opCode:opcode error:outError];

    if (frameData == nil) {
        WRErrorLog(@"Unable to build frame from data: %@", data);
        *outError = [NSError wr_errorWithCode:1234 description:@"Unable to write data, connection is closed."];
        return NO;
    }

    __weak typeof(self) wself = self;
    [_streamTask writeData:frameData timeout:_initialRequest.timeoutInterval completionHandler:^(NSError * _Nullable error) {
        __strong typeof(wself) sself = wself;
        if (sself == nil) { return; }

        if (sself.state == WRWebsocketStateClosed) {
            [sself closeStream];
            return;
        }

        if (error != nil) {
            WRErrorLog(@"Getting error while sending data: %@", error);
            backgroundDispatch(sself.delegate, @selector(websocket:didFailWithError:), ^{
                [sself.delegate websocket:sself didFailWithError:error];
            });
            [sself closeStream];
        } else {
            WRInfoLog(@"Websocket sent data");
        }
    }];

    return YES;
}

- (void)readData {
    __weak typeof(self) wself = self;
    [_streamTask readDataOfMinLength:2 maxLength:kWRWebsocketChunkLength timeout:0 completionHandler:^(NSData * _Nullable data, BOOL atEOF, NSError * _Nullable error) {
        __strong typeof(wself) sself = wself;
        if (sself == nil) return;

        if (error != nil) {
            WRErrorLog(@"Getting error while receiving data: %@", error);
            backgroundDispatch(sself.delegate, @selector(websocket:didFailWithError:), ^{
                [sself.delegate websocket:sself didFailWithError:error];
            });
            [sself closeStream];
        }
        else {
            if (atEOF) {
                [sself closeStream];
            }
            else {
                NSError *readerError;
                BOOL result = [sself->_frameReader readData:data error:&readerError];
                if (!result) {
                    WRErrorLog(@"Unable to read receiving frame: %@", readerError);
                    backgroundDispatch(sself.delegate, @selector(websocket:didFailWithError:), ^{
                        [sself.delegate websocket:sself didFailWithError:readerError];
                    });
                }

                [sself readData];
            }
        }
    }];
}

- (void)closeStream {
    WRDebugLog(@"Websocket was closed");
    
    [_streamTask closeRead];
    [_streamTask closeWrite];
    backgroundDispatch(self.delegate, @selector(websocket:didCloseWithData:), ^{
        [self.delegate websocket:self didCloseWithData:nil];
    });
}

- (void)setupFrameHandlersWithPreferences:(WRHandshakePreferences *)preferences {
    _frameWriter = [[WRFrameWriter alloc] init];
    _frameReader = [[WRFrameReader alloc] init];
    _frameReader.delegate = self;

    if (_enabledPerMessageDeflate) {
        _frameWriter.deflater = [[WRDataDeflater alloc] initWithWindowBits:preferences.maxWindowBits memoryLevel:kWRCompressionMemoryLevel noContextTakeover:preferences.noContextTakeover];
        _frameReader.inflater = [[WRDataInflater alloc] initWithWindowBits:preferences.maxWindowBits noContextTakeover:preferences.noContextTakeover];
    }
}

#pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {

    SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
    NSString *domain = challenge.protectionSpace.host;

    if ([_securePolicy evaluateServerTrust:serverTrust domain:domain]) {
        NSURLCredential *credential = [NSURLCredential credentialForTrust:serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
    } else {
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, NULL);
    }
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error {
    //TODO: add implementation
}

#pragma mark - WRFrameReaderDelegate

- (void)frameReader:(WRFrameReader *)reader didProcessText:(NSString *)text {
    WRDebugLog(@"Websocket did receive text message: %@", text);
    backgroundDispatch(self.delegate, @selector(websocket:didReceiveMessage:), ^{
        [self.delegate websocket:self didReceiveMessage:text];
    });
}

- (void)frameReader:(WRFrameReader *)reader didProcessData:(NSData *)data {
    WRDebugLog(@"Websocket did receive byte message, length %lu.", data.length);
    backgroundDispatch(self.delegate, @selector(websocket:didReceiveData:), ^{
        [self.delegate websocket:self didReceiveData:data];
    });
}

- (void)frameReader:(WRFrameReader *)reader didProcessClose:(NSData *)data {
    WRDebugLog(@"Websocket did receive close frame");
    NSAssert(self.state == WRWebsocketStateConnected, @"Getting close frame in %ld state.", (long)self.state);

    if (_state == WRWebsocketStateConnected) {
        [self close];
    }
}

- (void)frameReader:(WRFrameReader *)reader didProcessPing:(NSData *)data {
    WRDebugLog(@"Websocket did receive ping frame");
    backgroundDispatch(self.delegate, @selector(websocket:didReceivePing:), ^{
        [self.delegate websocket:self didReceivePing:data];
    });
    [self writeData:nil opcode:WROpCodePong error:nil];
}

- (void)frameReader:(WRFrameReader *)reader didProcessPong:(NSData *)data {
    WRDebugLog(@"Websocket did receive pong frame");
    backgroundDispatch(self.delegate, @selector(websocket:didReceivePong:), ^{
        [self.delegate websocket:self didReceivePong:data];
    });
}

@end
