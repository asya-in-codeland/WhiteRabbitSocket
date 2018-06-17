//
//  WRProxy.m
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 19/11/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import "WRProxy.h"

@interface WRProxy()
@property (nonatomic, copy) NSString *host;
@property (nonatomic, assign) NSInteger port;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;
@end

@interface WRHttpProxy: WRProxy
- (instancetype)initWithHost:(NSString *)host port:(NSInteger)port;
@end

@interface WRSocksProxy: WRProxy
- (instancetype)initWithHost:(NSString *)host port:(NSInteger)port username:(NSString *)username password:(NSString *)password;
@end

@implementation WRProxy

+ (instancetype)httpProxyWithHost:(NSString *)host port:(NSInteger)port {
    return [[WRHttpProxy alloc] initWithHost:host port:port];
}

+ (instancetype)socksProxyWithHost:(NSString *)host port:(NSInteger)port username:(NSString *)username password:(NSString *)password {
    return [[WRSocksProxy alloc] initWithHost:host port:port username:username password:password];
}

@end

@implementation WRHttpProxy

- (instancetype)initWithHost:(NSString *)host port:(NSInteger)port {
    self = [super init];
    if (self != nil) {
        self.host = host;
        self.port = port;
        self.username = nil;
        self.password = nil;
    }
    return self;
}

@end

@implementation WRSocksProxy

- (instancetype)initWithHost:(NSString *)host port:(NSInteger)port username:(NSString *)username password:(NSString *)password {
    self = [super init];
    if (self != nil) {
        self.host = host;
        self.port = port;
        self.username = username;
        self.password = password;
    }
    return self;
}

@end

