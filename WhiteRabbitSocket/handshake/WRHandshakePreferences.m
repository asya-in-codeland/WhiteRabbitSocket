//
//  WRHandshakePreferences.m
//  WhiteRabbitSocket
//
//  Created by Anastasia Kononova on 05/02/2018.
//  Copyright © 2018 ASya. All rights reserved.
//

#import "WRHandshakePreferences.h"

@implementation WRHandshakePreferences

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        _maxWindowBits = -15;
        _noContextTakeover = NO;
    }
    return self;
}

@end
