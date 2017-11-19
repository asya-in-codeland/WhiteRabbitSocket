//
//  WRProxy.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 19/11/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WRProxy : NSObject

@property (nonatomic, copy, readonly) NSString *host;
@property (nonatomic, assign, readonly) NSInteger port;
@property (nonatomic, copy, readonly) NSString *username;
@property (nonatomic, copy, readonly) NSString *password;

+ (instancetype)httpProxyWithHost:(NSString *)host port:(NSInteger)port;
+ (instancetype)socksProxyWithHost:(NSString *)host port:(NSInteger)port username:(NSString *)username password:(NSString *)password;

@end
