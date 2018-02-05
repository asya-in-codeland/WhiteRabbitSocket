//
//  WRDataDeflater.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 22/10/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WRDataDeflater : NSObject

- (instancetype)initWithWindowBits:(NSInteger)windowBits memoryLevel:(NSUInteger)memoryLevel noContextTakeover:(BOOL)noContextTakeover;

- (NSData *)deflateData:(NSData *)data error:(NSError *__autoreleasing *)outError;

@end
