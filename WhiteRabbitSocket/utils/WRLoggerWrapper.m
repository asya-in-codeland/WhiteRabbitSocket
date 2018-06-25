//
//  WRLoggerWrapper.m
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 17/06/2018.
//  Copyright © 2018 ASya. All rights reserved.
//

#import "WRLoggerWrapper.h"

@interface WRDefaultLogger: NSObject <WRLogger>
@end

@implementation WRDefaultLogger
- (WRLogLevel)logLevel {
    return WRLogLevelDebug;
}

- (void)receiveMessage:(NSString *)message {
    NSLog(@"%@", message);
}
@end

static id<WRLogger> sharedLogger = nil;
static NSDateFormatter *dateFormatter = nil;

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

+ (void)logMessage:(NSString *)message level:(WRLogLevel)level {
    id<WRLogger> currentLogger = self.logger != nil ? self.logger : [[WRDefaultLogger alloc] init];
    if (level < currentLogger.logLevel) { return; }
    
    NSString *date = [[self logDateFormatter] stringFromDate:[NSDate date]];
    NSString *compoundMessage = [NSString stringWithFormat:@"[WRWebsocket] %@ %@", date, message];
    [currentLogger receiveMessage:compoundMessage];
}

+ (NSDateFormatter *)logDateFormatter {
    static dispatch_once_t formatterPredicate;
    dispatch_once( &formatterPredicate, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat: @"HH:mm:ss.SSSZ"];
    } );
    return dateFormatter;
}

@end
