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
@property (nonatomic, strong, readonly, nullable) dispatch_queue_t delegateDispatchQueue;
@property (nonatomic, strong, readonly, nullable) NSOperationQueue *delegateOperationQueue;
@end
