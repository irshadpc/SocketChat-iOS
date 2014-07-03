//
//  ChatLogicMessage.h
//  SocketChat
//
//  Created by Manuel Menzella on 7/2/14.
//  Copyright (c) 2014 Manuel Menzella. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ChatLogicMessage : NSObject

@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *message;

+ (ChatLogicMessage *)chatLogicMessageWithUsername:(NSString *)username andMessage:(NSString *)message;

@end
