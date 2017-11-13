//
//  WRReadableData.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Kononova on 13/11/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WRReadableData : NSMutableData

- (WRReadableData *)readDataOfLength:(NSUInteger)length;
- (void)seekToDataOffset:(NSInteger)offset;

@end
