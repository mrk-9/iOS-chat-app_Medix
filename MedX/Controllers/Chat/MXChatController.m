//
//  MXChatController.m
//  MedX
//
//  Created by Anthony Zahra on 6/23/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import "MXChatController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>
#import "IQKeyboardManager.h"
#import "SVPullToRefresh.h"
#import "UIImage+fixOrientation.h"
#import "NBPhoneNumberUtil.h"
#import "MXChatCell.h"
#import "MXChatViewController.h"

#define kMinInputTextHeight                             33
#define kMaxInputTextHeight                             117
#define kMinInputBarHeight                              44
#define kMaxInputBarHeight                              128
#define kInputTextHeightOffset                          11
#define kNumberOfMessagesPerPage                        10
#define kMaxCharLength                                  500
#define kTag4MaxCharAlert                               101

@interface MXChatController () <UIAlertViewDelegate,chatCellDelegate> {
    __weak IBOutlet UITableView *messageTableView;
    
    __weak IBOutlet NSLayoutConstraint  *heightConstraint;
    __weak IBOutlet NSLayoutConstraint  *bottomConstraint;
    __weak IBOutlet IQTextView          *messageTextView;
    
    BOOL _wasKeyboardManagerEnabled;
    BOOL isDecrypting;
    BOOL isAlertShowing;
    BOOL isPageRefreshing;
    BOOL isSendingTextMessage;
    
    NSMutableArray      *messages;
    NSMutableArray      *sectionTitles;
    NSMutableDictionary *sections;

    NSDateFormatter     *dateFormatter;
    
    NSData  *attachment;
    UIImage *imageAttachment;
    UIImage *recipientImage;
    
    
    MedXUser            *currentUser;
    NBPhoneNumberUtil   *phoneUtil;
    
    int prevInputBarHeight;
}

@end

@implementation MXChatController

#pragma mark - LifeCycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.titleView = nil;
    // Do any additional setup after loading the view.

    if ( [self chatRootVC].recipient != nil ) {
        currentUser = [MedXUser CurrentUser];
        messages = [NSMutableArray array];
        sections = [NSMutableDictionary dictionary];
        sectionTitles = [NSMutableArray array];
        
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat: @"MMM dd, yyyy EEEE"];
        [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
        
        phoneUtil = [[NBPhoneNumberUtil alloc] init];
        
        [self initPage];
        [self checkRecipientInfo];
        [self registerNotifications];
    }
    
    [self chatRootVC].delegate = self;
}

- (void)viewDidLayoutSubviews {
    if ([messageTableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [messageTableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([messageTableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [messageTableView setLayoutMargins:UIEdgeInsetsZero];
    }
    
    [messageTableView.pullToRefreshView setTitle:NSLocalizedString(@"texts.pull_to_load", nil) forState:0];
    [messageTableView.pullToRefreshView setTitle:NSLocalizedString(@"texts.release_to_load", nil) forState:1];
}

- (void)viewDidAppear:(BOOL)animated {
    [[IQKeyboardManager sharedManager] setEnable:NO];
    
    [[ChatService instance] setDialogViewName:MX_DIALOG_VIEW_CHAT];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Internal notifications

- (void)registerNotifications {
    [self deregisterNotifications];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(chatDidReceiveNewDialogMessagesNotification:)
                                                 name:kNotificationChatDidReceiveNewDialogMessages
                                               object:nil];
}

- (void)deregisterNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationChatDidReceiveNewDialogMessages object:nil];
}


#pragma mark - Check Recipient's info again

- (void)checkRecipientInfo {
    // Check Recipient info while its public key was changed.
    MXUser *recipient = [self chatRootVC].recipient;
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"token"]     = [currentUser accessToken];
    params[@"user_id"]   = recipient.user_id;
    
    [self.backend accessAPIbyGET:@"users/info" Parameters:params CompletionHandler:^(NSDictionary *result, NSData *data, NSError *error) {
        NSLog(@"MXChatController > viewDidLoad - check recipient info result: %@", result);
        
        if ( !error ) {
            if ( [result[@"response"] isEqualToString:@"success"] ) {
                [MXUserUtil saveUserByInfo:result[@"user"] completion:^(NSString *user_id, NSError *error) {
                    if (!error)
                        [self chatRootVC].recipient = [MXUser MR_findFirstByAttribute:@"user_id" withValue:user_id];
                }];
            } else {
                NSLog(@"Failed to check recipient info from server: %@", result[@"status"]);
            }
            
        } else {
            NSLog(@"MXChatController > ViewDidLoad - Check recipient info - Network ERROR - %@", error.description);
        }
    }];
}


#pragma mark - UI Methods

- (void)initPage {
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    [self setRecipient];
    [self loadMessages];
    [[ChatService instance] startRegularCheck];
    
    [messageTableView addPullToRefreshWithActionHandler:^{
        isPageRefreshing = YES;
        [self loadMessages];
    }];
    
    messageTextView.placeholder = @"New Message";
    prevInputBarHeight          = 44;
}

- (void)setRecipient {
    
    MXUser *recipient = [self chatRootVC].recipient;
    recipientImage = [self chatRootVC].image;
    
    [self chatRootVC].navigationItem.title = [NSString stringWithFormat:@"%@ %@ %@",
                                                                                            recipient.salutation,
                                                                                            recipient.first_name,
                                                                                            recipient.last_name];
    [[ChatService instance] setDialogRecipientId:recipient.user_id];
}

- (void)reloadTableData {
    [messageTableView reloadData];
}

- (void)scrollBottomOfTableView:(BOOL)animated {
    if( messages.count == 0 ) return;
    
    @try {
        [messageTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:-1 + [sections[sectionTitles.lastObject] integerValue]
                                                                    inSection: sectionTitles.count - 1]
                                atScrollPosition: UITableViewScrollPositionBottom
                                        animated: animated];
    } @catch (NSException *exception) {
        NSLog(@"Exception occured: %@", exception.description);
    }
}

- (void)scrollTopOfTableView:(BOOL)animated {
    if( messages.count == 0 ) return;
    [messageTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                            atScrollPosition: UITableViewScrollPositionTop
                                    animated: animated];
}


#pragma mark - Attributes Methods

- (MXChatRootController *)chatRootVC {
    return ((MXChatRootController*)self.pageRootVC);
}


#pragma mark - Data Source Methods

- (void)loadMessages {
    [messageTableView.pullToRefreshView stopAnimating];
    
    isDecrypting = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    
        NSMutableArray *emptyStatusAppMessageIds = [NSMutableArray array];
        NSMutableArray *notMarkReadAppMessageIds = [NSMutableArray array];
        
        NSString *currentUserId = [currentUser userId];
        MXUser *recipient = [self chatRootVC].recipient;
        
        NSMutableArray *originalMessages = nil;
        NSInteger nDecryptingCount = 0;
        
        if ( [messages count] == 0 && [currentUser.userDialogs[recipient.user_id] count] > 0 ) {
            originalMessages = [NSMutableArray arrayWithArray:currentUser.userDialogs[recipient.user_id]];
            
            NSArray *messages1 = [MXMessageUtil findMessagesBetweenUser1:currentUserId andUser2:recipient.user_id LatestSentAt:originalMessages.firstObject[@"sent_at"]];
            for (MXMessage *m in messages1)
                [originalMessages insertObject:m atIndex:0];
            nDecryptingCount = [messages1 count];
            
        } else {
            NSDate *lastSentAt = nil;
            if ( [messages count] > 0 )
                lastSentAt = messages.firstObject[@"sent_at"];
            
            originalMessages = [NSMutableArray arrayWithArray:[MXMessageUtil findMessagesBetweenUser1:currentUserId
                                                                                             andUser2:recipient.user_id
                                                                                           LastSentAt:lastSentAt
                                                                                             PageSize:kNumberOfMessagesPerPage]];
            nDecryptingCount = [originalMessages count];
        }
        
        if ( nDecryptingCount > 0 )
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showProgress:NSLocalizedString(@"progress.decrypting", nil)];
            });
        
        for (id message in originalMessages) {
            NSMutableDictionary *message_info = nil;
            
            if ( [message isKindOfClass:[MXMessage class]] )
                message_info = [MXMessageUtil dictionaryWithValuesFromMessage:message];
            else
                message_info = [NSMutableDictionary dictionaryWithDictionary:message];
            
            if ( [AppUtil isEmptyObject:message_info[@"status"]] ) {
                [emptyStatusAppMessageIds addObject:message_info[@"app_message_id"]];
                message_info[@"status"] = @(MX_MESSAGE_STATUS_NOT_DELIVERED);
            }
            
            BOOL receivedMessage = [message_info[@"recipient_id"] isEqualToString:currentUserId];
            if (receivedMessage) {
                if ([AppUtil isEmptyObject:message_info[@"status"]] || [message_info[@"status"] integerValue] != MX_MESSAGE_STATUS_READ) {
                    [notMarkReadAppMessageIds addObject:message_info[@"app_message_id"]];
                    message_info[@"status"] = @(MX_MESSAGE_STATUS_READ);
                }
            }
            
            [messages insertObject:message_info atIndex:0];
            [self updateSectionWithDate:message_info[@"sent_at"] HasToInsertFirst:YES];
        }
        
        // Marks some of sent/received messages to NOT_DELIVERED/READ
        [MXMessageUtil updateMessagesInAppMessageIds:emptyStatusAppMessageIds withNewStatus:MX_MESSAGE_STATUS_NOT_DELIVERED IsOnlyForTextMessage:NO completion:^(BOOL success, NSError *error) {
            
            [MXMessageUtil updateMessagesInAppMessageIds:notMarkReadAppMessageIds withNewStatus:MX_MESSAGE_STATUS_READ IsOnlyForTextMessage:NO completion:^(BOOL success, NSError *error) {
                if (!error) {
                    currentUser.userDialogs[recipient.user_id] = [NSMutableArray arrayWithArray:[[messages reverseObjectEnumerator] allObjects]];
                    
                    [currentUser resetApplicationBadge];
                    [self markToReadOfServerMessages:messages];
                }
            }];
        }];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self reloadTableData];
            [self hideProgress];
            
            if ( !isPageRefreshing ) [self scrollBottomOfTableView:NO];
            
            isDecrypting = NO;
            isPageRefreshing = NO;
        });
    });
}

- (void)updateSectionWithDate:(NSDate *)date HasToInsertFirst:(BOOL)bInsertFirst {
    NSString *day = [dateFormatter stringFromDate:date];
    if( sections[day] )
        sections[day] = @([sections[day] integerValue] + 1);
    else {
        if ( bInsertFirst )
            [sectionTitles insertObject:day atIndex:0];
        else
            [sectionTitles addObject:day];
        sections[day] = @1;
    }
}

- (NSInteger)rowIndexForIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = 0;
    for(int i = 0; i < indexPath.section; i++)
        row += [sections[sectionTitles[i]] integerValue];
    
    return (row + indexPath.row);
}

- (id)lastTextMessageInMessages:(NSArray *)messageList {
    for (id m in [messageList reverseObjectEnumerator]) {
        NSInteger messateType = [[m valueForKey:@"type"] integerValue];
        if ( messateType == MX_MESSAGE_TYPE_TEXT )
            return m;
    }
    return nil;
}

// Mark status of new messages in server to read
- (void)markToReadOfServerMessages:(NSArray *)messageList {
    id lastTextMessage = [self lastTextMessageInMessages:messageList];
    if ( lastTextMessage ) {
        [[ChatService instance] updateReceivedMessagesStatus:[@(MX_MESSAGE_STATUS_READ) stringValue]
                                              forAppMessages:@[[lastTextMessage valueForKey:@"app_message_id"]]
                                                  completion:^(BOOL success) {
                                                  }];
    }
}

// Adds or updates data source with new message
- (void)addNewMessages:(NSArray *)newMessages {
    for (MXMessage *m in newMessages) {
        [self addNewMessage:m];
    }
    
    [[AppUtil appDelegate] vibe:nil];
    
    [currentUser resetApplicationBadge];
    
    [self markToReadOfServerMessages:newMessages];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [messageTableView reloadData];
        [self scrollBottomOfTableView:NO];
    });
}

- (void)addNewMessage:(MXMessage *)newMessage {
    
    NSUInteger dataSourceIndex = [self indexForAppMessageId:newMessage.app_message_id];
    NSMutableDictionary *new_message_info = [MXMessageUtil dictionaryWithValuesFromMessage:newMessage];
    
    if (dataSourceIndex == NSNotFound) {
        
        // Adds new message at the right place by sent_at
        if ( [messages count] > 0 ) {
            NSInteger targetIndex = NSNotFound;
            for (NSInteger i=[messages count]; i>0; i--) {
                NSDictionary *m = [messages objectAtIndex:i-1];
                if ( [newMessage.sent_at compare:m[@"sent_at"]]==NSOrderedAscending )
                    targetIndex = i-1;
                else
                    break;
            }
            if ( targetIndex == NSNotFound )
                [messages addObject:new_message_info];
            else
                [messages insertObject:new_message_info atIndex:targetIndex];
            
        } else
            [messages addObject:new_message_info];
        
        [self updateSectionWithDate:newMessage.sent_at HasToInsertFirst:NO];
        
    } else {
        [messages replaceObjectAtIndex:dataSourceIndex withObject:new_message_info];
    }
}

// Checks message index in data source by app_message_id
- (NSInteger)indexForAppMessageId:(NSString *)appMesageId {
    NSInteger count = [messages count];
    for (NSInteger i=count; i>0; i--) {
        NSDictionary *m = [messages objectAtIndex:i-1];
        if ( [m[@"app_message_id"] isEqualToString:appMesageId] ) {
            return i-1;
        }
    }
    return NSNotFound;
}


#pragma mark - TableView

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = [self rowIndexForIndexPath:indexPath];
    if( messages.count <= row ) return 50;
    
    NSDictionary *message_info = messages[row];
    CGFloat cellHeight = [MXChatCell cellHeightFromMessageInfo:message_info];
    
    return cellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 21.0f;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return sectionTitles.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [sections[sectionTitles[section]] integerValue];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, tableView.frame.size.width-40, 21)];
    
    label.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.9];
    label.text = sectionTitles[section];
    label.font = [UIFont fontWithName:@"Helvetica" size:11.0f];
    label.textColor = [UIColor grayColor];
    label.textAlignment = NSTextAlignmentCenter;
    
    return label;
}

- (NSString *)cellIDbyAppMessageId:(NSString *)app_message_id {
    return [NSString stringWithFormat:@"Cell%@", app_message_id];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger row = [self rowIndexForIndexPath:indexPath];
    if( messages.count <= row ) return [UITableViewCell new];
    
    MXChatCell *cell;
    NSMutableDictionary *message_info = messages[row];
    
    NSString *cellIdentifier = [self cellIDbyAppMessageId:message_info[@"app_message_id"]];

    cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if( !cell ) {
        cell = [[MXChatCell alloc] initWithStyle:UITableViewCellStyleDefault
                                 reuseIdentifier:cellIdentifier
                                         Message:message_info
                                    ProfileImage:recipientImage];
        cell.delegate = self;
    }
    else
        [cell setupCell:message_info];
    
    return cell;
    
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}


#pragma mark - UITextViewDelegate & Keyboard notification methods

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    BOOL b = [[textView text] length] - range.length + text.length > kMaxCharLength;
    
    if ( b && !isAlertShowing ) {
        isAlertShowing = YES;
        [self showMessage:MX_ALERT_EXCEEDING_MAX_CHARS Delegate:self Tag:kTag4MaxCharAlert];
    }
    
    return !b;
}

- (void)textViewDidChange:(UITextView *)textView {
    CGSize newSize = [textView sizeThatFits:CGSizeMake(textView.frame.size.width, MAXFLOAT)];
    
    if (![messageTextView hasText]) {
        [self updateInputBarHeight:kMinInputBarHeight];
    } else {
        int newHeight = (int)newSize.height + kInputTextHeightOffset;
        if ( newHeight != prevInputBarHeight ) {
            if ( newHeight >= kMaxInputBarHeight )
                newHeight = kMaxInputBarHeight;
            else if ( newHeight <= kMinInputBarHeight )
                newHeight = kMinInputBarHeight;
            
            [self updateInputBarHeight:newHeight];
            [self scrollTextViewToBottom:textView];
        }
    }
}

- (void)updateInputBarHeight:(int)newHeight {
    heightConstraint.constant = newHeight;
    
    [self.view setNeedsLayout];
    @try {
        [self.view layoutIfNeeded];
        prevInputBarHeight = newHeight;
    }
    @catch (NSException *e) {
        NSLog(@"%@", e.description);
    }
}

- (void)scrollTextViewToBottom:(UITextView *)textView {
    
    if ( textView.text.length > 0 ) {
        NSRange bottom = NSMakeRange(textView.text.length -1, 1);
        [textView scrollRangeToVisible:bottom];
    }
}

- (void)keyboardWillShow:(NSNotification *)note {
    // get keyboard size and loctaion
    CGRect keyboardBounds;
    [[note.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardBounds];
    NSNumber *duration = [note.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    
    // Need to translate the bounds to account for rotation.
    keyboardBounds = [self.view convertRect:keyboardBounds toView:nil];
    
    bottomConstraint.constant = keyboardBounds.size.height;
    [self.view setNeedsLayout];
    [UIView animateWithDuration:[duration floatValue] animations:^{
        @try{
            [self.view layoutIfNeeded];
        }@catch(NSException *e){
            NSLog(@"%@", e.description);
        }
    } completion:^(BOOL finished) {
        [self scrollBottomOfTableView:NO];
    }];
    
    
    [self performSelector:@selector(scrollBottomOfTableView:) withObject:nil afterDelay:0.25f];
    
}

- (void)keyboardWillHide:(NSNotification *)note {
    NSNumber *duration = [note.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *curve = [note.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    
    // get a rect for the textView frame
    
    // animations settings
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:[duration doubleValue]];
    [UIView setAnimationCurve:[curve intValue]];
    
    bottomConstraint.constant = 0;
    
    // commit animations
    [UIView commitAnimations];
}


#pragma mark - Invitation Pop-up

- (void)checkToPopupInvitation {
    MXUser *recipient = [self chatRootVC].recipient;
    if ( ![recipient hasInstalledApp] && ![recipient isVerified] ) {
        [self.view endEditing:YES];
        [self showTextInputMessage:MX_ALERT_INVITE2([recipient fullNameWithSalutation])
                          Delegate:self
                 CancelButtonTitle:NSLocalizedString(@"labels.title.skip", nil)
                     OKButtonTitle:NSLocalizedString(@"labels.title.send_sms", nil)
                      KeyboardType:UIKeyboardTypePhonePad];
    } else
        [self sendMessage];
}

- (void)doInviteByPhoneNumber:(NSString *)phoneNumber {
    [self showProgress:NSLocalizedString(@"progress.sending_invitation", nil)];
    MXUser *recipient = [self chatRootVC].recipient;
    [[MedXUser CurrentUser] inviteUser:recipient.user_id PhoneNumber:phoneNumber completion:^(BOOL success, NSString *errorMessage) {
        [self hideProgress];
        if ( success )
            [self sendMessage];
        else
            [self showMessage:errorMessage];
    }];
}


#pragma mark - Send Message

- (void)sendMessage {
    if ( isSendingTextMessage )
        [self sendTextMessage];
    else
        [self sendAttachment];
}

- (NSDictionary *)sendingMessageInfoByType:(int)message_type {
    
    MXUser *recipient = [self chatRootVC].recipient;

    NSString *sender_id = [currentUser userId];
    NSDate *sent_at = [NSDate date];
    NSString *app_message_id = [MXMessageUtil appMessageIdByUserId:sender_id datetime:sent_at];
    
    NSDictionary *data = nil;

    if (message_type == MX_MESSAGE_TYPE_TEXT) {
        data = @{
                     @"text": messageTextView.text,
                     @"sender_id": [currentUser userId],
                     @"recipient_id": recipient.user_id,
                     @"sent_at": sent_at,
                     @"app_message_id": app_message_id,
                     @"type": @(MX_MESSAGE_TYPE_TEXT)
                 };
        
    } else {
        data = @{
                     @"sender_id": sender_id,
                     @"recipient_id": recipient.user_id,
                     @"sent_at": sent_at,
                     @"app_message_id": app_message_id,
                     @"filename": [MXMessageUtil imageFileNameByAppMessageId:app_message_id],
                     @"type": @(MX_MESSAGE_TYPE_PHOTO),
                     @"width": [NSNumber numberWithInteger:[@(imageAttachment.size.width) integerValue]],
                     @"height":[NSNumber numberWithInteger:[@(imageAttachment.size.height) integerValue]],
                 };
    }
    
    return data;
}


#pragma mark - Text Message

- (IBAction)onSend:(id)sender {
    heightConstraint.constant = kMinInputBarHeight;
    if ( [AppUtil isEmptyString:messageTextView.text] ) return;
    
    isSendingTextMessage = YES;
    [self checkToPopupInvitation];
}

- (void)handleMessageDeliveredStatus:(int)message_status forAppMessageId:(NSString *)app_message_id {
    for (NSMutableDictionary *message_info in messages) {
        if ( [message_info[@"app_message_id"] isEqualToString:app_message_id] ) {
            message_info[@"status"] = @(message_status);
            break;
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [messageTableView reloadData];
        if ( message_status == MX_MESSAGE_STATUS_NOT_DELIVERED )
            [self showMessage:MX_ALERT_NETWORK_ERROR];
    });
}

- (void)sendTextMessage {
    NSDictionary *message_info = [self sendingMessageInfoByType:MX_MESSAGE_TYPE_TEXT];
    messageTextView.text = @"";
    
    [self showProgress:NSLocalizedString(@"progress.encrypting", nil)];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        [[ChatService instance] sendTextMessage:message_info localStoreCompletion:^(NSString *app_message_id, NSError *error) {
            if (app_message_id) {
                MXMessage *savedMessage = [MXMessage MR_findFirstByAttribute:@"app_message_id" withValue:app_message_id];
                
                NSMutableDictionary *new_message_info = [NSMutableDictionary dictionaryWithDictionary:message_info];
                [new_message_info setValue:savedMessage.is_encrypted forKey:@"is_encrypted"];
                [messages addObject:new_message_info];
                
                [self updateSectionWithDate:savedMessage.sent_at HasToInsertFirst:NO];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (app_message_id) {
                    [messageTableView reloadData];
                    [self scrollBottomOfTableView:NO];
                    
                    [self.view endEditing:YES];
                }
                [self hideProgress];
            });
            
        } deliverCompletion:^(NSString *app_message_id, int message_status) {
            [self handleMessageDeliveredStatus:message_status forAppMessageId:app_message_id];
        }];
    });
}


#pragma mark - Photo Message

- (IBAction)onAttachment:(id)sender {
    [self.view endEditing:YES];
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"labels.title.attach_image", nil)
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"labels.title.cancel", nil)
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:NSLocalizedString(@"labels.title.camera", nil), NSLocalizedString(@"labels.title.choose_from_gallery", nil), nil];
    
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"labels.title.cancel", nil)]) return;
    
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.mediaTypes = [[NSArray alloc] initWithObjects:(NSString*)kUTTypeImage, nil];
    imagePicker.allowsEditing = YES;
    imagePicker.delegate = self;
    
    if ( [[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"labels.title.camera", nil)] ) {
        if( [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
            imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"labels.title.tip", nil)
                                                            message:NSLocalizedString(@"alert.no_camera_device", nil)
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"labels.title.ok", nil)
                                                  otherButtonTitles:nil, nil];
            [alert show];
            return;
        }
    } else if([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"labels.title.choose_from_gallery", nil)]) {
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self presentViewController:imagePicker animated:YES completion:nil];
    }];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
        imageAttachment = [image fixOrientation];
        attachment = [MXMessageUtil attachmentByImage:imageAttachment];
        
        isSendingTextMessage = NO;
        [self checkToPopupInvitation];
    }
}

- (void)sendAttachment {
    
    NSDictionary *message_info = [self sendingMessageInfoByType:MX_MESSAGE_TYPE_PHOTO];
    
    [self showProgress:NSLocalizedString(@"progress.encrypting", nil)];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{

        [MXMessageUtil saveMessageByInfo:message_info attachment:attachment completion:^(NSString *app_message_id, NSString *sharedKeyString, NSError *error) {
            if (app_message_id) {
                MXMessage *savedMessage = [MXMessage MR_findFirstByAttribute:@"app_message_id" withValue:app_message_id];
                
                NSMutableDictionary *new_message_info = [NSMutableDictionary dictionaryWithDictionary:message_info];
                [new_message_info setValue:savedMessage.is_encrypted forKey:@"is_encrypted"];
                if (sharedKeyString)
                    [new_message_info setValue:sharedKeyString forKey:@"text"];
                [messages addObject:new_message_info];
                
                [self updateSectionWithDate:savedMessage.sent_at HasToInsertFirst:NO];
                
                [[ChatService instance] sendPhotoMessage:savedMessage completion:^(NSString *app_message_id, int message_status) {
                    if ( message_status == MX_MESSAGE_STATUS_NOT_DELIVERED ) {
                        [self handleMessageDeliveredStatus:MX_MESSAGE_STATUS_NOT_DELIVERED forAppMessageId:app_message_id];
                    }
                }];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (app_message_id) {
                    [messageTableView reloadData];
                    [self scrollBottomOfTableView:NO];
                }
                [self hideProgress];
            });
        }];
    });
}


#pragma mark - MXChatRootControllerDelegate

- (void)chatRootControllerDidClickBack {
    
    [[ChatService instance] setDialogRecipientId:nil];
    [[ChatService instance] stopRegularCheck];
}


#pragma mark - Chat Notification Methods

- (void)chatDidReceiveNewDialogMessagesNotification:(NSNotification *)notification {
    
    if( ![self.pageRootVC.navigationController respondsToSelector:@selector(isBeingPresented)] || isDecrypting ) return;
    
    NSArray *incomingsAppMessageIds = (NSArray *)notification.userInfo[@"incomings"];
    
    // Update message status with read
    NSArray *readAppMessageIds = (NSArray *)notification.userInfo[@"reads"];
    for (NSMutableDictionary *message_info in messages) {
        if ( [readAppMessageIds indexOfObject:message_info[@"app_message_id"]] != NSNotFound )
            message_info[@"status"] = @(MX_MESSAGE_STATUS_READ);
    }
    
    if ( [incomingsAppMessageIds count] > 0 || [readAppMessageIds count] > 0 ) {
        if ( [incomingsAppMessageIds count] > 0) {
            
            [MXMessageUtil updateMessagesInAppMessageIds:incomingsAppMessageIds withNewStatus:MX_MESSAGE_STATUS_READ IsOnlyForTextMessage:YES completion:^(BOOL success, NSError *error) {

                NSMutableArray *newMessages = [NSMutableArray array];
                for (NSString *app_message_id in incomingsAppMessageIds) {
                    MXMessage *message = [MXMessage MR_findFirstByAttribute:@"app_message_id" withValue:app_message_id];
                    [newMessages addObject:message];
                }
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    // Add new messages to data source
                    [self addNewMessages:newMessages];
                    
                    [self resetUserDialog];
                });
            }];
            
        } else {
            [messageTableView reloadData];
            
            [self resetUserDialog];
        }
        
        
    }
}

- (void)resetUserDialog {
    MXUser *recipient = [self chatRootVC].recipient;
    currentUser.userDialogs[recipient.user_id] = [NSMutableArray arrayWithArray:[[messages reverseObjectEnumerator] allObjects]];
}


#pragma mark - chatCellDelegate

- (void)chatCellDidUpdateMessageInfo:(NSDictionary *)message_info {
    for (NSInteger i=0; i<messages.count; i++) {
        if ( [messages[i][@"app_message_id"] isEqualToString:message_info[@"app_message_id"]] ) {
            [messages replaceObjectAtIndex:i withObject:[NSMutableDictionary dictionaryWithDictionary:message_info]];
            
            MXUser *recipient = [self chatRootVC].recipient;
            currentUser.userDialogs[recipient.user_id] = [NSMutableArray arrayWithArray:[[messages reverseObjectEnumerator] allObjects]];
            
            break;
        }
    }
}


#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ( alertView.alertViewStyle != UIAlertViewStylePlainTextInput ) {
        // Alert for characters limit
        if (alertView.tag == kTag4MaxCharAlert)
            isAlertShowing = NO;
        
    } else {
        // Invitation confirmation alert
        if ( buttonIndex == 1) {
            UITextField *textField = [alertView textFieldAtIndex:0];
            
            // Validates Phone Number
            NSError *anError = nil;
            NBPhoneNumber *myNumber = [phoneUtil parse:textField.text defaultRegion:@"AU" error:&anError];
            if( anError == nil ){
                if(![phoneUtil isValidNumber:myNumber])
                    anError = [NSError errorWithDomain:NSLocalizedString(@"labels.error.invalid_mobile_number2", nil) code:200 userInfo:nil];
            }
            if( anError )
                [self showMessage:NSLocalizedString(@"labels.error.incorrect_mobile_number", nil)];
            else
                [self doInviteByPhoneNumber:textField.text];
            
        } else
            [self sendMessage];
    }
}

@end
