//
//  ViewController.m
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 10/07/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import "ViewController.h"
#import "WRWebsocket.h"

@interface ViewController ()

@end

@implementation ViewController {
    WRWebsocket *_webSocket;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSURL *handshakeTestUrl = [NSURL URLWithString:@"ws://echo.websocket.org"];
    NSURLRequest *handshakeRequest = [NSURLRequest requestWithURL:handshakeTestUrl];
    
    _webSocket = [[WRWebsocket alloc] initWithURLRequest:handshakeRequest];
    [_webSocket open];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
