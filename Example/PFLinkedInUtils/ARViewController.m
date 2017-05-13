//
//  ARViewController.m
//  PFLinkedInUtils
//
//  Created by Alejandro Rupérez Hernando on 11/15/2014.
//  Copyright (c) 2014 Alejandro Rupérez Hernando. All rights reserved.
//

#import "ARViewController.h"

#import <PFLinkedInUtils/PFLinkedInUtils.h>

@interface ARViewController ()

@end

@implementation ARViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self login];
}
    
- (void)login
{
    [PFLinkedInUtils logInWithBlock:^(PFUser *user, NSError *error) {
        NSLog(@"User: %@, Error: %@", user, error);
    }];
}
    
- (IBAction)didTapLogout:(id)sender {
    [PFLinkedInUtils logOut];
    
    [self login];
}

@end
