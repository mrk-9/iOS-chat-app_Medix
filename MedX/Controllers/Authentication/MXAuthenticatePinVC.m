//
//  MXAuthenticatePinVC.m
//  MedX
//
//  Created by Ping Ahn on 8/22/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import "MXAuthenticatePinVC.h"
#import "MXExpirePeriodPicker.h"
#import "IQKeyboardManager.h"
#import "IQUIView+IQKeyboardToolbar.h"

@interface MXAuthenticatePinVC () <UIAlertViewDelegate> {
    
    __weak IBOutlet UITextField *txtPin;
    __weak IBOutlet UITextField *txtExpirePeriod;
    __weak IBOutlet UILabel *pinErrorLabel;
    
    MedXUser *currentUser;
    MXExpirePeriodPicker *expirePeriodPicker;
}

@end

@implementation MXAuthenticatePinVC

#pragma mark - Lifecycle methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    currentUser = [MedXUser CurrentUser];
    
    [self initUI];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark - Init methods

- (void)initUI {
    // Init text fields border
    [ThemeUtil initTextFields:@[txtPin, txtExpirePeriod]];
    
    // Init expire-period picker
    expirePeriodPicker = [[[NSBundle mainBundle] loadNibNamed:@"ExpirePeriod" owner:self options:nil] firstObject];
    [expirePeriodPicker setFrame:self.view.bounds];
    [expirePeriodPicker selectByIndex:3];
    txtExpirePeriod.inputView = expirePeriodPicker;
    txtExpirePeriod.text = [expirePeriodPicker selectedValue];
    
    // Add Done button action for specialty text field
    [txtExpirePeriod addDoneOnKeyboardWithTarget:self action:@selector(donePeriod:)];
}


#pragma mark - UITextFieldDelegate methods

- (IBAction)onPinChanged:(id)sender {
    if( txtPin.text.length > 4 )
        txtPin.text = [txtPin.text substringToIndex:4];
    txtPin.text = [txtPin.text uppercaseString];
}

- (IBAction)onPeriodChanged:(id)sender {
    if ( ![txtExpirePeriod hasText] )
        txtExpirePeriod.text = [NSString stringWithFormat:NSLocalizedString(@"texts.logout_after_x_inactivity", nil),
                                [[expirePeriodPicker selectedValue] lowercaseString]];
}

- (void)donePeriod:(id)sender {
    txtExpirePeriod.text = [NSString stringWithFormat:NSLocalizedString(@"texts.logout_after_x_inactivity", nil),
                            [[expirePeriodPicker selectedValue] lowercaseString]];
    [self.view endEditing:YES];
}


#pragma mark - Validation methods

- (void)validatePIN {
    if ( ![txtPin hasText] )
        pinErrorLabel.text = NSLocalizedString(@"labels.error.pin_cannot_be_blank", nil);
    pinErrorLabel.hidden = [txtPin hasText];
}

- (BOOL)doValidation {
    [self validatePIN];
    
    return pinErrorLabel.hidden;
}


#pragma mark - Button events methods

- (IBAction)onSignIn:(id)sender {
    [self.view endEditing:YES];
    if ( ![self doValidation] ) return;
    
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    
    NSString *period = [expirePeriodPicker selectedValue];
    
    [params setObject:self.mobileNumber     forKey:@"phone"];
    [params setObject:txtPin.text           forKey:@"pin"];
    [params setObject:period                forKey:@"expire_period"];
    
    [self showProgress:NSLocalizedString(@"progress.connect", nil)];
    [self.backend accessAPIbyPOST:@"auth/verify_pin" Parameters:params CompletionHandler:^(NSDictionary *result, NSData *data, NSError *error) {
        NSString* response = result[@"response"];
        
        if ( [response isEqualToString:@"success"] ) {
            [MXUserUtil updateUserDefaults:nil withLoginExpirePeriod:period];
            [currentUser setUserInfo:result[@"user"]];
            [MXUserUtil saveUserByInfo:result[@"user"] completion:^(NSString *user_id, NSError *error) {
                [self onAuthenticationSuccess:result[@"user"]];
            }];
        } else {
            [self hideProgress];
            pinErrorLabel.text = NSLocalizedString(@"labels.error.invalid_or_expired_pin", nil);
            pinErrorLabel.hidden = NO;
        }
        
    }];
}


#pragma mark - Authentication Success

- (void)onAuthenticationSuccess:(NSDictionary *)userInfo {
    NSArray *keys = [MXUserUtil getEncryptionKeysFromUserDefaults:nil];
    BOOL bHasToRegisterEncryptionKeys = [AppUtil isEmptyObject:keys] ||
                                        [AppUtil isEmptyObject:userInfo[@"public_key"]] ||
                                        ![keys[0] isEqualToString:userInfo[@"public_key"]];
    
    if ( bHasToRegisterEncryptionKeys ) {
        if ( [AppUtil isNotEmptyObject:userInfo[@"public_key"]] )
            [self showConfirmMessage:MX_ALERT_LOGIN_WITH_ANOTHER_DEVICE Delegate:self
                       OKButtonTitle:NSLocalizedString(@"labels.title.proceed", nil)];
        else
            [self doRegisterEncryptionKeys];
    } else
        [self doAfterSignInWithKeyPair:nil];
}

- (void)doRegisterEncryptionKeys {
    [self showProgress:NSLocalizedString(@"progress.generating_keys", nil)];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSArray *keyPair = [EncryptionUtil generateKeyPair];
        [currentUser registerPublicKey:keyPair[0] completion:^(BOOL success, NSError *error) {
            if ( success ) {
                [self doAfterSignInWithKeyPair:keyPair];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if ( !success ) {
                    [self hideProgress];
                    [self showMessage:NSLocalizedString(@"alert.check_internet_connection", nil)];
                }
            });
        }];
    });
}


#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch(buttonIndex) {
        case 0:
            [self hideProgress];
            break;
        case 1:
            [self doRegisterEncryptionKeys];
            break;
    }
}

@end
