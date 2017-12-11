//
//  WRFrame.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Kononova on 20/11/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, WROpCode)
{
    WROpCodeText = 0x1,
    WROpCodeBinary = 0x2,
    WROpCodeClose = 0x8,
    WROpCodePing = 0x9,
    WROpCodePong = 0xA
};

@interface WRFrame : NSObject

@property (nonatomic, assign) BOOL fin;
@property (nonatomic, assign) BOOL rsv1;
@property (nonatomic, assign) BOOL rsv2;
@property (nonatomic, assign) BOOL rsv3;
@property (nonatomic, assign) WROpCode opcode;
@property (nonatomic, assign) BOOL masked;
@property (nonatomic, assign) NSUInteger payloadLength;

@property (nonatomic, strong, readonly) NSMutableData *header;
@property (nonatomic, assign, readonly) NSUInteger headerCapacity;

@property (nonatomic, strong, readonly) NSMutableData *payload;
@property (nonatomic, assign) NSUInteger payloadCapacity;

@property (nonatomic, strong, readonly) NSMutableData *extraLengthBuffer;
@property (nonatomic, assign) NSUInteger extraLengthCapacity;

@end
