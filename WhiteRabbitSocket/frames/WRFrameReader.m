//
//  WRFrameReader.m
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 06/11/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import "WRFrameReader.h"
#import "WRFrameHeader.h"
#import "WRFramePayload.h"
#import "WRFrameMasks.h"
#import "WRReadableData.h"
#import "NSError+WRError.h"

typedef NS_ENUM(NSInteger, WRFrameReaderState) {
    WRFrameReaderStateHeader,
    WRFrameReaderStateExtended,
    WRFrameReaderStatePayload
};

@implementation WRFrameReader {
    WRFrameReaderState _state;
    WRFrameHeader _header;
    WRFramePayload *_payload;
    NSInteger _framesCount;
}

- (BOOL)readData:(NSData *)data error:(NSError *__autoreleasing *)error
{
    return [self read:[WRReadableData dataWithData:data] error:error];
}

- (BOOL)read:(WRReadableData *)data error:(NSError *__autoreleasing *)error
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
            
            _payload = [WRFramePayload new];
            
            if (_header.payloadLength == 0) {
                _state = WRFrameReaderStateHeader;
            }
            else if (_header.payloadLength < 126) {
                _state = WRFrameReaderStatePayload;
                _payload.capacity = _header.payloadLength;
            }
            else {
                _state = WRFrameReaderStateExtended;
                _payload.extraLengthCapacity = _header.payloadLength == 126 ? sizeof(uint16_t) : sizeof(uint64_t);
            }
            
            return [self read:data error:error];
        }
        case WRFrameReaderStateExtended: {
            if(_payload.extraLengthBuffer.length + data.length < _payload.extraLengthCapacity) {
                [_payload.extraLengthBuffer appendData:data];
                return YES;
            }
            
            NSInteger appendedDataLength = _payload.extraLengthCapacity - _payload.extraLengthBuffer.length;
            [_payload.extraLengthBuffer appendData:[data readDataOfLength:appendedDataLength]];
            
            if (_header.payloadLength == 126) {
                _payload.capacity = CFSwapInt16BigToHost(*(uint16_t *)_payload.extraLengthBuffer.bytes);
            }
            else if(_header.payloadLength == 127) {
                _payload.capacity = CFSwapInt64BigToHost(*(uint64_t *)_payload.extraLengthBuffer.bytes);
            }
            
            _state = WRFrameReaderStatePayload;
            return [self read:data error:error];
        }
        case WRFrameReaderStatePayload: {
            if(_payload.data.length + data.length < _payload.capacity) {
                [_payload.data appendData:data];
                return YES;
            }
            
            NSInteger appendedDataLength = _payload.capacity - _payload.data.length;
            [_payload.data appendData:[data readDataOfLength:appendedDataLength]];
            
            if (_header.fin) {
                [self performCompletionHandler];
            }
            
            _framesCount++;
            _state = WRFrameReaderStateHeader;
            return [self read:data error:error];
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
        _onTextFrameFinish([[NSString alloc] initWithData:_payload.data encoding:NSUTF8StringEncoding]);
    }
    else if (_header.opcode == WROpCodeBinaryFrame && _onDataFrameFinish != nil) {
        _onDataFrameFinish(_payload.data);
    }
}

@end
