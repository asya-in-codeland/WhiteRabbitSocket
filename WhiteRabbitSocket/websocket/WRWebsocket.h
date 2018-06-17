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

FOUNDATION_EXPORT NSString * _Nonnull const kWRWebsocketErrorDomain;

typedef NS_ENUM(NSInteger, WRWebsocketState) {
    WRWebsocketStateConnecting,
    WRWebsocketStateConnected,
    WRWebsocketStateClosed
};

__attribute__((objc_subclassing_restricted))

@interface WRWebsocket : NSObject

@property (nonatomic, weak, nullable) id<WRWebsocketDelegate> delegate;
@property (nonatomic, assign, readonly) WRWebsocketState state;
@property (nonatomic, assign) BOOL enabledPerMessageDeflate;

- (instancetype)initWithURLRequest:(NSURLRequest *)request;
- (instancetype)initWithURLRequest:(NSURLRequest *)request securePolicy:(WRServerTrustPolicy *)serverTrustPolicy NS_DESIGNATED_INITIALIZER;

- (nullable instancetype)init __attribute__((unavailable("Use designated initializer -initWithURLRequest:securePolicy:securePolicy: instead.")));
- (nullable instancetype)new __attribute__((unavailable("Use designated initializer -initWithURLRequest: instead.")));

- (void)open;
- (void)close;

- (BOOL)sendMessage:(NSString *)message error:(NSError * __autoreleasing  _Nullable *_Nullable)error;
- (BOOL)sendData:(NSData *)data error:(NSError * __autoreleasing  _Nullable * _Nullable)error;
- (BOOL)sendPing:(nullable NSData *)data error:(NSError * __autoreleasing  _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
