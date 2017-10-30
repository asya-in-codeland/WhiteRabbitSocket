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

    UIButton *bbutton = [[UIButton alloc] initWithFrame:CGRectMake(20, 50, 100, 40)];
    bbutton.backgroundColor = [UIColor redColor];
    [bbutton addTarget:self action:@selector(onBButonTap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:bbutton];

    NSURL *handshakeTestUrl = [NSURL URLWithString:@"ws://echo.websocket.org"];
    NSURLRequest *handshakeRequest = [NSURLRequest requestWithURL:handshakeTestUrl];
    
    _webSocket = [[WRWebsocket alloc] initWithURLRequest:handshakeRequest];
    [_webSocket open];
}


- (void)onBButonTap
{
    NSError *error;
    BOOL result = [_webSocket sendMessage:@"Kek" error:&error];

    if (!result) {
        NSLog(@"error: %@", error.localizedDescription);
    }
}


@end
