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
    NSData *_data;
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
    NSData *result = [self getDataOfLength:length];
    _offset += result.length;
    return result;
}

- (void)seekToDataOffset:(NSInteger)offset
{
    _offset = offset;
}

- (NSUInteger)length
{
    return _data.length - _offset;
}

- (NSData *)data
{
    return [self getDataOfLength:self.length];
}

#pragma mark - Private

- (NSData *)getDataOfLength:(NSUInteger)length
{
    if (_offset >= _data.length) {
        return nil;
    }

    NSUInteger possibleLength = MIN(length, self.length);
    if (possibleLength == 0) {
        return nil;
    }

    return [NSData dataWithBytes:(_data.bytes + _offset) length:possibleLength];
}

@end
