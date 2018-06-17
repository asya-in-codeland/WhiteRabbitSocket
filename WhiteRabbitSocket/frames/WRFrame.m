//
//  WRFrame.m
//  WhiteRabbitSocket
//
//  Created by Anastasia Kononova on 20/11/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import "WRFrame.h"

@implementation WRFrame

- (instancetype)init {
    self = [super init];
    if (self != nil) {
        _headerCapacity = 2;
        _header = [NSMutableData dataWithCapacity:_headerCapacity];
    }
    return self;
}

- (void)setPayloadCapacity:(NSUInteger)payloadCapacity {
    _payloadCapacity = payloadCapacity;
    _payload = [NSMutableData dataWithCapacity:payloadCapacity];
}

- (void)setExtraLengthCapacity:(NSUInteger)extraLengthCapacity {
    _extraLengthCapacity = extraLengthCapacity;
    _extraLengthBuffer = [NSMutableData dataWithCapacity:_extraLengthCapacity];
}

@end
