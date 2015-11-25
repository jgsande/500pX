//
//  PGUserViewController.m
//  500px
//
//  Created by Polo Garcia on 22/11/15.
//  Copyright © 2015 Polo Garcia. All rights reserved.
//

#import "PGUserViewController.h"

@interface PGUserViewController ()

@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation PGUserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void)loadView{
    [super loadView];
    
    self.navigationItem.title = @"User menu";
    
    CGRect frame = CGRectMake(0, 0, 300, 300);
    UIImageView *imageV = [[UIImageView alloc] initWithFrame:frame];
    imageV.image = [UIImage imageNamed:@"Work_In_Progress"];
    
    self.imageView = imageV;
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.center = self.view.center;
    [self.view addSubview:self.imageView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
