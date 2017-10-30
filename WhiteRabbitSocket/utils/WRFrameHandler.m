//
//  WRFrameHandler.m
//  WhiteRabbitSocket
//
//  Created by Anastasia Kononova on 23/10/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import "WRFrameHandler.h"
#import "NSError+WRError.h"
#import "WRSIMDFunction.h"

static const NSInteger WRFrameHeaderOverhead = 32;

static const uint8_t WRFinMask = 0x80;
static const uint8_t WROpCodeMask = 0x0F;
static const uint8_t WRRsvMask = 0x70;
static const uint8_t WRMaskMask = 0x80;
static const uint8_t WRPayloadLenMask = 0x7F;

@implementation WRFrameHandler

+ (NSData *)buildFrameFromData:(NSData *)data opCode:(WROpCode)opCode error:(NSError **)error
{
    if (data == nil) {
        //TODO: add error
        return nil;
    }

    size_t payloadLength = data.length;

    NSMutableData *frameData = [[NSMutableData alloc] initWithLength:payloadLength + WRFrameHeaderOverhead];
    if (frameData == nil) {
        *error = [NSError errorWithCode:2133 description: @"Message too big."];
        return nil;
    }

    uint8_t *frameBuffer = (uint8_t *)frameData.mutableBytes;
    frameBuffer[0] = WRFinMask | opCode;
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

    const uint8_t *unmaskedPayloadBuffer = (uint8_t *)data.bytes;
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

+ (NSData *)parseFrameFromData:(NSData *)data error:(NSError **)error
{
    const uint8_t *headerBuffer = data.bytes;
    assert(data.length >= 2);

    //TODO: check rsv flags for deflate
    if (headerBuffer[0] & WRRsvMask) {
        *error = [NSError errorWithCode:2133 description: @"Server used RSV bits."];
        return nil;
    }

    uint8_t receivedOpcode = (WROpCodeMask & headerBuffer[0]);

    BOOL isControlFrame = (receivedOpcode == WROpCodePing || receivedOpcode == WROpCodePong || receivedOpcode == WROpCodeConnectionClose);

    //TODO: fragmentation
//    if (!isControlFrame && receivedOpcode != 0 && sself->_currentFrameCount > 0) {
//        [sself _closeWithProtocolError:@"all data frames after the initial data frame must have opcode 0"];
//        return;
//    }
//
//    if (receivedOpcode == 0 && sself->_currentFrameCount == 0) {
//        [sself _closeWithProtocolError:@"cannot continue a message"];
//        return;
//    }
//
//    header.opcode = receivedOpcode == 0 ? sself->_currentFrameOpcode : receivedOpcode;

    BOOL fin = !!(WRFinMask & headerBuffer[0]);


    BOOL masked = !!(WRMaskMask & headerBuffer[1]);
    uint64_t payload_length = WRPayloadLenMask & headerBuffer[1];

    headerBuffer = NULL;

    if (masked) {
        *error = [NSError errorWithCode:2133 description: @"Client must receive unmasked data."];
        return nil;
    }

    NSLog(@"fin: %d, masked: %d, length: %llu", fin, masked, payload_length);
    return [NSData dataWithBytes:(data.bytes + 2) length:data.length - 2];

//    size_t extra_bytes_needed = 0;
//
//    if (payload_length == 126) {
//        extra_bytes_needed += sizeof(uint16_t);
//    } else if (payload_length == 127) {
//        extra_bytes_needed += sizeof(uint64_t);
//    }
}

@end
