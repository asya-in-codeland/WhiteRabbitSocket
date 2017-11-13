//
//  WRFramePayload.m
//  WhiteRabbitSocket
//
//  Created by Anastasia Kononova on 13/11/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import "WRFramePayload.h"

@implementation WRFramePayload

- (void)setCapacity:(NSUInteger)capacity
{
    _capacity = capacity;
    _data = [NSMutableData dataWithCapacity:_capacity];
}

- (void)setExtraLengthCapacity:(NSUInteger)extraLengthCapacity
{
    _extraLengthCapacity = extraLengthCapacity;
    _extraLengthBuffer = [NSMutableData dataWithCapacity:_extraLengthCapacity];
}

@end
