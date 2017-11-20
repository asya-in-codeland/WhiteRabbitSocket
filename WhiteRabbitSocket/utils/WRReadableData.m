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

- (instancetype)initWithData:(NSData *)data
{
    self = [super init];
    if (self != nil) {
        _data = data.copy;
    }
    return self;
}

- (NSData *)readDataOfLength:(NSUInteger)length
{
    if (_offset >= _data.length) {
        return nil;
    }

    NSUInteger possibleLength = MIN(length, _data.length - _offset - 1);
    if (possibleLength <= 0) {
        return nil;
    }

    NSData *result = [NSData dataWithBytes:(_data.bytes + _offset) length:possibleLength];
    _offset += possibleLength;

    return result;
}

- (void)seekToDataOffset:(NSInteger)offset
{
    _offset = offset;
}

- (NSUInteger)length
{
    return _data.length;
}

@end
