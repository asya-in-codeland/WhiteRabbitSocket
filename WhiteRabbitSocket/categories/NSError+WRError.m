//
//  NSError+WRError.m
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 23/07/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import "NSError+WRError.h"

@implementation NSError (WRError)

+ (void)wr_assignInoutError:(NSError * __autoreleasing  _Nullable *_Nullable)inoutError withCode:(WRStatusCode)code description:(NSString *)description {
    if (inoutError != nil) {
        *inoutError = [self wr_errorWithCode:code description:description];
    }
}

+ (instancetype)wr_errorWithCode:(WRStatusCode)code description:(NSString *)description {
    return [self wr_errorWithDomain:kWRWebsocketErrorDomain code:code description:description];
}

+ (instancetype)wr_errorWithDomain:(NSErrorDomain)domain code:(WRStatusCode)code description:(NSString *)description {
    return [self errorWithDomain:domain code:code userInfo:@{NSLocalizedDescriptionKey: description}];
}

@end
