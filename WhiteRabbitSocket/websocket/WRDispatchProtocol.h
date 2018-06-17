//
//  WRDispatchProtocol.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 17/06/2018.
//  Copyright © 2018 ASya. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol WRDispatchProtocol <NSObject>
@optional
@property (nonatomic, strong, readonly) dispatch_queue_t dispatchQueue;
@property (nonatomic, strong, readonly) NSOperationQueue *operationQueue;
@end
