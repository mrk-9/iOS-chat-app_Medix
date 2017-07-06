//
//  MXBaseController.m
//  MedX
//
//  Created by Anthony Zahra on 6/23/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import "MXBaseController.h"
#import <MBProgressHUD/MBProgressHud.h>

@interface MXBaseController ()

@end

@implementation MXBaseController

#pragma mark - Lifecycle methods

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
     _backend = [BackendBase sharedConnection];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAddedToSLPages:) name:@"AddSLPages" object:nil];
}

- (void)onAddedToSLPages:(NSNotification*)notification {
    
    if ( notification.userInfo[@"controller"] && _pageRootVC == nil ) {
        _pageRootVC = notification.userInfo[@"controller"];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Authentication methods

- (void)doAfterSignInWithKeyPair:(NSArray *)keyPair {
    [MXUserUtil updateUserDefaults:nil withUserInfo:[MedXUser CurrentUser].info LastLogin:[NSDate date]];
    
    if ( keyPair ) {
        [MXUserUtil updateUserDefaults:nil withEncryptionKeys:keyPair];
        [[MedXUser CurrentUser] setupKeys];
    }
    
    AppDelegate *app = [AppUtil appDelegate];
    [app registerForRemoteNotifications];
    app.window.rootViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"rootViewController"];
}


#pragma mark - Simple Alert Methods

- (void)showMessage:(NSString *)message {
    UIAlertView *msgView = [[UIAlertView alloc] initWithTitle:@"" message:message delegate:nil
                                            cancelButtonTitle:NSLocalizedString(@"labels.title.ok", nil)
                                            otherButtonTitles:nil, nil];
    [msgView show];
}

- (void)showMessage:(NSString *)message Delegate:(id)delegate Tag:(int)tag {
    UIAlertView *msgView = [[UIAlertView alloc] initWithTitle:@""
                                                      message:message
                                                     delegate:delegate
                                            cancelButtonTitle:NSLocalizedString(@"labels.title.ok", nil)
                                            otherButtonTitles:nil, nil];
    msgView.tag = tag;
    [msgView show];
}


#pragma mark - Confirmation Alert Methods

- (void)showConfirmMessage:(NSString *)message delegate:(id)delegate {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                    message:message
                                                   delegate:delegate
                                          cancelButtonTitle:NSLocalizedString(@"labels.title.cancel", nil)
                                          otherButtonTitles:NSLocalizedString(@"labels.title.block", nil), nil];
    [alert show];
}

- (void)showConfirmMessage:(NSString *)message Delegate:(id)delegate OKButtonTitle:(NSString *)okButtonTitle {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                    message:message
                                                   delegate:delegate
                                          cancelButtonTitle:NSLocalizedString(@"labels.title.cancel", nil)
                                          otherButtonTitles:okButtonTitle, nil];
    [alert show];
}

- (void)showTextInputMessage:(NSString *)message Delegate:(id)delegate CancelButtonTitle:(NSString *)cancelButtonTitle OKButtonTitle:(NSString *)okButtonTitle KeyboardType:(UIKeyboardType)keyboardType {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                    message:message
                                                   delegate:delegate
                                          cancelButtonTitle:cancelButtonTitle
                                          otherButtonTitles:okButtonTitle, nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert textFieldAtIndex:0].keyboardType = keyboardType;
    [alert show];
}

#pragma mark - MBProgressHUD

- (void)showProgress:(NSString *)message {
    [SVProgressHUD setBackgroundColor:RGBHEX(0x000, 0.8f)];
    [SVProgressHUD setForegroundColor:[UIColor whiteColor]];
    [SVProgressHUD showWithStatus:message maskType:SVProgressHUDMaskTypeClear];
}

- (void)hideProgress {
    [SVProgressHUD dismiss];
}

@end
