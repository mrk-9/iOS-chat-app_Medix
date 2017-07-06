//
//  MXDirectoryProfileVC.m
//  MedX
//
//  Created by Ping Ahn on 10/7/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import "MXDirectoryProfileVC.h"
#import "MXChatRootController.h"

@interface MXDirectoryProfileVC () <UIAlertViewDelegate, MXChatRootControllerDelegate> {
    __weak IBOutlet UILabel     *lblSpecialty;
    __weak IBOutlet UILabel     *lblAbout;
    __weak IBOutlet UILabel     *lblLocations;
    __weak IBOutlet UIButton    *btnBlock;
    __weak IBOutlet UIView      *viewFooter;
    
    __weak IBOutlet NSLayoutConstraint *descriptionHeightConstraint;
    __weak IBOutlet NSLayoutConstraint *locationHeightConstraints;
    __weak IBOutlet NSLayoutConstraint *contentHeightConstraint;
    __weak IBOutlet NSLayoutConstraint *scrollviewBottomLayoutMarign;
    
    MXUser            *user;
    NBPhoneNumberUtil *phoneUtil;
}

@end

@implementation MXDirectoryProfileVC

#pragma mark - Lifecycle methods

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    user = [MXUser MR_findFirstByAttribute:@"user_id" withValue:self.user_id];
    [self setupUI];
    
    phoneUtil = [[NBPhoneNumberUtil alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - UI methods

- (void)setupNavigationItems {
    UIBarButtonItem *backBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"btnCancel"] style:UIBarButtonItemStylePlain target:self action:@selector(onBtnBack:)];
    backBarButton.tintColor = RGBHEX(0xFFFFFF, 1.f);
    self.navigationItem.leftBarButtonItem = backBarButton;
}

- (void)setupUI {
    [self setupNavigationItems];
    self.navigationItem.title = [user fullNameWithSalutation];
    
    lblSpecialty.text = user.specialty;
    lblAbout.text     = user.about;
    
    if ([AppUtil isEmptyString:user.about]) {
        lblAbout.text = NSLocalizedString(@"texts.no_info", nil);
        lblAbout.textColor = [UIColor grayColor];
    }
    
    CGFloat footerMargin = -44;
    if ( [user hasInstalledApp] || [user isVerified] ) {
        viewFooter.hidden = YES;
        footerMargin = 0;
        scrollviewBottomLayoutMarign.constant = 0;
    }
    
    BOOL isBlocked = [[MedXUser CurrentUser] isBlockingUserId:user.user_id];
    [self setupBlockButtonTitleByState:isBlocked];
    
    // Locations views
    NSMutableString *locations = [[NSMutableString alloc] init];
    NSMutableArray  *locationList;
    
    if ( [AppUtil isNotEmptyString:user.locations] ) {
        locationList = [AppUtil getObjectFromJSONString:user.locations];
        for (NSString *location in locationList) {
            [locations appendString:[MXUserUtil refineOfficePhoneNumberInLocation:location]];
            [locations appendString:@"\n\n"];
        }
        lblLocations.text = locations;
    } else {
        locationList = [NSMutableArray array];
        lblLocations.text = NSLocalizedString(@"texts.no_info", nil);
        lblLocations.textColor = [UIColor grayColor];
    }
    
    CGSize size = [lblAbout sizeThatFits:CGSizeMake(lblAbout.bounds.size.width, MAXFLOAT)];
    if ( size.height + 20 > lblAbout.bounds.size.height ) {
        descriptionHeightConstraint.constant = size.height + 20;
    }
    
    size = [lblLocations sizeThatFits:CGSizeMake(lblLocations.bounds.size.width, MAXFLOAT)];
    if ( size.height + 20 > lblLocations.bounds.size.height ) {
        locationHeightConstraints.constant = size.height + 20;
    }
    
    contentHeightConstraint.constant = MAX(descriptionHeightConstraint.constant+
                                           locationHeightConstraints.constant+140+footerMargin,
                                           self.view.bounds.size.height-66+footerMargin);
    [self.view layoutIfNeeded];
}

- (void)setupBlockButtonTitleByState:(BOOL)isBlocked {
    if ( !isBlocked )
        [btnBlock setTitle:NSLocalizedString(@"labels.title.block_user", nil) forState:UIControlStateNormal];
    else
        [btnBlock setTitle:NSLocalizedString(@"labels.title.unblock_user", nil) forState:UIControlStateNormal];
}


#pragma mark - Block methods

- (void)doBlock {
    BOOL isBlock = ![[MedXUser CurrentUser] isBlockingUserId:self.user_id];
    
    [self showProgress:NSLocalizedString(@"progress.updating", nil)];
    [[MedXUser CurrentUser] blockOrUnblockUserById:self.user_id isBlock:isBlock completion:^(BOOL success, NSString *errorStatus) {
        [self hideProgress];
        if ( success )
            [self setupBlockButtonTitleByState:isBlock];
        else
            [self showMessage:NSLocalizedString(@"alert.could_not_be_done_try_later", nil)];
    }];
}


#pragma mark - Button events methods

- (void)onBtnBack:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onBlockUser:(id)sender {
    if ( ![[MedXUser CurrentUser] isBlockingUserId:self.user_id] )
        [self showConfirmMessage:MX_ALERT_BLOCK delegate:self];
    else
        [self doBlock];
}

- (IBAction)onChatUser:(id)sender {
    UINavigationController *chatNavController = (UINavigationController*)[self.storyboard instantiateViewControllerWithIdentifier:@"chatRootController"];
    MXChatRootController *chatRootController = (MXChatRootController*)chatNavController.viewControllers[0];
    chatRootController.recipient = [MXUser MR_findFirstByAttribute:@"user_id" withValue:self.user_id];
    chatRootController.pageIndex = 0;
    chatRootController.delegate2 = self;
    [self presentViewController:chatNavController animated:YES completion:nil];
}


#pragma mark - MXChatRootControllerDelegate

- (void)chatRootControllerDidClickBack {
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    // Block confirmation alert
    if ( buttonIndex == 1 )
        [self doBlock];
}

@end
