//
//  WRDataInflater.m
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 22/10/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import "WRDataInflater.h"
#import "NSError+WRError.h"
#import <zlib.h>

@implementation WRDataInflater {
    NSInteger _windowBits;
    uint8_t _chunkBuffer[16384];
    z_stream _stream;
    
    NSMutableData *_inflateBuffer;
}

- (void)dealloc
{
    [self reset];
}

- (instancetype)initWithWindowBits:(NSInteger)windowBits
{
    self = [super init];
    if(self != nil) {
        _windowBits = windowBits;
    }
    return self;
}

#pragma mark - Actions

- (BOOL)inflateBytes:(const void *)bytes length:(NSUInteger)length error:(NSError *__autoreleasing *)outError {
    NSParameterAssert(length);
    
    _stream.avail_in = (uInt)length;
    _stream.next_in = (Bytef *)bytes;
    
    int ret;
    do {
        _stream.avail_out = (uInt)sizeof(_chunkBuffer);
        _stream.next_out = (Bytef *)_chunkBuffer;
        
        ret = inflate(&_stream, Z_SYNC_FLUSH);
        if(ret == Z_NEED_DICT || ret == Z_DATA_ERROR || ret == Z_MEM_ERROR) {
            *outError = [NSError errorWithCode:4321 description:@"Failed to inflate bytes"];
            return NO;
        }
        
        uInt gotBack = sizeof(_chunkBuffer) - _stream.avail_out;
        if(gotBack > 0) {
            [_inflateBuffer appendBytes:_chunkBuffer length:gotBack];
        }
    } while(_stream.avail_out == 0);
    
    return YES;
}

- (BOOL)completeInflate:(NSError *__autoreleasing *)outError
{
    uint8_t finish[4] = {0x00, 0x00, 0xff, 0xff};
    return [self inflateBytes:finish length:sizeof(finish) error:outError];
}

- (void)reset
{
    if(_inflateBuffer != nil) {
        _inflateBuffer = nil;
        inflateEnd(&_stream);
        bzero(&_stream, sizeof(_stream));
        bzero(_chunkBuffer, sizeof(_chunkBuffer));
    }
}

#pragma mark - Private

- (void)inflateBufferLazyInitializationWithError:(NSError *__autoreleasing *)outError
{
    if (_inflateBuffer == nil) {
        if(inflateInit2(&_stream, -MAX_WBITS) != Z_OK) {
            *outError = [NSError errorWithCode:4321 description:@"Failed to initialize inflate stream"];
            return;
        }
        
        _inflateBuffer = [NSMutableData data];
    }
}

@end
