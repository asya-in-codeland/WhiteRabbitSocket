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
    BOOL _noContextTakeover;
    // TODO: зачем нужен _chunkBuffer? может его стоит перенести в метод
    uint8_t _chunkBuffer[16384];
    z_stream _stream;
}

- (instancetype)initWithWindowBits:(NSInteger)windowBits noContextTakeover:(BOOL)noContextTakeover
{
    NSAssert(windowBits >= 1 && windowBits <= 15, @"windowBits must be between 1 and 15");
    
    self = [super init];
    if(self != nil) {
        _windowBits = -windowBits;
        _noContextTakeover = noContextTakeover;

        [self buildInflateBufferWithError:nil];
    }
    return self;
}

- (void)dealloc
{
    [self reset];
}

#pragma mark - Actions

- (NSData *)inflateData:(NSData *)data error:(NSError *__autoreleasing *)outError
{
    NSParameterAssert(data != nil);

    _stream.avail_in = (uInt)data.length;
    _stream.next_in = (Bytef *)data.bytes;

    NSMutableData *inflatedBuffer = [NSMutableData data];
    int ret;
    do {
        _stream.avail_out = (uInt)sizeof(_chunkBuffer);
        _stream.next_out = (Bytef *)_chunkBuffer;
        
        ret = inflate(&_stream, Z_SYNC_FLUSH);
        if(ret == Z_NEED_DICT || ret == Z_DATA_ERROR || ret == Z_MEM_ERROR) {
            *outError = [NSError wr_errorWithCode:4321 description:@"Failed to inflate bytes"];
            return nil;
        }
        
        uInt gotBack = sizeof(_chunkBuffer) - _stream.avail_out;
        if(gotBack > 0) {
            [inflatedBuffer appendBytes:_chunkBuffer length:gotBack];
        }
    } while(_stream.avail_out == 0);

    //TODO: надо ли добавлять {0x00, 0x00, 0xff, 0xff} в конце фрейма или сообщения? СОВПАДЕНИЕ?!!! НЕ ДУМАЮ!!!
    return inflatedBuffer;
}

- (void)cancel
{
    if (_noContextTakeover) {
        [self reset];
        [self buildInflateBufferWithError:nil];
    }
}

#pragma mark - Private

- (void)buildInflateBufferWithError:(NSError *__autoreleasing *)outError
{
    if(inflateInit2(&_stream, _windowBits) != Z_OK) {
        *outError = [NSError wr_errorWithCode:4321 description:@"Failed to initialize inflate stream"];
    }
}

- (void)reset
{
    inflateEnd(&_stream);
    bzero(&_stream, sizeof(_stream));
    bzero(_chunkBuffer, sizeof(_chunkBuffer));
}

@end
