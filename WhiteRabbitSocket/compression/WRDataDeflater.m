//
//  WRDataDeflater.m
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 22/10/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import "WRDataDeflater.h"
#import "NSError+WRError.h"
#import <zlib.h>

@implementation WRDataDeflater {
    NSInteger _windowBits;
    NSUInteger _memoryLevel;
    uint8_t _chunkBuffer[16384];
    z_stream _stream;
    
    NSMutableData *_deflateBuffer;
}

- (instancetype)initWithWindowBits:(NSInteger)windowBits memoryLevel:(NSUInteger)memoryLevel
{
    self = [super init];
    if(self != nil) {
        _windowBits = windowBits;
        _memoryLevel = memoryLevel;
        
        NSAssert(_windowBits >= -15 && _windowBits <= -1, @"windowBits must be between -15 and -1");
        NSAssert(_memoryLevel >= 1 && _memoryLevel <= 9, @"memory level must be between 1 and 9");
        
        bzero(&_stream, sizeof(_stream));
        bzero(_chunkBuffer, sizeof(_chunkBuffer));
    }
    return self;
}

- (void)dealloc
{
    [self reset];
}

#pragma mark - Public

- (BOOL)deflateBytes:(const void *)bytes length:(NSUInteger)length error:(NSError *__autoreleasing *)outError {
    NSParameterAssert(length);
    
    [self deflateBufferLazyInitializationWithError:outError];
    
    _stream.avail_in = (uInt)length;
    _stream.next_in = (Bytef *)bytes;
    
    do {
        _stream.avail_out = (uInt)sizeof(_chunkBuffer);
        _stream.next_out = (Bytef *)_chunkBuffer;
        
        deflate(&_stream, Z_SYNC_FLUSH);
        
        uInt gotBack = sizeof(_chunkBuffer) - _stream.avail_out;
        if(gotBack > 0) {
            [_deflateBuffer appendBytes:_chunkBuffer length:gotBack];
        }
    } while(_stream.avail_out == 0);
    
    return YES;
}

- (void)reset
{
    if(_deflateBuffer != nil) {
        _deflateBuffer = nil;
        deflateEnd(&_stream);
        bzero(&_stream, sizeof(_stream));
        bzero(_chunkBuffer, sizeof(_chunkBuffer));
    }
}

- (BOOL)completeDeflate:(NSError *__autoreleasing *)outError
{
    if(_deflateBuffer.length > 4) {
        _deflateBuffer.length -= 4;
    } else {
        _deflateBuffer.length = 0;
    }
    return YES;
}

#pragma mark - Private

- (void)deflateBufferLazyInitializationWithError:(NSError *__autoreleasing *)outError
{
    if (_deflateBuffer == nil) {
        if(deflateInit2(&_stream, Z_DEFAULT_COMPRESSION, Z_DEFLATED, _windowBits, _memoryLevel, Z_FIXED) != Z_OK) {
            *outError = [NSError errorWithCode:4321 description:@"Failed to initialize deflate stream"];
            return;
        }
        
        _deflateBuffer = [NSMutableData data];
    }
}

@end
