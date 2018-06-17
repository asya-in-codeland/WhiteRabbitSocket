//
//  WRWebsocketDelegate.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 16/07/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WRDispatchProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol WRWebsocketDelegate <WRDispatchProtocol>
@required
- (void)websocket:(WRWebsocket *)websocket didReceiveData:(NSData *)data;
- (void)websocket:(WRWebsocket *)websocket didReceiveMessage:(NSString *)message;
- (void)websocket:(WRWebsocket *)websocket didFailWithError:(NSError *)error;

@optional
- (void)websocketDidEstablishConnection:(WRWebsocket *)websocket;
- (void)websocket:(WRWebsocket *)websocket didReceivePing:(nullable NSData *)data;
- (void)websocket:(WRWebsocket *)websocket didReceivePong:(nullable NSData *)data;
- (void)websocket:(WRWebsocket *)websocket didCloseWithData:(nullable NSData *)data;
@end

NS_ASSUME_NONNULL_END
