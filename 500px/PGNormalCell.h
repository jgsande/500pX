//
//  PGNormalCell.h
//  500px
//
//  Created by Polo Garcia on 12/11/15.
//  Copyright © 2015 Polo Garcia. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PGNormalCell : UICollectionViewCell

@property (weak, nonatomic) UIImageView *imageView;
@property (weak, nonatomic) UIImageView *avatarView;
@property (weak, nonatomic) UILabel *authorNameLabel;
@property (weak, nonatomic) UILabel *likesLabel;
@property (weak, nonatomic) UILabel *dateLabel;
@property (weak, nonatomic) UILabel *photoNameLabel;
@property (weak, nonatomic) UILabel *gearLabel;

@end
