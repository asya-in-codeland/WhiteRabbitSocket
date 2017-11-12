//
//  WRIteratableData.m
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 12/11/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import "WRIteratableData.h"

@implementation WRIteratableData {
    NSUInteger _position;
}

- (WRIteratableData *)readDataOfLength:(NSUInteger)length
{
    NSUInteger possibleLength = MIN(length, self.length - _position - 1);
    NSData *data = [self subdataWithRange:NSMakeRange(_position, possibleLength)];
    _position += possibleLength;
    return [WRIteratableData dataWithData:data];
}

@end
