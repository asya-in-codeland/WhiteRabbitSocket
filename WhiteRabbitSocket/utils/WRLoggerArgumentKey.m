//
//  WRLoggerArgumentKey.m
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 17/06/2018.
//  Copyright © 2018 ASya. All rights reserved.
//

#import "WRLoggerArgumentKey.h"

@interface WRLoggerArgumentKey ()
@property (nonatomic, copy, readonly) NSString *key;
@end

@implementation WRLoggerArgumentKey

- (instancetype)initWithKey:(NSString *)key {
    self = [super init];
    if (self != nil) {
        _key = key.copy;
    }
    return self;
}

- (instancetype)copyWithZone:(nullable NSZone *)zone {
    return [(WRLoggerArgumentKey *)[self.class allocWithZone:zone] initWithKey: self.key];
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:self.class]) {
        return NO;
    }
    
    return [self.key isEqualToString:((WRLoggerArgumentKey *)object).key];
}

- (NSUInteger)hash {
    return self.key.hash;
}

- (NSString *)description {
    return self.key;
}

#pragma mark - Public

+ (WRLoggerArgumentKey *)websocketRequest {
    return [[WRLoggerArgumentKey alloc] initWithKey:@"WRWebsocketArgumentKeyWebsocketRequest"];
}

+ (WRLoggerArgumentKey *)readDataLength {
    return [[WRLoggerArgumentKey alloc] initWithKey:@"WRWebsocketArgumentKeyReadDataLength"];
}
@end
