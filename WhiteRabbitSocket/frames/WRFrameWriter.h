//
//  WRFrameWriter.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 06/11/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WRFrame.h"

@class WRDataDeflater;

@interface WRFrameWriter : NSObject

@property (nonatomic, strong) WRDataDeflater *deflater;

- (NSData *)buildFrameFromData:(NSData *)data opCode:(WROpCode)opCode error:(NSError **)error;

@end
