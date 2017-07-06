//
//  MXChatRootController.m
//  MedX
//
//  Created by Anthony Zahra on 6/23/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import "MXChatRootController.h"
#import "TransitionDelegate.h"
#import "BackendBase.h"
#import "MXChatController.h"
#import "MBProgressHUD.h"
#import "IQKeyboardManager.h"
#import "MXRootViewController.h"
#import "MXChatViewController.h"

@interface MXChatRootController () {
    TransitionDelegate *transitionController;
    MedXUser* currentUser;
    BackendBase *backend;
    NSInteger originalPageIndex;
}

@end

@implementation MXChatRootController

#pragma mark - LifeCycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    self.navigationSideItemsStyle = SLNavigationSideItemsStyleDefault;
    self.navigationBarView.hidden = NO;
    
    [self addPageControls:self.pageIndex];
    [self setCurrentIndex:self.pageIndex animated:NO];
    [self setScrollEnabled: NO];
    
    transitionController = [[TransitionDelegate alloc] init];
    originalPageIndex = _pageIndex;
    currentUser = [MedXUser CurrentUser];
    backend = [BackendBase sharedConnection];
    
    [self setNavigationItems];
}

- (void)setNavigationItems {
    if (self.pageIndex == 0) {
        [self.navigationItem.leftBarButtonItem setImage:[UIImage imageNamed:@"btnCancel"]];
        [self.navigationItem.rightBarButtonItem setImage:[UIImage imageNamed:@"info"]];
    } else {
        [self.navigationItem.leftBarButtonItem setImage:[UIImage imageNamed:@"backArrow"]];
        [self.navigationItem.rightBarButtonItem setImage:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Button Events

- (IBAction)onBack:(id)sender {
    if( originalPageIndex != self.pageIndex ) {
        self.pageIndex = (self.pageIndex + 1) % 2;
        [self setCurrentIndex:self.pageIndex animated:YES];
        [self setNavigationItems];
    } else {
        [[IQKeyboardManager sharedManager] setEnable:YES];
        
        UINavigationController* rootVC = (UINavigationController*)[UIApplication sharedApplication].keyWindow.rootViewController;
        MXRootViewController *rootController = (MXRootViewController*)[rootVC.viewControllers objectAtIndex:0];
        MXChatViewController *chatHistoryController = (MXChatViewController*)rootController.controllerReferences[1];
        [chatHistoryController loadDataSource: NO];

        if ( self.delegate ) [self.delegate chatRootControllerDidClickBack];
        if ( self.delegate2 )
            [self.delegate2 chatRootControllerDidClickBack];
        else
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)onMenu:(id)sender {
    self.pageIndex = (originalPageIndex + 1) % 2;
    [self setCurrentIndex:self.pageIndex animated:YES];
    
    [self setNavigationItems];
}

@end
