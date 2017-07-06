//
//  MXIntroViewcontroller.m
//  MedX
//
//  Created by Anthony Zahra on 6/12/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import "MXIntroViewcontroller.h"
#import "AppDelegate.h"

@interface MXIntroViewcontroller (){
    
    __weak IBOutlet UIScrollView *introScrollView;
    __weak IBOutlet UIPageControl *pageControl;
}

@end

@implementation MXIntroViewcontroller

#pragma mark - Lifecycle methods

- (void)viewWillAppear: (BOOL)animated {
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewWillDisappear: (BOOL)animated {
    self.navigationController.navigationBarHidden = NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    MedXUser *currentUser = [MedXUser CurrentUser];
    
    if ( [MXUserUtil checkUserInfoExistsFromUserDefaults:defaults] ) {
        NSTimeInterval lastLogin = [[MXUserUtil getLastLoginFromUserDefaults:defaults] timeIntervalSince1970];
        
        if ( timeStamp - lastLogin < [MXUserUtil getLoginExpirePeriodInSeconds] ){
            
            [currentUser setUserInfo:[NSMutableDictionary dictionaryWithDictionary:[MXUserUtil getUserInfoFromUserDefaults:defaults]]];
            
            AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
            app.window.rootViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"rootViewController"];
            
            [app registerForRemoteNotifications];
        } else {
            
            [MXUserUtil removeUserParamsFromUserDefaults:defaults];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Button events

- (IBAction)onSignin:(id)sender {
    [self performSegueWithIdentifier:@"loginSegue" sender:self];
}

- (IBAction)prepareForUnwind:(UIStoryboardSegue *)segue {
}

#pragma mark - Intro

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [pageControl setCurrentPage:(int) scrollView.contentOffset.x / scrollView.frame.size.width];
}

@end
