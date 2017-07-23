//
//  NSURL+WebSocket.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 16/07/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (WebSocket)

@property (nonatomic, assign, readonly) NSInteger websocketPort;
@property (nonatomic, copy, readonly) NSString *handshakeHost;
@property (nonatomic, copy, readonly) NSString *baseAuthorization;
@property (nonatomic, copy, readonly) NSString *origin;
@end
