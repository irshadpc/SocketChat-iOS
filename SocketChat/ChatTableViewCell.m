//
//  ChatTableViewCell.m
//  SocketChat
//
//  Created by Manuel Menzella on 7/2/14.
//  Copyright (c) 2014 Manuel Menzella. All rights reserved.
//

#define CELL_HEIGHT    20.0f
#define CELL_PADDING_X 8.0f
#define CELL_PADDING_Y 2.0f

#import "ChatTableViewCell.h"

@implementation ChatTableViewCell

+ (float)height { return CELL_HEIGHT; }

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.label = [[UILabel alloc] init];
        [self.contentView addSubview:self.label];
    }
    return self;
}

- (void)layoutSubviews
{
    self.label.frame = CGRectMake(CELL_PADDING_X, CELL_PADDING_Y,
                                  self.contentView.bounds.size.width - 2 * CELL_PADDING_X, [ChatTableViewCell height] - 2 * CELL_PADDING_Y);
}

@end
