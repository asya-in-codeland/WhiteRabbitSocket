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

    BOOL _noContextTakeover;
}

- (instancetype)initWithWindowBits:(NSInteger)windowBits memoryLevel:(NSUInteger)memoryLevel noContextTakeover:(BOOL)noContextTakeover {
    NSAssert(windowBits >= 1 && windowBits <= 15, @"windowBits must be between 1 and 15");
    NSAssert(memoryLevel >= 1 && memoryLevel <= 9, @"memory level must be between 1 and 9");
    
    self = [super init];
    if(self != nil) {
        _windowBits = -windowBits;
        _memoryLevel = memoryLevel;
        _noContextTakeover = noContextTakeover;
        
        bzero(&_stream, sizeof(_stream));
        bzero(_chunkBuffer, sizeof(_chunkBuffer));

        [self buildDeflaterWithError:nil];
    }
    return self;
}

- (void)dealloc {
    [self reset];
}

#pragma mark - Public

- (NSData *)deflateData:(NSData *)data error:(NSError *__autoreleasing *)outError {
    NSParameterAssert(data != nil);
    
    if(_noContextTakeover && ![self buildDeflaterWithError:outError]) {
        return nil;
    }
    
    _stream.avail_in = (uInt)data.length;
    _stream.next_in = (Bytef *)data.bytes;

    NSMutableData *deflatedBuffer = [NSMutableData data];

    do {
        _stream.avail_out = (uInt)sizeof(_chunkBuffer);
        _stream.next_out = (Bytef *)_chunkBuffer;
        
        deflate(&_stream, Z_SYNC_FLUSH);
        
        uInt gotBack = sizeof(_chunkBuffer) - _stream.avail_out;
        if(gotBack > 0) {
            [deflatedBuffer appendBytes:_chunkBuffer length:gotBack];
        }
    } while(_stream.avail_out == 0);

    if(_noContextTakeover) {
        [self reset];
    }

    return deflatedBuffer;
}

#pragma mark - Private

- (BOOL)buildDeflaterWithError:(NSError *__autoreleasing *)outError {
    if(deflateInit2(&_stream, Z_DEFAULT_COMPRESSION, Z_DEFLATED, _windowBits, _memoryLevel, Z_FIXED) != Z_OK) {
        [NSError wr_assignInoutError:outError withCode:WRStatusCodeInternalError description:@"Failed to initialize deflate stream"];
        return NO;
    }
    return YES;
}

- (void)reset {
    deflateEnd(&_stream);
    bzero(&_stream, sizeof(_stream));
    bzero(_chunkBuffer, sizeof(_chunkBuffer));
}

@end
