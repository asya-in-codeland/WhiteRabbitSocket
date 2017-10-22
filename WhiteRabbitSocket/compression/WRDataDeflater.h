//
//  WRDataDeflater.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 22/10/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WRDataDeflater : NSObject

- (instancetype)initWithWindowBits:(NSInteger)windowBits memoryLevel:(NSUInteger)memoryLevel;

- (BOOL)deflateBytes:(const void *)bytes length:(NSUInteger)length error:(NSError *__autoreleasing *)outError;
- (BOOL)completeDeflate:(NSError *__autoreleasing *)outError;

- (void)reset;

@end
