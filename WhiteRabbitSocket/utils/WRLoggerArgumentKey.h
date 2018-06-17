//
//  WRLoggerArgumentKey.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 17/06/2018.
//  Copyright © 2018 ASya. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WRLoggerArgumentKey : NSObject<NSCopying>
@property (class, nonatomic, copy, readonly) WRLoggerArgumentKey *websocketRequest;
@property (class, nonatomic, copy, readonly) WRLoggerArgumentKey *readDataLength;
@end
