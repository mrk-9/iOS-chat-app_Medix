//
//  MXRegisterController.m
//  MedX
//
//  Created by Anthony Zahra on 6/15/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import "MXRegisterController.h"
#import "AppDelegate.h"
#import "NBPhoneNumberUtil.h"
#import "MXSpecialtyPicker.h"
#import "MXSalutationPicker.h"
#import "IQUIView+IQKeyboardToolbar.h"

#define MX_MIN_PASSWORD_LENGTH 6

@interface MXRegisterController () <UITextFieldDelegate>{
    __weak IBOutlet UILabel *notificationLabel;
    __weak IBOutlet UILabel *warningLabel;
    
    __weak IBOutlet UITextField *txtSalutation;
    
    __weak IBOutlet UITextField *txtUserName;
    __weak IBOutlet UILabel *usernameErrorLabel;
    
    __weak IBOutlet UITextField *txtMobileNumber;
    __weak IBOutlet UILabel *mobilenumberErrorLabel;
    __weak IBOutlet UILabel *lblMobilePlaceholder;
    
    __weak IBOutlet UITextField *txtPassword;
    __weak IBOutlet UILabel *passwordErrorLabel;
    __weak IBOutlet UILabel *lblPasswordPlaceholder;
    
    __weak IBOutlet UITextField *txtConfirmPassword;
    __weak IBOutlet UILabel *confirmPasswordErrorLabel;
    
    __weak IBOutlet UILabel *lblSpecialty;
    __weak IBOutlet UILabel *lblName;
    
    __weak IBOutlet UIScrollView *scrollView;
 
    MXSalutationPicker *salutationPicker;
    
    NBPhoneNumberUtil *phoneUtil;
}

@end

@implementation MXRegisterController

#pragma mark - Lifecycle methods

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    phoneUtil = [[NBPhoneNumberUtil alloc] init];
    
    [self setupPage];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - UI methods

- (void)setupPage {
    txtSalutation.text = _userInfo[@"salutation"];
    lblName.text       = _userInfo[@"last_name"];
    txtUserName.text   = _userInfo[@"preferred_first_name"];
    lblSpecialty.text  = _userInfo[@"specialty"];
    
    usernameErrorLabel.hidden = mobilenumberErrorLabel.hidden = YES;
    passwordErrorLabel.hidden = confirmPasswordErrorLabel.hidden = YES;
    
    salutationPicker = [[[NSBundle mainBundle] loadNibNamed:@"Salutation" owner:self options:nil] firstObject];
    [salutationPicker setFrame:self.view.bounds];
    txtSalutation.inputView = salutationPicker;
    [salutationPicker selectByValue:txtSalutation.text];
    
    [txtSalutation addDoneOnKeyboardWithTarget:self action:@selector(doneSalutation:)];
    [txtUserName addDoneOnKeyboardWithTarget:self action:@selector(doneUsername:)];
}


#pragma mark - Terms of Use

- (IBAction)onOpenTerms:(id)sender {
    [[UIApplication sharedApplication] openURL: [NSURL URLWithString:kMedXTermsURL]];
}


#pragma mark - TextFields

- (void)nextSalutation:(id)sender {
    txtSalutation.text = [salutationPicker selectedValue];
    [txtUserName becomeFirstResponder];
}

- (void)doneSalutation:(id)sender {
    txtSalutation.text = [salutationPicker selectedValue];
    [self.view endEditing:YES];
}

- (void)doneUsername:(id)sender {
    [self.view endEditing:YES];
}

- (IBAction)onSalutationChanged:(id)sender {
    if ( ![txtSalutation hasText] )
        txtSalutation.text = _userInfo[@"salutation"];
}

- (IBAction)onMobilenumberChanged:(id)sender {
    lblMobilePlaceholder.hidden = [txtMobileNumber hasText];
}

- (IBAction)onPasswordChanged:(id)sender {
    lblPasswordPlaceholder.hidden = [txtPassword hasText];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ( [textField isEqual:txtSalutation] ) {
        return NO;
    }
    return YES;
}


#pragma mark - Validation methods

- (void)validateUsername {
    usernameErrorLabel.hidden = [txtUserName hasText];
}

- (void)validatePhoneNumber {
    mobilenumberErrorLabel.text = NSLocalizedString(@"labels.error.mobile_number_cannot_be_blank", nil);
    
    if ( ![txtMobileNumber hasText] ) {
        mobilenumberErrorLabel.hidden = NO;
    } else {
        mobilenumberErrorLabel.hidden = YES;
        
        NSError *anError = nil;
        NBPhoneNumber *myNumber = [phoneUtil parse:txtMobileNumber.text defaultRegion:@"AU" error:&anError];
        if ( anError == nil ) {
            if(![phoneUtil isValidNumber:myNumber])
                anError = [NSError errorWithDomain:NSLocalizedString(@"labels.error.invalid_mobile_number", nil) code:200 userInfo:nil];
        }
        
        if ( anError ) {
            mobilenumberErrorLabel.text = NSLocalizedString(@"labels.error.invalid_mobile_number", nil);
            mobilenumberErrorLabel.hidden = NO;
        }
        
        // For allowing US phone number (temporary)
        NSError *anError1 = nil;
        NBPhoneNumber *myNumber1 = [phoneUtil parse:txtMobileNumber.text defaultRegion:@"US" error:&anError1];
        if ( anError1 == nil ) {
            if(![phoneUtil isValidNumber:myNumber1])
                anError1 = [NSError errorWithDomain:NSLocalizedString(@"labels.error.invalid_mobile_number", nil) code:200 userInfo:nil];
        }
        if ( !anError1 ) {
            mobilenumberErrorLabel.hidden = YES;
        }
    }
}

- (void)validatePasswords {
    // Password
    if ( ![txtPassword hasText] ) {
        passwordErrorLabel.text = NSLocalizedString(@"labels.error.password_cannot_be_blank", nil);
        passwordErrorLabel.hidden = NO;
    } else {
        if ( txtPassword.text.length < MX_MIN_PASSWORD_LENGTH ) {
            passwordErrorLabel.text = NSLocalizedString(@"labels.error.password_too_weak", nil);
            passwordErrorLabel.hidden = NO;
        } else
            passwordErrorLabel.hidden = YES;
    }
    
    // Confirm password
    confirmPasswordErrorLabel.hidden = [txtConfirmPassword.text isEqualToString:txtPassword.text];
}

- (BOOL)doValidation {
    [self validateUsername];
    [self validatePhoneNumber];
    [self validatePasswords];
    
    BOOL isValid = (usernameErrorLabel.hidden && mobilenumberErrorLabel.hidden &&
                    passwordErrorLabel.hidden && confirmPasswordErrorLabel.hidden);
    
    warningLabel.hidden = isValid;
    notificationLabel.hidden = !isValid;
    if ( !isValid ) {
        warningLabel.text = NSLocalizedString(@"labels.error.correct_errors_below.", nil);
        [scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
    }
    
    return isValid;
}


#pragma mark - Registration

- (IBAction)onRegister:(id)sender {
    [self.view endEditing:YES];
    if ( ![self doValidation] ) return;
    
    [self showProgress:NSLocalizedString(@"progress.registering", nil)];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *keypair = [EncryptionUtil generateKeyPair];
        
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        
        [params setObject:_userInfo[@"first_name"] forKey:@"first_name"];
        [params setObject:lblName.text forKey:@"last_name"];
        [params setObject:lblSpecialty.text forKey:@"specialty"];
        [params setObject:txtUserName.text      forKey:@"preferred_first_name"];
        [params setObject:txtMobileNumber.text  forKey:@"phone"];
        [params setObject:txtSalutation.text    forKey:@"salutation"];
        [params setObject:keypair[0]            forKey:@"public_key"];
        [params setObject:txtPassword.text      forKey:@"password"];
        [params setObject:_registrationCode     forKey:@"code"];

        [self.backend accessAPIbyPOST:@"auth/register" Parameters:params CompletionHandler:^(NSDictionary *result, NSData *data, NSError *error) {
            NSLog(@"Register: %@", result);
            
            if ( !error ) {
                NSString *response = result[@"response"];
                if ( [response isEqualToString:@"fail"] ) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self hideProgress];
                        NSString *status = result[@"status"];
                        
                        if( [status isEqualToString:@"phone"] )
                            warningLabel.text = NSLocalizedString(@"labels.error.mobile_number_had_already_taken", nil);
                        else if( [status isEqualToString:@"user"] )
                            warningLabel.text = NSLocalizedString(@"labels.error.username_had_already_taken", nil);
                        else if( [status isEqualToString:@"verified"] )
                            warningLabel.text = NSLocalizedString(@"labels.error.doctor_already_registered", nil);
                        else
                            warningLabel.text = NSLocalizedString(@"labels.error.provided_details_not_match", nil);
                        
                        warningLabel.hidden = NO;
                        notificationLabel.hidden = YES;
                        
                        [scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
                    });
                    
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        warningLabel.hidden = YES;
                        notificationLabel.hidden = NO;
                    });
                    
                    [self onRegistrationSuccessWithUserInfo:result[@"user"] KeyPair:keypair];
                }
                
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self hideProgress];
                    [self showMessage:MX_ALERT_NETWORK_ERROR];
                });
            }
            
        }];
    });
}

- (void)onRegistrationSuccessWithUserInfo:(NSDictionary *)userInfo KeyPair:(NSArray *)keyPair {
    [[MedXUser CurrentUser] setUserInfo:userInfo];
    [MXUserUtil saveUserByInfo:userInfo completion:^(NSString *user_id, NSError *error) {
        [self doAfterSignInWithKeyPair:keyPair];
    }];
}

@end
