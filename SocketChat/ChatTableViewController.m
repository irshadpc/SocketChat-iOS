//
//  ChatTableViewController.m
//  SocketChat
//
//  Created by Manuel Menzella on 7/2/14.
//  Copyright (c) 2014 Manuel Menzella. All rights reserved.
//

#define VIEW_BKGN_COLOR     0x3582CA
#define VIEW_USER_COLOR     0x55FFFF
#define VIEW_MESSAGE_COLOR  0xDDDDDD

#define SOCKET_HOST         @"menzella.com"
#define SOCKET_PORT         3800
#define SOCKET_RECONN_DELAY 2.0f

#define CHAT_USER           @"iOS"
#define CHAT_KEY_SEND       @"send"
#define CHAT_KEY_USER       @"username"
#define CHAT_KEY_MESSAGE    @"message"


#import "ChatTableViewController.h"
#import "ChatTableViewCell.h"
#import "SocketIO.h"
#import "SocketIOPacket.h"
#import "UIColorFromHex.h"

@interface ChatTableViewController () <SocketIODelegate>

@property (nonatomic, strong) SocketIO *socketIO;
@property (nonatomic, strong) NSMutableArray *messageArray;

@end

@implementation ChatTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Set background and tint color
    self.view.backgroundColor = UIColorFromHex(VIEW_BKGN_COLOR);
    self.navigationController.navigationBar.barTintColor = UIColorFromHex(VIEW_BKGN_COLOR);
    
    // Configure tableView
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    // Initialize messageArray
    self.messageArray = [[NSMutableArray alloc] init];
    
    // Create SocketIO instance and connect
    self.socketIO = [[SocketIO alloc] initWithDelegate:self];
    [self connectToSocket];
    
    // Register for lifecycle notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}


#pragma mark - Socket / Networking

- (void)connectToSocket {
    self.title = @"Connecting...";
    [self.socketIO connectToHost:SOCKET_HOST onPort:SOCKET_PORT];
}

- (void)reconnectAfterDelay:(float)delay {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (!self.socketIO.isConnected && !self.socketIO.isConnecting) {
            [self connectToSocket];
        }
    });
}

- (void)socketIODidConnect:(SocketIO *)socket
{
    self.title = @"Connected";
}

- (void)socketIODidDisconnect:(SocketIO *)socket disconnectedWithError:(NSError *)error
{
    [self reconnectAfterDelay:SOCKET_RECONN_DELAY];
    
    NSLog(@"Socket.IO Disconnected. Error: %@", error.description);
}

- (void)socketIO:(SocketIO *)socket onError:(NSError *)error
{
    [self reconnectAfterDelay:SOCKET_RECONN_DELAY];
    
    NSLog(@"Socket.IO Error. Error: %@", error.description);
}

#pragma mark - Chat

- (void)sendMessage:(NSString *)message fromUser:(NSString *)username {
    [self.socketIO sendEvent:CHAT_KEY_SEND withData:@{CHAT_KEY_USER: username, CHAT_KEY_MESSAGE: message}];
}

- (void)socketIO:(SocketIO *)socket didReceiveEvent:(SocketIOPacket *)packet
{
    NSString *usernameString = [[packet.args objectAtIndex:0] objectForKey:CHAT_KEY_USER] ? [[packet.args objectAtIndex:0] objectForKey:CHAT_KEY_USER] : nil;
    NSString *messageString = [[packet.args objectAtIndex:0] objectForKey:CHAT_KEY_MESSAGE];
    
    unsigned long usernameLength = 0;
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] init];
    if (usernameString) {
        [attrString appendAttributedString:[[NSAttributedString alloc] initWithString:usernameString]];
        [attrString appendAttributedString:[[NSAttributedString alloc] initWithString:@":"]];
        [attrString addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]] range:NSMakeRange(0, attrString.length)];
        [attrString addAttribute:NSForegroundColorAttributeName value:UIColorFromHex(VIEW_USER_COLOR) range:NSMakeRange(0, attrString.length)];
        usernameLength = attrString.length;
        
        [attrString appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
    }
    [attrString appendAttributedString:[[NSAttributedString alloc] initWithString:messageString]];
    [attrString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:[UIFont systemFontSize]] range:NSMakeRange(usernameLength, attrString.length - usernameLength)];
    [attrString addAttribute:NSForegroundColorAttributeName value:UIColorFromHex(VIEW_MESSAGE_COLOR) range:NSMakeRange(usernameLength, attrString.length - usernameLength)];
    
    [self.messageArray addObject:attrString];
    [self.tableView reloadData];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:([self.tableView numberOfRowsInSection:0] - 1) inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

#pragma mark - TableView Data Source

- (ChatTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellIdentifier";
    ChatTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[ChatTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    cell.label.attributedText = [self.messageArray objectAtIndex:indexPath.row];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.messageArray count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [ChatTableViewCell height];
}

#pragma mark - Application Lifecycle

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    __block UIBackgroundTaskIdentifier backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [self.socketIO disconnect];
        
        [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
        backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    }];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"backgroundTimeRemaining: %.2fs", [[UIApplication sharedApplication] backgroundTimeRemaining]);
        
        [self sendMessage:@"Going down!" fromUser:CHAT_USER];
        [self.socketIO disconnect];
        
        [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
        backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    });
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [self reconnectAfterDelay:SOCKET_RECONN_DELAY];
}

@end
