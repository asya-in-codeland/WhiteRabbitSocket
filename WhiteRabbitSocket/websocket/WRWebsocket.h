//
//  WRWebsocket.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 10/07/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol WRWebsocketDelegate;

FOUNDATION_EXPORT NSString * _Nonnull const kWRWebsocketErrorDomain;

typedef NS_ENUM(NSInteger, WRWebsocketState) {
    WRWebsocketStateConnecting,
    WRWebsocketStateConnected,
    WRWebsocketStateClosing,
    WRWebsocketStateClosed
};

@interface WRWebsocket : NSObject

@property (nonatomic, weak, nullable) id<WRWebsocketDelegate> delegate;
@property (nonatomic, assign, readonly) WRWebsocketState state;

- (nonnull instancetype)initWithURLRequest:(nonnull NSURLRequest *)request NS_DESIGNATED_INITIALIZER;

- (nullable instancetype)init __attribute__((unavailable("Use designated initializer -initWithURLRequest: instead.")));
- (nullable instancetype)new __attribute__((unavailable("Use designated initializer -initWithURLRequest: instead.")));

- (void)open;
- (void)close;

- (BOOL)sendMessage:(nonnull NSString *)message error:(NSError * __autoreleasing  _Nullable *_Nullable)error;
- (BOOL)sendData:(nonnull NSData *)data error:(NSError * __autoreleasing  _Nullable * _Nullable)error;
- (BOOL)sendPing:(nullable NSData *)data error:(NSError * __autoreleasing  _Nullable * _Nullable)error;

@end
