//
//  WRReadableData.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Kononova on 13/11/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WRReadableData : NSObject

@property (nonatomic, assign, readonly) NSUInteger length;
@property (nonatomic, copy, readonly) NSData *data;

- (instancetype)initWithData:(NSData *)data;

- (NSData *)readDataOfLength:(NSUInteger)length;
- (void)seekToDataOffset:(NSInteger)offset;

@end

NS_ASSUME_NONNULL_END
