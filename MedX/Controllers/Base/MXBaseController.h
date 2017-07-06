//
//  MXBaseController.h
//  MedX
//
//  Created by Anthony Zahra on 6/23/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import "BackendBase.h"
#import "MXRootViewController.h"

@interface MXBaseController : UIViewController

#pragma mark - Properties

@property BackendBase               *backend;
@property SLPagingViewController    *pageRootVC;


#pragma mark - Authentication methods

- (void)doAfterSignInWithKeyPair:(NSArray *)keyPair;


#pragma mark - Simple Alert Methods

- (void)showMessage:(NSString *)message;
- (void)showMessage:(NSString *)message Delegate:(id)delegate Tag:(int)tag;
    

#pragma mark - Confirmation Alert Methods

- (void)showConfirmMessage:(NSString *)message delegate:(id)delegate;
- (void)showConfirmMessage:(NSString *)message
                  Delegate:(id)delegate
             OKButtonTitle:(NSString *)okButtonTitle;
- (void)showTextInputMessage:(NSString *)message
                    Delegate:(id)delegate
           CancelButtonTitle:(NSString *)cancelButtonTitle
               OKButtonTitle:(NSString *)okButtonTitle
                KeyboardType:(UIKeyboardType)keyboardType;

#pragma mark - MBProgressHUD

- (void)showProgress:(NSString *)message;
- (void)hideProgress;

@end
