//
//  WRLoggerWrapper.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 17/06/2018.
//  Copyright © 2018 ASya. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WRLogger.h"

@interface WRLoggerWrapper : NSObject
@property (class, nonatomic, strong) id<WRLogger> logger;
+ (void)logMessage:(NSString *)message level:(WRLogLevel)level;
@end

#define WRDebugLog(message, ...) [WRLoggerWrapper logMessage:[NSString stringWithFormat:(message), ##__VA_ARGS__] level:WRLogLevelDebug]
#define WRInfoLog(message, ...) [WRLoggerWrapper logMessage:[NSString stringWithFormat:(message), ##__VA_ARGS__] level:WRLogLevelInfo]
#define WRWarningLog(message, ...) [WRLoggerWrapper logMessage:[NSString stringWithFormat:(message), ##__VA_ARGS__] level:WRLogLevelWarning]
#define WRErrorLog(message, ...) [WRLoggerWrapper logMessage:[NSString stringWithFormat:(message), ##__VA_ARGS__] level:WRLogLevelError]
