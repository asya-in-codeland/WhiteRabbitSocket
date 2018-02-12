//
//  WRFrameReader.m
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 06/11/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import "WRFrameReader.h"
#import "WRFrame.h"
#import "WRFrameMasks.h"
#import "WRReadableData.h"
#import "WRDataInflater.h"
#import "NSError+WRError.h"

typedef NS_ENUM(NSInteger, WRFrameReaderState) {
    WRFrameReaderStateHeader,
    WRFrameReaderStateExtended,
    WRFrameReaderStatePayload
};

@implementation WRFrameReader {
    WRFrameReaderState _state;
    WRFrame *_currentFrame;
    NSMutableData *_message;
    NSInteger _framesCount;
}

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        _message = [NSMutableData new];
        _currentFrame = [WRFrame new];
    }
    return self;
}

- (BOOL)readData:(NSData *)data error:(NSError *__autoreleasing *)error
{
    //TODO: handle async
    NSLog(@"Start reading data...");
    return [self read:[[WRReadableData alloc] initWithData:data] error:error];
}

#pragma mark - Private

- (BOOL)read:(WRReadableData *)data error:(NSError *__autoreleasing *)error
{
    NSLog(@"data length: %lu", (unsigned long)data.length);

    if (data.length == 0) {
        return YES;
    }
    
    switch (_state) {
        case WRFrameReaderStateHeader: {
            if(_currentFrame.header.length + data.length < _currentFrame.headerCapacity) {
                [_currentFrame.header appendData:data.data];
                return YES;
            }

            NSInteger appendedDataLength = _currentFrame.headerCapacity - _currentFrame.header.length;
            [_currentFrame.header appendData:[data readDataOfLength:appendedDataLength]];

            BOOL result = [self readHeader:_currentFrame.header error:error];
            if (!result) {
                return NO;
            }
            
            if (_currentFrame.payloadLength == 0) {
                _state = WRFrameReaderStateHeader;
                [self completeFrameProcessingIfNeeded];
            }
            else if (_currentFrame.payloadLength < 126) {
                _state = WRFrameReaderStatePayload;
                _currentFrame.payloadCapacity = _currentFrame.payloadLength;
            }
            else {
                _state = WRFrameReaderStateExtended;
                _currentFrame.extraLengthCapacity = _currentFrame.payloadLength == 126 ? sizeof(uint16_t) : sizeof(uint64_t);
            }
            
            return [self read:data error:error];
        }
        case WRFrameReaderStateExtended: {
            if(_currentFrame.extraLengthBuffer.length + data.length < _currentFrame.extraLengthCapacity) {
                [_currentFrame.extraLengthBuffer appendData:data.data];
                return YES;
            }
            
            NSInteger appendedDataLength = _currentFrame.extraLengthCapacity - _currentFrame.extraLengthBuffer.length;
            [_currentFrame.extraLengthBuffer appendData:[data readDataOfLength:appendedDataLength]];
            
            if (_currentFrame.payloadLength == 126) {
                uint16_t payloadLength = 0;
                memcpy(&payloadLength, _currentFrame.extraLengthBuffer.bytes, sizeof(uint16_t));
                _currentFrame.payloadCapacity = (NSUInteger)CFSwapInt16BigToHost(payloadLength);
            }
            else if(_currentFrame.payloadLength == 127) {
                _currentFrame.payloadCapacity = (NSUInteger)CFSwapInt64BigToHost(*(uint64_t *)_currentFrame.extraLengthBuffer.bytes);
            }
            
            _state = WRFrameReaderStatePayload;
            return [self read:data error:error];
        }
        case WRFrameReaderStatePayload: {
            if(_currentFrame.payload.length + data.length < _currentFrame.payloadCapacity) {
                [_currentFrame.payload appendData:data.data];
                return YES;
            }
            
            NSInteger appendedDataLength = _currentFrame.payloadCapacity - _currentFrame.payload.length;
            NSData *payload = [data readDataOfLength:appendedDataLength];
            if (_currentFrame.rsv1) {
                payload = [_inflater inflateData:payload error:error];
            }
            [_currentFrame.payload appendData:payload];
            
            _framesCount++;
            [_message appendData:_currentFrame.payload];

            [self completeFrameProcessingIfNeeded];

            _state = WRFrameReaderStateHeader;
            return [self read:data error:error];
        }
    }
}

- (BOOL)readHeader:(NSData *)data error:(NSError *__autoreleasing *)error
{
    const uint8_t *headerBuffer = data.bytes;
    assert(data.length >= 2);

    _currentFrame.rsv1 = !!(headerBuffer[0] & WRRsv1Mask);
    BOOL isPerMessageDeflateEnable = _inflater != nil;
    if (_currentFrame.rsv1 && !isPerMessageDeflateEnable) {
        *error = [NSError wr_errorWithCode:2133 description: @"Server used RSV bits."];
        return NO;
    }
    
    uint8_t receivedOpcode = (WROpCodeMask & headerBuffer[0]);

    BOOL isControlFrame = (receivedOpcode == WROpCodePing || receivedOpcode == WROpCodePong || receivedOpcode == WROpCodeClose);
    
    if (!isControlFrame && receivedOpcode != 0 && _framesCount > 0) {
        *error = [NSError wr_errorWithCode:2133 description: @"All data frames after the initial data frame must have opcode 0."];
        return NO;
    }

    if (receivedOpcode == 0 && _framesCount == 0) {
        *error = [NSError wr_errorWithCode:2133 description: @"Cannot continue a message."];
        return NO;
    }

    _currentFrame.opcode = receivedOpcode == 0 ? _currentFrame.opcode : receivedOpcode;
    
    _currentFrame.fin = !!(WRFinMask & headerBuffer[0]);
    _currentFrame.masked = !!(WRMaskMask & headerBuffer[1]);
    
    if (_currentFrame.masked) {
        *error = [NSError wr_errorWithCode:2133 description: @"Client must receive unmasked data."];
        return NO;
    }
    
    _currentFrame.payloadLength = WRPayloadLenMask & headerBuffer[1];
    
    return YES;
}

- (void)completeFrameProcessingIfNeeded
{
    if (_currentFrame.fin) {
        [self notifyDelegate];
        _message = [NSMutableData new];
        [_inflater cancel];
    }

    _currentFrame = [WRFrame new];
}

- (void)notifyDelegate
{
    switch (_currentFrame.opcode) {
        case WROpCodeText:
            [_delegate frameReader:self didProcessText:[[NSString alloc] initWithData:_message encoding:NSUTF8StringEncoding]];
            break;
        case WROpCodeBinary:
            [_delegate frameReader:self didProcessData:_message];
            break;
        case WROpCodeClose:
            [_delegate frameReader:self didProcessClose:_message];
            break;
        case WROpCodePing:
            [_delegate frameReader:self didProcessPing:_message];
            break;
        case WROpCodePong:
            [_delegate frameReader:self didProcessPong:_message];
            break;
    }
}

@end
