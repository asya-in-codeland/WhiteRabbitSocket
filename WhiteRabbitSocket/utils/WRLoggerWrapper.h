//
//  WRLoggerWrapper.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 17/06/2018.
//  Copyright © 2018 ASya. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WRLogger.h"
#import "WRLoggerArgumentKey.h"

@interface WRLoggerWrapper : NSObject
@property (class, nonatomic, strong) id<WRLogger> logger;
+ (void)logMessage:(NSString *)message level:(WRLogLevel)level arguments:(NSDictionary<WRLoggerArgumentKey *, NSString*> *)arguments;
@end

#define WRDebugLog(message, ...) [WRLoggerWrapper logMessage:message level:WRLogLevelDebug arguments: __VA_ARGS__]
#define WRInfoLog(message, ...) [WRLoggerWrapper logMessage:message level:WRLogLevelInfo arguments:__VA_ARGS__]
#define WRWarningLog(message, ...) [WRLoggerWrapper logMessage:message level:WRLogLevelWarning arguments: __VA_ARGS__]
#define WRErrorLog(message, ...) [WRLoggerWrapper logMessage:message level:WRLogLevelError arguments: __VA_ARGS__]
