//
//  MXChatCell.h
//  MedX
//
//  Created by Anthony Zahra on 6/23/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol chatCellDelegate <NSObject>

- (void)chatCellDidUpdateMessageInfo:(NSDictionary *)message_info;

@end

@interface MXChatCell : UITableViewCell

#pragma mark - Properties

@property UIImage* profileImage;
@property NSMutableDictionary *messageInfo;
@property (strong, nonatomic) id<chatCellDelegate> delegate;


#pragma mark - Cell configuration methods

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier
            Message:(NSDictionary *)message_info
       ProfileImage:(UIImage*)image;

- (void)setupCell:(NSDictionary *)message_info;


#pragma mark - Measurement methods

+ (CGFloat)cellHeightFromMessageInfo:(NSDictionary *)message_info;

@end
