//
//  WRReadableData.m
//  WhiteRabbitSocket
//
//  Created by Anastasia Kononova on 13/11/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import "WRReadableData.h"

@implementation WRReadableData {
    NSUInteger _offset;
}

- (WRReadableData *)readDataOfLength:(NSUInteger)length
{
    if (_offset >= self.length) {
        return nil;
    }

    NSUInteger possibleLength = MIN(length, self.length - _offset - 1);
    if (possibleLength <= 0) {
        return nil;
    }

    WRReadableData *result = [WRReadableData dataWithBytes:(self.bytes + _offset) length:possibleLength];
    _offset += possibleLength;

    return result;
}

- (void)seekToDataOffset:(NSInteger)offset
{
    _offset = offset;
}

@end
