//
//  WRFramePayload.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Kononova on 13/11/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WRFramePayload : NSObject

@property (nonatomic, strong, readonly) NSMutableData *data;
@property (nonatomic, assign) NSUInteger capacity;

@property (nonatomic, strong, readonly) NSMutableData *extraLengthBuffer;
@property (nonatomic, assign) NSUInteger extraLengthCapacity;

@end
