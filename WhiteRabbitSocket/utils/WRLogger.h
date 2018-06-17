//
//  WRLogger.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 17/06/2018.
//  Copyright © 2018 ASya. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class WRLoggerArgumentKey;

typedef NS_ENUM(NSInteger, WRLogLevel) {
    WRLogLevelDebug = 0,
    WRLogLevelInfo,
    WRLogLevelWarning,
    WRLogLevelError
};

@protocol WRLogger <NSObject>
@property (nonatomic, assign, readonly) WRLogLevel logLevel;
- (void)receiveMessage:(NSString *)message arguments:(nullable NSDictionary<WRLoggerArgumentKey *, NSString*> *)arguments;
@end

NS_ASSUME_NONNULL_END
