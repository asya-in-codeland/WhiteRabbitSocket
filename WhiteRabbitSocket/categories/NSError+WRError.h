//
//  NSError+WRError.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 23/07/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WRWebsocket.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSError (WRError)

+ (void)wr_assignInoutError:(NSError * __autoreleasing  _Nullable *_Nullable)inoutError withCode:(WRStatusCode)code description:(NSString *)description;
+ (instancetype)wr_errorWithCode:(WRStatusCode)code description:(NSString *)description;
+ (instancetype)wr_errorWithDomain:(NSErrorDomain)domain code:(WRStatusCode)code description:(NSString *)description;

@end

NS_ASSUME_NONNULL_END
