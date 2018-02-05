//
//  WRFrameWriter.m
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 06/11/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import "WRFrameWriter.h"
#import "NSError+WRError.h"
#import "WRSIMDFunction.h"
#import "WRFrameMasks.h"
#import "WRDataDeflater.h"

static const NSInteger WRFrameHeaderOverhead = 32;

@implementation WRFrameWriter

- (NSData *)buildFrameFromData:(NSData *)data opCode:(WROpCode)opCode error:(NSError **)error
{
    NSData *payloadData = data;
    BOOL shouldCompressData = _deflater != nil && payloadData.length > 0 && (opCode == WROpCodeText || opCode == WROpCodeBinary);

    if (shouldCompressData) {
        payloadData = [_deflater deflateData:payloadData error:error];
        if (payloadData == nil) {
            return nil;
        }
    }

    size_t payloadLength = payloadData.length;

    NSMutableData *frameData = [[NSMutableData alloc] initWithLength:payloadLength + WRFrameHeaderOverhead];
    if (frameData == nil) {
        *error = [NSError errorWithCode:2133 description: @"Message too big."];
        return nil;
    }
    
    uint8_t *frameBuffer = (uint8_t *)frameData.mutableBytes;
    frameBuffer[0] = WRFinMask | opCode;
    if (shouldCompressData) {
        frameBuffer[0] |= WRRsv1Mask;
    }

    frameBuffer[1] |= WRMaskMask;
    
    size_t frameBufferSize = 2;
    
    if (payloadLength < 126) {
        frameBuffer[1] |= payloadLength;
    } else {
        uint64_t declaredPayloadLength = 0;
        size_t declaredPayloadLengthSize = 0;
        
        if (payloadLength <= UINT16_MAX) {
            frameBuffer[1] |= 126;
            
            declaredPayloadLength = CFSwapInt16BigToHost((uint16_t)payloadLength);
            declaredPayloadLengthSize = sizeof(uint16_t);
        } else {
            frameBuffer[1] |= 127;
            
            declaredPayloadLength = CFSwapInt64BigToHost((uint64_t)payloadLength);
            declaredPayloadLengthSize = sizeof(uint64_t);
        }
        
        memcpy((frameBuffer + frameBufferSize), &declaredPayloadLength, declaredPayloadLengthSize);
        frameBufferSize += declaredPayloadLengthSize;
    }
    
    const uint8_t *unmaskedPayloadBuffer = (uint8_t *)payloadData.bytes;
    uint8_t *maskKey = frameBuffer + frameBufferSize;
    
    size_t randomBytesSize = sizeof(uint32_t);
    int result = SecRandomCopyBytes(kSecRandomDefault, randomBytesSize, maskKey);
    if (result != errSecSuccess) {
        *error = [NSError errorWithCode:2133 description: @"Message too big."];
        return nil;
    }
    
    frameBufferSize += randomBytesSize;
    
    uint8_t *frameBufferPayloadPointer = frameBuffer + frameBufferSize;
    
    memcpy(frameBufferPayloadPointer, unmaskedPayloadBuffer, payloadLength);
    [WRSIMDFunction maskBytes:frameBufferPayloadPointer length:payloadLength withKey:maskKey];
    frameBufferSize += payloadLength;
    
    assert(frameBufferSize <= frameData.length);
    frameData.length = frameBufferSize;
    
    return frameData;
}

@end
