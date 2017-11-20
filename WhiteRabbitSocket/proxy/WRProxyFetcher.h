//
//  WRProxyFetcher.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 19/11/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WRProxy;

@interface WRProxyFetcher: NSObject

- (instancetype)initWithURL:(NSURL *)url;
- (void)fetchProxyWithCompletionHandler:(void(^)(WRProxy *proxy))completionHandler;

@end
