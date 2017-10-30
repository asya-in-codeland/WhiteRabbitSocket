//
//  WRFrameHandler.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Kononova on 23/10/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, WROpCode)
{
    WROpCodeTextFrame = 0x1,
    WROpCodeBinaryFrame = 0x2,
    WROpCodeConnectionClose = 0x8,
    WROpCodePing = 0x9,
    WROpCodePong = 0xA
};

@interface WRFrameHandler : NSObject

+ (NSData *)buildFrameFromData:(NSData *)data opCode:(WROpCode)opCode error:(NSError **)error;
+ (NSData *)parseFrameFromData:(NSData *)data error:(NSError **)error;

@end
