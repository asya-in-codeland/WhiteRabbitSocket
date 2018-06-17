//
//  WRWebsocketDelegate.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 16/07/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WRDispatchProtocol.h"

@protocol WRWebsocketDelegate <WRDispatchProtocol>
@required
- (void)websocket:(nonnull WRWebsocket *)websocket didReceiveData:(nonnull NSData *)data;
- (void)websocket:(nonnull WRWebsocket *)websocket didReceiveMessage:(nonnull NSString *)message;
- (void)websocket:(nonnull WRWebsocket *)websocket didFailWithError:(nonnull NSError *)error;

@optional
- (void)websocketDidEstablishConnection:(nonnull WRWebsocket *)websocket;
- (void)websocket:(nonnull WRWebsocket *)websocket didReceivePing:(nullable NSData *)data;
- (void)websocket:(nonnull WRWebsocket *)websocket didReceivePong:(nullable NSData *)data;
- (void)websocket:(nonnull WRWebsocket *)websocket didCloseWithData:(nullable NSData *)data;
@end
