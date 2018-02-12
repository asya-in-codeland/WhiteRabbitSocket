//
//  ViewController.m
//  WhiteRabbitSocket
//
//  Created by Anastasia Sviridenko on 10/07/2017.
//  Copyright © 2017 ASya. All rights reserved.
//

#import "ViewController.h"
#import "WRWebsocket.h"
#import "WRWebsocketDelegate.h"

@interface ViewController () <WRWebsocketDelegate>

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

    NSURL *handshakeTestUrl = [NSURL URLWithString:@"ws://172.20.10.6:8080"];
    NSURLRequest *handshakeRequest = [NSURLRequest requestWithURL:handshakeTestUrl];
    
    _webSocket = [[WRWebsocket alloc] initWithURLRequest:handshakeRequest];
    _webSocket.enabledPerMessageDeflate = YES;
    _webSocket.delegate = self;
    [_webSocket open];
}


- (void)onBButonTap
{

    NSError *error;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Message" ofType:@"txt"];
    NSString *text = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];

    NSLog(@"send message length: %lu", (unsigned long)text.length);

    BOOL result = [_webSocket sendMessage:@"От улыбки станет всем светлей, от улыбки в небе радуга проснётся, поделись улыбкою своей, и она к тебе не раз ещё вернётся. И тогда, наверняка, вдруг запляшут облакааааа" error:&error];

    if (!result) {
        NSLog(@"error: %@", error.localizedDescription);
    }

//    [_webSocket sendPing:nil error:nil];
}

#pragma mark - WRWebsocketDelegate


- (void)websocket:(nonnull WRWebsocket *)websocket didFailWithError:(nonnull NSError *)error {
    NSLog(@"WRWebsocket didFailWithError: %@", error.localizedDescription);
}

- (void)websocket:(nonnull WRWebsocket *)websocket didReceiveData:(nonnull NSData *)data {
    NSLog(@"WRWebsocket didReceiveData: %@", [[NSString alloc] initWithData:data encoding:kCFStringEncodingUTF8]);
}

- (void)websocket:(nonnull WRWebsocket *)websocket didReceiveMessage:(nonnull NSString *)message {
    NSLog(@"WRWebsocket didReceiveMessage: %@", message);
}

- (void)webSocket:(nonnull WRWebsocket *)webSocket didCloseWithData:(nullable NSData *)data
{
    NSLog(@"WRWebsocket didCloseWithData");
}
@end
