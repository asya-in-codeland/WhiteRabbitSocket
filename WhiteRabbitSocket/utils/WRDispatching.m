//
//  WRDispatching.m
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 17/06/2018.
//  Copyright © 2018 ASya. All rights reserved.
//

#import "WRDispatching.h"

void backgroundDispatch(id<WRDispatchProtocol> object, SEL selector, void(^dispatchableBlock)(void)) {
    if (![object respondsToSelector:selector]) { return; }
    
    if (object.operationQueue != nil) {
        [object.operationQueue addOperationWithBlock:dispatchableBlock];
        return;
    }
    if (object.dispatchQueue != nil) {
        dispatch_async(object.dispatchQueue, dispatchableBlock);
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), dispatchableBlock);
}
