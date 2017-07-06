//
//  MXChatViewController.m
//  MedX
//
//  Created by Anthony Zahra on 6/23/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import "MXChatViewController.h"
#import "MXChatRootController.h"
#import "SVPullToRefresh.h"
#import "MXChatHistoryCell.h"

@interface MXChatViewController ()<UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, UIAlertViewDelegate> {
    
    __weak IBOutlet UIView *lblNomore;
    __weak IBOutlet UITableView *dialogsTableView;
    
    MedXUser *currentUser;
    NSInteger deletingRow;
    
    int nFailedCount;
}

@property (nonatomic, strong) NSMutableArray *recipients;

@property (nonatomic, strong) UIImageView* titleView;
@property NSInteger lastUpdatedTime;

@end

@implementation MXChatViewController

#pragma mark - LifeCycle

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self){
        [self setNavigationBar];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if( currentUser == nil ){
        currentUser = [MedXUser CurrentUser];
        
        [self setNavigationBar];
        [self initializeTableView];
        [self loadDataSource:NO];
        [[ChatService instance] checkAllDialogs:nil];
        [self registerNotifications];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    if( [self.recipients count] > 0 ) {
        [dialogsTableView reloadData];
    }
    [[ChatService instance] setDialogViewName:MX_DIALOG_VIEW_INDEX];
}


#pragma mark - Internal notifications

- (void)registerNotifications {
    [self deregisterNotifications];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(chatDidReceiveNewMessagesNotification:)
                                                 name:kNotificationChatDidReceiveNewMessages
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(chatDidFailInCheckAllDialogsNotification:)
                                                 name:kNotificationChatDidFailInCheckAllDialogs
                                               object:nil];
}

- (void)deregisterNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationChatDidReceiveNewMessages object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationChatDidFailInCheckAllDialogs object:nil];
}

#pragma mark - UI Methods

- (void)setNavigationBar {
    UIImage *logo = [UIImage imageNamed:@"chat"];
    logo = [logo imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _titleView = [[UIImageView alloc] initWithImage:logo];
    self.navigationItem.titleView = self.titleView;
}

- (void)initializeTableView {
    nFailedCount = 0;
    
    [dialogsTableView addPullToRefreshWithActionHandler:^{
        [self loadDataSource:YES];
        [[ChatService instance] checkAllDialogs:nil];
    }];
    
    UILongPressGestureRecognizer *gestureRecognizer = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handleLongPress:)];
    gestureRecognizer.minimumPressDuration = 1.0; //seconds
    gestureRecognizer.delegate = self;
    [dialogsTableView addGestureRecognizer:gestureRecognizer];
    
    [ThemeUtil removeSeparatorForEmptyCellInTableView:dialogsTableView];
}

- (void)stopAnimating {
    [dialogsTableView.pullToRefreshView stopAnimating];
}


#pragma mark - Data Source Methods

- (void)loadDataSource:(BOOL)load_more {
    
    [MXMessageUtil deleteOldMessagesForUserId:[currentUser userId] completion:^(BOOL success, NSError *error) {
        self.recipients   = [NSMutableArray array];
        NSArray *partners = [MXRelationshipUtil findPartnersByUserId:[currentUser userId]];
        [self.recipients addObjectsFromArray:partners];
        
        self.lastUpdatedTime = [[NSDate date] timeIntervalSince1970];
        lblNomore.hidden     = [self.recipients count] > 0;
        
        [currentUser resetApplicationBadge];
    }];
}


#pragma mark - UITableViewDelegate & UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return [self.recipients count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MXChatHistoryCell *cell = (MXChatHistoryCell*)[tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    [cell setupCell: self.recipients[indexPath.row] lastUpdated:self.lastUpdatedTime];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UINavigationController *chatNavController = (UINavigationController*)[self.storyboard instantiateViewControllerWithIdentifier:@"chatRootController"];
    MXChatRootController *chatRootController = (MXChatRootController*)chatNavController.viewControllers[0];
    
    MXUser *recipient = (MXUser *)self.recipients[indexPath.row];
    
    chatRootController.recipient = recipient;
    chatRootController.pageIndex = 0;
    
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:chatNavController animated:YES completion:nil];
}


#pragma mark - Long Pressure Gesture & Delete Conversation Methods

- (void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    CGPoint p = [gestureRecognizer locationInView:dialogsTableView];
    
    NSIndexPath *indexPath = [dialogsTableView indexPathForRowAtPoint:p];
    if ( indexPath && gestureRecognizer.state == UIGestureRecognizerStateBegan ) {
        deletingRow = indexPath.row;
        MXUser *deletingUser = _recipients[deletingRow];
        NSString *deletingUserName = [deletingUser fullNameWithSalutation];
        [self showConfirmMessage:MX_ALERT_DELETE_CHAT(deletingUserName) Delegate:self OKButtonTitle:@"Delete"];
    }
}

- (void)doDeleteConversation {
    MXUser *deletingUser = _recipients[deletingRow];
    
    [MXMessageUtil deleteConversationBetweenUser1:[currentUser userId] User2:deletingUser.user_id completion:^(BOOL success, NSError *error) {
        if ( !error ) {
            [MedXUser CurrentUser].userDialogs[deletingUser.user_id] = [NSMutableArray array];
            
            [_recipients removeObjectAtIndex:deletingRow];
            NSIndexPath *deletingIndexPath = [NSIndexPath indexPathForRow:deletingRow inSection:0];
            [dialogsTableView deleteRowsAtIndexPaths:@[deletingIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            
        } else {
            [self showMessage:NSLocalizedString(@"alert.error_on_deletion", nil)];
        }
    }];
}


#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch(buttonIndex) {
        case 0:
            break;
        case 1:
            [self doDeleteConversation];
            break;
    }
}


#pragma mark - Chat Notification Methods

- (void)chatDidReceiveNewMessagesNotification:(NSNotification *)notification {
    
    if( ![self.pageRootVC.navigationController respondsToSelector:@selector(isBeingPresented)] ) return;
    
    [self stopAnimating];
    
    NSArray *incomingsAppMessageIds = (NSArray *)notification.userInfo[@"incomings"];
    NSArray *readAppMessageIds = (NSArray *)notification.userInfo[@"reads"];
    
    if ( [incomingsAppMessageIds count] > 0 || [readAppMessageIds count] > 0 ) {
        [self loadDataSource:YES];
        [dialogsTableView reloadData];
    }
}

- (void)chatDidFailInCheckAllDialogsNotification:(NSNotification *)notification {
    [self stopAnimating];

    if (nFailedCount++ > 0 && ![ChatService instance].dialogRecipientId)
        [self showMessage:MX_ALERT_NETWORK_ERROR];
}

@end
