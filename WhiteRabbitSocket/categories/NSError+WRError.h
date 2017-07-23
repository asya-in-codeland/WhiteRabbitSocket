//
//  NSError+WRError.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 23/07/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSError (WRError)

+ (instancetype)errorWithCode:(NSInteger)code description:(NSString *)description;
+ (instancetype)errorWithDomain:(NSErrorDomain)domain code:(NSInteger)code description:(NSString *)description;

@end
