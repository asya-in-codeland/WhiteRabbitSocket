//
//  WRDataInflater.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 22/10/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WRDataInflater : NSObject

- (instancetype)initWithWindowBits:(NSInteger)windowBits noContextTakeover:(BOOL)noContextTakeover;

- (NSData *)inflateData:(NSData *)data error:(NSError *__autoreleasing *)outError;
- (void)cancel;

@end
