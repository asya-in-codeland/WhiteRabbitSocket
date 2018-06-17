//
//  NSURL+WRWebSocket.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 16/07/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURL (WRWebSocket)

@property (nonatomic, assign, readonly) NSInteger wr_websocketPort;
@property (nonatomic, copy, readonly, nullable) NSString *wr_handshakeHost;
@property (nonatomic, copy, readonly) NSString *wr_baseAuthorization;
@property (nonatomic, copy, readonly) NSString *wr_origin;
@property (nonatomic, assign, readonly) BOOL wr_isSecureConnection;

@end

NS_ASSUME_NONNULL_END
