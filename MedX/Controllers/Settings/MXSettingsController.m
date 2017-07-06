//
//  MXSettingsController.m
//  MedX
//
//  Created by Anthony Zahra on 6/18/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import "MXSettingsController.h"
#import "AppDelegate.h"
#import "MXSpecialtyPicker.h"
#import "MXLocationView.h"
#import "MXTextField.h"
#import "MXSalutationPicker.h"
#import "IQKeyboardManager.h"
#import "IQUIView+IQKeyboardToolbar.h"
#import <AddressBookUI/AddressBookUI.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreLocation/CLPlacemark.h>

#define kDeleteButtonTag            1000
#define kAddressHeight              65
#define kDeleteButtonWidth          40
#define kMinAboutTextHeight         33
#define kMaxAboutTextHeight         150
#define kMinAboutContainerHeight    50
#define kMaxAboutContainerHeight    117

@interface MXSettingsController () {
    
    __weak IBOutlet UITextField  *txtSalutation;
    __weak IBOutlet UILabel      *lblName;
    __weak IBOutlet UITextField  *txtUsername;
    __weak IBOutlet UILabel      *lblSpecialty;
    __weak IBOutlet UITextView   *txtAbout;
    __weak IBOutlet UIView       *locationsView;
    __weak IBOutlet UILabel      *lblPreferredFirstNameError;
    __weak IBOutlet UILabel      *lblAboutPlaceholder;
    __weak IBOutlet UIScrollView *contentScrollView;
    
    __weak IBOutlet NSLayoutConstraint *txtAboutContainerHConstraint;
    __weak IBOutlet NSLayoutConstraint *locationViewHeightContraint;
    __weak IBOutlet NSLayoutConstraint *contentHeightConstraint;
    
    MedXUser *currentUser;
    MXLocationView *locationView;
    
    MXSalutationPicker *salutationPicker;
    NSMutableArray *offices;
    
    int prevAboutTextHeight;
}

@property (nonatomic, strong) UIImageView* titleView;

@end

@implementation MXSettingsController

#pragma mark - LifeCycle

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if ( self ) {
        [self setNavigationBar];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if( currentUser == nil ){
        currentUser = [MedXUser CurrentUser];
        [self initContents];
    }
    
    // Add Done button action for text fields
    [txtSalutation addDoneOnKeyboardWithTarget:self action:@selector(doneAction2:)];
    [txtUsername addDoneOnKeyboardWithTarget:self action:@selector(doneAction:)];
    [txtAbout addDoneOnKeyboardWithTarget:self action:@selector(doneAction:)];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[ChatService instance] setDialogViewName:MX_DIALOG_VIEW_SETTINGS];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Init & UI Methods

- (void)setNavigationBar {
    UIImage *logo = [UIImage imageNamed:@"gear"];
    logo = [logo imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _titleView = [[UIImageView alloc] initWithImage:logo];
    self.navigationItem.titleView = self.titleView;
}

- (void)initContents {
    MXUser *user = [MXUserUtil findByUserId:[currentUser userId] inContext:nil];
    
    txtSalutation.text = user.salutation;
    lblName.text       = user.last_name;
    lblSpecialty.text  = user.specialty;
    txtUsername.text   = user.preferred_first_name;
    
    if( [AppUtil isNotEmptyString:user.about] ) {
        txtAbout.text = user.about;
    } else {
        txtAbout.text = @"";
        lblAboutPlaceholder.hidden = NO;
    }
    [self adjustTextViewHeight2];
    
    offices = [[NSMutableArray alloc] init];
    if ( currentUser.info[@"offices"] ) {
        NSArray *officeList = currentUser.info[@"offices"];
        for(NSDictionary *officeInfo in officeList){
            [self addLocation:officeInfo];
        }
    }
    
    salutationPicker = [[[NSBundle mainBundle] loadNibNamed:@"Salutation" owner:self options:nil] firstObject];
    [salutationPicker setFrame:self.view.bounds];
    txtSalutation.inputView = salutationPicker;
    [salutationPicker selectByValue:txtSalutation.text];
}


#pragma mark - UITextViewDelegate methods

- (void)textViewDidEndEditing:(UITextView *)theTextView {
    if (![txtAbout hasText]) {
        lblAboutPlaceholder.hidden = NO;
    }
}

- (void)textViewDidChange:(UITextView *)textView {
    if (![txtAbout hasText]) {
        lblAboutPlaceholder.hidden = NO;
        txtAboutContainerHConstraint.constant = kMinAboutContainerHeight;
    } else {
        lblAboutPlaceholder.hidden = YES;
        [self adjustTextViewHeight];
    }
}

- (void)adjustTextViewHeight {
    CGSize oldSize = CGSizeMake(txtAbout.frame.size.width, txtAbout.frame.size.height);
    CGSize newSize = [txtAbout sizeThatFits:CGSizeMake(txtAbout.frame.size.width, MAXFLOAT)];
    if ( (int)newSize.height <= kMinAboutTextHeight )
        txtAboutContainerHConstraint.constant = kMinAboutContainerHeight;
    else if ( newSize.height > kMinAboutTextHeight &&
        newSize.height < kMaxAboutTextHeight &&
        (txtAboutContainerHConstraint.constant < newSize.height ||
         txtAboutContainerHConstraint.constant > newSize.height) ) {
            txtAboutContainerHConstraint.constant = (int)newSize.height + 17;
            
            // Reset scrollview content offset y when textview height changes
            if ( abs((int)newSize.height - (int)oldSize.height) >= 15 ) {
                CGPoint ptOffset = CGPointMake(contentScrollView.contentOffset.x, contentScrollView.contentOffset.y);
                ptOffset.y += newSize.height - oldSize.height;
                [contentScrollView setContentOffset:ptOffset];
            }
    }
    [self adjustContentViewHeight:0];
}

- (void)adjustTextViewHeight2 {
    CGSize newSize = [txtAbout sizeThatFits:CGSizeMake(txtAbout.frame.size.width, MAXFLOAT)];
    if ( (int)newSize.height <= kMinAboutTextHeight )
        txtAboutContainerHConstraint.constant = kMinAboutContainerHeight;
    else {
        txtAboutContainerHConstraint.constant = MIN((int)newSize.height + 17, kMaxAboutContainerHeight);
    }
}

- (void)adjustContentViewHeight:(CGFloat)dH {
    contentHeightConstraint.constant = locationsView.frame.origin.y +
                                       locationsView.frame.size.height +
                                       dH + 15;
}


#pragma mark - TextFields

- (void)doneAction:(id)sender {
    [self.view endEditing:YES];
    [self updateAfterCheckingTextFieldsChanged];
}

- (void)doneAction2:(id)sender {
    txtSalutation.text = [salutationPicker selectedValue];
    [self.view endEditing:YES];
    [self updateAfterCheckingTextFieldsChanged];
}

- (IBAction)onSalutationChanged:(id)sender {
    if ( ![txtSalutation hasText] )
        txtSalutation.text = currentUser.info[@"salutation"];
}

- (IBAction)onPreferredFirstNameChanged:(id)sender {
    if ( [txtUsername.text isEqualToString:@""] )
        lblPreferredFirstNameError.hidden = NO;
    else
        lblPreferredFirstNameError.hidden = YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ( [textField isEqual:txtSalutation] ) {
        return NO;
    }
    return YES;
}

- (void)updateAfterCheckingTextFieldsChanged {
    BOOL bChanged = !( [currentUser.info[@"salutation"] isEqualToString:txtSalutation.text] &&
                       [currentUser.info[@"preferred_first_name"] isEqualToString:txtUsername.text] &&
                       [currentUser.info[@"about"] isEqualToString:txtAbout.text]);
    
    if ( !lblPreferredFirstNameError.hidden ) return;
    
    if ( bChanged )
        [self onUpdate:nil];
}


#pragma mark - Location Methods

- (void)onDeleteLocation:(id)sender {
    UIButton *btnDel = (UIButton*)sender;
    NSInteger tag = btnDel.tag, removingIndex = tag - kDeleteButtonTag;
    
    UIView *removingView = [locationsView viewWithTag:tag + 1000];
    
    [offices removeObjectAtIndex:removingIndex];
    [removingView removeFromSuperview];
    
    if ( removingIndex < [offices count] ) {
        for (NSInteger i=removingIndex; i < [offices count]; i++) {
            NSInteger tagBtnDel = kDeleteButtonTag + i + 1;
            UIView    *view     = [locationsView viewWithTag:tagBtnDel + 1000];
            UIButton  *del      = (UIButton *)[view viewWithTag:tagBtnDel];
            
            // Decreases tag by 1
            view.tag = view.tag - 1;
            del.tag  = del.tag - 1;
            
            // Resets y pos
            CGRect frame = view.frame;
            frame.origin.y = 15 + i*60;
            view.frame     = frame;
        }
    }
    
    [self adjustContentViewHeight:-kAddressHeight];
    
    locationViewHeightContraint.constant -= kAddressHeight;
    [UIView animateWithDuration:0.2f animations:^{
        [self.view layoutIfNeeded];
    }];
    
    [self onUpdate:nil];
}

- (IBAction)onAddLocations:(id)sender {
    if ( locationView == nil ) {
        locationView = [[[NSBundle mainBundle] loadNibNamed:@"LocationView"
                                                      owner:self options:nil] firstObject];
        locationView.frame = self.view.bounds;
        locationView.parentVC = self;
        
        __block typeof(self) _weakSelf = self;
        locationView.onDismiss = ^(NSDictionary* dict) {
            
            NSString     *address    = [NSString stringWithFormat:@"%@\n%@\n%@", dict[@"street"], dict[@"formatted_address"], dict[@"phone"]];
            CLLocation   *loc        = dict[@"location"];
            NSDictionary *officeInfo = [[NSDictionary alloc] initWithObjects:@[dict[@"postcode"], dict[@"phone"], address,
                                                                               @(loc.coordinate.latitude), @(loc.coordinate.longitude)]
                                                                     forKeys:@[@"postcode", @"phone", @"address", @"latitude", @"longitude"]];
            
            [_weakSelf addLocation:officeInfo];
            [_weakSelf onUpdate:nil];
        };
    }
    
    [[IQKeyboardManager sharedManager] setEnable:NO];
    
    [self.view addSubview:locationView];
}

- (void)addLocation:(NSDictionary *)officeInfo {
    int cnt = (int)[offices count];
    [offices addObject:officeInfo];
    
    locationViewHeightContraint.constant += kAddressHeight;
    
    [self adjustContentViewHeight:kAddressHeight];
    
    [UIView animateWithDuration:0.2f animations:^{
        [self.view layoutIfNeeded];
    }];
    
    UIView   *view       = [[UIView alloc] initWithFrame:CGRectMake(0, cnt*60, locationsView.frame.size.width - 100, kAddressHeight)];
    UILabel  *lblAddress = [[UILabel alloc] initWithFrame:CGRectMake(94, 0, view.frame.size.width - kDeleteButtonWidth - 10, kAddressHeight)];
    UIButton *btnDelete  = [[UIButton alloc] initWithFrame:CGRectMake(78 - kDeleteButtonWidth - 10, 5, kDeleteButtonWidth, kAddressHeight/2.0f)];
    
    lblAddress.numberOfLines = 0;
    lblAddress.text = [MXUserUtil refineOfficePhoneNumberInLocation:officeInfo[@"address"]];
    lblAddress.font = [UIFont systemFontOfSize:13.f];
    
    [btnDelete setImage:[UIImage imageNamed:@"trash"] forState:UIControlStateNormal];
    [btnDelete addTarget:self action:@selector(onDeleteLocation:) forControlEvents:UIControlEventTouchUpInside];
    [btnDelete.titleLabel setFont:[UIFont systemFontOfSize:13.0f]];
    btnDelete.tag = kDeleteButtonTag + cnt;
    
    
    [view addSubview:lblAddress];
    [view addSubview:btnDelete];
    view.tag = kDeleteButtonTag + 1000 + cnt;
    
    [locationsView addSubview: view];
}


#pragma mark - Button Events

- (IBAction)onUpdate:(id)sender {

    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    
    [params setObject:[currentUser accessToken] forKey:@"token"];
    [params setObject:txtSalutation.text        forKey:@"salutation"];
    [params setObject:txtUsername.text          forKey:@"preferred_first_name"];
    [params setObject:txtAbout.text             forKey:@"about"];
    
    NSString *jsonString = [AppUtil getJSONStringFromObject:offices];
    [params setObject:jsonString forKey:@"offices"];
    
    [self showProgress:NSLocalizedString(@"progress.updating", nil)];
    [[BackendBase sharedConnection] accessAPIbyPOST:@"users/update" Parameters:params CompletionHandler:^(NSDictionary *result, NSData *data, NSError *error) {
        [self hideProgress];
        if ( [result[@"response"] isEqualToString:@"success"] ) {
            currentUser.info[@"offices"] = offices;
            currentUser.info[@"salutation"] = txtSalutation.text;
            currentUser.info[@"preferred_first_name"] = txtUsername.text;
            currentUser.info[@"about"] = txtAbout.text;
            
            [MXUserUtil updateUserDefaults:nil withUserInfo:currentUser.info LastLogin:[NSDate date]];
            
            NSDictionary *info = @{@"user_id": [currentUser userId],
                                   @"about": txtAbout.text,
                                   @"salutation": txtSalutation.text,
                                   @"preferred_first_name": txtUsername.text,
                                   };
            
            [MXUserUtil saveUserByInfo:info completion:nil];
        } else {
            [self showMessage:NSLocalizedString(@"alert.server_error_try_later", nil)];
        }
    }];
}

@end
