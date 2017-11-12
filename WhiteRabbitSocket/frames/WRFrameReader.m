//
//  WRFrameReader.m
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 06/11/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import "WRFrameReader.h"
#import "WRFrameHeader.h"
#import "WRFrameMasks.h"
#import "NSError+WRError.h"
#import "WRIteratableData.h"

typedef NS_ENUM(NSInteger, WRFrameReaderState) {
    WRFrameReaderStateHeader,
    WRFrameReaderStateExtended,
    WRFrameReaderStatePayload
};

@implementation WRFrameReader {
    WRFrameReaderState _state;
    WRFrameHeader _header;
    NSInteger _framesCount;
    NSMutableData *_payload;
    NSUInteger _payloadCapacity;
    NSMutableData *_payloadExtraLength;
    NSUInteger _payloadExtraLengthCapacity;
}

- (BOOL)readData:(NSData *)data error:(NSError *__autoreleasing *)error
{
    return [self readIteratableData:[WRIteratableData dataWithData:data] error:error];
}

- (BOOL)readIteratableData:(WRIteratableData *)data error:(NSError *__autoreleasing *)error
{
    if (data.length == 0) {
        return YES;
    }
    
    switch (_state) {
        case WRFrameReaderStateHeader: {
            BOOL result = [self readHeader:[data readDataOfLength:2] error:error];
            if (!result) {
                return NO;
            }
            
            _payloadExtraLengthCapacity = 0;
            
            if (_header.payloadLength == 0) {
                _state = WRFrameReaderStateHeader;
            }
            else if (_header.payloadLength < 126) {
                _state = WRFrameReaderStatePayload;
                _payloadCapacity = _header.payloadLength;
                _payload = [NSMutableData dataWithCapacity:_payloadCapacity];
            }
            else {
                _state = WRFrameReaderStateExtended;
                _payloadExtraLengthCapacity = _header.payloadLength == 126 ? sizeof(uint16_t) : sizeof(uint64_t);
                _payloadExtraLength = [NSMutableData dataWithCapacity:_payloadExtraLengthCapacity];
            }
            
            return [self readIteratableData:data error:error];
        }
        case WRFrameReaderStateExtended: {
            if(_payloadExtraLength.length + data.length < _payloadExtraLengthCapacity) {
                [_payloadExtraLength appendData:data];
                return YES;
            }
            
            NSInteger appendedDataLength = _payloadExtraLengthCapacity - _payloadExtraLength.length;
            [_payloadExtraLength appendData:[data readDataOfLength:appendedDataLength]];
            
            if (_header.payloadLength == 126) {
                _payloadCapacity = CFSwapInt16BigToHost(*(uint16_t *)_payloadExtraLength.bytes);
            }
            else if(_header.payloadLength == 127) {
                _payloadCapacity = CFSwapInt64BigToHost(*(uint64_t *)_payloadExtraLength.bytes);
            }
            
            _payload = [NSMutableData dataWithCapacity:_payloadCapacity];
            
            _state = WRFrameReaderStatePayload;
            return [self readIteratableData:data error:error];
        }
        case WRFrameReaderStatePayload: {
            if(_payload.length + data.length < _payloadCapacity) {
                [_payloadExtraLength appendData:data];
                return YES;
            }
            
            NSInteger appendedDataLength = _payloadCapacity - _payload.length;
            [_payloadExtraLength appendData:[data readDataOfLength:appendedDataLength]];
            
            if (_header.fin) {
                [self performCompletionHandler];
            }
            
            _framesCount++;
            _state = WRFrameReaderStateHeader;
            return [self readIteratableData:data error:error];
        }
    }
}

#pragma mark - Private

- (BOOL)readHeader:(NSData *)data error:(NSError *__autoreleasing *)error
{
    const uint8_t *headerBuffer = data.bytes;
    assert(data.length >= 2);
    
    //TODO: check rsv flags for deflate
    if (headerBuffer[0] & WRRsvMask) {
        *error = [NSError errorWithCode:2133 description: @"Server used RSV bits."];
        return NO;
    }
    
    uint8_t receivedOpcode = (WROpCodeMask & headerBuffer[0]);
    
    BOOL isControlFrame = (receivedOpcode == WROpCodePing || receivedOpcode == WROpCodePong || receivedOpcode == WROpCodeConnectionClose);
    
    if (!isControlFrame && receivedOpcode != 0 && _framesCount > 0) {
        *error = [NSError errorWithCode:2133 description: @"All data frames after the initial data frame must have opcode 0."];
        return NO;
    }

    if (receivedOpcode == 0 && _framesCount == 0) {
        *error = [NSError errorWithCode:2133 description: @"Cannot continue a message."];
        return NO;
    }

    _header.opcode = receivedOpcode == 0 ? _header.opcode : receivedOpcode;
    
    _header.fin = !!(WRFinMask & headerBuffer[0]);
    _header.masked = !!(WRMaskMask & headerBuffer[1]);
    
    if (_header.masked) {
        *error = [NSError errorWithCode:2133 description: @"Client must receive unmasked data."];
        return NO;
    }
    
    _header.payloadLength = WRPayloadLenMask & headerBuffer[1];
    
    return YES;
}

- (void)performCompletionHandler
{
    if (_header.opcode == WROpCodeTextFrame && _onTextFrameFinish != nil) {
        _onTextFrameFinish([[NSString alloc] initWithData:_payload encoding:NSUTF8StringEncoding]);
    }
    else if (_header.opcode == WROpCodeBinaryFrame && _onDataFrameFinish != nil) {
        _onDataFrameFinish(_payload);
    }
}

@end
