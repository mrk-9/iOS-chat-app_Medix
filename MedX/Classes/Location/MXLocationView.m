//
//  MXLocationView.m
//  MedX
//
//  Created by Anthony Zahra on 6/24/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import "MXLocationView.h"
#import "NBPhoneNumberUtil.h"
#import <AddressBookUI/AddressBookUI.h>
#import <CoreLocation/CLGeocoder.h>
#import <CoreLocation/CLPlacemark.h>
#import "LMGeocoder.h"
#import "IQKeyboardManager.h"
#import "IQUIView+IQKeyboardToolbar.h"

#define OFFSET_VALUE(i)          80+i*50

@interface MXLocationView() <UITextFieldDelegate> {
    
    __weak IBOutlet UITextField *txtPostcode;
    __weak IBOutlet UITextField *txtStreet;
    __weak IBOutlet UITextField *txtPhone;
    __weak IBOutlet UILabel     *lblError;
    
    NBPhoneNumberUtil *phoneUtil;
    
    NSDictionary *dictStates;
    NSInteger     iFocusedText;
    CGRect        originFrame;
}

@end

@implementation MXLocationView


#pragma mark - Lifecycle methods

- (void)awakeFromNib {
    dictStates = @{@"Australian Capital Territory": @"ACT",
                   @"New South Wales": @"NSW",
                   @"Northern Territory": @"NT",
                   @"Queensland": @"QLD",
                   @"South Australia": @"SA",
                   @"Tasmania": @"TAS",
                   @"Victoria": @"VIC",
                   @"Western Australia": @"WA"};
    
    [txtPostcode addDoneOnKeyboardWithTarget:self action:@selector(onDone:)];
    [txtStreet addDoneOnKeyboardWithTarget:self action:@selector(onDone:)];
    [txtPhone addDoneOnKeyboardWithTarget:self action:@selector(onDone:)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
    
    originFrame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.frame.size.height);
}


#pragma mark - Internal notifications

- (void)registerNotifications {
    [self deregisterNotifications];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)deregisterNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}


#pragma mark - Events methods

- (IBAction)onSave:(id)sender {
    
    if( [txtPostcode.text isEqualToString:@""] || [txtPhone.text isEqualToString:@""] || [txtStreet.text isEqualToString:@""] ){
        [self showMessage:NSLocalizedString(@"alert.enter_all_fields", nil)];
        return;
    }
    
    /////// Check Phone number
    NSError *anError = nil;
    if(!phoneUtil)
        phoneUtil = [[NBPhoneNumberUtil alloc] init];
    
    NBPhoneNumber *myNumber = [phoneUtil parse:txtPhone.text defaultRegion:@"AU" error:&anError];
    
    if ( anError == nil ) {
        if(![phoneUtil isValidNumber:myNumber]) anError = [NSError errorWithDomain:@"Invalid Phone Number" code:200 userInfo:nil];
    }
    
    if ( anError ) {
        [self showMessage:NSLocalizedString(@"alert.invalid_phone_enter_again", nil)];
        return;
    }
    
    /////// Geocoding by postcode from server
    lblError.hidden = YES;
    NSDictionary *params = @{@"token": [[MedXUser CurrentUser] accessToken],
                             @"postcode": txtPostcode.text};

    [_parentVC showProgress:NSLocalizedString(@"progress.updating", nil)];
    [[BackendBase sharedConnection] accessAPIbyGET:@"users/geocode" Parameters:params CompletionHandler:^(NSDictionary *result, NSData *data, NSError *error) {
        if ( [result[@"response"] isEqualToString:@"success"] ) {
            if ( [txtPhone.text length] == 9 )
                txtPhone.text = [NSString stringWithFormat:@"0%@", txtPhone.text];
            
            CLLocation *location = [[CLLocation alloc] initWithLatitude:[result[@"coordinate"][@"latitude"] floatValue]
                                                              longitude:[result[@"coordinate"][@"longitude"] floatValue]];
            NSDictionary *dict   = [[NSDictionary alloc] initWithObjects:@[txtPostcode.text, result[@"location"], txtStreet.text, txtPhone.text, location]
                                                                 forKeys:@[@"postcode", @"formatted_address", @"street", @"phone", @"location"]];

            self.onDismiss(dict);
        
            txtPostcode.text = txtStreet.text = txtPhone.text = @"";
            lblError.hidden  = YES;
            
            [[IQKeyboardManager sharedManager] setEnable:YES];
            
            [self removeFromSuperview];
        } else
            error = [[NSError alloc] init];

        if (error) {
            [_parentVC hideProgress];
            lblError.hidden = NO;
        }
    }];
}

- (IBAction)onClose:(id)sender {
    [[IQKeyboardManager sharedManager] setEnable:YES];
    
    [self removeFromSuperview];
}


#pragma mark - Keyboard notifiation methods

- (void)keyboardWillShow:(NSNotification*)aNotification {
    if ( abs((int)originFrame.origin.y-(int)self.frame.origin.y) >= OFFSET_VALUE(iFocusedText) ) return;
    [UIView animateWithDuration:0.25 animations:^{
        CGRect newFrame = [self frame];
        newFrame.origin.y -= OFFSET_VALUE(iFocusedText);
        [self setFrame:newFrame];
    } completion:^(BOOL finished) {
    }];
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
    CGFloat d = abs((int)originFrame.origin.y-(int)self.frame.origin.y);
    [UIView animateWithDuration:0.25 animations:^{
        CGRect newFrame = [self frame];
        newFrame.origin.y += d;
        [self setFrame:newFrame];
    } completion:^(BOOL finished) {
    }];
}


#pragma mark - TextFields Event methods

- (void)onDone:(id)sender {
    [self endEditing:YES];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if ( textField == txtPostcode )
        iFocusedText = 0;
    else if ( textField == txtStreet )
        iFocusedText = 1;
    else if ( textField == txtPhone )
        iFocusedText = 2;
    return YES;
}

- (void)showMessage:(NSString*)message {
    UIAlertView *msg = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"labels.title.warning", nil)
                                                  message:message
                                                 delegate:nil
                                        cancelButtonTitle:NSLocalizedString(@"labels.ok", nil)
                                        otherButtonTitles:nil, nil];
    [msg show];
}

@end
