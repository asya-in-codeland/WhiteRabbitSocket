//
//  WRWebsocket.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 10/07/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class WRServerTrustPolicy;
@protocol WRWebsocketDelegate;
@protocol WRLogger;

FOUNDATION_EXPORT NSString * _Nonnull const kWRWebsocketErrorDomain;

typedef NS_ENUM(NSInteger, WRStatusCode) {
    // 0-999: Reserved and not used.
    WRStatusCodeNormal = 1000,
    WRStatusCodeGoingAway = 1001,
    WRStatusCodeProtocolError = 1002,
    WRStatusCodeUnhandledType = 1003,
    // 1004 reserved.
    SRStatusNoStatusReceived = 1005,
    WRStatusCodeAbnormal = 1006,
    WRStatusCodeInvalidUTF8 = 1007,
    WRStatusCodePolicyViolated = 1008,
    WRStatusCodeMessageTooBig = 1009,
    WRStatusCodeMissingExtension = 1010,
    WRStatusCodeInternalError = 1011,
    WRStatusCodeServiceRestart = 1012,
    WRStatusCodeTryAgainLater = 1013,
    // 1014: Reserved for future use by the WebSocket standard.
    WRStatusCodeTLSHandshake = 1015,
    // 1016-1999: Reserved for future use by the WebSocket standard.
    // 2000-2999: Reserved for use by WebSocket extensions.
    // 3000-3999: Available for use by libraries and frameworks. May not be used by applications. Available for registration at the IANA via first-come, first-serve.
    // 4000-4999: Available for use by applications.
};

typedef NS_ENUM(NSInteger, WRWebsocketState) {
    WRWebsocketStateConnecting,
    WRWebsocketStateConnected,
    WRWebsocketStateClosed
};

__attribute__((objc_subclassing_restricted))

@interface WRWebsocket : NSObject

@property (nonatomic, copy, readonly, nullable) NSURL *url;
@property (nonatomic, copy, readonly, nullable) NSArray<NSHTTPCookie *> *cookies;
@property (nonatomic, copy, readonly, nullable) NSArray<NSString *> *protocols;

@property (nonatomic, weak, nullable) id<WRWebsocketDelegate> delegate;
@property (nonatomic, assign, readonly) WRWebsocketState state;
@property (nonatomic, assign) BOOL enabledPerMessageDeflate;
@property (nonatomic, strong, nullable) id<WRLogger> logger;

- (instancetype)initWithURLRequest:(NSURLRequest *)request;
- (instancetype)initWithURLRequest:(NSURLRequest *)request securePolicy:(WRServerTrustPolicy *)serverTrustPolicy;
- (instancetype)initWithURLRequest:(NSURLRequest *)request securePolicy:(WRServerTrustPolicy *)serverTrustPolicy protocols:(nullable NSArray<NSString *> *)protocols cookies:(nullable NSArray<NSHTTPCookie *> *)cookies NS_DESIGNATED_INITIALIZER;

- (nullable instancetype)init __attribute__((unavailable("Use designated initializer -initWithURLRequest:securePolicy:protocols:cookies: instead.")));
- (nullable instancetype)new __attribute__((unavailable("Use designated initializer -initWithURLRequest:securePolicy:protocols:cookies: instead.")));

- (void)open;
- (void)close;

- (BOOL)sendMessage:(NSString *)message error:(NSError * __autoreleasing  _Nullable *_Nullable)error;
- (BOOL)sendData:(NSData *)data error:(NSError * __autoreleasing  _Nullable * _Nullable)error;
- (BOOL)sendPing:(nullable NSData *)data error:(NSError * __autoreleasing  _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
