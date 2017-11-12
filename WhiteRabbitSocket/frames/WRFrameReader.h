//
//  WRFrameReader.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 06/11/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WRFrameReader : NSObject

@property (nonatomic, strong) void(^onDataFrameFinish)(NSData *data);
@property (nonatomic, strong) void(^onTextFrameFinish)(NSString *text);

- (BOOL)readData:(NSData *)data error:(NSError **)error;

@end
