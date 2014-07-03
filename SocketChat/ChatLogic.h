//
//  ChatLogic.h
//  SocketChat
//
//  Created by Manuel Menzella on 7/2/14.
//  Copyright (c) 2014 Manuel Menzella. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChatLogicMessage.h"

@protocol ChatLogicDelegate;

@interface ChatLogic : NSObject

- (ChatLogic *)initWithDelegate:(id<ChatLogicDelegate>)delegate;

- (void)connectToChat;
- (void)disconnectFromChat;

- (void)sendMessage:(ChatLogicMessage *)message;

@property (nonatomic, strong) NSMutableArray *messageArray;
@property (nonatomic, assign) NSObject<ChatLogicDelegate> *delegate;

@end

@protocol ChatLogicDelegate
@optional

- (void)chatLogicDidBeginConnecting:(ChatLogic *)chatLogic;
- (void)chatLogicDidConnect:(ChatLogic *)chatLogic;
- (void)chatLogicDidDisconnect:(ChatLogic *)chatLogic withError:(NSError *)error;
- (void)chatLogic:(ChatLogic *)chatLogic didReceiveMessage:(ChatLogicMessage *)message;

@end