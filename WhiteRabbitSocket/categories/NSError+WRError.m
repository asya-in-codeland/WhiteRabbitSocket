//
//  NSError+WRError.m
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 23/07/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import "NSError+WRError.h"
#import "WRWebsocket.h"

@implementation NSError (WRError)

+ (instancetype)errorWithCode:(NSInteger)code description:(NSString *)description
{
    return [self errorWithDomain:kWRWebsocketErrorDomain code:code description:description];
}

+ (instancetype)errorWithDomain:(NSErrorDomain)domain code:(NSInteger)code description:(NSString *)description
{
    return [self errorWithDomain:domain code:code userInfo:@{NSLocalizedDescriptionKey: description}];
}

@end
