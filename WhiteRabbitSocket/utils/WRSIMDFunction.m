//
//  WRSIMDFunction.m
//  WhiteRabbitSocket
//
//  Created by Anastasia Kononova on 23/10/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import "WRSIMDFunction.h"

typedef uint8_t uint8x32_t __attribute__((vector_size(32)));

@implementation WRSIMDFunction

+ (void)maskBytes:(uint8_t *)bytes length:(size_t)length withKey:(uint8_t *)maskKey {
    size_t alignmentBytes = _Alignof(uint8x32_t) - ((uintptr_t)bytes % _Alignof(uint8x32_t));
    if (alignmentBytes == _Alignof(uint8x32_t)) {
        alignmentBytes = 0;
    }

    if (alignmentBytes > length || (length - alignmentBytes) < sizeof(uint8x32_t)) {
        [self manualMaskingBytes:bytes length:length maskKey:maskKey];
        return;
    }

    size_t vectorLength = (length - alignmentBytes) / sizeof(uint8x32_t);
    size_t manualStartOffset = alignmentBytes + (vectorLength * sizeof(uint8x32_t));
    size_t manualLength = length - manualStartOffset;

    uint8x32_t *vector = (uint8x32_t *)(bytes + alignmentBytes);
    uint8x32_t maskVector = { };

    memset_pattern4(&maskVector, maskKey, sizeof(uint8x32_t));
    maskVector = [self shiftVector:maskVector alignmentBytes:alignmentBytes];

    [self manualMaskingBytes:bytes length:alignmentBytes maskKey:maskKey];

    for (size_t vectorIndex = 0; vectorIndex < vectorLength; vectorIndex++) {
        vector[vectorIndex] = vector[vectorIndex] ^ maskVector;
    }

    [self manualMaskingBytes:bytes + manualStartOffset length:manualLength maskKey:(uint8_t *) &maskVector];
}

+ (uint8x32_t)shiftVector:(uint8x32_t)vector alignmentBytes:(size_t)by {
    uint8x32_t vectorCopy = vector;
    by = by % _Alignof(uint8x32_t);

    uint8_t *vectorPointer = (uint8_t *)&vector;
    uint8_t *vectorCopyPointer = (uint8_t *)&vectorCopy;

    memmove(vectorPointer + by, vectorPointer, sizeof(vector) - by);
    memcpy(vectorPointer, vectorCopyPointer + (sizeof(vector) - by), by);

    return vector;
}

+ (void)manualMaskingBytes:(uint8_t *)bytes length:(size_t)length maskKey:(uint8_t *)maskKey {
    for (size_t i = 0; i < length; i++) {
        bytes[i] = bytes[i] ^ maskKey[i % sizeof(uint32_t)];
    }
}

@end
