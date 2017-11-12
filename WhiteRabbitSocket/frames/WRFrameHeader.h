//
//  WRFrameHeader.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 06/11/2017.
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

struct WRFrameHeader
{
    BOOL fin;
    BOOL rsv1;
    BOOL rsv2;
    BOOL rsv3;
    WROpCode opcode;
    BOOL masked;
    NSUInteger payloadLength;
    NSUInteger extendedPayloadLength;
};

typedef struct WRFrameHeader WRFrameHeader;

