//
//  WRIteratableData.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 12/11/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WRIteratableData : NSMutableData

- (WRIteratableData *)readDataOfLength:(NSUInteger)length;

@end
