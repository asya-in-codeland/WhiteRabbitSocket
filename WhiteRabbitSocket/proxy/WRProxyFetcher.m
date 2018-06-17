//
//  WRProxyFetcher.m
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 19/11/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import "WRProxyFetcher.h"
#import "WRProxy.h"
#import "NSURL+WRWebSocket.h"

@implementation WRProxyFetcher {
    NSURL *_url;
    WRProxy *_proxy;
    void(^_completionHandler)(WRProxy *proxy);
}

- (instancetype)initWithURL:(NSURL *)url {
    self = [super init];
    if (self != nil) {
        _url = url.copy;
    }
    return self;
}

#pragma mark - Public

- (void)fetchProxyWithCompletionHandler:(void(^)(WRProxy *proxy))completionHandler {
    _completionHandler = completionHandler;
    [self fetchProxy];
}

#pragma mark - Private

- (void)fetchProxy {
    NSDictionary *proxySettings = CFBridgingRelease(CFNetworkCopySystemProxySettings());
    
    NSURL *httpURL = [NSURL URLWithString:_url.wr_origin];
    
    NSArray *proxies = CFBridgingRelease(CFNetworkCopyProxiesForURL((__bridge CFURLRef)httpURL, (__bridge CFDictionaryRef)proxySettings));
    if (proxies.count == 0) {
        [self onProcessCompletion];
        return;
    }
    
    NSDictionary *settings = proxies[0];
    NSString *proxyType = settings[(NSString *)kCFProxyTypeKey];
    if ([proxyType isEqualToString:(NSString *)kCFProxyTypeAutoConfigurationURL]) {
        NSURL *pacURL = settings[(NSString *)kCFProxyAutoConfigurationURLKey];
        if (pacURL != nil) {
            [self fetchPACURL:pacURL settings:proxySettings];
            return;
        }
    }
    if ([proxyType isEqualToString:(__bridge NSString *)kCFProxyTypeAutoConfigurationJavaScript]) {
        NSString *script = settings[(__bridge NSString *)kCFProxyAutoConfigurationJavaScriptKey];
        if (script) {
            [self performPACScript:script settings:proxySettings];
            return;
        }
    }
    [self buildProxyWithType:proxyType settings:settings];
    
    [self onProcessCompletion];
}

- (void)fetchPACURL:(NSURL *)PACurl settings:(NSDictionary *)settings {
    if ([PACurl isFileURL]) {
        NSError *error = nil;
        NSString *script = [NSString stringWithContentsOfURL:PACurl usedEncoding:NULL error:&error];
        
        if (error != nil) {
            [self onProcessCompletion];
        } else {
            [self performPACScript:script settings:settings];
        }
        return;
    }
    
    NSString *scheme = [PACurl.scheme lowercaseString];
    if (![scheme isEqualToString:@"http"] && ![scheme isEqualToString:@"https"]) {
        [self onProcessCompletion];
        return;
    }
    
    __weak typeof(self) wself = self;
    NSURLRequest *request = [NSURLRequest requestWithURL:PACurl];
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        __strong typeof(wself) sself = wself;
        if (sself == nil) return;
        
        if (error != nil) {
            [self onProcessCompletion];
        } else {
            NSString *script = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            [sself performPACScript:script settings:settings];
        }
    }] resume];
}

- (void)performPACScript:(NSString *)script settings:(NSDictionary *)proxySettings {
    if (script == nil) {
        [self onProcessCompletion];
        return;
    }
    
    // From: http://developer.apple.com/samplecode/CFProxySupportTool/listing1.html
    // Work around <rdar://problem/5530166>.
    CFBridgingRelease(CFNetworkCopyProxiesForURL((__bridge CFURLRef)_url, (__bridge CFDictionaryRef)proxySettings));

    CFErrorRef err = NULL;
    NSURL *httpURL = [NSURL URLWithString:_url.wr_origin];
    
    NSArray *proxies = CFBridgingRelease(CFNetworkCopyProxiesForAutoConfigurationScript((__bridge CFStringRef)script,(__bridge CFURLRef)httpURL, &err));
    if (err == nil && proxies.count > 0) {
        NSDictionary *settings = [proxies objectAtIndex:0];
        NSString *proxyType = settings[(NSString *)kCFProxyTypeKey];
        [self buildProxyWithType:proxyType settings:settings];
    }

    [self onProcessCompletion];
}

- (void)buildProxyWithType:(NSString *)proxyType settings:(NSDictionary *)settings {
    if ([proxyType isEqualToString:(NSString *)kCFProxyTypeHTTP] ||
        [proxyType isEqualToString:(NSString *)kCFProxyTypeHTTPS]) {
        NSString *host = settings[(NSString *)kCFProxyHostNameKey];
        NSInteger port = [settings[(NSString *)kCFProxyPortNumberKey] integerValue];
        _proxy = [WRProxy httpProxyWithHost:host port:port];
    }
    
    if ([proxyType isEqualToString:(NSString *)kCFProxyTypeSOCKS]) {
        NSString *host = settings[(NSString *)kCFProxyHostNameKey];
        NSInteger port = [settings[(NSString *)kCFProxyPortNumberKey] integerValue];
        NSString *username = settings[(NSString *)kCFProxyUsernameKey];
        NSString *password = settings[(NSString *)kCFProxyPasswordKey];
        _proxy = [WRProxy socksProxyWithHost:host port:port username:username password:password];
    }
}

- (void)onProcessCompletion {
    if (_completionHandler != nil) {
        _completionHandler(_proxy);
    }
}

@end
