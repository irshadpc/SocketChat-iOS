//
//  ChatLogicMessage.m
//  SocketChat
//
//  Created by Manuel Menzella on 7/2/14.
//  Copyright (c) 2014 Manuel Menzella. All rights reserved.
//

#import "ChatLogicMessage.h"

@implementation ChatLogicMessage

+ (ChatLogicMessage *)chatLogicMessageWithUsername:(NSString *)username andMessage:(NSString *)message {
    ChatLogicMessage *chatLogicMessage = [[ChatLogicMessage alloc] init];
    if (chatLogicMessage) {
        chatLogicMessage.username = username;
        chatLogicMessage.message = message;
    }
    return chatLogicMessage;
}

@end
