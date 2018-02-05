//
//  WRHandshakePreferences.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Kononova on 05/02/2018.
//  Copyright © 2018 ASya. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WRHandshakePreferences : NSObject

@property (nonatomic, assign, readonly) NSUInteger maxWindowBits;
@property (nonatomic, assign, readonly) BOOL noContextTakeover;

@end
