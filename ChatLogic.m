//
//  ChatLogic.m
//  SocketChat
//
//  Created by Manuel Menzella on 7/2/14.
//  Copyright (c) 2014 Manuel Menzella. All rights reserved.
//

#define SOCKET_HOST         @"menzella.com"
#define SOCKET_PORT         3800
#define SOCKET_CONN_DELAY   0.8f

#define CHAT_KEY_SEND       @"send"
#define CHAT_KEY_USER       @"username"
#define CHAT_KEY_MESSAGE    @"message"

#define CHAT_USER           @"iOS"
#define CHAT_DISCONN_STRING @"Going down..."

#import "ChatLogic.h"
#import "SocketIO.h"
#import "SocketIOPacket.h"

@interface ChatLogic () <SocketIODelegate>

@property (nonatomic, strong) SocketIO *socketIO;

@end

@implementation ChatLogic

- (id)init {
    if (self = [super init]) {
        
        // Initialize messageArray
        self.messageArray = [[NSMutableArray alloc] init];
        
        // Create SocketIO instance and connect
        self.socketIO = [[SocketIO alloc] initWithDelegate:self];
        [self connectAfterDelay:SOCKET_CONN_DELAY];
        
        // Register for lifecycle notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        
    }
    return self;
}

- (id)initWithDelegate:(NSObject<ChatLogicDelegate> *)delegate {
    if (self = [self init]) {
        self.delegate = delegate;
    }
    return self;
}

#pragma mark - Socket / Networking

- (void)connectToSocket {
    [self.socketIO connectToHost:SOCKET_HOST onPort:SOCKET_PORT];
    
    if ( [self.delegate respondsToSelector:@selector(chatLogicDidBeginConnecting:)] ) {
        [self.delegate chatLogicDidBeginConnecting:self];
    }
}

- (void)connectAfterDelay:(float)delay {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (!self.socketIO.isConnected && !self.socketIO.isConnecting) {
            [self connectToSocket];
        }
    });
}

#pragma mark - SocketIO Delegate Methods

- (void)socketIODidConnect:(SocketIO *)socket
{
    if ( [self.delegate respondsToSelector:@selector(chatLogicDidConnect:)] ) {
        [self.delegate chatLogicDidConnect:self];
    }
}

- (void)socketIODidDisconnect:(SocketIO *)socket disconnectedWithError:(NSError *)error
{
    [self connectAfterDelay:SOCKET_CONN_DELAY];
    
    if ( [self.delegate respondsToSelector:@selector(chatLogicDidDisconnect:withError:)] ) {
        [self.delegate chatLogicDidDisconnect:self withError:error];
    }
    
    NSLog(@"Socket.IO Disconnected. Error: %@", error.description);
}

- (void)socketIO:(SocketIO *)socket onError:(NSError *)error
{
    [self connectAfterDelay:SOCKET_CONN_DELAY];
    
    if ( [self.delegate respondsToSelector:@selector(chatLogicDidDisconnect:withError:)] ) {
        [self.delegate chatLogicDidDisconnect:self withError:error];
    }
    
    NSLog(@"Socket.IO Error. Error: %@", error.description);
}

#pragma mark - Chat

- (void)sendMessage:(ChatLogicMessage *)chatLogicMessage {
    [self.socketIO sendEvent:CHAT_KEY_SEND withData:@{CHAT_KEY_USER: chatLogicMessage.username, CHAT_KEY_MESSAGE: chatLogicMessage.message}];
}

- (void)socketIO:(SocketIO *)socket didReceiveEvent:(SocketIOPacket *)packet
{
    NSString *usernameString = [[packet.args objectAtIndex:0] objectForKey:CHAT_KEY_USER] ? [[packet.args objectAtIndex:0] objectForKey:CHAT_KEY_USER] : nil;
    NSString *messageString = [[packet.args objectAtIndex:0] objectForKey:CHAT_KEY_MESSAGE];
    
    ChatLogicMessage *chatLogicMessage = [ChatLogicMessage chatLogicMessageWithUsername:usernameString andMessage:messageString];
    [self.messageArray addObject:chatLogicMessage];
    
    if ( [self.delegate respondsToSelector:@selector(chatLogic:didReceiveMessage:)] ) {
        [self.delegate chatLogic:self didReceiveMessage:chatLogicMessage];
    }
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
        
        [self sendMessage:[ChatLogicMessage chatLogicMessageWithUsername:CHAT_USER andMessage:CHAT_DISCONN_STRING]];
        [self.socketIO disconnect];
        
        [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
        backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    });
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [self connectAfterDelay:SOCKET_CONN_DELAY];
}


@end
