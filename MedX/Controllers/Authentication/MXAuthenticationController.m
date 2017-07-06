//
//  MXAuthenticationController.m
//  MedX
//
//  Created by Anthony Zahra on 6/16/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import "MXAuthenticationController.h"
#import "MXAuthenticatePinVC.h"
#import "NBPhoneNumberUtil.h"

@interface MXAuthenticationController () {
    __weak IBOutlet UITextField *txtPhone;
    __weak IBOutlet UILabel *phoneErrorLabel;
    
    __weak IBOutlet UITextField *txtPassword;
    __weak IBOutlet UILabel *passwordErrorLabel;
    
    NBPhoneNumberUtil *phoneUtil;
}

@end

@implementation MXAuthenticationController

#pragma mark - Lifecycle methods

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
        
    phoneUtil = [[NBPhoneNumberUtil alloc] init];
    
    [self initUI];
}


#pragma mark - Init UI

- (void)initUI {
    [ThemeUtil initTextFields:@[txtPhone, txtPassword]];
    phoneErrorLabel.hidden = passwordErrorLabel.hidden = YES;
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ( [segue.identifier isEqualToString:@"pinAuthSegue"] ) {
        MXAuthenticatePinVC *vc = segue.destinationViewController;
        vc.mobileNumber = txtPhone.text;
    }
}

- (IBAction)prepareForUnwind:(UIStoryboardSegue *)segue {
}


#pragma mark - Validation methods

- (void)validatePhoneNumber {
    phoneErrorLabel.text = NSLocalizedString(@"labels.error.mobile_number_cannot_be_blank", nil);
    if ( [txtPhone.text isEqualToString:@""] )
        phoneErrorLabel.hidden = NO;
    else {
        phoneErrorLabel.hidden = YES;
        
        NSError *anError = nil;
        NBPhoneNumber *myNumber = [phoneUtil parse:txtPhone.text defaultRegion:@"AU" error:&anError];
        if( anError == nil ){
            if(![phoneUtil isValidNumber:myNumber])
                anError = [NSError errorWithDomain:NSLocalizedString(@"labels.error.invalid_mobile_number", nil) code:200 userInfo:nil];
        }
        
        if( anError ){
            phoneErrorLabel.text = NSLocalizedString(@"labels.error.invalid_mobile_number", nil);
            phoneErrorLabel.hidden = NO;
        }
        
        // For allowing US phone number (temporary)
        NSError *anError1 = nil;
        NBPhoneNumber *myNumber1 = [phoneUtil parse:txtPhone.text defaultRegion:@"US" error:&anError1];
        if( anError1 == nil ){
            if(![phoneUtil isValidNumber:myNumber1])
                anError1 = [NSError errorWithDomain:NSLocalizedString(@"labels.error.invalid_mobile_number", nil) code:200 userInfo:nil];
        }
        if ( !anError1 ) {
            phoneErrorLabel.hidden = YES;
        }
    }
}

- (void)validatePassword {
    passwordErrorLabel.hidden = ![txtPassword.text isEqualToString:@""];
}

- (BOOL)doValidation {
    [self validatePhoneNumber];
    [self validatePassword];
    
    return (phoneErrorLabel.hidden && passwordErrorLabel.hidden);
}


#pragma mark - Button events

- (IBAction)onSendPin:(id)sender {
    [self.view endEditing:YES];
    if ( ![self doValidation] ) return;
    
    NSDictionary *params = @{@"phone": txtPhone.text, @"password": txtPassword.text};
    [self showProgress:NSLocalizedString(@"progress.wait", nil)];
    [self.backend accessAPIbyPOST:@"auth/pin" Parameters:params CompletionHandler:^(NSDictionary *result, NSData *data, NSError *error) {
        [self hideProgress];
        if ( !error) {
            if( [result[@"response"] isEqualToString:@"success"] )
                [self performSegueWithIdentifier:@"pinAuthSegue" sender:nil];
                
            else {
                if ( [result[@"status"] isEqualToString:@"phone"] ) {
                    phoneErrorLabel.text = NSLocalizedString(@"labels.error.unregistered_mobile_number", nil);
                    phoneErrorLabel.hidden = NO;
                } else {
                    passwordErrorLabel.text = NSLocalizedString(@"labels.error.invalid_password", nil);
                    passwordErrorLabel.hidden = NO;
                }
            }
            
        } else {
            [self showMessage:MX_ALERT_NETWORK_ERROR];
        }
    }];
    
}

- (IBAction)onBtnMedxIO:(id)sender {
    [[UIApplication sharedApplication] openURL: [NSURL URLWithString:kMedXForgotURL]];
}


@end