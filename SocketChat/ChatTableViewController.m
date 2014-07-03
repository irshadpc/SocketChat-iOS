//
//  ChatTableViewController.m
//  SocketChat
//
//  Created by Manuel Menzella on 7/2/14.
//  Copyright (c) 2014 Manuel Menzella. All rights reserved.
//

#define CHAT_USER           @"iOS"
#define CHAT_EXIT_STRING    @"Going down..."

#define VIEW_BKGN_COLOR     0x3582CA
#define VIEW_USER_COLOR     0x55FFFF
#define VIEW_MESSAGE_COLOR  0xDDDDDD


#import "ChatTableViewController.h"
#import "ChatTableViewCell.h"
#import "UIColorFromHex.h"
#import "ChatLogic.h"

@interface ChatTableViewController () <ChatLogicDelegate>
@property (nonatomic, strong) ChatLogic *chatLogic;
@end

@implementation ChatTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Instantiate self.chatLogic
    self.chatLogic = [[ChatLogic alloc] initWithDelegate:self];
    
    // Set background and tint color
    self.view.backgroundColor = UIColorFromHex(VIEW_BKGN_COLOR);
    self.navigationController.navigationBar.barTintColor = UIColorFromHex(VIEW_BKGN_COLOR);
    
    // Configure tableView
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    // Register for lifecycle notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

#pragma mark - ChatLogic Delegate Methods

- (void)chatLogicDidBeginConnecting:(ChatLogic *)chatLogic
{
    self.title = @"Connecting...";
}

- (void)chatLogicDidConnect:(ChatLogic *)chatLogic
{
    self.title = @"Connected";
}

- (void)chatLogicDidDisconnect:(ChatLogic *)chatLogic withError:(NSError *)error
{
    self.title = @"Disconnected";
}

- (void)chatLogic:(ChatLogic *)chatLogic didReceiveMessage:(ChatLogicMessage *)message
{
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
    
    ChatLogicMessage *chatLogicMessage = [self.chatLogic.messageArray objectAtIndex:indexPath.row];
    cell.label.attributedText = [self attributedStringForChatLogicMessage:chatLogicMessage];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.chatLogic.messageArray count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [ChatTableViewCell height];
}

#pragma mark - Message Attributed String

- (NSAttributedString *)attributedStringForChatLogicMessage:(ChatLogicMessage *)chatLogicMessage
{
    unsigned long usernameLength = 0;
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] init];
    if (chatLogicMessage.username) {
        [attrString appendAttributedString:[[NSAttributedString alloc] initWithString:chatLogicMessage.username]];
        [attrString appendAttributedString:[[NSAttributedString alloc] initWithString:@":"]];
        [attrString addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]] range:NSMakeRange(0, attrString.length)];
        [attrString addAttribute:NSForegroundColorAttributeName value:UIColorFromHex(VIEW_USER_COLOR) range:NSMakeRange(0, attrString.length)];
        usernameLength = attrString.length;
        
        [attrString appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
    }
    [attrString appendAttributedString:[[NSAttributedString alloc] initWithString:chatLogicMessage.message]];
    [attrString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:[UIFont systemFontSize]] range:NSMakeRange(usernameLength, attrString.length - usernameLength)];
    [attrString addAttribute:NSForegroundColorAttributeName value:UIColorFromHex(VIEW_MESSAGE_COLOR) range:NSMakeRange(usernameLength, attrString.length - usernameLength)];
    
    return attrString;
}

#pragma mark - Application Lifecycle

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [self.chatLogic connectToChat];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    __block UIBackgroundTaskIdentifier backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [self.chatLogic disconnectFromChat];
        
        [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
        backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    }];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"backgroundTimeRemaining: %.2fs", [[UIApplication sharedApplication] backgroundTimeRemaining]);
        
        [self.chatLogic sendMessage:[ChatLogicMessage chatLogicMessageWithUsername:CHAT_USER andMessage:CHAT_EXIT_STRING]];
        [self.chatLogic disconnectFromChat];
        
        [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
        backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    });
}

@end
