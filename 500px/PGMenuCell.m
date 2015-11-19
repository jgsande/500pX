//
//  FRPCell.m
//  FunctionalReactivePixels
//
//  Created by Polo Garcia on 04/10/15.
//  Copyright © 2015 Polo Garcia. All rights reserved.
//

#import "PGMenuCell.h"

@interface PGMenuCell ()

@end

@implementation PGMenuCell

-(instancetype)initWithFrame:(CGRect)frame{
    if (!(self = [super initWithFrame:frame])) {
        return nil;
    }
    self.backgroundColor = [UIColor darkGrayColor];
    
    UIImageView *imageV = [[UIImageView alloc] initWithFrame:self.bounds];
    //imageV.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    imageV.contentMode = UIViewContentModeScaleToFill;
    [self.contentView addSubview:imageV];
    self.imageView = imageV;
    
    CGRect rect = CGRectMake(0, 0, 130, 50);
    UILabel *myLabel = [[UILabel alloc] initWithFrame:rect];
    myLabel.textColor = [UIColor whiteColor];
    myLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:30.0];
    
    [myLabel setCenter:CGPointMake(self.contentView.frame.size.width / 2, self.contentView.frame.size.height / 2)];
    myLabel.adjustsFontSizeToFitWidth = YES;
    myLabel.textAlignment = NSTextAlignmentCenter;
    
    self.label = myLabel;
    [self.contentView addSubview:myLabel];
    

    UIInterpolatingMotionEffect *motionEffect;
    motionEffect = [[UIInterpolatingMotionEffect alloc]
                    initWithKeyPath:@"center.x"
                    type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    
    motionEffect.minimumRelativeValue = @(-15);
    motionEffect.maximumRelativeValue = @(15);
    
    [self.contentView addMotionEffect:motionEffect];
    
    motionEffect = [[UIInterpolatingMotionEffect alloc]
                    initWithKeyPath:@"center.y"
                    type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    
    motionEffect.minimumRelativeValue = @(-15);
    motionEffect.maximumRelativeValue = @(15);
    [self.contentView addMotionEffect:motionEffect];
    return self;
}

-(void)prepareForReuse{
    [super prepareForReuse];
    self.imageView.image = nil;
}

@end
