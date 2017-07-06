//
//  MXChatProfileViewController.m
//  MedX
//
//  Created by Anthony Zahra on 6/23/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import "MXChatProfileViewController.h"
#import "MXChatRootController.h"

@interface MXChatProfileViewController () <UIAlertViewDelegate> {
    
    __weak IBOutlet UILabel     *lblSpecialty;
    __weak IBOutlet UILabel     *lblAbout;
    __weak IBOutlet UILabel     *lblLocations;
    __weak IBOutlet UILabel     *lblNotInstalled;
    __weak IBOutlet UIButton    *btnBlock;
    __weak IBOutlet UIView      *viewFooter;
    
    __weak IBOutlet NSLayoutConstraint *descriptionHeightConstraint;
    __weak IBOutlet NSLayoutConstraint *locationHeightConstraints;
    __weak IBOutlet NSLayoutConstraint *contentHeightConstraint;
    __weak IBOutlet NSLayoutConstraint *scrollviewBottomLayoutMarign;
    
    MXChatRootController* rootVC;
}

@end

@implementation MXChatProfileViewController

#pragma mark - Lifecycle methods

- (void)viewDidLoad {
    //[super viewDidAppear:animated];
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UINavigationController *navController = (UINavigationController*)[UIApplication sharedApplication].keyWindow.rootViewController;
    MXChatRootController *rootController = (MXChatRootController*)navController.visibleViewController;
    
    if( rootController.recipient != nil && rootVC == nil ){
        rootVC = rootController;
        [self setupUI];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - UI methods

- (void)setupUI {
    MXUser *user = [MXUser MR_findFirstByAttribute:@"user_id" withValue:rootVC.recipient.user_id];
    
    lblSpecialty.text = user.specialty;
    lblAbout.text     = user.about;

    if ([AppUtil isEmptyString:user.about]) {
        lblAbout.text = NSLocalizedString(@"texts.no_info", nil);
        lblAbout.textColor = [UIColor grayColor];
    }

    CGFloat footerMargin = -44;
    if ( [user hasInstalledApp] || [user isVerified] ) {
        viewFooter.hidden = YES;
        footerMargin=0;
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
    if( size.height + 20 > lblAbout.bounds.size.height ){
        descriptionHeightConstraint.constant = size.height + 20;
    }
    
    size = [lblLocations sizeThatFits:CGSizeMake(lblLocations.bounds.size.width, MAXFLOAT)];
    if( size.height + 20 > lblLocations.bounds.size.height ){
        locationHeightConstraints.constant = size.height + 20;
    }
    
    contentHeightConstraint.constant = MAX(descriptionHeightConstraint.constant+
                                           locationHeightConstraints.constant+30+
                                           lblNotInstalled.frame.size.height+footerMargin,
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
    NSString *user_id = rootVC.recipient.user_id;
    BOOL isBlock = ![[MedXUser CurrentUser] isBlockingUserId:user_id];
    
    [self showProgress:NSLocalizedString(@"progress.updating", nil)];
    [[MedXUser CurrentUser] blockOrUnblockUserById:user_id isBlock:isBlock completion:^(BOOL success, NSString *errorStatus) {
        [self hideProgress];
        if ( success )
            [self setupBlockButtonTitleByState:isBlock];
        else
            [self showMessage:NSLocalizedString(@"alert.could_not_be_done_try_later", nil)];
    }];
}


#pragma mark - Button events methods

- (IBAction)onBlockUser:(id)sender {
    if ( ![[MedXUser CurrentUser] isBlockingUserId:rootVC.recipient.user_id] )
        [self showConfirmMessage:MX_ALERT_BLOCK delegate:self];
    else
        [self doBlock];
}


#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch(buttonIndex) {
        case 0:
            break;
        case 1:
            [self doBlock];
            break;
    }
}

@end
