//
//  MXRootViewController.m
//  MedX
//
//  Created by Anthony Zahra on 6/17/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import "MXRootViewController.h"

@interface MXRootViewController ()

@end

@implementation MXRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    UIColor *orange = RGBHEX(0xFFFFFF, 1.f);
    UIColor *gray = RGBHEX(0xFFFFFF, 1.f);
    
    self.navigationSideItemsStyle = SLNavigationSideItemsStyleOnBounds;
    [self setCurrentIndex:0 animated:NO];
    float minX = 45.0;
    
    __block typeof(self) _weakSelf = self;
    [self setCurrentIndex:1 animated:NO];
    self.pagingViewMoving = ^(NSArray *subviews) {
        [_weakSelf.view endEditing:YES];
        
        float mid  = [UIScreen mainScreen].bounds.size.width/2 - minX;
        float midM = [UIScreen mainScreen].bounds.size.width - minX;
        for(UIImageView *v in subviews){
            UIColor *c = gray;
            if(v.frame.origin.x > minX && v.frame.origin.x < mid)
                // Left part
                c = [UIColor gradient:v.frame.origin.x top:minX+1 bottom:mid-1 init:orange goal:gray];
            else if(v.frame.origin.x > mid && v.frame.origin.x < midM)
                // Right part
                c = [UIColor gradient:v.frame.origin.x top:mid+1 bottom:midM-1 init:gray goal:orange];
            else if(v.frame.origin.x == mid)
                c = orange;
            v.tintColor= c;
        }
    };
    
    self.pagingViewMovingRedefine = ^(UIScrollView * scrollView, NSArray *subviews) {
        [_weakSelf setLogoutButtonByIndex:(int) ((scrollView.contentOffset.x + scrollView.frame.size.width/2) / scrollView.frame.size.width)];
    };
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setLogoutButtonByIndex:(int)nShowingPageIndex {
    if ( nShowingPageIndex == 0 ) {
        if ( !self.navigationItem.leftBarButtonItem ) {
            UIBarButtonItem *btnLogout = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"labels.title.logout", nil)
                                                                           style:UIBarButtonItemStylePlain
                                                                          target:self action:@selector(onBtnLogout)];
            self.navigationItem.leftBarButtonItem = btnLogout;
        }
    } else
        self.navigationItem.leftBarButtonItem = nil;
}

- (void)onBtnLogout {
    [[AppUtil appDelegate] logout];
}

@end
