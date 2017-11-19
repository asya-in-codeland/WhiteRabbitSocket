//
//  WRProxySettingsHandler.h
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 19/11/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WRProxy;

typedef void(^WRProxyConfigureCompletionHandler)(WRProxy *proxy);

@interface WRProxyConfigure: NSObject

- (instancetype)initWithURL:(NSURL *)url;

- (void)getProxyWithCompletionHandler:(WRProxyConfigureCompletionHandler)completionHandler;

@end
