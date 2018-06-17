//
//  WRDataInflater.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 22/10/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WRDataInflater : NSObject

- (instancetype)initWithWindowBits:(NSInteger)windowBits noContextTakeover:(BOOL)noContextTakeover;

- (NSData *)inflateData:(NSData *)data error:(NSError * __autoreleasing  _Nullable *_Nullable)outError;
- (void)cancel;

@end

NS_ASSUME_NONNULL_END
