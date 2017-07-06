//
//  MXDirectoryViewController.m
//  MedX
//
//  Created by Anthony Zahra on 6/17/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import "MXDirectoryViewController.h"
#import "SVPullToRefresh.h"
#import "MXDoctorsCell.h"
#import "MXChatRootController.h"
#import "MXSpecialtyPicker.h"
#import "IQKeyboardManager.h"
#import "IQUIView+IQKeyboardToolbar.h"
#import <CoreLocation/CLGeocoder.h>
#import <CoreLocation/CLPlacemark.h>
#import "MXChatViewController.h"
#import "MXDirectoryProfileVC.h"
#import "LMGeocoder.h"

@interface MXDirectoryViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, MXDirectoryProfileVCDelegate> {
    
    __weak IBOutlet UITableView *doctorsTableView;    
    __weak IBOutlet UIView *lblNomore;
    
    __weak IBOutlet UITextField *txtKeyword;
    __weak IBOutlet UITextField *txtSpecialty;
    __weak IBOutlet UITextField *txtPostCode;
    __weak IBOutlet UIButton *btnOrderAZ;
    __weak IBOutlet UIButton *btnOrderDistance;
    
    __weak IBOutlet NSLayoutConstraint *searchViewHeightConstraint;
    
    NSMutableArray *doctorsList;
    MedXUser *currentUser;
    MXSpecialtyPicker *specialtyPicker;
}

@property (nonatomic, strong) UIImageView* titleView;

@end

@implementation MXDirectoryViewController

#pragma mark - Lifecycle methods

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if ( self ) {
        [self setNavigationBar];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ( doctorsList == nil ) {
        [self.view layoutIfNeeded];
        
        doctorsList = [[NSMutableArray alloc] init];
        currentUser = [MedXUser CurrentUser];
        
        [self setNavigationBar];
        [self initializeTableView];
        [self loadDoctors: NO];
        
        specialtyPicker = [[[NSBundle mainBundle] loadNibNamed:@"Specialty" owner:self options:nil] firstObject];
        [specialtyPicker setFrame:self.view.bounds];
        [specialtyPicker setupPicker: YES];
        txtSpecialty.inputView = specialtyPicker;
        
        // Add Done button action for specialty text field
        [txtSpecialty addDoneOnKeyboardWithTarget:self action:@selector(doneSpecialty:)];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [[IQKeyboardManager sharedManager] setEnable: NO];
    
    [[ChatService instance] setDialogViewName:MX_DIALOG_VIEW_SETTINGS];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[IQKeyboardManager sharedManager] setEnable: YES];
}


#pragma mark - Init methods

- (void)setNavigationBar {
    UIImage *logo = [UIImage imageNamed:@"search"];
    logo = [logo imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _titleView = [[UIImageView alloc] initWithImage:logo];
    self.navigationItem.titleView = self.titleView;
}

- (void)initializeTableView {
    [ThemeUtil removeSeparatorForEmptyCellInTableView:doctorsTableView];
    
    [doctorsTableView addPullToRefreshWithActionHandler:^{
        [self loadDoctors: NO];
    }];
    
    [doctorsTableView addInfiniteScrollingWithActionHandler:^{
        [self loadDoctors: YES];
    }];
}


#pragma mark - Load doctors

- (void)loadDoctors:(BOOL)load_more {
    if ( load_more && doctorsList.count < 10 ) {
        [doctorsTableView.infiniteScrollingView stopAnimating];
        return;
    }
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"token"]     = [currentUser accessToken];
    params[@"size"]      = @"25";
    params[@"keyword"]   = [txtKeyword.text isEqualToString:@"*"] ? @"" : txtKeyword.text;
    params[@"specialty"] = [txtSpecialty.text isEqualToString:@"All Specialties"] ? @"" : txtSpecialty.text;
    
    if ( btnOrderDistance.selected ) {
        params[@"order"]    = @"D";
        params[@"postcode"] = txtPostCode.text;
    } else
        params[@"order"] = @"C";
    
    params[@"start"] = load_more ? @(doctorsList.count) : @"0";
    
    [self.backend accessAPIbyGET:@"users/search" Parameters:params CompletionHandler:^(NSDictionary *result, NSData *data, NSError *error) {
        [doctorsTableView.pullToRefreshView stopAnimating];
        [doctorsTableView.infiniteScrollingView stopAnimating];
        [self hideProgress];
        
        if ( [result[@"response"] isEqualToString:@"success"] ) {
            if( load_more ){
                [doctorsList addObjectsFromArray:result[@"doctors"]];
            } else
                doctorsList = [NSMutableArray arrayWithArray:result[@"doctors"]];
            
            [doctorsTableView reloadData];
        } else {
            if ( [AppUtil isNotEmptyString: result[@"status"]] )
                [self showMessage:result[@"status"]];
            else {
                [self showMessage:MX_ALERT_NETWORK_ERROR];
            }
        }
        
        if ( [doctorsList count] > 0)
            lblNomore.hidden = YES;
        else
            lblNomore.hidden = NO;
    }];
    
}


#pragma mark - TableView

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return doctorsList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MXDoctorsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"doctorCell"];
    
    if (indexPath.row < doctorsList.count)
        [cell setupCell:doctorsList[indexPath.row]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *info = doctorsList[indexPath.row];
    [MXUserUtil saveUserByInfo:info completion:^(NSString *user_id, NSError *error) {
        
        if (!error) {
            [MXRelationshipUtil saveRelationshipByInfo:info forUserId:currentUser.userId];
            
            MXDirectoryProfileVC *profileVC = [self.storyboard instantiateViewControllerWithIdentifier:@"directoryProfileVC"];
            profileVC.user_id = user_id;
            profileVC.delegate = self;
            
            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:profileVC];

            [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:nc animated:YES completion:nil];
            
        } else {
            
        }
    }];
}


#pragma mark - TextField delegate methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if ( [textField isEqual:txtPostCode] ) {
        btnOrderDistance.selected = YES;
        btnOrderAZ.selected       = NO;
    }
    return YES;
}


#pragma mark - Search

- (void)doneSpecialty:(id)sender {
    txtSpecialty.text = [specialtyPicker selectedValue];
    [self.view endEditing:YES];
}

- (IBAction)onSortByAZ:(id)sender {
    btnOrderAZ.selected = !btnOrderAZ.selected;
    btnOrderDistance.selected = !btnOrderAZ.selected;
}

- (IBAction)onSortByDistance:(id)sender {
    btnOrderDistance.selected = !btnOrderDistance.selected;
    btnOrderAZ.selected = !btnOrderDistance.selected;
}

- (IBAction)onSearch:(id)sender {
    [self.view endEditing:YES];
    [self showProgress:NSLocalizedString(@"progress.searching", nil)];
    
    txtKeyword.text = [txtKeyword.text stringByTrimmingCharactersInSet:
                       [NSCharacterSet whitespaceCharacterSet]];
    
    if ( btnOrderDistance.selected && [txtPostCode.text isEqualToString:@""]) {
        [self hideProgress];
        [self showMessage:NSLocalizedString(@"alert.invalid_postcode", nil)];
        return;
    }
    [self loadDoctors: NO];
}


#pragma mark - MXDirectoryProfileVCDelegate

- (void)directoryProfileVCDidClickChatUser:(MXDirectoryProfileVC *)profileVC {
}

@end
