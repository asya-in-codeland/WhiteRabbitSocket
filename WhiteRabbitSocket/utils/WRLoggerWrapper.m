//
//  WRLoggerWrapper.m
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 17/06/2018.
//  Copyright © 2018 ASya. All rights reserved.
//

#import "WRLoggerWrapper.h"

static id<WRLogger> sharedLogger = nil;

@interface WRDefaultLogger: NSObject <WRLogger>
@end

@implementation WRDefaultLogger
- (WRLogLevel)logLevel {
    return WRLogLevelDebug;
}

- (void)receiveMessage:(NSString *)message arguments:(nullable NSDictionary<WRLoggerArgumentKey *, NSString*> *)arguments {
    NSLog(@"%@[%@]", message, arguments);
}
@end

@implementation WRLoggerWrapper

+ (id<WRLogger>)logger {
    return sharedLogger;
}

+ (void)setLogger:(id<WRLogger>)logger {
    static dispatch_once_t predicate;
    dispatch_once( &predicate, ^{
        sharedLogger = logger;
    } );
}

+ (void)logMessage:(NSString *)message level:(WRLogLevel)level arguments:(NSDictionary<WRLoggerArgumentKey *,NSString *> *)arguments {
    id<WRLogger> currentLogger = self.logger != nil ? self.logger : [[WRDefaultLogger alloc] init];
    if (level < currentLogger.logLevel) { return; }
    [currentLogger receiveMessage:message arguments:arguments];
}

@end
