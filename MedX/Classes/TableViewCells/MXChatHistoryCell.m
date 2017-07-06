//
//  MXChatHistoryCell.m
//  MedX
//
//  Created by Anthony Zahra on 6/23/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import "MXChatHistoryCell.h"
#import "JSQMessagesAvatarImageFactory.h"
#import "UIImage+JSQMessages.h"

static NSDateFormatter *dateFormatter;

@interface MXChatHistoryCell(){
    
    __weak IBOutlet UILabel *lblUsername;
    __weak IBOutlet UILabel *lblMessage;
    __weak IBOutlet UILabel *lblDate;
    __weak IBOutlet UIImageView *statusImageView;
    __weak IBOutlet UILabel *lblUnreadMessageCount;
    __weak IBOutlet UIImageView *avatarImageView;
}

@end

@implementation MXChatHistoryCell

- (void)awakeFromNib {
    // Initialization code
    if( !dateFormatter ) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setupCell:(id)data lastUpdated:(NSInteger)lastUpdatedTime {
    
    MedXUser *currentUser = [MedXUser CurrentUser];
    MXUser *recipient = (MXUser *)data;
    
    MXRelationship *rel = [MXRelationshipUtil findRelationshipByUserId:[currentUser userId]
                                                             PartnerId:recipient.user_id
                                                             inContext:nil];
    // First & last name
    lblUsername.text = [recipient fullName];
    if ( ![recipient hasInstalledApp] && ![recipient isVerified] ) {
        lblUsername.textColor = RGBHEX(0xDB5A76, 1.f);
    } else {
        lblUsername.textColor = [UIColor blackColor];
    }
    
    // Last message
    lblMessage.textColor    = [UIColor blackColor];
    MXMessage *lastMessage  = [MXMessageUtil findLastMessageBetweenUser1:[currentUser userId] andUser2:recipient.user_id];
    if ( lastMessage ) {
        if ( [lastMessage.type integerValue] == MX_MESSAGE_TYPE_TEXT ) {
            
            NSString *decryptedText = lastMessage.text;
            if ( [lastMessage.is_encrypted isEqualToString:@"1"] ) {
                decryptedText = [EncryptionUtil decryptLocalText:lastMessage.text];
                if ( [AppUtil isEmptyString:decryptedText] ) {
                    decryptedText = MX_MESSAGE_TEXT_SENT_FOR_DIFFERENT_DEVICE;
                    lblMessage.font = [UIFont fontWithName:@"HelveticaNeue-Italic" size:13.0];
                } else
                    lblMessage.font = [UIFont fontWithName:@"HelveticaNeue" size:13.0];
            }
            
            if ( decryptedText.length > 60 )
                lblMessage.text = [NSString stringWithFormat:@"%@", [decryptedText substringToIndex:60]];
            else
                lblMessage.text = decryptedText;
            
        } else {
            lblMessage.text = NSLocalizedString(@"labels.title.photo", nil);
        }
        
        if ( [lastMessage.status integerValue] == MX_MESSAGE_STATUS_READ )
            lblMessage.textColor = [UIColor grayColor];
        else
            lblMessage.textColor = [UIColor redColor];
        
    } else
        lblMessage.text = @"";
    
    // Unread message count
    lblUnreadMessageCount.hidden = YES;
    statusImageView.hidden = ([MXMessageUtil countOfUnreadMessageRecipient:rel.user bySender:recipient] == 0);
    
    // Last messaged time
    NSTimeInterval lastStamp = [[rel last_message_date] timeIntervalSince1970];
    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
    if ( timeStamp - lastStamp < MX_TIME_INTERVAL_DIFF_MINUTE )
        lblDate.text = [NSString stringWithFormat:@"%d secs", (int)(timeStamp - lastStamp)];
    else if ( timeStamp - lastStamp < MX_TIME_INTERVAL_DIFF_HOUR )
        lblDate.text = [NSString stringWithFormat:@"%d mins", (int)(timeStamp - lastStamp) / 60];
    else if (timeStamp - lastStamp < MX_TIME_INTERVAL_DIFF_DAY ) {
        [dateFormatter setDateFormat: @"hh:mm a"];
        lblDate.text = [dateFormatter stringFromDate:[rel last_message_date]];
    } else if ( timeStamp - lastStamp < MX_TIME_INTERVAL_DIFF_WEEK ) {
        [dateFormatter setDateFormat: @"EEE hh:mm a"];
        lblDate.text = [dateFormatter stringFromDate:[rel last_message_date]];
    } else {
        [dateFormatter setDateFormat: @"MMM dd YYYY"];
        lblDate.text = [dateFormatter stringFromDate:[rel last_message_date]];
        
        if( lastStamp != 0 ){
            lblMessage.text = NSLocalizedString(@"texts.auto_destroyed", nil);
            lblMessage.textColor = [UIColor grayColor];
        }
    }
    lblDate.textColor = [UIColor grayColor];
    
    // Avatar image
    NSString *initials = [recipient initials];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image =
        [[JSQMessagesAvatarImageFactory avatarImageWithUserInitials:initials
                                                    backgroundColor:[ThemeUtil avatarBGColorByIndex:[recipient avtarBGColorIndex]]
                                                          textColor:[UIColor whiteColor]
                                                               font:[UIFont fontWithName:@"HelveticaNeue-Bold" size:36.f]
                                                           diameter:100] avatarImage];
        dispatch_async(dispatch_get_main_queue(), ^{
            avatarImageView.image = image;
            [ThemeUtil applyRoundedBorderToImageView:avatarImageView];
        });
    });
}

@end
