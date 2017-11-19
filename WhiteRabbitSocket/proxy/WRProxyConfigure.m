//
//  WRProxySettingsHandler.m
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 19/11/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import "WRProxyConfigure.h"
#import "WRProxy.h"
#import "NSURL+WebSocket.h"

@implementation WRProxyConfigure {
    WRProxy *_proxy;
    NSURL *_url;
    WRProxyConfigureCompletionHandler _completionHandler;
}

- (instancetype)initWithURL:(NSURL *)url
{
    self = [super init];
    if (self != nil) {
        _url = url.copy;
    }
    return self;
}

#pragma mark - Public

- (void)getProxyWithCompletionHandler:(WRProxyConfigureCompletionHandler)completionHandler
{
    _completionHandler = completionHandler;
    _proxy = [WRProxy new];
    
    [self configureProxy];
}

#pragma mark - Private

- (void)configureProxy
{
    NSDictionary *proxySettings = CFBridgingRelease(CFNetworkCopySystemProxySettings());
    
    NSURL *httpURL = [NSURL URLWithString:_url.origin];
    
    NSArray *proxies = CFBridgingRelease(CFNetworkCopyProxiesForURL((__bridge CFURLRef)httpURL, (__bridge CFDictionaryRef)proxySettings));
    if (proxies.count == 0) {
        [self onProcessCompletion];
        return;
    }
    
    NSDictionary *settings = [proxies objectAtIndex:0];
    NSString *proxyType = settings[(NSString *)kCFProxyTypeKey];
    if ([proxyType isEqualToString:(NSString *)kCFProxyTypeAutoConfigurationURL]) {
        NSURL *pacURL = settings[(NSString *)kCFProxyAutoConfigurationURLKey];
        if (pacURL) {
            [self fetchPAC:pacURL withProxySettings:proxySettings];
            return;
        }
    }
    if ([proxyType isEqualToString:(__bridge NSString *)kCFProxyTypeAutoConfigurationJavaScript]) {
        NSString *script = settings[(__bridge NSString *)kCFProxyAutoConfigurationJavaScriptKey];
        if (script) {
            [self runPACScript:script withProxySettings:proxySettings];
            return;
        }
    }
    [self readProxySettingWithType:proxyType settings:settings];
    
    [self onProcessCompletion];
}

- (void)fetchPAC:(NSURL *)PACurl withProxySettings:(NSDictionary *)proxySettings
{
    if ([PACurl isFileURL]) {
        NSError *error = nil;
        NSString *script = [NSString stringWithContentsOfURL:PACurl usedEncoding:NULL error:&error];
        
        if (error != nil) {
            [self onProcessCompletion];
        } else {
            [self runPACScript:script withProxySettings:proxySettings];
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
            [sself runPACScript:script withProxySettings:proxySettings];
        }
    }] resume];
}

- (void)runPACScript:(NSString *)script withProxySettings:(NSDictionary *)proxySettings
{
    if (script == nil) {
        [self onProcessCompletion];
        return;
    }
    
    // From: http://developer.apple.com/samplecode/CFProxySupportTool/listing1.html
    // Work around <rdar://problem/5530166>.
    CFBridgingRelease(CFNetworkCopyProxiesForURL((__bridge CFURLRef)_url, (__bridge CFDictionaryRef)proxySettings));

    CFErrorRef err = NULL;
    NSURL *httpURL = [NSURL URLWithString:_url.origin];
    
    NSArray *proxies = CFBridgingRelease(CFNetworkCopyProxiesForAutoConfigurationScript((__bridge CFStringRef)script,(__bridge CFURLRef)httpURL, &err));
    if (err == nil && proxies.count > 0) {
        NSDictionary *settings = [proxies objectAtIndex:0];
        NSString *proxyType = settings[(NSString *)kCFProxyTypeKey];
        [self readProxySettingWithType:proxyType settings:settings];
    }
    [self onProcessCompletion];
}

- (void)readProxySettingWithType:(NSString *)proxyType settings:(NSDictionary *)settings
{
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

- (void)onProcessCompletion
{
    if (_completionHandler != nil) {
        _completionHandler(_proxy);
    }
}

@end
