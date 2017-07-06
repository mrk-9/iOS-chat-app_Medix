//
//  MXRegisterWelcomeController.m
//  MedX
//
//  Created by Anthony Zahra on 6/22/15.
//  Copyright (c) 2015 Hugo. All rights reserved.
//

#import "MXRegisterWelcomeController.h"
#import "MXIntroViewcontroller.h"

@implementation MXRegisterWelcomeController

-(void) viewWillAppear:(BOOL)animated
{
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [MXUserUtil removeUserParamsFromUserDefaults:nil];
}


- (IBAction)onSignin:(id)sender {
    
    MXIntroViewcontroller *introVC = (MXIntroViewcontroller*)[self.navigationController.viewControllers firstObject];
    
    [self.navigationController popToViewController:introVC animated:NO];    
    [introVC performSegueWithIdentifier:@"loginSegue" sender:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
