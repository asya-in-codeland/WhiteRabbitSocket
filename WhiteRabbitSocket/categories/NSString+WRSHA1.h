//
//  NSString+WRSHA1.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Kononova on 17/10/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (WRSHA1)

- (NSData *)wr_SHA1;

@end

NS_ASSUME_NONNULL_END
