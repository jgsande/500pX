//
//  PGNormalCell.m
//  500px
//
//  Created by Polo Garcia on 12/11/15.
//  Copyright © 2015 Polo Garcia. All rights reserved.
//

#import "PGNormalCell.h"

@implementation PGNormalCell

-(instancetype)initWithFrame:(CGRect)frame{
    if (!(self = [super initWithFrame:frame])) {
        return nil;
    }
    self.backgroundColor = [UIColor darkGrayColor];
    UIImageView *imageV = [[UIImageView alloc] initWithFrame:self.bounds];
    imageV.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.contentView addSubview:imageV];
    self.imageView = imageV;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5, 10, 100, 30)];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont fontWithName:@"Arial" size:20.0f];
    label.hidden = YES;
    label.adjustsFontSizeToFitWidth = YES;
    [self.contentView addSubview:label];
    self.authorNameLabel = label;
    
    label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 30)];
    label.center = self.imageView.center;
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont fontWithName:@"Arial Bold" size:30.0f];
    label.textAlignment = NSTextAlignmentCenter;
    label.adjustsFontSizeToFitWidth = YES;
    label.hidden = YES;
    [self.contentView addSubview:label];
    self.photoNameLabel = label;
    
    return self;
}

@end
