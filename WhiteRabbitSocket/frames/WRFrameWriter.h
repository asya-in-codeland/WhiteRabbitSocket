//
//  WRFrameWriter.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 06/11/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WRFrame.h"

NS_ASSUME_NONNULL_BEGIN

@class WRDataDeflater;

@interface WRFrameWriter : NSObject
@property (nonatomic, strong, nullable) WRDataDeflater *deflater;
- (NSData *)buildFrameFromData:(NSData *)data opCode:(WROpCode)opCode error:(NSError * __autoreleasing  _Nullable *_Nullable)error;
@end

NS_ASSUME_NONNULL_END
