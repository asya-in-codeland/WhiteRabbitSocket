//
//  WRDispatching.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 17/06/2018.
//  Copyright © 2018 ASya. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WRDispatchProtocol.h"

void backgroundDispatch(id<WRDispatchProtocol> object, SEL selector, void(^dispatchableBlock)(void));
