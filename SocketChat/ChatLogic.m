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

#import "ChatLogic.h"
#import "SocketIO.h"
#import "SocketIOPacket.h"

@interface ChatLogic () <SocketIODelegate>

@property (nonatomic) BOOL shouldReconnectAutomatically;
@property (nonatomic, strong) SocketIO *socketIO;

@end

@implementation ChatLogic

- (ChatLogic *)initWithDelegate:(NSObject<ChatLogicDelegate> *)delegate {
    if (self = [super init]) {
        
        // Set delegate
        self.delegate = delegate;
        
        // Initialize messageArray
        self.messageArray = [[NSMutableArray alloc] init];
        
        // Create SocketIO instance and connect
        self.socketIO = [[SocketIO alloc] initWithDelegate:self];
        [self connectToSocket];
        
        // Configure automatic reconnection
        self.shouldReconnectAutomatically = YES;
        
    }
    return self;
}

- (ChatLogic *)init {
    return [self initWithDelegate:nil];
}

#pragma mark - ChatLogic Connection Interface

- (void)connectToChat {
    self.shouldReconnectAutomatically = YES;
    [self connectToSocket];
}

- (void)disconnectFromChat {
    self.shouldReconnectAutomatically = NO;
    [self disconnectFromSocket];
}

#pragma mark - Socket / Networking

- (void)connectToSocket {
    [self.socketIO connectToHost:SOCKET_HOST onPort:SOCKET_PORT];
    
    if ( [self.delegate respondsToSelector:@selector(chatLogicDidBeginConnecting:)] ) {
        [self.delegate chatLogicDidBeginConnecting:self];
    }
}

- (void)connectToSocketAfterDelay:(float)delay {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (!self.socketIO.isConnected && !self.socketIO.isConnecting) {
            [self connectToSocket];
        }
    });
}

- (void)disconnectFromSocket {
    [self.socketIO disconnect];
}

- (void)handleSocketDisconnectionWithError:(NSError *)error {
    if (self.shouldReconnectAutomatically) [self connectToSocketAfterDelay:SOCKET_CONN_DELAY];
    
    if ( [self.delegate respondsToSelector:@selector(chatLogicDidDisconnect:withError:)] ) {
        [self.delegate chatLogicDidDisconnect:self withError:error];
    }
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
    [self handleSocketDisconnectionWithError:error];
    NSLog(@"Socket.IO Disconnected. Error: %@", error.description);
}

- (void)socketIO:(SocketIO *)socket onError:(NSError *)error
{
    [self handleSocketDisconnectionWithError:error];
    NSLog(@"Socket.IO Error. Error: %@", error.description);
}

#pragma mark - Chat

- (void)sendMessage:(ChatLogicMessage *)chatLogicMessage {
    NSMutableDictionary *dataDictionary = [[NSMutableDictionary alloc] init];
    if (chatLogicMessage.username) [dataDictionary addEntriesFromDictionary:@{CHAT_KEY_USER: chatLogicMessage.username}];
    if (chatLogicMessage.message) [dataDictionary addEntriesFromDictionary:@{CHAT_KEY_MESSAGE: chatLogicMessage.message}];
    [self.socketIO sendEvent:CHAT_KEY_SEND withData:dataDictionary];
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

@end
