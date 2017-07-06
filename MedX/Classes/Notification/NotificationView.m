//
//  NotificationView.m
//  MedX
//
//  Created by Anthony Zahra on 6/23/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import "NotificationView.h"

@interface NotificationView(){
    UILabel *msgLabel;
    CGRect hiddenRect, visibleRect;
}
@end

@implementation NotificationView

-(id) init{
    
    hiddenRect  = CGRectMake(0, -70, [[UIScreen mainScreen] bounds].size.width, 70);
    visibleRect =  CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 70);
    self = [super initWithFrame: hiddenRect];
    
    if(self){
        
        self.backgroundColor = [UIColor colorWithRed:56/255.0f green:203/255.0f blue:240/255.0f alpha:1.0f];
        msgLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 30, self.frame.size.width-30, 30)];
        msgLabel.textColor = [UIColor whiteColor];
        msgLabel.font = [UIFont systemFontOfSize:15];
        
        [self addSubview:msgLabel];
        
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationDidChange:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    [self orientationDidChange:nil];
    
    return self;
}

-(void) orientationDidChange: (NSNotification*) notification
{
    UIInterfaceOrientation iOrientation = [UIApplication sharedApplication].statusBarOrientation;
    UIDeviceOrientation dOrientation = [UIDevice currentDevice].orientation;
    
    bool landscape;
    
    if (dOrientation == UIDeviceOrientationUnknown || dOrientation == UIDeviceOrientationFaceUp || dOrientation == UIDeviceOrientationFaceDown) {
        // If the device is laying down, use the UIInterfaceOrientation based on the status bar.
        landscape = UIInterfaceOrientationIsLandscape(iOrientation);
    } else {
        // If the device is not laying down, use UIDeviceOrientation.
        landscape = UIDeviceOrientationIsLandscape(dOrientation);
                
        // So values needs to be reversed for landscape!
        if (dOrientation == UIDeviceOrientationLandscapeLeft) iOrientation = UIInterfaceOrientationLandscapeRight;
        else if (dOrientation == UIDeviceOrientationLandscapeRight) iOrientation = UIInterfaceOrientationLandscapeLeft;
        
        else if (dOrientation == UIDeviceOrientationPortrait) iOrientation = UIInterfaceOrientationPortrait;
        else if (dOrientation == UIDeviceOrientationPortraitUpsideDown) iOrientation = UIInterfaceOrientationPortraitUpsideDown;
    }
    
    if (landscape) {
        hiddenRect.size.width = [[UIScreen mainScreen] bounds].size.height > [[UIScreen mainScreen] bounds].size.width ? [[UIScreen mainScreen] bounds].size.height : [[UIScreen mainScreen] bounds].size.width;
        visibleRect.size.width = hiddenRect.size.width;
    } else {
        hiddenRect.size.width = [[UIScreen mainScreen] bounds].size.height < [[UIScreen mainScreen] bounds].size.width ? [[UIScreen mainScreen] bounds].size.height : [[UIScreen mainScreen] bounds].size.width;
        visibleRect.size.width = hiddenRect.size.width;
    }
    
    if( self.superview != nil )
       [self setFrame:visibleRect];
    
    [msgLabel setFrame:CGRectMake(20, 30, visibleRect.size.width - 30, 30)];
    // Set the status bar to the right spot just in case
    [[UIApplication sharedApplication] setStatusBarOrientation:iOrientation];
    
}

-(void) hideNotification
{
    [self setFrame:hiddenRect];
}

-(void) showMessage: (NSString*) msg{

    msgLabel.text = msg;
    
    if( _isShowing == NO)
        [self setFrame:hiddenRect];
    else
        [self setFrame:visibleRect];

    _isShowing = YES;
    [UIView animateWithDuration:0.3f animations:^{
        [self setFrame:visibleRect];
    } completion:^(BOOL finished) {
        [self performSelector:@selector(hideMessage) withObject:nil afterDelay:5.0f];
    }];
    
}

-(void) hideMessage
{
   [UIView animateWithDuration:0.3f animations:^{
       [self setFrame:hiddenRect];
   } completion:^(BOOL finished) {
       //[self removeFromSuperview];
       _isShowing = NO;
   }];

}

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if( _messageInfo )
        [self.delegate openMessage: _messageInfo];

    [self hideMessage];
}

@end
