//
//  NSString+WRSHA1.m
//  WhiteRabbitSocket
//
//  Created by Anastasia Kononova on 17/10/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import "NSString+WRSHA1.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (WRSHA1)

- (NSData *)wr_SHA1
{
    size_t length = [self lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    uint8_t outputLength = CC_SHA1_DIGEST_LENGTH;
    unsigned char output[outputLength];
    CC_SHA1(self.UTF8String, (CC_LONG)length, output);

    return [NSData dataWithBytes:output length:outputLength];
}

@end
