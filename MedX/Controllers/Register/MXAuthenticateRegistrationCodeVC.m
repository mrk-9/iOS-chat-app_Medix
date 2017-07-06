//
//  MXAuthenticateRegistrationCodeVC.m
//  MedX
//
//  Created by Ping Ahn on 11/12/15.
//  Copyright © 2015 Hugo. All rights reserved.
//

#import "MXAuthenticateRegistrationCodeVC.h"
#import "MXRegisterController.h"

@interface MXAuthenticateRegistrationCodeVC () {
    __weak IBOutlet UITextField *txtCode;
    __weak IBOutlet UILabel     *errorLabel;
}

@end

@implementation MXAuthenticateRegistrationCodeVC

#pragma mark - Lifecycle methods

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [ThemeUtil initTextFields:@[txtCode]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ( [segue.identifier isEqualToString:@"segueRegisterVC"] ) {
        MXRegisterController *vc = segue.destinationViewController;
        
        vc.registrationCode = txtCode.text;
        vc.userInfo = sender;
    }
}

- (IBAction)prepareForUnwind:(UIStoryboardSegue *)segue {
}


#pragma mark - UITextFieldDelegate methods

- (IBAction)onCodeChanged:(id)sender {
    if ( txtCode.text.length > 6 )
        txtCode.text = [txtCode.text substringToIndex:6];
    txtCode.text = [txtCode.text uppercaseString];
}


#pragma mark - Validation methods

- (void)validateCode {
    if ( ![txtCode hasText] )
        errorLabel.text = NSLocalizedString(@"labels.error.registration_code_cannot_be_blank", nil);
    errorLabel.hidden = [txtCode hasText];
}

- (BOOL)doValidation {
    [self validateCode];
    
    return errorLabel.hidden;
}


#pragma mark - Button events methods

- (IBAction)onBtnVerify:(id)sender {
    [self.view endEditing:YES];
    if ( ![self doValidation] ) return;
    
    [self showProgress:NSLocalizedString(@"wait", nil)];
    [self.backend accessAPIbyPOST:@"auth/verify_registration_code" Parameters:@{@"code":txtCode.text} CompletionHandler:^(NSDictionary *result, NSData *data, NSError *error) {
        [self hideProgress];
        if( [result[@"response"] isEqualToString:@"success"] ){
            [self performSegueWithIdentifier:@"segueRegisterVC" sender:result[@"user"]];
        } else {
            errorLabel.text = NSLocalizedString(@"labels.error.invalid_registration_code", nil);
            errorLabel.hidden = NO;
        }
    }];
}

- (IBAction)onBtnTerms:(id)sender {
    [[UIApplication sharedApplication] openURL: [NSURL URLWithString:kMedXTermsURL]];
}

- (IBAction)onBtnMedxIO:(id)sender {
    [[UIApplication sharedApplication] openURL: [NSURL URLWithString:kMedXURL]];
}

@end
