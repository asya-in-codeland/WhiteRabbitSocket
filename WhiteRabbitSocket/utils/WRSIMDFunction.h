//
//  WRSIMDFunction.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Kononova on 23/10/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WRSIMDFunction : NSObject

+ (void)maskBytes:(uint8_t *)bytes length:(size_t)length withKey:(uint8_t *)maskKey;

@end
