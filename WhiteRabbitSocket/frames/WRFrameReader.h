//
//  WRFrameReader.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 06/11/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WRDataInflater;
@protocol WRFrameReaderDelegate;

@interface WRFrameReader : NSObject

@property (nonatomic, weak) id<WRFrameReaderDelegate> delegate;
@property (nonatomic, strong) WRDataInflater *inflater;

- (BOOL)readData:(NSData *)data error:(NSError **)error;

@end

@protocol WRFrameReaderDelegate<NSObject>
- (void)frameReader:(WRFrameReader *)reader didProcessText:(NSString *)text;
- (void)frameReader:(WRFrameReader *)reader didProcessData:(NSData *)data;
- (void)frameReader:(WRFrameReader *)reader didProcessPing:(NSData *)data;
- (void)frameReader:(WRFrameReader *)reader didProcessPong:(NSData *)data;
- (void)frameReader:(WRFrameReader *)reader didProcessClose:(NSData *)data;
@end
